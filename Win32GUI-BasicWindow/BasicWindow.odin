package main

import "core:fmt"
import win32 "core:sys/windows"

CLASSNAME : cstring : "MyWindowClass"
APPNAME : cstring : "MyWindow"

WinProc :: proc "stdcall" (
    window: win32.HWND,
    message: win32.UINT,
    wparam: win32.WPARAM,
    lparam: win32.LPARAM 
) -> win32.LRESULT {

    result: win32.LRESULT

    switch message {
        case win32.WM_DESTROY:
            win32.DestroyWindow(window)
            win32.PostQuitMessage(0)
            result = 0
        case:
            result = win32.DefWindowProcW( window, message, wparam, lparam)
    }

    return result
}

main :: proc() {
    
    hinst : win32.HANDLE = auto_cast win32.GetModuleHandleW(nil)
    icon := win32.LoadIconA(nil, win32.IDI_APPLICATION)
    cursor := win32.LoadCursorA(nil, win32.IDC_ARROW)

    wndclass := win32.WNDCLASSEXW {
        size_of(win32.WNDCLASSEXW),
        win32.CS_HREDRAW | win32.CS_VREDRAW,
        WinProc,
        0,0,
        hinst,icon,cursor,nil,nil,
        win32.L(CLASSNAME),
        nil,
    }

    if error := win32.RegisterClassExW(&wndclass); error == 0 {
        win32.MessageBoxW(nil,win32.L("Unable to Register Window Class"),win32.L("Error"), win32.MB_ICONERROR)
    } 

    hwnd := win32.CreateWindowExW(
        win32.WS_EX_OVERLAPPEDWINDOW,
        win32.L(CLASSNAME),
        win32.L(APPNAME),
        win32.WS_OVERLAPPEDWINDOW | win32.WS_SYSMENU,
        win32.CW_USEDEFAULT,win32.CW_USEDEFAULT,win32.CW_USEDEFAULT,win32.CW_USEDEFAULT,
        nil,nil,hinst,nil,
    )

    if hwnd == nil {
        win32.MessageBoxW(nil,win32.L("Unable to Create Window"),win32.L("Error"), win32.MB_ICONERROR)
    }

    win32.ShowWindow(hwnd, win32.SW_SHOWNORMAL)

    msg : win32.MSG
    for {
        if win32.GetMessageW(&msg, nil, 0, 0) == 0 do break;
        win32.TranslateMessage(&msg)
        win32.DispatchMessageW(&msg)
    }

}