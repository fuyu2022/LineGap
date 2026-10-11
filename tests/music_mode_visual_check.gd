extends SceneTree
const Game = preload("res://scripts/game.gd")
var game
var preview: SubViewport


func _initialize() -> void:
	call_deferred("run")


func capture(name: String) -> void:
	game.queue_redraw()
	game.background_layer.queue_redraw()
	game.music_wave_layer.queue_redraw()
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var prefix := "music-mode-web-" if "web-font" in OS.get_cmdline_user_args() else "music-mode-"
	preview.get_texture().get_image().save_png("res://artifacts/" + prefix + name + ".png")


func run() -> void:
	preview = SubViewport.new()
	preview.size = Vector2i(1080, 720)
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(preview)
	game = Game.new()
	game.test_mode = true
	preview.add_child(game)
	game.set_physics_process(false)
	if "web-font" in OS.get_cmdline_user_args():
		game.font = load(Game.WEB_FONT_PATH)
	game.set_language("zh")
	game.set_music_mode(true)
	game.best = 820
	game.best_broken = 25
	game.best_time = 123.4
	await capture("ready")
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999
	game.lives = 3
	game.music_clock.update(game.music_clock.offset + game.music_clock.period * 16)
	for index in 5:
		game.obstacles.append({"center": Vector2(270 + index * 120, 250 + index * 45),
			"velocity": Vector2.ZERO, "angle": 0.4 + index * 0.5, "spin": 0.0,
			"length": 100.0, "age": 2.0, "warning": 0.8, "life": 20.0})
	game.pickup = Vector2(800, 460)
	game.pickup_active = true
	game.try_dash()
	game.advance_game(0.11, Vector2.ZERO)
	await capture("wave")
	game.advance_game(0.2, Vector2.ZERO)
	await capture("shatter")
	game._begin_super_dash()
	await capture("super")
	game.phase = Game.Phase.PAUSED
	game.music_wave_layer.hide()
	await capture("paused")
	game.set_language("en")
	game.phase = Game.Phase.PLAYING
	game.music_wave_layer.show()
	await capture("en")
	print("PASS: six music mode screenshots saved")
	quit()
