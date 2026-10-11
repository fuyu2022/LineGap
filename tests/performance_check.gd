extends SceneTree

class ProfileGame extends "res://scripts/game.gd":
	var frame_times: Array[float] = []
	var draw_times: Array[float] = []
	var physics_times: Array[float] = []
	var repeated_positions := 0
	var measured_frames := 0
	var sample_time := 0.0
	var last_frame_us := 0
	var last_position := Vector2.INF
	var peak_fragments := 0
	var peak_obstacles := 0
	var draw_calls := 0
	var attack_wait := 0.0
	var profile_duration := 17.0
	var next_report := 30.0
	var windows: Array[Dictionary] = []

	func _notification(_what: int) -> void:
		pass

	func _physics_process(delta: float) -> void:
		var started := Time.get_ticks_usec()
		if phase != Phase.PLAYING:
			begin_run()
			lives = 3
			spawn_wait = 999
			pickup_wait = 999
		attack_wait -= delta
		if attack_wait <= 0:
			player = Vector2(350, 390)
			lives = 3
			hit_grace = 999
			dash_cooldown_remaining = 0
			for distance in [60, 95, 135, 190]:
				obstacles.append({"center": player + Vector2(distance, 0), "velocity": Vector2.ZERO,
					"angle": PI / 2, "spin": 0.0, "length": 180.0, "age": 2.0, "warning": 0.8, "life": 12.0})
			try_dash(Vector2.RIGHT)
			attack_wait = 1.4
		super._physics_process(delta)
		peak_fragments = maxi(peak_fragments, fragments.size())
		peak_obstacles = maxi(peak_obstacles, obstacles.size())
		if sample_time > 2:
			physics_times.append(float(Time.get_ticks_usec() - started) / 1000.0)

	func _process(delta: float) -> void:
		super._process(delta)
		sample_time += delta
		var now := Time.get_ticks_usec()
		if sample_time > 2 and last_frame_us > 0:
			frame_times.append(float(now - last_frame_us) / 1000.0)
		last_frame_us = now
		if sample_time >= next_report:
			record_window()
			next_report += 30.0
		if sample_time >= profile_duration:
			finish_profile()

	func _movement_input() -> Vector2:
		return Vector2.from_angle(visual_time * 1.5)

	func _draw() -> void:
		var started := Time.get_ticks_usec()
		super._draw()
		draw_calls += 1
		if sample_time > 2:
			draw_times.append(float(Time.get_ticks_usec() - started) / 1000.0)
			measured_frames += 1
			if player.is_equal_approx(last_position):
				repeated_positions += 1
		last_position = player

	func stats(values: Array[float]) -> Dictionary:
		values.sort()
		var total := 0.0
		for value in values:
			total += value
		return {"samples": values.size(), "average_ms": total / max(1, values.size()),
			"p95_ms": values[int((values.size() - 1) * 0.95)],
			"p99_ms": values[int((values.size() - 1) * 0.99)], "max_ms": values[-1]}

	func finish_profile() -> void:
		set_process(false)
		set_physics_process(false)
		var args := OS.get_cmdline_user_args()
		var label := args[0] if not args.is_empty() else "current"
		var report := {"label": label, "display_hz": DisplayServer.screen_get_refresh_rate(),
			"physics_hz": Engine.physics_ticks_per_second, "frames": stats(frame_times),
			"draw_cpu": stats(draw_times), "physics_cpu": stats(physics_times),
			"repeated_positions": repeated_positions, "drawn_frames": measured_frames,
			"peak_fragments": peak_fragments, "peak_obstacles": peak_obstacles,
			"render_draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"duration_seconds": sample_time, "windows": windows}
		var file := FileAccess.open("res://artifacts/performance-" + label + ".json", FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		print(JSON.stringify(report))
		call_deferred("close_profile")

	func record_window() -> void:
		var recent: Array[float] = []
		recent.assign(frame_times.slice(maxi(0, frame_times.size() - 900)))
		var summary := {"at_seconds": sample_time, "frames": stats(recent),
			"static_memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576,
			"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
			"fragments": fragments.size(), "obstacles": obstacles.size()}
		windows.append(summary)
		print(JSON.stringify(summary))

	func close_profile() -> void:
		var tree := get_tree()
		tree.create_timer(0.1).timeout.connect(tree.quit)
		queue_free()


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var game = ProfileGame.new()
	game.test_mode = true
	root.add_child(game)
	game._setup_audio()
	game.rng.seed = 20261010
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		game.profile_duration = float(args[1])
	game.begin_run()
	game.lives = 3
	game.hit_grace = 999
	game.spawn_wait = 999
	game.pickup_wait = 999
	for index in 18:
		game.obstacles.append({"center": Vector2(120 + (index % 6) * 160, 200 + (index / 6) * 150),
			"velocity": Vector2(0, 12), "angle": float(index) * 0.35, "spin": 0.5,
			"length": 140.0, "age": 2.0, "warning": 0.8, "life": 99.0})
