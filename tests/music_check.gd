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


func peak_of(samples: PackedVector2Array) -> float:
	var peak := 0.0
	for sample in samples:
		peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
	return peak


func run() -> void:
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game._setup_audio()
	game._setup_music(false)
	expect(game.music_enabled and not game.music_player.playing, "Music defaults on; deferred playback waits for input")
	expect(game.music_player.stream is AudioStreamMP3 and game.music_player.stream.loop, "Original MP3 is loaded and loops")
	var imported_music = load(Game.BACKGROUND_MUSIC_PATH)
	expect(imported_music.loop and imported_music.loop_offset == 0.0, "Imported resource loops from the beginning too")
	expect(game.music_player.stream.get_length() > 270, "Complete song is available")
	for stream in game.sound_players.values():
		expect(stream != game.music_player and stream.bus == "LineGapSFX", "Music is separate from every sound effect")

	var music_bus := AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(music_bus, "MusicCheck")
	game.music_player.bus = "MusicCheck"
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 1
	AudioServer.add_bus_effect(music_bus, capture)
	game.set_music_enabled(true)
	# Measure the natural intro as well as playback later in the track.
	await create_timer(2.0).timeout
	var intro_samples := capture.get_buffer(capture.get_frames_available())
	var intro_square := 0.0
	for sample in intro_samples:
		intro_square += sample.length_squared() * 0.5
	var intro_rms := sqrt(intro_square / max(1, intro_samples.size()))
	expect(intro_rms > 0.04, "Music intro is audible without seeking or changing volume")
	capture.clear_buffer()
	game.music_player.seek(8.0)
	await create_timer(0.2).timeout
	var music_samples := capture.get_buffer(capture.get_frames_available())
	expect(not music_samples.is_empty() and peak_of(music_samples) > 0.001, "Music produces audible PCM output")
	game.set_music_enabled(false)
	await create_timer(0.1).timeout
	var paused_position: float = game.music_player.get_playback_position()
	capture.clear_buffer()
	await create_timer(0.2).timeout
	var muted_samples := capture.get_buffer(capture.get_frames_available())
	expect(game.music_player.stream_paused and peak_of(muted_samples) < 0.0001, "Music toggle silences only music")
	expect(absf(game.music_player.get_playback_position() - paused_position) < 0.02, "Muted music holds its playback position")
	game._play_sound(game.shatter_sound)
	expect(game.sound_players[game.shatter_sound.get_instance_id()].playing, "Sound effects still play with music off")
	game.set_music_enabled(true)
	await create_timer(0.1).timeout
	expect(not game.music_player.stream_paused and game.music_player.get_playback_position() >= paused_position, "Turning music on resumes from its previous position")
	var previous_position: float = game.music_player.get_playback_position()
	game.begin_run()
	expect(game.music_player.get_playback_position() >= previous_position, "Starting or restarting does not restart music")
	for state in [Game.Phase.PLAYING, Game.Phase.PAUSED, Game.Phase.DEAD]:
		game.phase = state
		game.music_player.seek(game.music_player.stream.get_length() - 0.08)
		await create_timer(0.3).timeout
		expect(game.music_enabled and game.music_player.playing and game.music_player.get_playback_position() < 1.0, "Repeated end-of-song loops preserve the music switch in phase %d" % state)
	# Exercise a backend that reports completion instead of honoring native looping.
	game.music_player.stream.loop = false
	game.music_player.seek(game.music_player.stream.get_length() - 0.08)
	await create_timer(0.3).timeout
	expect(game.music_enabled and game.music_player.playing and game.music_player.get_playback_position() < 1.0, "Completion callback restarts music when native looping is unavailable")
	game.music_player.seek(game.music_player.stream.get_length() - 0.08)
	game.set_music_enabled(false)
	await create_timer(0.3).timeout
	expect(not game.music_enabled and game.music_player.stream_paused and game.music_player.get_playback_position() > 270.0, "Disabling music near the end prevents an automatic restart")
	game.music_player.stream.loop = true

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game.position = Vector2(80, 40)
	game.scale = Vector2(1.5, 1.5)
	click.position = game.get_global_transform_with_canvas() * Game.MUSIC_BUTTON.get_center()
	for state in [Game.Phase.READY, Game.Phase.PLAYING, Game.Phase.PAUSED, Game.Phase.DEAD]:
		game.phase = state
		game.dash_remaining = 0
		game.dash_cooldown_remaining = 0.75
		game._open_settings()
		var settings_phase: int = game.phase
		var previous: bool = game.music_enabled
		game._unhandled_input(click)
		expect(game.music_enabled != previous, "Music button works in phase %d after scaling" % state)
		expect(game.phase == settings_phase and game.dash_remaining == 0 and game.dash_cooldown_remaining == 0.75, "Music button preserves settings state and cannot trigger a dash in phase %d" % state)
		game._close_settings()
		expect(game.phase == state, "Closing music settings restores phase %d" % state)
	for selected in ["zh", "en"]:
		game.set_language(selected)
		for key in ["music_on", "music_off"]:
			expect(game.font.get_string_size(game.ui_text(key), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x < Game.MUSIC_BUTTON.size.x - 16, "Music label fits " + selected + ":" + key)

	# Use an isolated file so this test never changes the player's saved settings.
	var settings_path := "user://music-check-%d.cfg" % Time.get_ticks_usec()
	var config := ConfigFile.new()
	config.set_value("record", "score", 4321)
	config.set_value("settings", "language", "en")
	config.save(settings_path)
	game._load_music_preference(settings_path)
	expect(game.music_enabled, "Existing saves without music settings default to on")
	for enabled in [false, true]:
		game.set_music_enabled(enabled)
		game._save_music_preference(settings_path)
		game.music_enabled = not enabled
		game._load_music_preference(settings_path)
		expect(game.music_enabled == enabled, "Music preference persists: " + str(enabled))
	config.load(settings_path)
	expect(config.get_value("record", "score") == 4321 and config.get_value("settings", "language") == "en", "Saving music preserves records and language")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
	game.music_player.finished.disconnect(game._start_music_if_enabled)
	game.music_player.stop()
	game.queue_free()
	await process_frame
	AudioServer.remove_bus(music_bus)
	print("%s: %d music checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)
