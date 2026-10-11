extends SceneTree
const Game = preload("res://scripts/game.gd")
const TEST_SAVE := "user://linegap-records-test.cfg"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)

func finish(game, points: int, broken: int, seconds: float = 0.0) -> void:
	game.begin_run()
	game.score = points
	game.broken_obstacles = broken
	game.elapsed = seconds
	game.finish_run()

func run() -> void:
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_language("zh")
	game._load_record("user://linegap-missing-records-test.cfg")
	expect(game.best == 0 and game.best_broken == 0, "New players start with two zero records")
	finish(game, 700, 10, 31.2)
	expect(game.best == 700 and game.best_broken == 10, "First finished run records score and shatters")
	expect(game._best_record_label() == "00700 / 010 / 31.2秒", "Record display combines score, shatters and survival on one line")
	game.set_language("en")
	expect(game._best_record_label() == "00700 / 010 / 31.2s", "Record survival unit follows language")
	game.set_language("zh")
	finish(game, 900, 5)
	expect(game.best == 900 and game.best_broken == 10, "A higher score cannot lower the shatter record")
	finish(game, 500, 15)
	expect(game.best == 900 and game.best_broken == 15, "A lower scoring run can independently improve shatters")
	expect(game.score <= game.old_best and game.broken_obstacles > game.old_best_broken, "Shatter-only record qualifies for the new record notice")
	finish(game, 400, 3)
	expect(game.best == 900 and game.best_broken == 15, "A worse run preserves both records")
	game.finish_run()
	expect(game.best == 900 and game.best_broken == 15, "Finishing an already dead run does not alter records")
	game.begin_run()
	expect(game.broken_obstacles == 0 and game.score == 0 and game.best == 900 and game.best_broken == 15, "Restart clears this run while preserving both records")
	var config := ConfigFile.new()
	config.set_value("settings", "language", "en")
	config.set_value("settings", "music_enabled", false)
	expect(config.save(TEST_SAVE) == OK, "Create isolated settings fixture")
	game._save_record(TEST_SAVE)
	game.best = 0
	game.best_broken = 0
	game._load_record(TEST_SAVE)
	expect(game.best == 900 and game.best_broken == 15 and game.old_best_broken == 15 and is_equal_approx(game.best_time, 31.2), "All three records persist across save and reload")
	config.load(TEST_SAVE)
	expect(config.get_value("settings", "language") == "en" and config.get_value("settings", "music_enabled") == false, "Saving records preserves language and music preferences")
	config = ConfigFile.new()
	config.set_value("record", "score", 1234)
	config.set_value("record", "seconds", 31.2)
	config.save(TEST_SAVE)
	game._load_record(TEST_SAVE)
	expect(game.best == 1234 and is_equal_approx(game.best_time, 31.2) and game.best_broken == 0, "Old saves keep score and survival time with zero unknown shatters")
	finish(game, 600, 8)
	game._save_record(TEST_SAVE)
	game._load_record(TEST_SAVE)
	expect(game.best == 1234 and game.best_broken == 8, "Old saves gain a shatter record without losing their score")
	expect(DirAccess.remove_absolute(TEST_SAVE) == OK, "Remove isolated test save")
	game.queue_free()
	await process_frame
	print("%s: %d record checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)
