const std = @import("std");
const utf8ToUtf16 = @import("std").unicode.utf8ToUtf16LeStringLiteral;
const win = @import("std").os.windows;


extern "user32" fn DefWindowProcW(hWnd: win.HWND, Msg: win.UINT, wParam: usize, lParam: isize) callconv(.winapi) isize;

extern "kernel32" fn GetModuleHandleW(lpModuleName: ?win.LPCWSTR) callconv(.winapi) ?win.HMODULE;

extern "user32" fn RegisterClassExW(wc: ?*const WNDCLASSEXW) callconv(.winapi) win.ATOM;

extern "user32" fn CreateWindowExW(dwExStyle: win.DWORD, lpClassName: ?win.LPCWSTR, lpWindowName: ?win.LPCWSTR, dwStyle: win.DWORD, x: win.INT, y: win.INT, nWidth: win.INT, nHeight: win.INT, hWndParent: ?win.HWND, hMenu: ?win.HMENU, hInstance: ?win.HINSTANCE, lpParam: ?win.LPVOID) callconv(.winapi) ?win.HWND;

extern "user32" fn ShowWindow(hWnd: win.HWND, nCmdShow: win.INT) callconv(.winapi) win.BOOL;

extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: ?win.HWND, wMsgFilterMin: win.UINT, wMsgFilterMax: win.UINT) callconv(.winapi) win.INT;

extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.winapi) win.INT;

extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.winapi) isize;
 
const WNDCLASSEXW = extern struct {
    cbSize: win.UINT,
    style: win.UINT,
    lpfnWndProc: ?*const fn (up1: win.HWND, up2: win.UINT, up3: usize, up4: isize) callconv(.winapi) isize,
    cbClsExtra: win.INT,
    cbWndExtra: win.INT,
    hInstance: win.HINSTANCE,
    hIcon: win.HICON,
    hCursor: win.HCURSOR,
    hbrBackground: win.HBRUSH,
    lpszMenuName: win.LPCWSTR,
    lpszClassName: win.LPCWSTR,
    hIconSm: win.HICON
};

const POINT = extern struct {
    x: win.LONG,
    y: win.LONG,
};

const MSG = extern struct {
    hwnd: win.HWND,
    message: win.UINT,
    wParam: usize,
    lParam: isize,
    time: win.DWORD,
    pt: POINT,
    lPrivate: win.DWORD,
};

pub fn main() !void {
    const class_name: [*:0] const u16 = utf8ToUtf16("WINDOW CLASS");
    const window_text: [*:0] const u16 = utf8ToUtf16("Zig Window");
    const WS_OVERLAPPED: win.LONG = 0x00000000;
    const WS_CAPTION: win.LONG = 0x00C00000;
    const WS_SYSMENU: win.LONG = 0x00080000;
    const WS_THICKFRAME: win.LONG = 0x00040000;
    const WS_MINIMIZEBOX: win.LONG = 0x00020000;
    const WS_MAXIMIZEBOX: win.LONG = 0x00010000;
    const WS_OVERLAPPEDWINDOW: win.LONG = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;
    std.debug.print("{d}", .{WS_OVERLAPPED + WS_CAPTION});
    const module_instance: win.HINSTANCE = @ptrCast(GetModuleHandleW(null) orelse return); 

    var wc: WNDCLASSEXW = std.mem.zeroes(WNDCLASSEXW);
    wc.cbSize = @sizeOf(WNDCLASSEXW);
    wc.lpfnWndProc = DefWindowProcW;
    wc.hInstance = module_instance;
    wc.lpszClassName = class_name;

    _ = RegisterClassExW(&wc);
    const window_handle: win.HWND = CreateWindowExW(0, class_name, window_text, WS_OVERLAPPEDWINDOW, 100, 100, 800, 600, null, null, module_instance, null) orelse return;

    _ = ShowWindow(window_handle, 5);

    var msg: MSG = std.mem.zeroes(MSG);
    while (GetMessageW(&msg, null, 0, 0) > 0) {
        _ = TranslateMessage(&msg);
        _ = DispatchMessageW(&msg);
    }
}