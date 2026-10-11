extends SceneTree

const Game = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("run")


func capture(name: String) -> void:
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
	game.visual_time = 2.0
	game.queue_redraw()
	await capture("ready")
	game.begin_run()
	game.elapsed = 24.6
	game.score = 396
	game.best = 820
	game.old_best = 820
	game.collected = 3
	game.broken_obstacles = 12
	game.player = Vector2(480, 420)
	for index in 22:
		game.trail.append(game.player - Vector2(index * 3, sin(index * 0.15) * 15))
	game.pickup = Vector2(745, 310)
	game.pickup_active = true
	game.obstacles.assign([
		{"center": Vector2(260, 245), "velocity": Vector2(0, 90), "angle": 0.0, "spin": 0.0, "length": 245.0, "age": 2.0, "warning": 0.8, "life": 12.0},
		{"center": Vector2(840, 484), "velocity": Vector2(-90, 0), "angle": PI / 2, "spin": 0.0, "length": 170.0, "age": 2.0, "warning": 0.8, "life": 12.0},
		{"center": Vector2(360, 544), "velocity": Vector2.ZERO, "angle": -0.7, "spin": 0.7, "length": 205.0, "age": 2.0, "warning": 1.15, "life": 7.0},
		{"center": Vector2(690, 194), "velocity": Vector2(0, 90), "angle": 0.0, "spin": 0.0, "length": 220.0, "age": 0.3, "warning": 0.8, "life": 12.0}])
	game.queue_redraw()
	await capture("playing")
	game.phase = Game.Phase.PAUSED
	game.queue_redraw()
	await capture("paused")
	game.phase = Game.Phase.PLAYING
	game.finish_run()
	game.death_age = 0.7
	game._update_effects(0.3)
	game.queue_redraw()
	await capture("dead")
	print("PASS: ready, playing, paused, dead screenshots saved")
	quit()
