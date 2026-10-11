extends SceneTree

const Game = preload("res://scripts/game.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func capture(game, name: String) -> Image:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.save_png("res://artifacts/" + name + ".png") != OK:
		failures.append("Could not save " + name)
	return image

func run() -> void:
	root.size = Vector2i(1080, 720)
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_language("zh")
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999
	for index in 7:
		game.pickup = game.player
		game.pickup_active = true
		game._update_pickup(0.001)
		game.pickup_wait = 999
	await capture(game, "super-dash-ready")
	for index in 40:
		game.advance_game(1.0 / 120, Vector2.RIGHT)
		game._update_effects(1.0 / 120)
	await capture(game, "super-dash-invincible-walk")
	game.obstacles.append({"center": game.player + Vector2(35, 0), "velocity": Vector2.ZERO,
		"angle": PI / 2, "spin": 0.0, "length": 180.0, "age": 2.0, "warning": 0.8, "life": 99.0})
	game.advance_game(0.06, Vector2.RIGHT)
	game._update_effects(0.02)
	if game.broken_obstacles != 1 or game.dash_remaining != 0 or game.fragments.is_empty():
		failures.append("Walking contact did not produce shatter effects without a dash")
	await capture(game, "super-contact-shatter")
	game.try_dash(Vector2.RIGHT)
	game.advance_game(0.08, Vector2.RIGHT)
	var image := await capture(game, "super-dash-gold")
	var bar := image.get_pixel(500, 695)
	var trail := image.get_pixelv(Vector2i(game.trail[12]))
	if not (bar.r > bar.b * 1.5 and bar.r > 0.5):
		failures.append("Super-dash countdown bar is not gold")
	if not (trail.r > trail.b * 1.5 and trail.r > 0.05):
		failures.append("Super-dash trail is not gold")
	game.set_language("en")
	await capture(game, "super-dash-gold-en")
	game.advance_game(game.super_dash_remaining, Vector2.ZERO)
	game.player = Game.ARENA.get_center()
	game.trail.clear()
	game._update_effects(1.0)
	game.set_language("zh")
	await capture(game, "super-dash-protection")
	game.advance_game(2.0, Vector2.ZERO)
	await capture(game, "super-dash-normal")
	for failure in failures:
		printerr("FAIL: ", failure)
	print("PASS: super dash visual checks" if failures.is_empty() else "FAIL: super dash visual checks")
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
