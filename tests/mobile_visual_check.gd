extends SceneTree
const Game = preload("res://scripts/game.gd")
var game
var preview: SubViewport

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	# Let resized viewport and font atlas uploads settle before capturing.
	await create_timer(0.8).timeout
	for frame in 5:
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
	RenderingServer.force_draw(false)
	var image := preview.get_texture().get_image()
	if name in ["paused", "dead", "title"]:
		var credits_y: int = int(game.touch_controls.safe_bounds.end.y + game.position.y - 78)
		var text_pixels := 0
		for y in range(credits_y, mini(image.get_height(), credits_y + 70)):
			for x in image.get_width():
				var pixel := image.get_pixel(x, y)
				if maxf(pixel.r, maxf(pixel.g, pixel.b)) > 0.25:
					text_pixels += 1
		if text_pixels < 500:
			printerr("FAIL: missing footer text in ", name)
			quit(1)
			return
	if image.save_png(ProjectSettings.globalize_path("res://artifacts/mobile-" + name + ".png")) != OK:
		quit(1)

func run() -> void:
	root.size = Vector2i(1440, 810)
	# Capture an offscreen render target so native window occlusion cannot mask pixels.
	preview = SubViewport.new()
	preview.size = Vector2i(1440, 810)
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(preview)
	game = Game.new()
	game.mobile_ui = true
	game.test_mode = true
	preview.add_child(game)
	game.set_physics_process(false)
	game.begin_run()
	game.score = 2345
	game.broken_obstacles = 22
	game.best = 12345
	game.best_broken = 111
	game.lives = 3
	game.elapsed = 18.5
	game.spawn_wait = 999
	game.pickup_wait = 999
	for size in [Vector2i(1440, 810), Vector2i(1920, 864), Vector2i(1280, 960)]:
		root.size = size
		preview.size = Vector2i(Vector2(size) / minf(size.x / 1440.0, size.y / 810.0))
		await process_frame
		await process_frame
		game._layout_mobile()
		game.pickup_active = true
		game.pickup = game.arena_rect.position + game.arena_rect.size * Vector2(0.65, 0.65)
		game.obstacles.clear()
		for line in 4:
			game._spawn_obstacle()
		for index in game.obstacles.size():
			var item: Dictionary = game.obstacles[index]
			item["age"] = 2.0
			item["center"] = game.arena_rect.position + game.arena_rect.size * Vector2(0.15 + index * 0.2, 0.35)
		await capture("%dx%d" % [size.x, size.y])
	root.size = Vector2i(1440, 810)
	preview.size = Vector2i(1440, 810)
	await process_frame
	await process_frame
	game._layout_mobile()
	game.dash_cooldown_remaining = 0.8
	await capture("cooldown")
	game.dash_cooldown_remaining = 0.0
	game._begin_super_dash()
	game.super_dash_remaining = 5.6
	game.set_joystick_following(true)
	game.touch_controls.press(1, Vector2(120, 450))
	game.touch_controls.drag(1, Vector2(240, 410))
	await capture("following-super")
	game._open_settings()
	for selected in ["zh", "en"]:
		game.set_language(selected)
		await capture("settings-" + selected)
	game._close_settings()
	game.set_language("zh")
	game.phase = Game.Phase.PAUSED
	await capture("paused")
	game.phase = Game.Phase.DEAD
	game.death_age = 0.7
	await capture("dead")
	game.phase = Game.Phase.READY
	await capture("title")
	print("PASS: ten mobile screenshots saved")
	game.queue_free()
	await process_frame
	quit()
