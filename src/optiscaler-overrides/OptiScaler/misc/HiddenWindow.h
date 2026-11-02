// Modified for the Heat experimental integration, 2026-11-01. See docs/PIPELINE.md.
#pragma once
#include <windows.h>
#include <stdexcept>

inline HWND g_hiddenSwapchainWindow = nullptr;
inline constexpr wchar_t kHiddenSwapchainWindowClass[] = L"OptiDx11SwapchainHost";

inline bool IsHiddenSwapchainWindow(HWND hwnd)
{
    if (hwnd == nullptr)
        return false;

    if (hwnd == g_hiddenSwapchainWindow)
        return true;

    wchar_t className[64] = {};
    return GetClassNameW(hwnd, className, ARRAYSIZE(className)) > 0 &&
           wcscmp(className, kHiddenSwapchainWindowClass) == 0;
}

inline bool IsNvPresentAuxiliaryWindow(HWND hwnd)
{
    if (hwnd == nullptr)
        return false;

    wchar_t className[64] = {};
    return GetClassNameW(hwnd, className, ARRAYSIZE(className)) > 0 &&
           wcscmp(className, L"InvisibleWindowClassNvPresent") == 0;
}

inline static LRESULT CALLBACK HiddenSwapchainWindowProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

inline HWND CreateHiddenSwapchainWindow()
{
    if (g_hiddenSwapchainWindow != nullptr)
        return g_hiddenSwapchainWindow;

    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = HiddenSwapchainWindowProc;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpszClassName = kHiddenSwapchainWindowClass;

    if (!RegisterClassExW(&wc))
    {
        if (GetLastError() != ERROR_CLASS_ALREADY_EXISTS)
            throw std::runtime_error("RegisterClassExW failed");
    }

    // ReShade creates a runtime for this bootstrap swapchain before the real
    // Frostbite swapchain exists. A 1x1 client makes its empty-texture setup
    // fail with DXGI_ERROR_DRIVER_INTERNAL_ERROR, which prevents it from ever
    // observing the real swapchain. Keep the host hidden, but give the
    // bootstrap swapchain a small non-degenerate client area.
    g_hiddenSwapchainWindow = CreateWindowExW(WS_EX_TOOLWINDOW, kHiddenSwapchainWindowClass, L"", WS_POPUP, 0, 0, 64, 64,
                                              nullptr, nullptr, wc.hInstance, nullptr);

    if (g_hiddenSwapchainWindow == nullptr)
        throw std::runtime_error("CreateWindowExW failed");

    ShowWindow(g_hiddenSwapchainWindow, SW_HIDE);
    return g_hiddenSwapchainWindow;
}

inline void DestroyHiddenSwapchainWindow()
{
    if (g_hiddenSwapchainWindow != nullptr)
    {
        DestroyWindow(g_hiddenSwapchainWindow);
        g_hiddenSwapchainWindow = nullptr;
    }
}
