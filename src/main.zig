const std = @import("std");
const utf8ToUtf16 = @import("std").unicode.utf8ToUtf16LeStringLiteral;
const win = @import("std").os.windows;


extern "user32" fn DefWindowProcW(hWnd: win.HWND, Msg: win.UINT, wParam: usize, lParam: isize) callconv(.winapi) isize;

extern "kernel32" fn GetModuleHandleW(lpModuleName: ?win.LPCWSTR) callconv(.winapi) ?win.HMODULE;

extern "user32" fn RegisterClassExW(wc: ?*const WNDCLASSEXW) callconv(.winapi) win.ATOM;

extern "user32" fn CreateWindowExW(dwExStyle: win.DWORD, lpClassName: ?win.LPCWSTR, lpWindowName: ?win.LPCWSTR, dwStyle: win.DWORD, x: win.INT, y: win.INT, nWidth: win.INT, nHeight: win.INT, hWndParent: ?win.HWND, hMenu: ?win.HMENU, hInstance: ?win.HINSTANCE, lpParam: ?win.LPVOID) callconv(.winapi) ?win.HWND;

extern "user32" fn ShowWindow(hWnd: win.HWND, nCmdShow: win.INT) callconv(.winapi) win.BOOL;

extern "user32" fn PeekMessageW(lpMsg: *MSG, hWnd: ?win.HWND, wMsgFilterMin: win.UINT, wMsgFilterMax: win.UINT, wRemoveMsg: win.UINT) callconv(.winapi) win.INT;

extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.winapi) win.INT;

extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.winapi) isize;

extern "user32" fn PostQuitMessage(nExitCode: win.INT) callconv(.winapi) void;
 
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

// TODO: MAYBE CHANGE THESE NAMES
fn windowProcedure(window_handle: win.HWND, msg: win.UINT, wParam: usize, lParam: isize) callconv(.winapi) isize {
    const WM_SIZE: win.UINT = 0x0005;
    const WM_CLOSE: win.UINT = 0x0010;
    switch (msg) {
        WM_SIZE => {
            return 0;
        },
        WM_CLOSE => {
            PostQuitMessage(0);
            return 0;
        },
        else => return DefWindowProcW(window_handle, msg, wParam, lParam),
    }
} 

pub fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?win.HINSTANCE, lpCmdLine: win.LPWSTR, nShowCmd: win.INT) win.INT {
    _ = hPrevInstance;
    _ = lpCmdLine;
    main(hInstance, nShowCmd) catch return 1; // TODO: THIS ONLY MATTERS IF I WERE TO ACTUALLY USE THE ERROR UNIONS, SO USELESS CURRENTLY
    std.debug.print("END OF PROGRAM", .{});
    return 0;
}

fn main(hInstance: win.HINSTANCE, nShowCmd: win.INT) !void {
    const class_name: [*:0] const u16 = utf8ToUtf16("WINDOW CLASS");
    const window_text: [*:0] const u16 = utf8ToUtf16("Zig Window");
    const WS_OVERLAPPED: win.LONG = 0x00000000;
    const WS_CAPTION: win.LONG = 0x00C00000;
    const WS_SYSMENU: win.LONG = 0x00080000;
    const WS_THICKFRAME: win.LONG = 0x00040000;
    const WS_MINIMIZEBOX: win.LONG = 0x00020000;
    const WS_MAXIMIZEBOX: win.LONG = 0x00010000;
    const WS_OVERLAPPEDWINDOW: win.LONG = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | 
                                          WS_MAXIMIZEBOX;
    const CW_USEDEFAULT: win.INT = -2147483648;
    const module_instance: win.HINSTANCE = @ptrCast(hInstance); 

    var wc: WNDCLASSEXW = std.mem.zeroes(WNDCLASSEXW);
    wc.cbSize = @sizeOf(WNDCLASSEXW);
    wc.lpfnWndProc = windowProcedure;
    wc.hInstance = module_instance;
    wc.lpszClassName = class_name;

    _ = RegisterClassExW(&wc);
    // TODO: COULD RETURN ERROR.
    const window_handle: win.HWND = CreateWindowExW(0, class_name, window_text, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, 
                                                    CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, null, null, 
                                                    module_instance, null) orelse unreachable; 

    _ = ShowWindow(window_handle, nShowCmd);

    var msg: MSG = std.mem.zeroes(MSG);
    // TODO: MAKE A BETTER PLACE FOR THESE.
    const PM_REMOVE: win.UINT = 0x0001;
    const WM_QUIT: win.UINT = 0x0012;
    var should_quit: bool = false;
    while (!should_quit) {
        // PeekMessageW returns even if there are no messages in the queue,
        // this is obviously desired in a game as we can not wait to retrieve input for the game to progress.
        // The while loop ensures all of the messages in the queue are processed by window procedure and then 
        // removed from the queue (PeekMessageW returns 0 when there are no messages to handle,
        // PM_REMOVAL ensures removal), 
        // some messages are created at the moment of the function call as well.
        while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE) != 0) {
            if (msg.message == WM_QUIT) should_quit = true;
            _ = TranslateMessage(&msg);
            _ = DispatchMessageW(&msg);
        }
    }
    
}