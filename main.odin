package audio_player;

import "core:fmt";
import "core:log";
import "core:os";
import "core:strings";
import rl "vendor:raylib";
import osd "osdialog";

WINDOW_HEIGHT :: 600;
WINDOW_WIDTH  :: 800;

Button :: struct {
    rect: rl.Rectangle,
    label: string,
}

draw_button :: proc(b: Button) -> bool {
    mouse: rl.Vector2 = rl.GetMousePosition();
    hover: bool       = rl.CheckCollisionPointRec(mouse, b.rect);
    clicked: bool     = hover && rl.IsMouseButtonPressed(rl.MouseButton.LEFT);
    color: rl.Color   = hover?rl.LIGHTGRAY:rl.GRAY;
    text: cstring     = strings.clone_to_cstring(b.label);
    defer delete(text);

    rl.DrawRectangleRec(b.rect, color);
    rl.DrawText(
	text,
	i32(b.rect.x) + 10,
	i32(b.rect.y) + 15,
	20,
	rl.BLACK
    );
    
    return clicked;
}

main :: proc() {
    logger := log.create_console_logger();
    context.logger = logger;
    music: rl.Music;



    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Audio Player");
    rl.InitAudioDevice()
    rl.SetTargetFPS(120);
    rl.PlayMusicStream(music);
    defer rl.CloseWindow();
    defer rl.CloseAudioDevice();
    defer rl.UnloadMusicStream(music);
    rl.EnableCursor();
    pause: bool = true;
    dir: string = "audio";
    files, err := os.read_directory_by_path(dir, 0, context.allocator);
    audio_files: [dynamic]string;
    for file in files {
	if os.is_file(file.fullpath) {
	    append(&audio_files, file.name);
	}
    }

    selected_audio_file: int = 0;

    if selected_audio_file > 0 { music = rl.LoadMusicStream(strings.clone_to_cstring(audio_files[selected_audio_file])); }

    for !rl.WindowShouldClose() {
	rl.UpdateMusicStream(music);

	  if rl.GuiButton(
            rl.Rectangle{20, 20, 120, 30},
            "Add Dir",
          ) == true {
	      log.info(osd.path(.Open_Dir));
	  }
	if rl.GuiButton(
            rl.Rectangle{20, 60, 120, 30},
            "Add Track",
        ) == true {
	    log.info(osd.path(.Open));
	}


	if rl.IsKeyPressed(.P) {
	    pause = !pause;
	    if pause {
		rl.PauseMusicStream(music);
		log.info("pause music");
	    } else {
		rl.PlayMusicStream(music);
		log.info("play music");
	    }
	}

	if rl.IsKeyPressed(.DOWN) { selected_audio_file = (selected_audio_file + 1) % len(audio_files); }
	if rl.IsKeyPressed(.UP)   { selected_audio_file = (selected_audio_file - 1) % len(audio_files); }

	if rl.IsKeyPressed(.ENTER) {
	    rl.StopMusicStream(music);
	    rl.UnloadMusicStream(music);
	    pause = false;

	    path := strings.concatenate([]string{"audio/", audio_files[selected_audio_file]});
	    music = rl.LoadMusicStream(strings.clone_to_cstring(path));
	    rl.PlayMusicStream(music);
	}

	//draw loop
	{
	    rl.BeginDrawing();
	    defer rl.EndDrawing();

	    rl.ClearBackground(rl.RAYWHITE);

	    title: cstring = "PRESS P TO PAUSE AND PLAY | ENTER + UP/DOWN TO CHOOSE SONG";
	    rl.DrawText(title, (WINDOW_WIDTH - rl.MeasureText(title, 20))/2, WINDOW_HEIGHT/2 + 150, 20, rl.LIGHTGRAY);
	    text: cstring = pause ? "PLAY" : "PAUSED";
	    rl.DrawText(text, (WINDOW_WIDTH-rl.MeasureText(text, 20))/2, WINDOW_HEIGHT/2, 20, rl.DARKGRAY);

	    // audio selector

	    for i in 0..<len(audio_files) {
		y := 100 + i * 30;
		color := rl.BLACK;
		if i == selected_audio_file { color = rl.RED; }
		rl.DrawText(strings.clone_to_cstring(audio_files[i]), 100, i32(y), 20, color);
	    }

	    rl.DrawCircle(i32(rl.GetMousePosition().x), i32(rl.GetMousePosition().y), 10, rl.RED);
	}
    }
}
