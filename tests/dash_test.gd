extends SceneTree
const Game = preload("res://scripts/game.gd")
const Ripple = preload("res://scripts/dash_ripple.gd")
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


func run() -> void:
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	expect(not game.try_dash(Vector2.RIGHT), "Title screen cannot dash")
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	game._unhandled_input(key)
	expect(game.phase == Game.Phase.PLAYING and game.dash_remaining == 0, "Space starts the game without also dashing")
	game.spawn_wait = 999
	game.pickup_wait = 999
	var origin: Vector2 = game.player
	expect(game.try_dash(Vector2.RIGHT), "Ready dash activates")
	expect(game.dash_ripple.ripples.size() == 1 and game.dash_ripple.ripples[0]["position"] == origin, "Dash leaves one ring at its origin")
	expect(not game.try_dash(Vector2.LEFT) and game.dash_ripple.ripples.size() == 1, "Cooldown blocks repeated activation and extra rings")
	game.advance_game(Game.DASH_DURATION, Vector2.ZERO)
	expect(is_equal_approx(game.player.distance_to(origin), 160), "Dash covers 160 pixels in its configured duration")
	expect(game.dash_remaining == 0 and game.velocity == Vector2.ZERO, "Stationary dash ends without an extra speed tail")
	expect(game.dash_ripple.ripples[0]["position"] == origin, "Ring stays at origin after player moves")
	game.advance_game(Game.DASH_COOLDOWN - Game.DASH_DURATION - 0.01, Vector2.ZERO)
	expect(not game.try_dash(Vector2.RIGHT), "Dash is unavailable before the cooldown ends")
	game.advance_game(0.02, Vector2.ZERO)
	expect(game.try_dash(Vector2.LEFT), "Dash becomes available again after 1.5 seconds")
	quiet_run(game)
	origin = game.player
	game.try_dash(Vector2.ONE)
	game.advance_game(Game.DASH_DURATION, Vector2.ZERO)
	expect(is_equal_approx(game.player.distance_to(origin), 160), "Diagonal dash has the same distance")
	quiet_run(game)
	origin = game.player
	game.try_dash(Vector2.RIGHT)
	game.advance_game(0.08, Vector2.LEFT)
	expect(is_equal_approx(game.player.x - origin.x, 80) and game.player.y == origin.y, "Dash keeps its initial heading during the burst")
	var cooldown: float = game.dash_cooldown_remaining
	var remaining: float = game.dash_remaining
	game.phase = Game.Phase.PAUSED
	game._physics_process(1)
	expect(game.dash_remaining == remaining and game.dash_cooldown_remaining == cooldown, "Pause freezes dash and cooldown timers")
	expect(not game.try_dash(Vector2.RIGHT) and not game.dash_ripple.visible, "Pause blocks dashes and hides effects")
	game._unhandled_input(key)
	expect(game.phase == Game.Phase.PLAYING and game.dash_ripple.emitted_count == 1, "Space resumes without triggering another dash")
	quiet_run(game)
	game.advance_game(0.01, Vector2.LEFT)
	game._unhandled_input(key)
	expect(game.dash_remaining == Game.DASH_DURATION and game.dash_direction == Vector2.LEFT, "Space dashes using the last direction when no key is held")
	key.echo = true
	game._unhandled_input(key)
	expect(game.dash_ripple.emitted_count == 1, "Keyboard repeat does not auto-dash")
	key.echo = false
	quiet_run(game)
	game.player = Game.ARENA.end - Vector2(12, 12)
	game.try_dash(Vector2.ONE)
	game.advance_game(Game.DASH_DURATION, Vector2.ZERO)
	expect(game.player == Game.ARENA.end - Vector2(10, 10), "Dash cannot leave arena bounds")
	quiet_run(game)
	game.lives = 2
	game.obstacles.append({"center": game.player + Vector2(70, 0), "velocity": Vector2.ZERO,
		"angle": PI / 2, "spin": 0.0, "length": 180.0, "age": 2.0, "warning": 0.8, "life": 12.0})
	game.try_dash(Vector2.RIGHT)
	game.advance_game(0.1, Vector2.ZERO)
	expect(game.phase == Game.Phase.PLAYING and game.obstacles.is_empty() and game.broken_obstacles == 1 and not game.fragments.is_empty(), "Dash breaks a crossed obstacle and emits line fragments")
	expect(game.score == 16, "Shattering awards 15 points immediately alongside one time point")
	game.finish_run()
	game._unhandled_input(key)
	expect(game.phase == Game.Phase.PLAYING and game.dash_cooldown_remaining == 0 and game.dash_remaining == 0 and game.dash_ripple.ripples.is_empty(), "Space restarts after death with a ready dash and cleared effects")
	game.try_dash(Vector2.RIGHT)
	var ring: Dictionary = game.dash_ripple.ripples[0]
	var previous := Ripple.appearance(ring)
	var monotonic := true
	for frame in 107:
		game._update_effects(1.0 / 120)
		var current := Ripple.appearance(ring)
		monotonic = monotonic and current.x >= previous.x and current.y <= previous.y
		previous = current
	expect(monotonic, "Dash ring expands and fades smoothly")
	game._update_effects(0.02)
	expect(game.dash_ripple.ripples.is_empty(), "Dash ring disappears completely")
	game.dash_ripple.emit_at(game.player)
	key.keycode = KEY_R
	game._unhandled_input(key)
	expect(game.dash_ripple.ripples.is_empty() and game.dash_cooldown_remaining == 0, "R clears rings and resets cooldown")
	expect(game.ripple_clip.clip_contents and game.ripple_clip.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Ring effects stay within arena and do not intercept controls")
	quiet_run(game)
	game.lives = 2
	for distance in [35, 75, 120]:
		game.obstacles.append({"center": game.player + Vector2(distance, 0), "velocity": Vector2.ZERO,
			"angle": PI / 2, "spin": 0.0, "length": 180.0, "age": 2.0, "warning": 0.8, "life": 12.0})
	game.try_dash(Vector2.RIGHT)
	game.advance_game(Game.DASH_DURATION, Vector2.ZERO)
	expect(game.phase == Game.Phase.PLAYING and game.broken_obstacles == 3 and game.obstacles.is_empty(), "One dash can break every obstacle along its path")
	expect(game.score == 46, "Three barriers award 45 points in one dash alongside one time point")
	game._update_effects(1)
	expect(game.fragments.is_empty(), "Shattered line fragments fade and are reclaimed")
	quiet_run(game)
	game.lives = 2
	game.obstacles.append({"center": game.player + Vector2(55, 0), "velocity": Vector2.ZERO,
		"angle": PI / 2, "spin": 0.0, "length": 180.0, "age": 0.0, "warning": 0.8, "life": 12.0})
	game.try_dash(Vector2.RIGHT)
	game.advance_game(0.08, Vector2.ZERO)
	expect(game.phase == Game.Phase.PLAYING and game.broken_obstacles == 1, "Dash can also break a warning line")
	quiet_run(game)
	game.obstacles.append({"center": game.player + Vector2(170, 0), "velocity": Vector2.ZERO,
		"angle": PI / 2, "spin": 0.0, "length": 180.0, "age": 2.0, "warning": 0.8, "life": 12.0})
	game.try_dash(Vector2.RIGHT)
	game.advance_game(0.2, Vector2.RIGHT)
	expect(game.phase == Game.Phase.DEAD and game.broken_obstacles == 0, "Normal movement after the dash ends is not protected in the same frame")
	quiet_run(game)
	game.dash_cooldown_remaining = 1.2
	game.pickup = game.player
	game.pickup_active = true
	game.advance_game(1.0 / 120, Vector2.ZERO)
	expect(game.collected == 1 and game.dash_cooldown_remaining == 0 and game.try_dash(Vector2.RIGHT), "Collecting an orb makes a cooling dash available immediately")
	quiet_run(game)
	game.pickup = game.player + Vector2(70, 0)
	game.pickup_active = true
	game.try_dash(Vector2.RIGHT)
	game.advance_game(0.1, Vector2.ZERO)
	expect(game.collected == 1 and not game.pickup_active and game.dash_cooldown_remaining == 0 and game.dash_remaining > 0, "Dash collects an orb swept along its path and resets cooldown without cancelling the burst")
	game.advance_game(0.07, Vector2.ZERO)
	expect(game.try_dash(Vector2.LEFT), "Orb refill allows another dash as soon as the current dash ends")
	quiet_run(game)
	game.lives = 2
	game.obstacles.append({"center": game.player + Vector2(45, 0), "velocity": Vector2.ZERO,
		"angle": PI / 2, "spin": 0.0, "length": 180.0, "age": 2.0, "warning": 0.8, "life": 12.0})
	game.pickup = game.player + Vector2(90, 0)
	game.pickup_active = true
	game.try_dash(Vector2.RIGHT)
	game.advance_game(Game.DASH_DURATION, Vector2.ZERO)
	expect(game.phase == Game.Phase.PLAYING and game.broken_obstacles == 1 and game.collected == 1 and game.dash_cooldown_remaining == 0, "A single dash can shatter a wall and collect an orb behind it")
	expect(game.score == 66, "Collecting an orb in the same frame preserves the 15-point shatter bonus")
	game.advance_game(0.1, Vector2.ZERO)
	expect(game.score == 67, "Later time updates retain the shatter bonus without awarding it twice")
	game.finish_run()
	expect(game.best >= 67 and game.score == 67, "Final score and best record include the shatter bonus")
	game.begin_run()
	expect(game.fragments.is_empty() and game.broken_obstacles == 0, "Restart clears all shatter effects and counters")
	expect(game.score == 0, "Restart clears the shatter score")
	quiet_run(game)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = game.player + Vector2(90, -40)
	game._unhandled_input(click)
	var aim := Vector2(90, -40).normalized()
	expect(game.dash_direction.is_equal_approx(aim) and game.dash_remaining == Game.DASH_DURATION, "Left click dashes toward its position")
	click.position = game.player + Vector2(-100, 0)
	game._unhandled_input(click)
	expect(game.dash_direction.is_equal_approx(aim) and game.dash_ripple.emitted_count == 1, "Repeated clicks cannot steer a dash or bypass cooldown")
	key.keycode = KEY_SPACE
	game._unhandled_input(key)
	expect(game.dash_ripple.emitted_count == 1, "Mouse and space share cooldown")
	quiet_run(game)
	click.pressed = false
	game._unhandled_input(click)
	expect(game.dash_remaining == 0, "Mouse release does not trigger dash")
	click.pressed = true
	click.position = game.player
	game._unhandled_input(click)
	expect(game.dash_remaining == 0 and game.dash_cooldown_remaining == 0, "Clicking the player's center does not waste a dash")
	game.position = Vector2(80, 40)
	game.scale = Vector2(1.5, 1.5)
	click.position = game.get_global_transform_with_canvas() * (game.player + Vector2(0, 100))
	game._unhandled_input(click)
	expect(game.dash_direction.is_equal_approx(Vector2.DOWN), "Mouse aim accounts for canvas position and scale")
	game.position = Vector2.ZERO
	game.scale = Vector2.ONE
	quiet_run(game)
	game.phase = Game.Phase.PAUSED
	click.position = Vector2(100, 200)
	game._unhandled_input(click)
	expect(game.phase == Game.Phase.PAUSED and game.dash_remaining == 0, "An outside click cannot dash or resume while paused")
	click.position = Vector2(540, 495)
	game._unhandled_input(click)
	expect(game.phase == Game.Phase.PLAYING and game.dash_remaining == 0, "Resume button still resumes without dashing")
	for overlay_phase in [Game.Phase.READY, Game.Phase.DEAD]:
		game.phase = overlay_phase
		game._unhandled_input(click)
		expect(game.phase == Game.Phase.PLAYING and game.dash_remaining == 0, "Title and death buttons still start a run without dashing")
	game.queue_free()
	await process_frame
	print("%s: %d dash checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)
