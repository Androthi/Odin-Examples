package raylib_portable_window

import "core:c/libc"

// conversion of portable_window.c example to odin.
// LICENSE: zlib/libpng

import rl "vendor:raylib"

main :: proc() {

    screenWidth  : libc.int = 800
    screenHeight : libc.int = 600
    
    rl.SetConfigFlags({.WINDOW_UNDECORATED})
    rl.InitWindow(screenWidth, screenHeight, "raygui - protable window")

    mousePosition  : rl.Vector2
    windowPosition : rl.Vector2 = { 500, 200 }
    panOffset := mousePosition
    dragWindow : bool = false

    rl.SetWindowPosition(libc.int(windowPosition.x), libc.int(windowPosition.y))

    exitWindow : libc.int = 0

    rl.SetTargetFPS(60)

    for (exitWindow == 0 && !rl.WindowShouldClose()) {
        
        // Update
        mousePosition = rl.GetMousePosition()

        if(rl.IsMouseButtonPressed(rl.MouseButton.LEFT) && !dragWindow) {
            
            if(rl.CheckCollisionPointRec(mousePosition, rl.Rectangle({0,0, f32(screenWidth), 20}))) {

                dragWindow = true
                panOffset = mousePosition

            }
        }

        if(dragWindow) {
            windowPosition.x += mousePosition.x - panOffset.x
            windowPosition.y += mousePosition.y - panOffset.y

            rl.SetWindowPosition(libc.int(windowPosition.x), libc.int(windowPosition.y))
            if rl.IsMouseButtonReleased((rl.MouseButton.LEFT)) { dragWindow = false }
        }

        // Draw
        rl.BeginDrawing()

            rl.ClearBackground(rl.RAYWHITE)

            exitWindow = rl.GuiWindowBox( rl.Rectangle({0, 0, f32(screenWidth), f32(screenHeight) }), "#198# PORTABLE WINDOW")

            // NOTE: made the font sizes bigger than the original C example
            rl.DrawText(rl.TextFormat("Mouse Position: [ %.0f, %.0f ]", mousePosition.x, mousePosition.y), 10, 40, 40, rl.DARKGRAY)
            rl.DrawText(rl.TextFormat("Window Position: [ %.0f, %.0f ]", windowPosition.x, windowPosition.y), 10,100, 40, rl.DARKGRAY)

        rl.EndDrawing()
    }

    // De-Initialization
    rl.CloseWindow()

}