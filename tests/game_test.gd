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


func barrier(center: Vector2, age: float = 2.0, travel: Vector2 = Vector2.ZERO) -> Dictionary:
	return {"center": center, "velocity": travel, "angle": 0.0, "spin": 0.0,
		"length": 180.0, "age": age, "warning": 0.8, "life": 12.0}


func run() -> void:
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.rng.seed = 42
	expect(game.phase == Game.Phase.READY, "Launch starts on title screen")
	expect(is_equal_approx(Game.point_segment_distance(Vector2(5, 4), Vector2.ZERO, Vector2(10, 0)), 4), "Point to line interior")
	expect(is_equal_approx(Game.point_segment_distance(Vector2(13, 4), Vector2.ZERO, Vector2(10, 0)), 5), "Point to line endpoint")
	expect(is_equal_approx(Game.point_segment_distance(Vector2(3, 4), Vector2.ZERO, Vector2.ZERO), 5), "Zero length segment")
	expect(is_zero_approx(Game.segment_distance(Vector2(0, 0), Vector2(10, 10), Vector2(0, 10), Vector2(10, 0))), "Crossing swept segments")
	expect(is_equal_approx(Game.segment_distance(Vector2(0, 0), Vector2(10, 0), Vector2(0, 8), Vector2(10, 8)), 8), "Parallel swept segments")
	var clipped: PackedVector2Array = game._clip_to_arena(Vector2(0, 300), Vector2(1080, 300))
	expect(clipped.size() == 2 and clipped[0] == Vector2(48, 300) and clipped[1] == Vector2(1032, 300), "Drawing clips lines to arena")
	expect(game._clip_to_arena(Vector2.ZERO, Vector2(20, 20)).is_empty(), "Outside line is invisible")
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999
	game.advance_game(1.0 / 120.0, Vector2(1, 1))
	expect(game.velocity.length() <= Game.PLAYER_SPEED + 0.001, "Diagonal input is normalized")
	for step in 120:
		game.advance_game(1.0 / 120.0, Vector2(1, 1))
	expect(is_equal_approx(game.velocity.length(), Game.PLAYER_SPEED), "Acceleration reaches configured speed")
	expect(game.trail.size() == 22, "Trail remains bounded")
	game.player = Game.ARENA.end - Vector2(10, 10)
	game.advance_game(1.0 / 120.0, Vector2.ONE)
	expect(game.player == Game.ARENA.end - Vector2(10, 10), "Player cannot leave arena")
	game.pickup = game.player
	game.pickup_active = true
	game.advance_game(1.0 / 120.0, Vector2.ZERO)
	expect(game.collected == 1 and not game.pickup_active, "Pickup collected once")
	expect(game.score == int(game.elapsed * 10) + 50, "Time plus collection score")
	game.advance_game(1.0 / 120.0, Vector2.ZERO)
	expect(game.collected == 1, "Consumed pickup cannot score twice")
	game.pickup_active = true
	game.pickup = Vector2(100, 180)
	game.pickup_age = 9.1
	game._update_pickup(1.0 / 120.0)
	expect(not game.pickup_active, "Uncollected pickup expires")
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999
	game.obstacles.append(barrier(game.player, 0.0))
	game.advance_game(1.0 / 120.0, Vector2.ZERO)
	expect(game.phase == Game.Phase.PLAYING, "Warning line has no collision")
	game.obstacles[0]["age"] = 0.8
	game.advance_game(1.0 / 120.0, Vector2.ZERO)
	expect(game.phase == Game.Phase.DEAD, "Active line ends run")
	expect(game.sparks.size() >= 34 and not game.rings.is_empty(), "Death feedback emitted")
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999
	game.obstacles.append(barrier(game.player + Vector2(0, 7.8)))
	game.advance_game(1.0 / 120.0, Vector2.ZERO)
	expect(game.phase == Game.Phase.DEAD, "Collision includes radius and line thickness")
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999
	game.obstacles.append(barrier(game.player + Vector2(0, 40), 2, Vector2(0, -9600)))
	game.advance_game(1.0 / 120.0, Vector2.ZERO)
	expect(game.phase == Game.Phase.DEAD, "Swept moving obstacle catches crossing")
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999
	game.player = Vector2(450, 390)
	game.obstacles.append(barrier(Vector2(548, 383)))
	game.advance_game(1.0 / 120.0, Vector2.ZERO)
	expect(game.phase == Game.Phase.PLAYING, "Passing outside endpoint radius is safe")
	game.obstacles[0]["age"] = 12.1
	game.advance_game(1.0 / 120.0, Vector2.ZERO)
	expect(game.obstacles.is_empty(), "Expired obstacles removed")
	game.score = 700
	game.elapsed = 31.2
	game.finish_run()
	expect(game.best == 700 and is_equal_approx(game.best_time, 31.2), "Record updates on death")
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	game._unhandled_input(key)
	expect(game.phase == Game.Phase.PLAYING and game.score == 0 and game.obstacles.is_empty() and game.collected == 0, "Space immediately restarts and resets run")
	expect(game.best == 700, "Restart keeps record")
	# Exercise the actual save/load path, then restore any existing user record.
	var record_existed := FileAccess.file_exists(Game.SAVE_PATH)
	var previous_record := FileAccess.get_file_as_string(Game.SAVE_PATH) if record_existed else ""
	game._save_record()
	game.best = 0
	game.best_time = 0
	game._load_record()
	expect(game.best == 700 and is_equal_approx(game.best_time, 31.2), "Highest score and survival time persist to disk")
	if record_existed:
		var restore := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
		expect(restore != null, "Existing record can be restored")
		if restore != null:
			restore.store_string(previous_record)
			restore.close()
	else:
		expect(DirAccess.remove_absolute(Game.SAVE_PATH) == OK, "Verification record cleaned up")
	key.keycode = KEY_ESCAPE
	game._unhandled_input(key)
	var before_time: float = game.elapsed
	var before_player: Vector2 = game.player
	game._physics_process(1)
	expect(game.phase == Game.Phase.PAUSED and game.elapsed == before_time and game.player == before_player, "Pause freezes gameplay")
	game._unhandled_input(key)
	expect(game.phase == Game.Phase.PLAYING, "Escape resumes")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	expect(game.phase == Game.Phase.PAUSED, "Focus loss pauses game")
	game.begin_run()
	game.pickup_wait = 0
	game._update_pickup(0.01)
	expect(game.pickup_active and Game.ARENA.has_point(game.pickup) and game.pickup.distance_to(game.player) > 85, "Pickup spawns inside arena away from player")
	var stream: AudioStreamWAV = game._make_sound(720, 1180, 0.12)
	expect(stream.data.size() == int(0.12 * 22050) * 2 and stream.mix_rate == 22050, "Procedural sound has valid PCM data")
	# Long deterministic runs exercise spawning, rotation, death, restart and cleanup.
	var deaths := 0
	var rotations := 0
	for frame in 21600:
		if game.phase == Game.Phase.DEAD:
			deaths += 1
			game.begin_run()
		if frame % 240 == 0:
			game.elapsed = maxf(game.elapsed, 10)
		var direction := Vector2.from_angle(float(frame) * 0.007)
		game.advance_game(1.0 / 120.0, direction)
		game._update_effects(1.0 / 120.0)
		for item in game.obstacles:
			if absf(item["spin"]) > 0.01:
				rotations += 1
	expect(deaths > 0, "Three minute simulation reaches collisions and restarts")
	expect(rotations > 0, "Three minute simulation exercises rotating lines")
	expect(game.obstacles.size() < 40 and game.sparks.size() < 150, "Long run entity counts remain bounded")
	game.queue_free()
	await process_frame
	print("PASS: %d checks; 180 simulated seconds; %d restarts; rotation samples %d" % [checks, deaths, rotations])
	quit(0 if failures.is_empty() else 1)
