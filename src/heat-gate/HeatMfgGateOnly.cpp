#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winnt.h>

#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdio>
#include <cstring>

namespace
{
constexpr std::array<std::uint8_t, 13> kPattern = {
    0x84, 0xD2, 0x0F, 0x84, 0x03, 0x01, 0x00, 0x00,
    0xBE, 0x05, 0x00, 0x00, 0x00};
constexpr std::array<std::uint8_t, 2> kOriginal = {0x0F, 0x84};
constexpr std::array<std::uint8_t, 2> kReplacement = {0xEB, 0x04};
constexpr std::array<std::uint8_t, 4> kCountOne = {0x41, 0x83, 0xF8, 0x01};

HMODULE g_self = nullptr;
HANDLE g_ready_event = nullptr;

void Log(const char *format, ...)
{
    wchar_t module_path[MAX_PATH] = {};
    GetModuleFileNameW(g_self, module_path, MAX_PATH);
    wchar_t *slash = wcsrchr(module_path, L'\\');
    if (slash) wcscpy_s(slash + 1, MAX_PATH - static_cast<size_t>(slash + 1 - module_path),
        L"HeatMfgGateOnly.log");

    SYSTEMTIME time = {};
    GetLocalTime(&time);
    char message[1024] = {};
    const int prefix = std::snprintf(message, sizeof(message),
        "%02u:%02u:%02u.%03u ", time.wHour, time.wMinute,
        time.wSecond, time.wMilliseconds);
    if (prefix <= 0 || static_cast<size_t>(prefix) >= sizeof(message)) return;
    va_list args;
    va_start(args, format);
    const int body = std::vsnprintf(message + prefix, sizeof(message) - prefix, format, args);
    va_end(args);
    if (body < 0) return;
    const size_t used = (std::min)(sizeof(message) - 2,
        static_cast<size_t>(prefix) + static_cast<size_t>(body));
    message[used] = '\r';
    message[used + 1] = '\n';
    HANDLE file = CreateFileW(module_path, FILE_APPEND_DATA,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
        OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) return;
    DWORD written = 0;
    WriteFile(file, message, static_cast<DWORD>(used + 2), &written, nullptr);
    CloseHandle(file);
}

bool IsAdaAdapter()
{
    DISPLAY_DEVICEW device = {};
    device.cb = sizeof(device);
    for (DWORD index = 0; EnumDisplayDevicesW(nullptr, index, &device, 0); ++index)
    {
        if ((device.StateFlags & DISPLAY_DEVICE_MIRRORING_DRIVER) == 0 &&
            wcsstr(device.DeviceID, L"VEN_10DE") != nullptr &&
            wcsstr(device.DeviceString, L"RTX 40") != nullptr)
        {
            Log("verified local Ada adapter: %ls", device.DeviceString);
            return true;
        }
        device = {};
        device.cb = sizeof(device);
    }
    return false;
}

bool StandaloneFirstPresentReady()
{
    wchar_t local_app_data[MAX_PATH] = {};
    const DWORD count = GetEnvironmentVariableW(L"LOCALAPPDATA", local_app_data, MAX_PATH);
    if (count == 0 || count >= MAX_PATH) return false;
    if (wcscat_s(local_app_data, L"\\RHI\\Logs\\standalone-dlssnr.log") != 0)
        return false;

    HANDLE file = CreateFileW(local_app_data, GENERIC_READ,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
        OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) return false;
    char buffer[32768] = {};
    DWORD read = 0;
    const BOOL ok = ReadFile(file, buffer, sizeof(buffer) - 1, &read, nullptr);
    CloseHandle(file);
    return ok && read != 0 &&
        std::strstr(buffer, "presentation contract candidate:") != nullptr;
}

bool IsExecuteRead(const void *address, size_t bytes)
{
    MEMORY_BASIC_INFORMATION info = {};
    if (VirtualQuery(address, &info, sizeof(info)) != sizeof(info)) return false;
    const auto begin = reinterpret_cast<std::uintptr_t>(address);
    const auto end = begin + bytes;
    const auto region_end = reinterpret_cast<std::uintptr_t>(info.BaseAddress) + info.RegionSize;
    const DWORD protection = info.Protect & 0xFFu;
    return end >= begin && end <= region_end && info.State == MEM_COMMIT &&
        (protection == PAGE_EXECUTE_READ || protection == PAGE_EXECUTE_WRITECOPY ||
         protection == PAGE_EXECUTE_READWRITE);
}

bool Matches(const std::uint8_t *candidate)
{
    return std::memcmp(candidate, kPattern.data(), 2) == 0 &&
        (std::memcmp(candidate + 2, kOriginal.data(), 2) == 0 ||
         std::memcmp(candidate + 2, kReplacement.data(), 2) == 0) &&
        std::memcmp(candidate + 4, kPattern.data() + 4, kPattern.size() - 4) == 0;
}

bool PatchProvider(HMODULE module, size_t &patched_rva)
{
    auto *base = reinterpret_cast<std::uint8_t *>(module);
    const auto *dos = reinterpret_cast<const IMAGE_DOS_HEADER *>(base);
    if (!dos || dos->e_magic != IMAGE_DOS_SIGNATURE || dos->e_lfanew <= 0 ||
        dos->e_lfanew > 0x100000) return false;
    const auto *nt = reinterpret_cast<const IMAGE_NT_HEADERS64 *>(base + dos->e_lfanew);
    if (nt->Signature != IMAGE_NT_SIGNATURE ||
        nt->OptionalHeader.Magic != IMAGE_NT_OPTIONAL_HDR64_MAGIC ||
        nt->FileHeader.NumberOfSections > 96) return false;

    const size_t image_bytes = nt->OptionalHeader.SizeOfImage;
    const auto valid = [image_bytes](size_t rva, size_t size) {
        return rva < image_bytes && size <= image_bytes - rva;
    };

    std::uint8_t *match = nullptr;
    size_t matches = 0;
    const IMAGE_SECTION_HEADER *section = IMAGE_FIRST_SECTION(nt);
    for (unsigned int i = 0; i < nt->FileHeader.NumberOfSections; ++i, ++section)
    {
        if ((section->Characteristics & IMAGE_SCN_MEM_EXECUTE) == 0 ||
            section->VirtualAddress >= image_bytes) continue;
        const size_t section_size = (std::min)(image_bytes - section->VirtualAddress,
            static_cast<size_t>((std::max)(section->Misc.VirtualSize, section->SizeOfRawData)));
        auto *begin = base + section->VirtualAddress;
        for (size_t offset = 0; offset + kPattern.size() <= section_size; ++offset)
        {
            if (!Matches(begin + offset)) continue;
            match = begin + offset;
            if (++matches != 1) return false;
        }
    }
    if (matches != 1 || !match) return false;

    const size_t match_rva = static_cast<size_t>(match - base);
    std::int32_t displacement = 0;
    std::memcpy(&displacement, match + 4, sizeof(displacement));
    const size_t target_rva = match_rva + 8 + displacement;
    DWORD64 image_base = 0;
    const RUNTIME_FUNCTION *function = RtlLookupFunctionEntry(
        reinterpret_cast<DWORD64>(match), &image_base, nullptr);
    if ((reinterpret_cast<std::uintptr_t>(match + 2) & 1u) != 0 ||
        !valid(target_rva, kCountOne.size()) ||
        std::memcmp(base + target_rva, kCountOne.data(), kCountOne.size()) != 0 ||
        !function || image_base != reinterpret_cast<DWORD64>(module) ||
        function->BeginAddress > match_rva ||
        function->EndAddress <= target_rva + kCountOne.size() ||
        !IsExecuteRead(match, kPattern.size()) ||
        !IsExecuteRead(base + target_rva, kCountOne.size()))
        return false;

    patched_rva = match_rva + 2;
    if (std::memcmp(match + 2, kReplacement.data(), 2) == 0) return true;
    if (std::memcmp(match + 2, kOriginal.data(), 2) != 0) return false;

    DWORD old_protection = 0;
    if (!VirtualProtect(match + 2, 2, PAGE_EXECUTE_WRITECOPY, &old_protection))
        return false;
    const short observed = InterlockedCompareExchange16(
        reinterpret_cast<volatile short *>(match + 2),
        static_cast<short>(0x04EB), static_cast<short>(0x840F));
    FlushInstructionCache(GetCurrentProcess(), match + 2, 2);
    DWORD unused = 0;
    VirtualProtect(match + 2, 2, old_protection, &unused);
    return (observed == static_cast<short>(0x840F) ||
            observed == static_cast<short>(0x04EB)) &&
        std::memcmp(match + 2, kReplacement.data(), 2) == 0;
}

DWORD WINAPI Worker(void *)
{
    wchar_t event_name[96] = {};
    swprintf_s(event_name, L"Local\\HeatMfgGateOnlyReady-%lu", GetCurrentProcessId());
    g_ready_event = CreateEventW(nullptr, TRUE, FALSE, event_name);
    if (!g_ready_event) return 0;

    // Do not touch the provider shared with OptiScaler. It initializes before
    // Frostbite's first Present and caches its own count maximum. The renderer
    // uses a private provider copy and waits on this process-local event before
    // calling that copy's Init_Ext.
    bool first_present_ready = false;
    for (unsigned int attempt = 0; attempt < 120000 && !first_present_ready; ++attempt)
    {
        first_present_ready = StandaloneFirstPresentReady();
        if (!first_present_ready) Sleep(1);
    }
    if (!first_present_ready)
    {
        Log("first Present marker did not appear within 120 seconds; patch not attempted");
        return 0;
    }
    Log("first Present marker observed; gate-only patch window opened");

    HMODULE provider = nullptr;
    for (unsigned int attempt = 0; attempt < 120000 && !provider; ++attempt)
    {
        provider = GetModuleHandleW(L"nvngx_dlssg_standalone.dll");
        if (!provider) Sleep(1);
    }
    if (!provider)
    {
        Log("private nvngx_dlssg_standalone.dll did not load within 120 seconds");
        return 0;
    }
    if (!IsAdaAdapter())
    {
        Log("RTX 40 adapter was not detected; patch not attempted");
        return 0;
    }

    HMODULE retained = nullptr;
    if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS,
            reinterpret_cast<LPCWSTR>(provider), &retained))
    {
        Log("provider retention failed: error=%lu", GetLastError());
        return 0;
    }

    size_t rva = 0;
    const bool patched = PatchProvider(retained, rva);
    Log("provider gate result: candidate_rva=0x%zX patched=%u module=%p",
        rva, patched ? 1u : 0u, retained);
    if (patched) SetEvent(g_ready_event);
    return 0;
}
}

BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID)
{
    if (reason == DLL_PROCESS_ATTACH)
    {
        g_self = instance;
        DisableThreadLibraryCalls(instance);
        HANDLE thread = CreateThread(nullptr, 0, Worker, nullptr, 0, nullptr);
        if (thread) CloseHandle(thread);
    }
    return TRUE;
}
