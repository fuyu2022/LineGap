extends SceneTree
const Game = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("run")


func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")
	if result != OK:
		quit(1)


func run() -> void:
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.queue_redraw()
	await capture("dash-ready")
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999
	game.player = Vector2(420, 390)
	game.try_dash(Vector2.RIGHT)
	for frame in 10:
		game.advance_game(1.0 / 120, Vector2.ZERO)
		game._update_effects(1.0 / 120)
	game.queue_redraw()
	await capture("dash-burst")
	game.advance_game(0.2, Vector2.ZERO)
	game._update_effects(0.2)
	game.queue_redraw()
	await capture("dash-cooldown")
	game.advance_game(1.3, Vector2.ZERO)
	game._update_effects(1.3)
	game.queue_redraw()
	await capture("dash-recharged")
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999
	game.player = Vector2(420, 390)
	game.lives = 2
	for x in [485, 520]:
		game.obstacles.append({"center": Vector2(x, 390), "velocity": Vector2.ZERO,
			"angle": PI / 2, "spin": 0.0, "length": 190.0, "age": 2.0, "warning": 0.8, "life": 12.0})
	game.pickup = Vector2(490, 390)
	game.pickup_active = true
	game.try_dash(Vector2.RIGHT)
	for frame in 14:
		game.advance_game(1.0 / 120, Vector2.ZERO)
		game._update_effects(1.0 / 120)
	game.queue_redraw()
	await capture("dash-break-refill")
	game.advance_game(0.1, Vector2.ZERO)
	game._update_effects(0.1)
	game.queue_redraw()
	await capture("dash-refilled-ready")
	print("PASS: rendered dash, shatter fragments, orb refill and ready state")
	quit()
