package asteroids

// Odin port of asteroids example from the raylib project.
// Some changes from the original have been made.


/*******************************************************************************************
*
*   raylib - classic game: asteroids
*
*   Sample game developed by Ian Eito, Albert Martos and Ramon Santamaria
*
*   This game has been created using raylib v1.3 (www.raylib.com)
*   raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)
*
*   Copyright (c) 2015 Ramon Santamaria (@raysan5)
*
********************************************************************************************/
/*
	Copyright (c) 2013-2022 Ramon Santamaria (@raysan5)

	This software is provided "as-is", without any express or implied warranty. In no event 
	will the authors be held liable for any damages arising from the use of this software.

	Permission is granted to anyone to use this software for any purpose, including commercial 
	applications, and to alter it and redistribute it freely, subject to the following restrictions:

		1. The origin of this software must not be misrepresented; you must not claim that you 
		wrote the original software. If you use this software in a product, an acknowledgment 
		in the product documentation would be appreciated but is not required.

		2. Altered source versions must be plainly marked as such, and must not be misrepresented
		as being the original software.

		3. This notice may not be removed or altered from any source distribution.
*/

import "core:math"
import rl "vendor:raylib"
import "core:c"
import "core:fmt"


PLAYER_BASE_SIZE	:: 20.0
PLAYER_SPEED		:: 6.0
PLAYER_MAX_SHOOTS	:: 10

METEORS_SPEED		:: 2
MAX_BIG_METEORS		:: 4
MAX_MEDIUM_METEORS	:: 8
MAX_SMALL_METEORS	:: 16

screenWidth			:i32: 800
screenHeight		:i32: 450

gameOver	:bool
pause		:bool
victory		:bool


// NOTE: Defined triangle is isosceles with common angles of 70 degrees.
shipHeight	:f32
player		:Player
shoot		:[PLAYER_MAX_SHOOTS]Shoot
bigMeteor	:[MAX_BIG_METEORS]Meteor
mediumMeteor:[MAX_MEDIUM_METEORS]Meteor
smallMeteor	:[MAX_SMALL_METEORS]Meteor

midMeteorsCount			:c.int
smallMeteorsCount		:c.int
destroyedMeteorsCount	:c.int

Player :: struct {
    position	:rl.Vector2,
    speed		:rl.Vector2,
    acceleration:f32, //f64?
    rotation	:f32,
    collider	:rl.Vector3,
    color		:rl.Color,
}

Shoot :: struct {
    position	:rl.Vector2,
    speed		:rl.Vector2,
    radius		:f32,
    rotation	:f32,
    lifeSpawn	:c.int,
    active		:bool,
    color		:rl.Color,
}

Meteor :: struct {
    position	:rl.Vector2,
    speed		:rl.Vector2,
    radius		:f32,
    active		:bool,
    color		:rl.Color,
}

main :: proc() {
	rl.InitWindow(screenWidth, screenHeight, "classic game: asteroids")
	InitGame()

	rl.SetTargetFPS(60)
    for !rl.WindowShouldClose()    // Detect window close button or ESC key
    {
        // Update and Draw
        //----------------------------------------------------------------------------------
        UpdateDrawFrame()
        //----------------------------------------------------------------------------------
    }
    
	UnloadGame()		// Unload loaded data (textures, sounds, models...)
    rl.CloseWindow()	// Close window and OpenGL context
    //--------------------------------------------------------------------------------------
	
    return
	
}

//------------------------------------------------------------------------------------
// Module Functions Definitions (local)
//------------------------------------------------------------------------------------

InitGame :: proc() {
	
	posx, posy	:c.int
	velx, vely	:c.int

	 correctRange :bool
	 victory = false
	 pause = false
		
	shipHeight = (PLAYER_BASE_SIZE/2)/math.tan_f32(20*rl.DEG2RAD)
		
	// Initialization player
	player.position = (rl.Vector2){ f32(screenWidth/2), f32(screenHeight/2) - shipHeight/2}
	player.speed = (rl.Vector2){0, 0}
	player.acceleration = 0
	player.rotation = 0
	player.collider = (rl.Vector3){player.position.x + math.sin(player.rotation*rl.DEG2RAD)*(shipHeight/2.5), player.position.y - math.cos(player.rotation*rl.DEG2RAD)*(shipHeight/2.5), 12}
	player.color = rl.LIGHTGRAY

	destroyedMeteorsCount = 0
	
    // Initialization shoot
    for i := 0; i < PLAYER_MAX_SHOOTS; i+=1
    {
        shoot[i].position = (rl.Vector2){0, 0}
        shoot[i].speed = (rl.Vector2){0, 0}
        shoot[i].radius = 2
        shoot[i].active = false
        shoot[i].lifeSpawn = 0
        shoot[i].color = rl.WHITE
    }

    for i := 0; i < MAX_BIG_METEORS; i+=1
    {
        posx = rl.GetRandomValue(0, screenWidth)

        for !correctRange
        {
            if posx > screenWidth/2 - 150 && posx < screenWidth/2 + 150 {
				posx = rl.GetRandomValue(0, screenWidth)
			} else { correctRange = true }
        }

        correctRange = false

        posy = rl.GetRandomValue(0, screenHeight)

        for !correctRange
        {
            if posy > screenHeight/2 - 150 && posy < screenHeight/2 + 150 {
				posy = rl.GetRandomValue(0, screenHeight)
			} else { correctRange = true }
        }

        bigMeteor[i].position = (rl.Vector2){f32(posx), f32(posy)}

        correctRange = false
        velx = rl.GetRandomValue(-METEORS_SPEED, METEORS_SPEED)
        vely = rl.GetRandomValue(-METEORS_SPEED, METEORS_SPEED)

        for !correctRange
        {
            if velx == 0 && vely == 0
            {
                velx = rl.GetRandomValue(-METEORS_SPEED, METEORS_SPEED)
                vely = rl.GetRandomValue(-METEORS_SPEED, METEORS_SPEED)
            } else { correctRange = true }
        }

        bigMeteor[i].speed = (rl.Vector2){f32(velx), f32(vely)}
        bigMeteor[i].radius = 40
        bigMeteor[i].active = true
        bigMeteor[i].color = rl.BLUE
    }
 
	for i:=0; i < MAX_MEDIUM_METEORS; i+=1
    {
        mediumMeteor[i].position = (rl.Vector2){-100, -100}
        mediumMeteor[i].speed = (rl.Vector2){0,0}
        mediumMeteor[i].radius = 20
        mediumMeteor[i].active = false
        mediumMeteor[i].color = rl.BLUE
    }

    for i:=0; i < MAX_SMALL_METEORS; i+=1
    {
        smallMeteor[i].position = (rl.Vector2){-100, -100}
        smallMeteor[i].speed = (rl.Vector2){0,0}
        smallMeteor[i].radius = 10
        smallMeteor[i].active = false
        smallMeteor[i].color = rl.BLUE
    }

    midMeteorsCount = 0
    smallMeteorsCount = 0
}

// Update game (one frame)
UpdateGame :: proc() {

    if !gameOver {

		if rl.IsKeyPressed(.P) do pause = !pause

        if (!pause)
        { 
			// Player logic: rotation
            if rl.IsKeyDown(.LEFT) do player.rotation -= 5
            if rl.IsKeyDown(.RIGHT) do player.rotation += 5
			
            // Player logic: speed
            player.speed.x = math.sin(player.rotation*rl.DEG2RAD)*PLAYER_SPEED;
            player.speed.y = math.cos(player.rotation*rl.DEG2RAD)*PLAYER_SPEED;
			
            // Player logic: acceleration
            if rl.IsKeyDown(.UP) {
                if player.acceleration < 1 do player.acceleration += 0.04
            } else {
                if player.acceleration > 0 {
					player.acceleration -= 0.02
				} else if player.acceleration < 0 do player.acceleration = 0
            }
            if rl.IsKeyDown(.DOWN)
            {
                if player.acceleration > 0 {
					player.acceleration -= 0.04
				} else if player.acceleration < 0 do player.acceleration = 0
            }

            // Player logic: movement
            player.position.x += (player.speed.x*player.acceleration)
            player.position.y -= (player.speed.y*player.acceleration)

            // Collision logic: player vs walls
            if player.position.x > f32(screenWidth) + f32(shipHeight) do player.position.x = -(shipHeight)
            else if player.position.x < -(shipHeight) do player.position.x = f32(screenWidth) + f32(shipHeight)
            if player.position.y > (f32(screenHeight) + f32(shipHeight)) do player.position.y = -(shipHeight)
            else if player.position.y < -(shipHeight) do player.position.y = f32(screenHeight) + f32(shipHeight)

            // Player shoot logic
            if rl.IsKeyPressed(.SPACE)
            {
                for i:= 0; i < PLAYER_MAX_SHOOTS; i+=1
                {
                    if !shoot[i].active
                    {
                        shoot[i].position = (rl.Vector2){ player.position.x + math.sin(player.rotation*rl.DEG2RAD)*(shipHeight), player.position.y - math.cos(player.rotation*rl.DEG2RAD)*(shipHeight) }
                        shoot[i].active = true
                        shoot[i].speed.x = 1.5*math.sin(player.rotation*rl.DEG2RAD)*PLAYER_SPEED
                        shoot[i].speed.y = 1.5*math.cos(player.rotation*rl.DEG2RAD)*PLAYER_SPEED
                        shoot[i].rotation = player.rotation
                        break
                    }
                }
            }
            
			// Shoot life timer
            for i:= 0; i < PLAYER_MAX_SHOOTS; i+=1
            {
				if shoot[i].active do shoot[i].lifeSpawn+=1
			}
				
				
            // Shot logic
            for i:= 0; i < PLAYER_MAX_SHOOTS; i+=1
            {
                if shoot[i].active
                {
                    // Movement
                    shoot[i].position.x += shoot[i].speed.x
                    shoot[i].position.y -= shoot[i].speed.y

                    // Collision logic: shoot vs walls
                    if shoot[i].position.x >f32(screenWidth) + shoot[i].radius
                    {
                        shoot[i].active = false
                        shoot[i].lifeSpawn = 0
                    }
                    else if shoot[i].position.x < 0 - shoot[i].radius
                    {
                        shoot[i].active = false
                        shoot[i].lifeSpawn = 0
                    }
                    if shoot[i].position.y > f32(screenHeight) + shoot[i].radius
                    {
                        shoot[i].active = false
                        shoot[i].lifeSpawn = 0
                    }
                    else if shoot[i].position.y < 0 - shoot[i].radius
                    {
                        shoot[i].active = false
                        shoot[i].lifeSpawn = 0
                    }

                    // Life of shoot
                    if shoot[i].lifeSpawn >= 60
                    {
                        shoot[i].position = (rl.Vector2){0, 0}
                        shoot[i].speed = (rl.Vector2){0, 0}
                        shoot[i].lifeSpawn = 0
                        shoot[i].active = false
                    }
                }
            }

            // Collision logic: player vs meteors
            player.collider = (rl.Vector3){player.position.x + math.sin(player.rotation*rl.DEG2RAD)*(shipHeight/2.5), player.position.y - math.cos(player.rotation*rl.DEG2RAD)*(shipHeight/2.5), 12}

            for a:= 0; a < MAX_BIG_METEORS; a+=1
            {
                if rl.CheckCollisionCircles((rl.Vector2){player.collider.x, player.collider.y}, player.collider.z, bigMeteor[a].position, bigMeteor[a].radius) && bigMeteor[a].active do gameOver = true
            }

            for a:= 0; a < MAX_MEDIUM_METEORS; a+=1
            {
                if rl.CheckCollisionCircles((rl.Vector2){player.collider.x, player.collider.y}, player.collider.z, mediumMeteor[a].position, mediumMeteor[a].radius) && mediumMeteor[a].active do gameOver = true
            }

            for a:= 0; a < MAX_SMALL_METEORS; a+=1
            {
                if rl.CheckCollisionCircles((rl.Vector2){player.collider.x, player.collider.y}, player.collider.z, smallMeteor[a].position, smallMeteor[a].radius) && smallMeteor[a].active do gameOver = true
            }

            // Meteors logic: big meteors
            for i:= 0; i < MAX_BIG_METEORS; i+=1
            {
                if bigMeteor[i].active
                {
                    // Movement
                    bigMeteor[i].position.x += bigMeteor[i].speed.x
                    bigMeteor[i].position.y += bigMeteor[i].speed.y

                    // Collision logic: meteor vs wall
                    if bigMeteor[i].position.x > f32(screenWidth) + bigMeteor[i].radius do bigMeteor[i].position.x = -(bigMeteor[i].radius)
                    else if bigMeteor[i].position.x < 0 - bigMeteor[i].radius do bigMeteor[i].position.x = f32(screenWidth) + bigMeteor[i].radius
                    if bigMeteor[i].position.y > f32(screenHeight) + bigMeteor[i].radius do bigMeteor[i].position.y = -(bigMeteor[i].radius)
                    else if bigMeteor[i].position.y < 0 - bigMeteor[i].radius do bigMeteor[i].position.y = f32(screenHeight) + bigMeteor[i].radius
                }
            }

            // Meteors logic: medium meteors
            for i:= 0; i < MAX_MEDIUM_METEORS; i+=1
            {
                if mediumMeteor[i].active
                {
                    // Movement
                    mediumMeteor[i].position.x += mediumMeteor[i].speed.x
                    mediumMeteor[i].position.y += mediumMeteor[i].speed.y

                    // Collision logic: meteor vs wall
                    if mediumMeteor[i].position.x > f32(screenWidth) + mediumMeteor[i].radius do mediumMeteor[i].position.x = -(mediumMeteor[i].radius)
                    else if mediumMeteor[i].position.x < 0 - mediumMeteor[i].radius do mediumMeteor[i].position.x = f32(screenWidth) + mediumMeteor[i].radius
                    if mediumMeteor[i].position.y > f32(screenHeight) + mediumMeteor[i].radius do mediumMeteor[i].position.y = -(mediumMeteor[i].radius)
                    else if mediumMeteor[i].position.y < 0 - mediumMeteor[i].radius do mediumMeteor[i].position.y = f32(screenHeight) + mediumMeteor[i].radius
                }
            }

            // Meteors logic: small meteors
            for i:= 0; i < MAX_SMALL_METEORS; i+=1
            {
                if smallMeteor[i].active
                {
                    // Movement
                    smallMeteor[i].position.x += smallMeteor[i].speed.x
                    smallMeteor[i].position.y += smallMeteor[i].speed.y

                    // Collision logic: meteor vs wall
                    if smallMeteor[i].position.x > f32(screenWidth) + smallMeteor[i].radius do smallMeteor[i].position.x = -(smallMeteor[i].radius)
                    else if smallMeteor[i].position.x < 0 - smallMeteor[i].radius do smallMeteor[i].position.x = f32(screenWidth) + smallMeteor[i].radius
                    if smallMeteor[i].position.y > f32(screenHeight) + smallMeteor[i].radius do smallMeteor[i].position.y = -(smallMeteor[i].radius)
                    else if smallMeteor[i].position.y < 0 - smallMeteor[i].radius do smallMeteor[i].position.y = f32(screenHeight) + smallMeteor[i].radius
                }
            }

            // Collision logic: player-shoots vs meteors
            for i:= 0; i < PLAYER_MAX_SHOOTS; i+=1
            {
                if shoot[i].active
                {
                    for a:= 0; a < MAX_BIG_METEORS; a+=1
                    {
                        if bigMeteor[a].active && rl.CheckCollisionCircles(shoot[i].position, shoot[i].radius, bigMeteor[a].position, bigMeteor[a].radius)
                        {
                            shoot[i].active = false
                            shoot[i].lifeSpawn = 0
                            bigMeteor[a].active = false
                            destroyedMeteorsCount+=1

                            for j:= 0; j < 2; j +=1
                            {
                                if midMeteorsCount%2 == 0
                                {
                                    mediumMeteor[midMeteorsCount].position = (rl.Vector2){bigMeteor[a].position.x, bigMeteor[a].position.y}
                                    mediumMeteor[midMeteorsCount].speed = (rl.Vector2){math.cos(shoot[i].rotation*rl.DEG2RAD)*METEORS_SPEED*-1, math.sin(shoot[i].rotation*rl.DEG2RAD)*METEORS_SPEED*-1}
                                }
                                else
                                {
                                    mediumMeteor[midMeteorsCount].position = (rl.Vector2){bigMeteor[a].position.x, bigMeteor[a].position.y}
                                    mediumMeteor[midMeteorsCount].speed = (rl.Vector2){math.cos(shoot[i].rotation*rl.DEG2RAD)*METEORS_SPEED, math.sin(shoot[i].rotation*rl.DEG2RAD)*METEORS_SPEED}
                                }

                                mediumMeteor[midMeteorsCount].active = true
                                midMeteorsCount +=1
                            }
                            bigMeteor[a].color = rl.RED
                            a = MAX_BIG_METEORS
                        }
                    }

                    for b:= 0; b < MAX_MEDIUM_METEORS; b+=1
                    {
                        if mediumMeteor[b].active && rl.CheckCollisionCircles(shoot[i].position, shoot[i].radius, mediumMeteor[b].position, mediumMeteor[b].radius)
                        {
                            shoot[i].active = false
                            shoot[i].lifeSpawn = 0
                            mediumMeteor[b].active = false
                            destroyedMeteorsCount+=1

                            for j:= 0; j < 2; j +=1
                            {
                                 if smallMeteorsCount%2 == 0
                                {
                                    smallMeteor[smallMeteorsCount].position = (rl.Vector2){mediumMeteor[b].position.x, mediumMeteor[b].position.y}
                                    smallMeteor[smallMeteorsCount].speed = (rl.Vector2){math.cos(shoot[i].rotation*rl.DEG2RAD)*METEORS_SPEED*-1, math.sin(shoot[i].rotation*rl.DEG2RAD)*METEORS_SPEED*-1}
                                }
                                else
                                {
                                    smallMeteor[smallMeteorsCount].position = (rl.Vector2){mediumMeteor[b].position.x, mediumMeteor[b].position.y}
                                    smallMeteor[smallMeteorsCount].speed = (rl.Vector2){math.cos(shoot[i].rotation*rl.DEG2RAD)*METEORS_SPEED, math.sin(shoot[i].rotation*rl.DEG2RAD)*METEORS_SPEED}
                                }

                                smallMeteor[smallMeteorsCount].active = true
                                smallMeteorsCount +=1
                            }
                            mediumMeteor[b].color = rl.GREEN
                            b = MAX_MEDIUM_METEORS
                        }
                    }

                    for c:= 0; c < MAX_SMALL_METEORS; c+=1
                    {
                        if smallMeteor[c].active && rl.CheckCollisionCircles(shoot[i].position, shoot[i].radius, smallMeteor[c].position, smallMeteor[c].radius)
                        {
                            shoot[i].active = false
                            shoot[i].lifeSpawn = 0
                            smallMeteor[c].active = false
                            destroyedMeteorsCount+=1
                            smallMeteor[c].color = rl.YELLOW
                            c = MAX_SMALL_METEORS
                        }
                    }
                }
            }
        }

        if destroyedMeteorsCount == MAX_BIG_METEORS + MAX_MEDIUM_METEORS + MAX_SMALL_METEORS do victory = true
    } else {
        if rl.IsKeyPressed(.ENTER)
        {
            InitGame()
            gameOver = false
        }
    }
}


// Draw game (one frame)
DrawGame :: proc() {
	
    rl.BeginDrawing();

        rl.ClearBackground(rl.RAYWHITE);

        if !gameOver
        {
            // Draw spaceship
            v1 :rl.Vector2 = { player.position.x + math.sin_f32(player.rotation*rl.DEG2RAD)*(shipHeight), player.position.y - math.cos_f32(player.rotation*rl.DEG2RAD)*(shipHeight) }
            v2 :rl.Vector2 = { player.position.x - math.cos_f32(player.rotation*rl.DEG2RAD)*(PLAYER_BASE_SIZE/2), player.position.y - math.sin_f32(player.rotation*rl.DEG2RAD)*(PLAYER_BASE_SIZE/2) }
            v3 :rl.Vector2 = { player.position.x + math.cos_f32(player.rotation*rl.DEG2RAD)*(PLAYER_BASE_SIZE/2), player.position.y + math.sin_f32(player.rotation*rl.DEG2RAD)*(PLAYER_BASE_SIZE/2) }
			
			rl.DrawTriangle(v1, v2, v3, rl.MAROON)

            // Draw meteors
            for i:= 0; i < MAX_BIG_METEORS; i+=1
            {
                if bigMeteor[i].active { rl.DrawCircleV(bigMeteor[i].position, bigMeteor[i].radius, rl.DARKGRAY) }
                else do rl.DrawCircleV(bigMeteor[i].position, bigMeteor[i].radius, rl.Fade(rl.LIGHTGRAY, 0.3))
            }
            for i:= 0; i < MAX_MEDIUM_METEORS; i+=1
            {
				if mediumMeteor[i].active { rl.DrawCircleV(mediumMeteor[i].position, mediumMeteor[i].radius, rl.GRAY) }
                else do rl.DrawCircleV(mediumMeteor[i].position, mediumMeteor[i].radius, rl.Fade(rl.LIGHTGRAY, 0.3))
			}
				
            for i:= 0; i < MAX_SMALL_METEORS; i+=1
            {
				if smallMeteor[i].active { rl.DrawCircleV(smallMeteor[i].position, smallMeteor[i].radius, rl.GRAY) }
                else do rl.DrawCircleV(smallMeteor[i].position, smallMeteor[i].radius, rl.Fade(rl.LIGHTGRAY, 0.3))
			}
				
				
            // Draw shoot
            for i:= 0; i < PLAYER_MAX_SHOOTS; i+=1
            {
                if shoot[i].active do rl.DrawCircleV(shoot[i].position, shoot[i].radius, rl.BLACK)
            }

            if victory do rl.DrawText("VICTORY", screenWidth/2 - rl.MeasureText("VICTORY", 20)/2, screenHeight/2, 20, rl.LIGHTGRAY)

            if pause do rl.DrawText("GAME PAUSED", screenWidth/2 - rl.MeasureText("GAME PAUSED", 40)/2, screenHeight/2 - 40, 40, rl.GRAY)

		} else { rl.DrawText("PRESS [ENTER] TO PLAY AGAIN", rl.GetScreenWidth()/2 - rl.MeasureText("PRESS [ENTER] TO PLAY AGAIN", 20)/2, rl.GetScreenHeight()/2 - 50, 20, rl.GRAY) }
	

    rl.EndDrawing()
}

// Update and Draw (one frame)
UpdateDrawFrame :: proc() 
{
    UpdateGame()
    DrawGame()
}
