extends SceneTree
const Game = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var label := args[0] if not args.is_empty() else "current"
	var output_dir := args[1] if args.size() >= 2 else "res://artifacts"
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.begin_run()
	game.lives = 3
	game.elapsed = 24.6
	game.score = 396
	game.best = 820
	game.broken_obstacles = 12
	game.player = Vector2(480, 420)
	game.pickup = Vector2(745, 310)
	game.pickup_active = true
	game.obstacles.assign([
		{"center": Vector2(260, 245), "velocity": Vector2(0, 90), "angle": 0.0, "spin": 0.0, "length": 245.0, "age": 2.0, "warning": 0.8, "life": 12.0},
		{"center": Vector2(360, 544), "velocity": Vector2.ZERO, "angle": -0.7, "spin": 0.7, "length": 205.0, "age": 2.0, "warning": 1.15, "life": 7.0}])
	game._update_effects(1)
	var reports := []
	for size in [Vector2i(1080, 720), Vector2i(1800, 1000)]:
		root.size = size
		await create_timer(0.2).timeout
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		var saved := picture.save_png(output_dir + "/resize-" + label + "-%d.png" % size.x)
		if saved != OK:
			printerr("Resize capture failed: ", error_string(saved))
			quit(1)
			return
		reports.append({"requested": size, "window": root.size, "image": picture.get_size(),
			"stretch": root.get_stretch_transform(), "oversampling": root.oversampling,
			"font_oversampling": game.font.oversampling, "font_msdf": game.font.multichannel_signed_distance_field})
	print(JSON.stringify({"sizes": reports, "screen_dpi": DisplayServer.screen_get_dpi(),
		"allow_hidpi": ProjectSettings.get_setting("display/window/dpi/allow_hidpi"),
		"font_oversampling_setting": ProjectSettings.get_setting("gui/fonts/dynamic_fonts/use_oversampling")}))
	quit()
