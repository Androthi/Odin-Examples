package asteroids

// robotron type game

import "core:math"
import rl "vendor:raylib"
import "core:c"
import "core:fmt"

PLAYER_BASE_SIZE	:: 20.0
PLAYER_SPEED		:: 6.0
PLAYER_MAX_SHOOTS	:: 10

screenWidth			:i32: 800
screenHeight		:i32: 600

MAX_LEVEL			:: 6	// the higher this is, the more meteors on screen
MAX_BIG_METEORS		:: 4
MAX_MEDIUM_METEORS	:: 8
MAX_SMALL_METEORS	:: 16
METEORS_SPEED		:: 2

level				:int = 1

bigMeteor	:[MAX_LEVEL*MAX_BIG_METEORS]Meteor
mediumMeteor:[MAX_LEVEL*MAX_MEDIUM_METEORS]Meteor
smallMeteor	:[MAX_LEVEL*MAX_SMALL_METEORS]Meteor

gameScreenWidth     :i32 = screenWidth
gameScreenHeight    :i32 = screenHeight

render_target       :rl.RenderTexture
gameOver			:bool
pause				:bool
victory				:bool

shipHeight	:f32
player		:Player
shoot		:[PLAYER_MAX_SHOOTS]Shoot

midMeteorsCount			:int
smallMeteorsCount		:int
destroyedMeteorsCount	:int

snd_lazer1		:rl.Sound
snd_explosion1	:rl.Sound
snd_thrust		:rl.Sound

score			:int

Player :: struct {
	position	:rl.Vector2,
	speed		:rl.Vector2,
	acceleration:f32,
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

	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(screenWidth, screenHeight, "Asteroids")
	rl.SetWindowMinSize(screenWidth, screenHeight)
	render_target = rl.LoadRenderTexture(gameScreenWidth, gameScreenHeight)
	rl.SetTextureFilter(render_target.texture, .BILINEAR)
	rl.SetTargetFPS(60)
	rl.InitAudioDevice()

	snd_lazer1 = rl.LoadSound("resources/lazer1.wav")
	defer rl.UnloadSound(snd_lazer1)
	snd_explosion1 = rl.LoadSound("resources/explosion1.wav")
	defer rl.UnloadSound(snd_explosion1)
	snd_thrust = rl.LoadSound("resources/thrust.wav")
	defer rl.UnloadSound(snd_thrust)

	InitGame()

	for !rl.WindowShouldClose()    // Detect window close button or ESC key
	{
		UpdateGame()
		RenderFrame()
		DrawFrame()
	}
	
	rl.UnloadRenderTexture(render_target)
	rl.CloseAudioDevice()
	rl.CloseWindow()	// Close window and OpenGL context

	return
	
}

RenderFrame:: proc() {
	
	rl.BeginTextureMode(render_target)
  
	rl.ClearBackground(rl.BLACK)
	
	if !gameOver
	{
		// Draw spaceship
		v1 :rl.Vector2 = { player.position.x + math.sin_f32(player.rotation*rl.DEG2RAD)*(shipHeight), player.position.y - math.cos_f32(player.rotation*rl.DEG2RAD)*(shipHeight) }
		v2 :rl.Vector2 = { player.position.x - math.cos_f32(player.rotation*rl.DEG2RAD)*(PLAYER_BASE_SIZE/2), player.position.y - math.sin_f32(player.rotation*rl.DEG2RAD)*(PLAYER_BASE_SIZE/2) }
		v3 :rl.Vector2 = { player.position.x + math.cos_f32(player.rotation*rl.DEG2RAD)*(PLAYER_BASE_SIZE/2), player.position.y + math.sin_f32(player.rotation*rl.DEG2RAD)*(PLAYER_BASE_SIZE/2) }
		
		rl.DrawTriangle(v1, v2, v3, rl.MAROON)

		// Draw meteors
		for i:= 0; i < level*MAX_BIG_METEORS; i+=1
		{
			if bigMeteor[i].active do rl.DrawCircleV(bigMeteor[i].position, bigMeteor[i].radius, rl.DARKGRAY)
		}
		for i:= 0; i < level*MAX_MEDIUM_METEORS; i+=1
		{
			if mediumMeteor[i].active do rl.DrawCircleV(mediumMeteor[i].position, mediumMeteor[i].radius, rl.GRAY)
		}
			
		for i:= 0; i < level*MAX_SMALL_METEORS; i+=1
		{
			if smallMeteor[i].active do rl.DrawCircleV(smallMeteor[i].position, smallMeteor[i].radius, rl.GRAY)
		}
			
			
		// Draw shoot
		for i:= 0; i < PLAYER_MAX_SHOOTS; i+=1
		{
			if shoot[i].active do rl.DrawCircleV(shoot[i].position, shoot[i].radius, rl.YELLOW)
		}

		if victory do rl.DrawText("VICTORY", screenWidth/2 - rl.MeasureText("VICTORY", 20)/2, screenHeight/2, 20, rl.LIGHTGRAY)

		if pause do rl.DrawText("GAME PAUSED", screenWidth/2 - rl.MeasureText("GAME PAUSED", 40)/2, screenHeight/2 - 40, 40, rl.GRAY)


		rl.DrawText( rl.TextFormat("Score %v", score), 10, 10, 20, rl.WHITE)

	} else { rl.DrawText("PRESS [ENTER] TO PLAY AGAIN", screenWidth/2 - rl.MeasureText("PRESS [ENTER] TO PLAY AGAIN", 20)/2, screenHeight/2, 20, rl.GRAY) }

	rl.EndTextureMode()
}

// Update game (one frame)
UpdateGame :: proc() {

	if !gameOver {

		if rl.IsKeyPressed(.P) do pause = !pause

		if (!pause)
		{ 
			if player.acceleration > 0 {rl.PlaySound(snd_thrust)}
			else do rl.StopSound(snd_thrust)

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
				rl.PlaySound(snd_lazer1)
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

			for a:= 0; a < level*MAX_BIG_METEORS; a+=1
			{
				if rl.CheckCollisionCircles((rl.Vector2){player.collider.x, player.collider.y}, player.collider.z, bigMeteor[a].position, bigMeteor[a].radius) && bigMeteor[a].active do gameOver = true
			}

			for a:= 0; a < level*MAX_MEDIUM_METEORS; a+=1
			{
				if rl.CheckCollisionCircles((rl.Vector2){player.collider.x, player.collider.y}, player.collider.z, mediumMeteor[a].position, mediumMeteor[a].radius) && mediumMeteor[a].active do gameOver = true
			}

			for a:= 0; a < level*MAX_SMALL_METEORS; a+=1
			{
				if rl.CheckCollisionCircles((rl.Vector2){player.collider.x, player.collider.y}, player.collider.z, smallMeteor[a].position, smallMeteor[a].radius) && smallMeteor[a].active do gameOver = true
			}
			if gameOver do rl.PlaySound(snd_explosion1)

			// Meteors logic: big meteors
			for i:= 0; i < level*MAX_BIG_METEORS; i+=1
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
			for i:= 0; i < level*MAX_MEDIUM_METEORS; i+=1
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
			for i:= 0; i < level*MAX_SMALL_METEORS; i+=1
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
					for a:= 0; a < level*MAX_BIG_METEORS; a+=1
					{
						if bigMeteor[a].active && rl.CheckCollisionCircles(shoot[i].position, shoot[i].radius, bigMeteor[a].position, bigMeteor[a].radius)
						{
							rl.PlaySound(snd_explosion1)
							score += 10
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
							a = level*MAX_BIG_METEORS
						}
					}

					for b:= 0; b < level*MAX_MEDIUM_METEORS; b+=1
					{
						if mediumMeteor[b].active && rl.CheckCollisionCircles(shoot[i].position, shoot[i].radius, mediumMeteor[b].position, mediumMeteor[b].radius)
						{
							rl.PlaySound(snd_explosion1)
							score += 20
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
							b = level*MAX_MEDIUM_METEORS
						}
					}

					for c:= 0; c < level*MAX_SMALL_METEORS; c+=1
					{
						if smallMeteor[c].active && rl.CheckCollisionCircles(shoot[i].position, shoot[i].radius, smallMeteor[c].position, smallMeteor[c].radius)
						{
							rl.PlaySound(snd_explosion1)
							score += 30
							shoot[i].active = false
							shoot[i].lifeSpawn = 0
							smallMeteor[c].active = false
							destroyedMeteorsCount+=1
							smallMeteor[c].color = rl.YELLOW
							c = level*MAX_SMALL_METEORS
						}
					}
				}
			}
		 }
		
		if destroyedMeteorsCount == level*MAX_BIG_METEORS + level*MAX_MEDIUM_METEORS + level*MAX_SMALL_METEORS {
			level += 1
			if level == MAX_LEVEL { victory = true }
			else {
				InitGame()
			}
			
		}

	} else {
		if rl.IsKeyPressed(.ENTER)
		{
			InitGame()
			gameOver = false
			score = 0
		}
	}
}

DrawFrame :: proc() {
	
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	rl.DrawTexturePro(
		render_target.texture,
		(rl.Rectangle){
			0.0, 0.0, f32(render_target.texture.width),f32(-render_target.texture.height) 
		},
		(rl.Rectangle){ 0.0, 0.0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())},
		rl.Vector2({ 0.0, 0.0 }), 0.0, rl.WHITE)

	rl.EndDrawing()
}

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

	for i := 0; i < level*MAX_BIG_METEORS; i+=1
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
 
	for i:=0; i < level*MAX_MEDIUM_METEORS; i+=1
	{
		mediumMeteor[i].position = (rl.Vector2){-100, -100}
		mediumMeteor[i].speed = (rl.Vector2){0,0}
		mediumMeteor[i].radius = 20
		mediumMeteor[i].active = false
		mediumMeteor[i].color = rl.BLUE
	}

	for i:=0; i < level*MAX_SMALL_METEORS; i+=1
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
