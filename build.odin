package main

import "core:fmt"
import "core:c/libc"
import "core:os"

main :: proc() {
    
    os.make_directory("bin")
    fmt.println("Building Examples into /bin")

    libc.system("odin build ./raylib_protable_window/raylib_portable_window.odin -out:bin/raylib_portable_window.exe -file")
    libc.system("odin build ./Win32GUI-BasicWindow/BasicWindow.odin -out:bin/basic-window.exe -file -subsystem:windows")
 
    // NOTE: will not show icon if you run this program from anywhere other than the bin folder.
    // NOTE: look into making the icon a compiled resource.
    libc.system("odin build ./Win32GUI-Window_Callback/CallbackWindow.odin -out:bin/callback-window.exe -file -subsystem:windows")
    
}