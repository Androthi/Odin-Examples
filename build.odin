package main

import "core:fmt"
import "core:c/libc"
import "core:os"

/*
    This will compile all the examples and place them in the bin folder

*/

main :: proc() {
    
    fmt.println("Building Examples into /bin")

    libc.system("odin build ./Win32GUI-BasicWindow/BasicWindow.odin -out:bin/basic-window.exe -file -subsystem:windows")
    libc.system("odin build ./Win32GUI-PaintWindow/PaintWindow.odin -out:bin/callback-window.exe -file -subsystem:windows -resource:Win32GUI-PaintWindow/res.rc")

    libc.system("odin build ./raylib_portable_window/raylib_portable_window.odin -out:bin/raylib_portable_window.exe -file")
    libc.system("odin build ./raylib_asteroids/asteroids.odin -out:bin/asteroids.exe -file")
}