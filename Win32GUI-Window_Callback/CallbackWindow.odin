package main

import "core:fmt"
import win32 "core:sys/windows"

CLASSNAME : cstring : "MyWindowClass"
APPNAME : cstring : "MyWindow"

hdc : win32.HDC
background_brush : win32.HBRUSH
background_color := win32.GetSysColor( win32.COLOR_WINDOW)

WinProc :: proc "stdcall" (
    hwin: win32.HWND,
    message: win32.UINT,
    wparam: win32.WPARAM,
    lparam: win32.LPARAM 
) -> win32.LRESULT {

    result: win32.LRESULT

    switch message {
        case win32.WM_PAINT:
            rect : win32.RECT
            ps   : win32.PAINTSTRUCT
            if win32.GetUpdateRect(hwin, &rect, false) {
                win32.BeginPaint(hwin, &ps) // don't care about return

                win32.FillRect(hdc, &rect, background_brush)
                win32.TextOutW(hdc, 20, 20, win32.L("Hellope"), 7);
                win32.EndPaint(hwin, &ps)
                
            }
            result = 0

        case win32.WM_DESTROY:
            win32.DestroyWindow(hwin)
            win32.PostQuitMessage(0)
            result = 0

        case win32.WM_CREATE:
            hdc = win32.GetDC(hwin)
            background_brush = win32.CreateSolidBrush(background_color)

        case:
            result = win32.DefWindowProcW( hwin, message, wparam, lparam)
    }

    return result
}

main :: proc() {
    
    hinst : win32.HANDLE = auto_cast win32.GetModuleHandleW(nil)
    cursor := win32.LoadCursorA(nil, win32.IDC_ARROW)

    icon := win32.LoadImageW(
        nil,
        win32.L("..\\Resources\\troll.ico"),
        win32.IMAGE_ICON,
        0,
        0,
        win32.LR_DEFAULTSIZE | win32.LR_LOADFROMFILE
    )


    if icon == nil {
        // NOTE: we are just ignoring this.
        // if you want the wonderful icon to show, change directory to bin before running program
        // or change the icon path above 
        //win32.MessageBoxW(nil,win32.L("Unable to Load Icon"),win32.L("Error"), win32.MB_ICONERROR)

    } 

    wndclass := win32.WNDCLASSEXW {
        size_of(win32.WNDCLASSEXW),
        win32.CS_HREDRAW | win32.CS_VREDRAW | win32.CS_OWNDC,
        WinProc,
        0,0,
        hinst,win32.HICON(icon),cursor,nil,nil,
        win32.L(CLASSNAME),
        win32.HICON(icon),
    }


    if error := win32.RegisterClassExW(&wndclass); error == 0 {
        win32.MessageBoxW(nil,win32.L("Unable to Register Window Class"),win32.L("Error"), win32.MB_ICONERROR)
    } 

    hwnd := win32.CreateWindowExW(
        win32.WS_EX_OVERLAPPEDWINDOW |
         win32.WS_CLIPCHILDREN | 
         win32.ES_NOHIDESEL,
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
        if !win32.GetMessageW(&msg, nil, 0, 0) do break;
        win32.TranslateMessage(&msg)
        win32.DispatchMessageW(&msg)
    }

}