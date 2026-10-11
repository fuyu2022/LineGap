extends SceneTree
const Game = preload("res://scripts/game.gd")
const Clock = preload("res://scripts/music_clock.gd")
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)


func barrier(at: Vector2, length: float = 50.0) -> Dictionary:
	return {"center": at, "velocity": Vector2.ZERO, "angle": PI / 2, "spin": 0.0,
		"length": length, "age": 2.0, "warning": 0.8, "life": 100.0}


func quiet(game) -> void:
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999
	game.music_clock.reset()
	game.music_clock.update(game.music_clock.offset + 4 * game.music_clock.period)


func run() -> void:
	var clock = Clock.new()
	clock.update(clock.offset + clock.period * 10)
	expect(clock.on_beat() and clock.pulse > 0.99, "Track-grid beat triggers pulse and judgement")
	clock.update(clock.position + 0.26)
	expect(not clock.on_beat() and clock.pulse < 0.1, "Between beats brightness decays and judgement misses")
	var previous: float = clock.position
	clock.update(previous - 0.01)
	expect(clock.position == previous, "Minor playback jitter cannot rewind the clock")
	clock.update(clock.duration - 0.01)
	var old_index: int = clock.beat_index
	expect(clock.update(clock.offset + 0.01) and clock.beat_index > old_index, "Track loop starts a new beat cycle")
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_music_mode(true)
	quiet(game)
	expect(game.lives == 1 and game.music_wave_ready, "Music mode starts at stage one with a ready wave")
	var origin: Vector2 = game.player
	game.obstacles.append(barrier(origin + Vector2(70, 0)))
	game.obstacles.append(barrier(origin + Vector2(350, 0)))
	expect(game.try_dash(Vector2.RIGHT), "On-beat input releases a wave")
	expect(game.dash_remaining == 0 and game.dash_cooldown_remaining == 0, "Wave has no dash movement or timed cooldown")
	expect(not game.music_wave_ready and not game.try_dash(), "Button becomes unavailable and same-beat repeats are blocked")
	expect(game.obstacles.all(func(item): return item["ghost_remaining"] > 0), "On-beat input phases every obstacle, including distant ones")
	game.advance_game(0.15, Vector2.ZERO)
	expect(game.player == origin and game.broken_obstacles == 0, "Wave expands from stationary origin and does not destroy distant lines early")
	game.advance_game(0.10, Vector2.ZERO)
	expect(game.broken_obstacles == 1 and game.obstacles.size() == 1, "Expanding front shatters phased obstacle at contact")
	game.advance_game(0.25, Vector2.ZERO)
	expect(game.obstacles.size() == 1 and game.obstacles[0]["ghost_remaining"] == 0, "Outside-range obstacle survives and becomes solid again")
	game._update_music_beat(game.music_clock.period)
	expect(game.music_wave_ready, "Following beat resets the button")
	quiet(game)
	game.music_clock.update(game.music_clock.position + 0.25)
	game.obstacles.append(barrier(game.player + Vector2(50, 0)))
	expect(game.try_dash() and game.music_feedback == "beat_miss", "Off-beat input still produces a wave")
	expect(game.obstacles[0].get("ghost_remaining", 0.0) == 0, "Off-beat input does not phase solid obstacles")
	game.advance_game(0.3, Vector2.ZERO)
	expect(game.broken_obstacles == 0 and game.obstacles.size() == 1, "A wave passing a solid obstacle cannot shatter it")
	quiet(game)
	game.music_clock.update(game.music_clock.position + 0.26)
	game.obstacles.append(barrier(game.player))
	game.try_dash()
	game.advance_game(0.01, Vector2.ZERO)
	expect(game.phase == Game.Phase.DEAD, "Off-beat wave grants no invulnerability against a solid line")
	var radii: Array[float] = []
	for stage in range(1, 4):
		quiet(game)
		game.lives = stage
		radii.append(game._music_wave_radius())
		game.obstacles.append(barrier(game.player + Vector2(150, 0)))
		game.try_dash()
		game.advance_game(0.44, Vector2.ZERO)
		expect(game.broken_obstacles == (0 if stage == 1 else 1), "Stage %d respects its wave range" % stage)
	expect(radii[0] < radii[1] and radii[1] < radii[2], "Stages two and three progressively enlarge the wave")
	quiet(game)
	game.music_clock.update(game.music_clock.position + game.music_clock.period - 0.05)
	game.try_dash()
	game._update_music_beat(0.06)
	expect(not game.music_wave_ready, "Early on-beat input reserves upcoming beat and prevents a duplicate")
	game._update_music_beat(game.music_clock.period)
	expect(game.music_wave_ready, "Early input resets on the next distinct beat")
	quiet(game)
	game._begin_super_dash()
	expect(game.velocity == Vector2.ZERO, "Super resonance does not apply normal mode's speed boost")
	game.obstacles.append(barrier(game.player))
	game.obstacles.append(barrier(game.player + Vector2(350, 0)))
	game.advance_game(0.1, Vector2.ZERO)
	expect(game.lives == 1 and game.obstacles.size() == 2, "Super resonance phases obstacles continuously; contact alone does not shatter")
	game._update_music_beat(game.music_clock.period)
	expect(game.broken_obstacles == 2 and game.obstacles.is_empty(), "Super resonance shatters obstacles automatically on beat, beyond wave range")
	game._spawn_obstacle()
	var count: int = game.obstacles.size()
	game.phase = Game.Phase.PAUSED
	var time: float = game.music_clock.position
	var remaining: float = game.super_dash_remaining
	game._physics_process(1.0)
	expect(game.music_clock.position == time and game.super_dash_remaining == remaining and game.obstacles.size() == count, "Pause freezes beat, super timer and obstacles")
	game.phase = Game.Phase.PLAYING
	game.advance_game(7.0, Vector2.ZERO)
	expect(not game.super_dash_active and game.hit_grace > 0, "Super resonance expires with existing exit protection")
	tolerance_checks(game)
	quiet(game)
	game._setup_music()
	game.phase = Game.Phase.PAUSED
	game._sync_music_transport()
	expect(game.music_player.stream_paused, "PC music transport pauses with rhythm gameplay")
	game.phase = Game.Phase.PLAYING
	game.set_music_enabled(false)
	expect(game.music_player.playing and not game.music_player.stream_paused and game.music_player.volume_db == -80, "Muting music preserves rhythm clock and SFX")
	game.set_music_enabled(true)
	expect(game.music_player.volume_db == -3, "Unmuting restores music volume")
	game._handle_ui_press(Game.MUSIC_MODE_BUTTON.get_center())
	expect(not game.music_mode and game.phase == Game.Phase.PLAYING and game.elapsed == 0, "Mode button switches mode and restarts the run without a dash")
	game.try_dash(Vector2.RIGHT)
	expect(game.dash_remaining > 0 and game.dash_cooldown_remaining > 0, "Normal mode retains moving dash and timed cooldown")
	var path := "user://music-mode-check-%d.cfg" % Time.get_ticks_usec()
	game.best = 123
	game._save_record(path)
	game.music_mode = true
	game.best = 456
	game._save_record(path)
	game._save_mode_preference(path)
	game._load_record(path)
	expect(game.best == 456, "Music mode records persist independently")
	game.music_mode = false
	game._load_record(path)
	expect(game.best == 123, "Ordinary mode retains its records")
	game._load_mode_preference(path)
	expect(game.music_mode, "Mode selection persists")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.music_player.stop()
	game.queue_free()
	await process_frame
	print("%s: %d music mode checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


func queue_before_next_beat(game, early: float = 0.06) -> void:
	quiet(game)
	game.try_dash()
	game.music_clock.update(game.music_clock.position + game.music_clock.period - early)
	game.try_dash()


func tolerance_checks(game) -> void:
	var clock = Clock.new()
	for offset in [-0.231, -0.23, -0.22, 0.22, 0.23, 0.231]:
		clock.reset()
		clock.update(clock.offset + 10 * clock.period + offset)
		expect(clock.on_beat() == (absf(offset) <= 0.23), "230ms judgement boundary at %.3fs" % offset)
	for offset in [-0.22, 0.22]:
		quiet(game)
		game.music_clock.update(game.music_clock.offset + 5 * game.music_clock.period + offset)
		game.obstacles.append(barrier(game.player + Vector2(60, 0)))
		expect(game.try_dash() and game.music_feedback == "beat_hit" and game.obstacles[0]["ghost_remaining"] > 0, "New tolerance actually phases obstacles at %.2fs" % offset)
	queue_before_next_beat(game)
	expect(game.music_waves.size() == 1 and not game.music_wave_ready and game.music_wave_buffered_beat == 5, "Early gray-button input queues one upcoming beat without immediately firing")
	for repeat in 10:
		expect(not game.try_dash(), "Repeated buffered press cannot stack input %d" % repeat)
	game._update_music_beat(0.07)
	expect(game.music_waves.size() == 2 and game.music_feedback == "beat_hit" and game.music_ghost_remaining > 0, "Buffered input automatically fires an on-beat wave")
	expect(game.music_wave_used_beat == 5 and not game.music_wave_ready and game.music_wave_buffered_beat == -1 and not game.try_dash(), "Buffered wave consumes its beat and clears the queue")
	quiet(game)
	game.try_dash()
	game.music_clock.update(game.music_clock.position + game.music_clock.period - 0.081)
	expect(not game.try_dash() and game.music_wave_buffered_beat == -1, "Input more than 80ms early is rejected while gray")
	game.music_clock.update(game.music_clock.position + 0.001)
	expect(game.try_dash() and game.music_wave_buffered_beat == 5, "80ms boundary accepts buffered input")
	quiet(game)
	game.music_clock.update(game.music_clock.position + game.music_clock.period - 0.14)
	game.try_dash()
	game.music_clock.update(game.music_clock.position + 0.08)
	expect(not game.try_dash() and game.music_wave_buffered_beat == -1, "Cannot buffer a beat already consumed by an early on-beat wave")
	queue_before_next_beat(game)
	game._update_music_beat(game.music_clock.period + 0.07)
	expect(game.music_waves.size() == 1 and game.music_wave_buffered_beat == -1 and game.music_wave_ready, "Skipped target beat discards stale input")
	queue_before_next_beat(game)
	game._update_music_beat(0.32)
	expect(game.music_waves.size() == 1 and game.music_wave_buffered_beat == -1, "Long frame arriving outside the judgement window discards stale input")
	queue_before_next_beat(game)
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	game._unhandled_input(key)
	expect(game.phase == Game.Phase.PAUSED and game.music_wave_buffered_beat == -1, "Pause cancels pending input")
	game._unhandled_input(key)
	game._update_music_beat(0.07)
	expect(game.phase == Game.Phase.PLAYING and game.music_waves.size() == 1, "Resume never releases the canceled wave")
	queue_before_next_beat(game)
	game._open_settings()
	expect(game.music_wave_buffered_beat == -1, "Opening settings cancels pending input")
	game._close_settings()
	queue_before_next_beat(game)
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	expect(game.phase == Game.Phase.PAUSED and game.music_wave_buffered_beat == -1, "Losing focus cancels pending input")
	queue_before_next_beat(game)
	game.begin_run()
	expect(game.music_waves.is_empty() and game.music_wave_buffered_beat == -1 and game.music_wave_ready, "Restart clears all pending input and waves")
	queue_before_next_beat(game)
	game.finish_run()
	expect(game.music_wave_buffered_beat == -1, "Death cancels pending input")
	quiet(game)
	game.music_clock.update(game.music_clock.duration - 0.1)
	game.try_dash()
	game.music_clock.update(game.music_clock.duration - 0.03)
	expect(game.try_dash() and game.music_wave_buffered_beat >= 0, "Input may buffer the next beat across a track loop")
	game.music_clock.update(game.music_clock.offset + 0.01)
	game._on_music_beat()
	expect(game.music_waves.size() == 2 and game.music_wave_buffered_beat == -1, "Loop-start beat consumes its buffer once")
