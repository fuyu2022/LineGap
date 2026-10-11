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

func click(game, at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = game.get_global_transform_with_canvas() * at
	game._unhandled_input(event)

func key(game, code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._unhandled_input(event)

func run() -> void:
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.position = Vector2(80, 40)
	game.scale = Vector2(1.5, 1.5)
	for state in [Game.Phase.READY, Game.Phase.PLAYING, Game.Phase.PAUSED, Game.Phase.DEAD]:
		game.begin_run()
		game.phase = state
		game.score = 500
		game.broken_obstacles = 10
		game.dash_cooldown_remaining = 0.75
		game.super_dash_active = true
		game.super_dash_remaining = 5.0
		game.hit_grace = 1.5
		var origin: Vector2 = game.player
		click(game, Game.SETTINGS_BUTTON.get_center())
		var expected_phase: int = Game.Phase.PAUSED if state == Game.Phase.PLAYING else state
		expect(game.settings_open and game.phase == expected_phase and game.dash_remaining == 0, "Settings button opens without dashing in phase %d" % state)
		game._physics_process(2.0)
		expect(game.elapsed == 0 and game.score == 500 and game.player == origin and game.super_dash_remaining == 5.0 and game.hit_grace == 1.5 and game.dash_cooldown_remaining == 0.75, "Settings freezes movement and every gameplay timer in phase %d" % state)
		var music_before: bool = game.music_enabled
		click(game, Game.MUSIC_BUTTON.get_center())
		expect(game.music_enabled != music_before and game.settings_open and game.phase == expected_phase, "Music toggle stays inside settings in phase %d" % state)
		var language_before: String = game.language
		click(game, Game.LANGUAGE_BUTTON.get_center())
		expect(game.language != language_before and game.settings_open and game.phase == expected_phase, "Language switches immediately without closing settings in phase %d" % state)
		key(game, KEY_SPACE)
		key(game, KEY_R)
		click(game, Vector2(100, 200))
		expect(game.settings_open and game.phase == expected_phase and game.score == 500 and game.broken_obstacles == 10 and game.dash_remaining == 0, "Modal blocks restart, dash and outside clicks in phase %d" % state)
		click(game, Game.SETTINGS_CLOSE_BUTTON.get_center())
		expect(not game.settings_open and game.phase == state and game.dash_remaining == 0, "Close restores the original phase without dashing in phase %d" % state)
	game.begin_run()
	game._open_settings()
	key(game, KEY_ESCAPE)
	expect(not game.settings_open and game.phase == Game.Phase.PLAYING, "Escape closes settings and resumes a previously playing run")
	game.phase = Game.Phase.PAUSED
	game._open_settings()
	key(game, KEY_ESCAPE)
	expect(not game.settings_open and game.phase == Game.Phase.PAUSED, "Escape preserves a previously paused run")
	game.begin_run()
	game._open_settings()
	game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	game._close_settings()
	expect(game.phase == Game.Phase.PAUSED, "Closing after focus loss keeps the game paused until explicit resume")
	game._open_settings()
	click(game, Game.SETTINGS_BUTTON.get_center())
	expect(not game.settings_open and game.phase == Game.Phase.PAUSED, "Settings button can also close the panel")
	game._open_settings()
	game.begin_run()
	expect(not game.settings_open and not game.settings_resume_playing and game.phase == Game.Phase.PLAYING, "Restart resets settings state")
	game.phase = Game.Phase.READY
	var music_before: bool = game.music_enabled
	var language_before: String = game.language
	click(game, Game.MUSIC_BUTTON.get_center())
	click(game, Game.LANGUAGE_BUTTON.get_center())
	expect(game.music_enabled == music_before and game.language == language_before and not game.settings_open, "Hidden controls cannot toggle settings on the title screen")
	game.queue_free()
	await process_frame
	print("%s: %d settings checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)
