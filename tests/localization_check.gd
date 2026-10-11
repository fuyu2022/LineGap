extends SceneTree

const Game = preload("res://scripts/game.gd")
var checks := 0
var failures: Array[String] = []
var output_dir := ""


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)


func capture(game: Node2D, name: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(output_dir + "/" + name + ".png") == OK, "Save " + name)


func run() -> void:
	var visual := "visual" in OS.get_cmdline_user_args()
	if visual:
		output_dir = ProjectSettings.globalize_path("res://artifacts")
		DirAccess.make_dir_recursive_absolute(output_dir)
	for locale in ["zh_CN", "zh-TW", "zh-HK", "ZH_cn"]:
		expect(Game.language_for_locale(locale) == "zh", "Chinese locale " + locale)
	for locale in ["en_US", "en-GB", "de_DE", "", "ja_JP"]:
		expect(Game.language_for_locale(locale) == "en", "English fallback " + locale)
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	for selected in ["zh", "en"]:
		game.set_language(selected)
		for key in Game.UI_TEXT["zh"]:
			expect(Game.UI_TEXT["en"].has(key) and not game.ui_text(key).is_empty(), "Translation present: " + selected + ":" + key)
		expect(game.font.get_string_size(game.ui_text("name"), HORIZONTAL_ALIGNMENT_LEFT, -1, 22 if selected == "en" else 26).x < 145, "Header title fits " + selected)
		expect(game.font.get_string_size(game.ui_text("dash_controls"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x < 132, "Dash hint fits " + selected)
		expect(game.font.get_string_size(game.ui_text("cooldown") % 1.5, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x < 100, "Cooldown fits " + selected)
		expect(game.font.get_string_size(game.ui_text("stats") % [999.9, 999, 999], HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x < Game.ARENA.size.x, "Death statistics fit " + selected)
		game.best = 999999
		game.best_broken = 9999
		game.best_time = 9999.9
		expect(game.font.get_string_size(game._best_record_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, game._best_record_font_size()).x <= Game.RECORD_LABEL_WIDTH, "Combined score, shatters and time fit " + selected)
		expect(game.font.get_string_size(game.ui_text("best"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x < 190, "Record heading fits " + selected)
		for key in ["start", "resume", "restart"]:
			expect(game.font.get_string_size(game.ui_text(key), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x < 260, "Button fits " + selected + ":" + key)
		if visual:
			game.phase = Game.Phase.READY
			await capture(game, "locale-" + selected + "-ready")
			game.begin_run()
			game.elapsed = 24.6
			game.score = 396
			game.best = 820
			game.best_broken = 25
			game.broken_obstacles = 12
			game.collected = 3
			game.lives = 3
			game.dash_cooldown_remaining = 0.6
			await capture(game, "locale-" + selected + "-playing")
			game.phase = Game.Phase.PAUSED
			await capture(game, "locale-" + selected + "-paused")
			game.phase = Game.Phase.DEAD
			game.death_age = 0.7
			game.score = 1234
			game.old_best = 820
			await capture(game, "locale-" + selected + "-dead")
			game._open_settings()
			await capture(game, "locale-" + selected + "-settings")
			game._close_settings()
	game.set_language("en")
	game.set_language("invalid")
	expect(game.language == "en", "Invalid language cannot break UI")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game.position = Vector2(80, 40)
	game.scale = Vector2(1.5, 1.5)
	click.position = game.get_global_transform_with_canvas() * Game.LANGUAGE_BUTTON.get_center()
	for state in [Game.Phase.READY, Game.Phase.PLAYING, Game.Phase.PAUSED, Game.Phase.DEAD]:
		game.phase = state
		game.score = 396
		game.lives = 2
		game.dash_remaining = 0
		game.dash_cooldown_remaining = 0.75
		game._open_settings()
		var settings_phase: int = game.phase
		var previous: String = game.language
		game._unhandled_input(click)
		expect(game.language != previous, "Transformed language button works in phase %d" % state)
		expect(game.phase == settings_phase and game.score == 396 and game.lives == 2, "Switch preserves paused settings state in phase %d" % state)
		expect(game.dash_remaining == 0 and game.dash_cooldown_remaining == 0.75, "Language button neither dashes nor refills in phase %d" % state)
		game._close_settings()
		expect(game.phase == state, "Closing settings returns to the original phase %d" % state)
	game.queue_free()
	await process_frame
	print("%s: %d localization checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)
