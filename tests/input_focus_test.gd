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

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	for code in Game.MOVE_KEYS:
		for focus_out in [Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
			game.begin_run()
			game.spawn_wait = 999
			game.pickup_wait = 999
			key(code, true)
			game._physics_process(0.1)
			expect(not game._movement_input().is_zero_approx(), "Key %d moves before losing focus" % code)
			game._notification(focus_out)
			expect(game.phase == Game.Phase.PAUSED and game._movement_input() == Vector2.ZERO and game.velocity == Vector2.ZERO, "Focus loss clears key %d and pauses without receiving key-up" % code)
			game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
			var origin: Vector2 = game.player
			key(KEY_SPACE, true)
			key(KEY_SPACE, false)
			for tick in 30:
				game._physics_process(1.0 / 120)
			expect(game.phase == Game.Phase.PLAYING and game.player == origin, "Key %d cannot drift after resuming" % code)
			key(code, true)
			game._physics_process(0.1)
			expect(game.player != origin, "Key %d responds to a fresh press" % code)
			key(code, false)
			for tick in 30:
				game._physics_process(1.0 / 120)
			expect(game._movement_input() == Vector2.ZERO and game.velocity == Vector2.ZERO, "Key %d release stops normally" % code)
		game.begin_run()
		key(code, true)
		key(KEY_ESCAPE, true)
		key(KEY_ESCAPE, false)
		expect(game.phase == Game.Phase.PAUSED and game._movement_input() == Vector2.ZERO, "Manual pause clears key %d" % code)
		key(KEY_ESCAPE, true)
		key(KEY_ESCAPE, false)
		expect(game.phase == Game.Phase.PLAYING and game._movement_input() == Vector2.ZERO, "Escape resume does not restore key %d" % code)
		key(code, true)
		game.begin_run()
		expect(game._movement_input() == Vector2.ZERO, "Restart clears stale key %d" % code)
	game.begin_run()
	key(KEY_A, true)
	key(KEY_W, true)
	expect(game._movement_input().is_equal_approx(Vector2(-1, -1).normalized()), "Diagonal input stays normalized")
	key(KEY_LEFT, true)
	key(KEY_A, false)
	expect(game._movement_input().is_equal_approx(Vector2(-1, -1).normalized()), "Releasing A keeps the separately held left arrow")
	game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	expect(game._movement_input() == Vector2.ZERO, "Focus loss clears every held direction together")
	game.queue_free()
	await process_frame
	print("%s: %d input focus checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)
