extends SceneTree
const Game = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("run")


func capture(game, name: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")
	if result != OK:
		printerr("Screenshot save failed: ", error_string(result))
		quit(1)


func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999
	game.elapsed = 24.6
	game.best = 820
	game.old_best = 820
	game.broken_obstacles = 12
	game.player = Vector2(630, 400)
	game.last_move_direction = Vector2.RIGHT
	game.obstacles.assign([
		{"center": Vector2(260, 245), "velocity": Vector2(0, 90), "angle": 0.0, "spin": 0.0, "length": 245.0, "age": 2.0, "warning": 0.8, "life": 12.0},
		{"center": Vector2(840, 484), "velocity": Vector2(-90, 0), "angle": PI / 2, "spin": 0.0, "length": 170.0, "age": 2.0, "warning": 0.8, "life": 12.0}])
	game._update_effects(1)
	game.score = int(game.elapsed * 10)
	await capture(game, "rings-stage-1")
	for stage in range(2, 4):
		game.pickup = game.player
		game.pickup_active = true
		game._update_pickup(0.001)
		game._update_effects(1)
		await capture(game, "rings-stage-%d" % stage)
	game.obstacles.append({"center": game.player, "velocity": Vector2.ZERO,
		"angle": PI / 2, "spin": 0.0, "length": 180.0, "age": 2.0, "warning": 0.8, "life": 12.0})
	game.advance_game(0.01, Vector2.ZERO)
	game._update_effects(0.15)
	await capture(game, "rings-hit")
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999
	game.player = Vector2(490, 400)
	game.obstacles.append({"center": Vector2(560, 400), "velocity": Vector2.ZERO,
		"angle": PI / 2, "spin": 0.0, "length": 180.0, "age": 2.0, "warning": 0.8, "life": 12.0})
	game.try_dash(Vector2.RIGHT)
	game.advance_game(0.16, Vector2.ZERO)
	game._update_effects(0.16)
	game.obstacles.append({"center": Vector2(800, 400), "velocity": Vector2.ZERO,
		"angle": PI / 2, "spin": 0.0, "length": 180.0, "age": 0.0, "warning": 0.8, "life": 12.0})
	await capture(game, "rings-ghost")
	for frame in 362:
		game.advance_game(1.0 / 120, Vector2.ZERO)
		game._update_effects(1.0 / 120)
	await capture(game, "rings-restored")
	game.pickup = game.player
	game.pickup_active = true
	game._update_pickup(0.001)
	game._update_effects(1)
	game.try_dash(Vector2.LEFT)
	for frame in 20:
		game.advance_game(1.0 / 120, Vector2.ZERO)
		game._update_effects(1.0 / 120)
	await capture(game, "rings-half-cooldown")
	game.queue_free()
	await process_frame
	print("PASS: three stages with no/faint/solid single ring, dash phasing, damage protection and half cooldown screenshots saved")
	quit()
