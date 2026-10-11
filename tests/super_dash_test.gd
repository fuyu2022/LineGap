extends SceneTree

const Game = preload("res://scripts/game.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)

func quiet_run(game) -> void:
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999

func collect(game, count: int) -> void:
	for index in count:
		game.pickup = game.player
		game.pickup_active = true
		game._update_pickup(0.001)
		game.pickup_wait = 999

func barrier(at: Vector2) -> Dictionary:
	return {"center": at, "velocity": Vector2.ZERO, "angle": PI / 2, "spin": 0.0,
		"length": 120.0, "age": 2.0, "warning": 0.8, "life": 99.0}

func run() -> void:
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	quiet_run(game)
	collect(game, 6)
	expect(not game.super_dash_active and game.dash_remaining == 0, "Six orbs do not activate super mode")
	game.dash_cooldown_remaining = 0.5
	collect(game, 1)
	expect(game.super_dash_active and game.super_dash_remaining == 7 and game.dash_remaining == 0 and game.dash_cooldown_remaining == 0, "Seventh orb opens a seven-second no-cooldown window without starting a dash")
	expect(game.collected == 7 and game.score == 350 and game.lives == 3, "Trigger preserves scoring and the three-life cap")
	var origin: Vector2 = game.player
	game.advance_game(0.2, Vector2.ZERO)
	expect(game.player == origin and game.dash_remaining == 0 and game.dash_ripple.emitted_count == 0, "Standing still in super mode never auto-dashes")
	game.velocity = Vector2.LEFT * Game.PLAYER_SPEED * 2.0
	game.advance_game(0.02, Vector2.LEFT)
	expect(game.player.is_equal_approx(origin + Vector2.LEFT * Game.PLAYER_SPEED * 2.0 * 0.02), "Direction keys move at twice ordinary speed without triggering a dash")
	game.obstacles.append(barrier(game.player))
	game.obstacles.append(barrier(game.player + Vector2(3, 0)))
	game.velocity = Vector2.ZERO
	game.lives = 1
	game.advance_game(0.01, Vector2.ZERO)
	expect(game.phase == Game.Phase.PLAYING and game.lives == 1 and game.obstacles.is_empty() and game.broken_obstacles == 2 and not game.fragments.is_empty(), "Stationary super contact shatters overlapping barriers at one life without starting a dash")
	game._take_hit()
	expect(game.lives == 1, "Direct collision damage also respects super invincibility")
	game.advance_game(3.0, Vector2.ZERO)
	expect(game.super_dash_active and game.super_dash_remaining > 3 and game.lives == 1, "Super invincibility continues beyond three seconds")
	game.obstacles.clear()
	game.lives = 3
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	game.position = Vector2(80, 40)
	game.scale = Vector2(1.5, 1.5)
	click.position = game.get_global_transform_with_canvas() * (game.player + Vector2(0, -100))
	game._unhandled_input(click)
	game.position = Vector2.ZERO
	game.scale = Vector2.ONE
	expect(game.dash_remaining == Game.DASH_FULL_DURATION and game.dash_cooldown_remaining == 0, "Mouse explicitly starts a normal-length dash with zero cooldown")
	origin = game.player
	game.advance_game(0.02, Vector2.ZERO)
	expect(game.dash_direction.is_equal_approx(Vector2.UP) and game.player.is_equal_approx(origin + Vector2(0, -20)), "Mouse aiming accounts for canvas position and scale")
	var dash_left: float = game.dash_remaining
	var super_left: float = game.super_dash_remaining
	var emitted: int = game.dash_ripple.emitted_count
	game.try_dash(Vector2.DOWN)
	expect(game.dash_direction == Vector2.DOWN and game.dash_remaining == dash_left and game.super_dash_remaining == super_left and game.dash_ripple.emitted_count == emitted, "Active dash can turn without extending the burst or super window")
	game.advance_game(game.dash_remaining, Vector2.ZERO)
	expect(game.dash_remaining == 0 and game.dash_cooldown_remaining == 0, "Manual burst ends and leaves no cooldown")
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	game._unhandled_input(key)
	expect(game.dash_remaining == Game.DASH_FULL_DURATION and game.dash_cooldown_remaining == 0 and game.dash_ripple.emitted_count == emitted + 1, "Space can start another burst immediately after the previous one")
	key.keycode = KEY_ESCAPE
	game._unhandled_input(key)
	dash_left = game.dash_remaining
	super_left = game.super_dash_remaining
	origin = game.player
	game._physics_process(10)
	expect(game.phase == Game.Phase.PAUSED and game.dash_remaining == dash_left and game.super_dash_remaining == super_left and game.player == origin, "Pause freezes both independent timers and movement")
	game._unhandled_input(key)
	collect(game, 1)
	expect(game.collected == 8 and game.super_dash_remaining == super_left and game.dash_remaining == dash_left, "Extra pickup does not extend the current window or burst")
	game.advance_game(game.dash_remaining, Vector2.ZERO)
	game.advance_game(game.super_dash_remaining - 0.001, Vector2.ZERO)
	expect(game.super_dash_active and game.dash_remaining == 0 and game.super_dash_remaining > 0, "Super mode lasts almost seven full seconds without requiring any dash")
	game.advance_game(0.002, Vector2.ZERO)
	expect(not game.super_dash_active and game.super_dash_remaining == 0 and game.dash_remaining == 0 and game.hit_grace > 1.99, "Window ends at seven seconds and grants the existing two-second protection")
	game.obstacles.append(barrier(game.player))
	game.obstacles.append(barrier(game.player + Vector2(3, 0)))
	game.velocity = Vector2.ZERO
	var broken_before_protection: int = game.broken_obstacles
	game.advance_game(1.9, Vector2.ZERO)
	expect(game.lives == 3 and game.phase == Game.Phase.PLAYING and game.obstacles.size() == 2 and game.broken_obstacles == broken_before_protection, "Post-window protection ignores damage but does not shatter contacted barriers")
	super_left = game.hit_grace
	game.phase = Game.Phase.PAUSED
	game._physics_process(10)
	expect(game.hit_grace == super_left, "Pause freezes the post-window protection shell")
	game.phase = Game.Phase.PLAYING
	game.advance_game(0.11, Vector2.ZERO)
	expect(game.lives == 2, "Collisions resume normally after protection expires")
	game.obstacles.clear()
	collect(game, 6)
	expect(game.collected == 14 and game.super_dash_remaining == 7 and game.dash_remaining == 0, "Fourteenth orb opens the next window without automatic movement")
	quiet_run(game)
	collect(game, 7)
	game.lives = 1
	game.super_dash_remaining = 0.05
	game.try_dash(Vector2.RIGHT)
	game.obstacles.append(barrier(game.player + Vector2(20, 0)))
	game.obstacles.append(barrier(game.player + Vector2(61, 0)))
	game.advance_game(0.06, Vector2.ZERO)
	expect(game.broken_obstacles == 1 and game.obstacles.size() == 1 and game.obstacles[0]["ghost_remaining"] > 0, "Super shattering applies only to the protected part of a dash crossing the window boundary")
	expect(game.lives == 1 and game.phase == Game.Phase.PLAYING and is_equal_approx(game.hit_grace, 1.99) and game.dash_remaining > 0, "An explicitly started dash continues across expiry while post-window protection starts on time")
	game.obstacles.clear()
	game.advance_game(game.dash_remaining, Vector2.ZERO)
	game.try_dash(Vector2.LEFT)
	expect(game.dash_cooldown_remaining == 1.5, "Normal cooldown returns after the window ends")
	quiet_run(game)
	game.collected = 6
	game.try_dash(Vector2.RIGHT)
	game.pickup = game.player + Vector2(40, 0)
	game.pickup_active = true
	game.advance_game(0.08, Vector2.ZERO)
	expect(game.super_dash_remaining == 7 and is_equal_approx(game.dash_remaining, 0.08), "Seventh orb collected mid-dash preserves that already-started burst")
	game.finish_run()
	expect(not game.super_dash_active and game.super_dash_remaining == 0 and game.dash_remaining == 0 and game.hit_grace == 0, "Run termination clears both timers and protection")
	quiet_run(game)
	collect(game, 7)
	game.begin_run()
	expect(not game.super_dash_active and game.super_dash_remaining == 0 and game.dash_remaining == 0 and game.hit_grace == 0 and game.collected == 0, "Restart clears the window, shell and seven-orb progress")
	for heading in [Vector2.RIGHT, Vector2.ONE.normalized()]:
		quiet_run(game)
		collect(game, 7)
		for tick in 20:
			game.advance_game(1.0 / 120, heading)
		origin = game.player
		game.advance_game(0.01, heading)
		expect(is_equal_approx(game.player.distance_to(origin), 6.7) and game.dash_remaining == 0, "Accelerated straight and diagonal movement settles at 670 pixels per second")
		game.super_dash_remaining = 0.005
		origin = game.player
		game.advance_game(0.01, heading)
		expect(is_equal_approx(game.player.distance_to(origin), 5.025) and is_equal_approx(game.velocity.length(), 335.0), "Movement returns to ordinary speed at expiry, including a frame crossing the boundary")
		origin = game.player
		game.advance_game(0.01, heading)
		expect(is_equal_approx(game.player.distance_to(origin), 3.35), "Ordinary movement resumes at 335 pixels per second after the window")
	for state in ["solid", "warning", "phased"]:
		quiet_run(game)
		collect(game, 7)
		game.lives = 1
		game.velocity = Vector2.RIGHT * Game.PLAYER_SPEED * 2.0
		var obstacle := barrier(game.player + Vector2(70, 0))
		if state == "warning":
			obstacle["age"] = 0.0
		elif state == "phased":
			obstacle["ghost_remaining"] = 0.5
		game.obstacles.append(obstacle)
		game.advance_game(0.1, Vector2.RIGHT)
		expect(game.obstacles.is_empty() and game.broken_obstacles == 1 and game.dash_remaining == 0 and game.lives == 1, "Ordinary swept movement shatters a %s barrier without manual dashing" % state)
	quiet_run(game)
	collect(game, 7)
	game.lives = 1
	var moving_obstacle := barrier(game.player + Vector2(30, 0))
	moving_obstacle["velocity"] = Vector2(-6000, 0)
	game.obstacles.append(moving_obstacle)
	game.advance_game(0.01, Vector2.ZERO)
	expect(game.obstacles.is_empty() and game.broken_obstacles == 1 and game.lives == 1, "A moving barrier crossing a stationary player is shattered")
	quiet_run(game)
	collect(game, 7)
	game.lives = 1
	game.super_dash_remaining = 0.05
	game.velocity = Vector2.RIGHT * Game.PLAYER_SPEED * 2.0
	game.obstacles.append(barrier(game.player + Vector2(20, 0)))
	game.obstacles.append(barrier(game.player + Vector2(43, 0)))
	game.advance_game(0.06, Vector2.RIGHT)
	expect(game.broken_obstacles == 1 and game.obstacles.size() == 1 and game.lives == 1, "Ordinary contact shatters only before the exact end of the super window")
	game.queue_free()
	await process_frame
	print("%s: %d super dash checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)
