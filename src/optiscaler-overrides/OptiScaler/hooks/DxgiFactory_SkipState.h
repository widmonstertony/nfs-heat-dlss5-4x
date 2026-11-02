#pragma once

// DXGI factories can be observed through both the vtable-hook path and the
// wrapped-factory path during one nested CreateSwapChain call. They must share
// the same recursion guard; separate flags allow an internal swapchain created
// by one path to be mistaken for a second game swapchain by the other path.
namespace DxgiFactorySkipState
{
inline bool skipFGSwapChainCreation = false;
}

