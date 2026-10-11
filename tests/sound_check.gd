extends SceneTree
const Game = preload("res://scripts/game.gd")
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)


func waveform_stats(stream: AudioStreamWAV) -> Dictionary:
	var peak := 0.0
	var square := 0.0
	var front := 0.0
	var frames := stream.data.size() / 2
	for index in frames:
		var sample := float(stream.data.decode_s16(index * 2)) / 32768.0
		peak = maxf(peak, absf(sample))
		square += sample * sample
		if index < int(stream.mix_rate * 0.04):
			front += sample * sample
	return {"peak": peak, "rms": sqrt(square / frames), "first_40ms_energy": front / maxf(square, 0.000001)}


func run() -> void:
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game._setup_audio()
	# Finish initial font/geometry uploads before measuring a 150 ms sound.
	await process_frame
	await RenderingServer.frame_post_draw
	var shatter = game.sound_players[game.shatter_sound.get_instance_id()]
	var death = game.sound_players[game.death_sound.get_instance_id()]
	var collect = game.sound_players[game.collect_sound.get_instance_id()]
	expect(shatter != death and shatter != collect, "Effects use separate players")
	expect(shatter.volume_db == 0 and death.volume_db == 0 and collect.volume_db == 0, "All effects have the old -16 dB attenuation removed")
	expect(shatter.max_polyphony == 6, "Consecutive shatters can overlap")
	var shatter_stats := waveform_stats(game.shatter_sound)
	var death_stats := waveform_stats(game.death_sound)
	expect(shatter_stats["peak"] > 0.93 and death_stats["peak"] > 0.93, "Impact effects have strong normalized peaks")
	expect(shatter_stats["first_40ms_energy"] > 0.8, "Shatter energy is concentrated at the impact")
	game.shatter_sound.save_to_wav("res://artifacts/shatter-sfx.wav")
	game.death_sound.save_to_wav("res://artifacts/death-sfx.wav")
	var bus := AudioServer.get_bus_index("LineGapSFX")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 2
	AudioServer.add_bus_effect(bus, capture)
	game.begin_run()
	game.lives = 2
	game.spawn_wait = 999
	game.pickup_wait = 999
	game.obstacles.append({"center": game.player + Vector2(55, 0), "velocity": Vector2.ZERO,
		"angle": PI / 2, "spin": 0.0, "length": 180.0, "age": 2.0, "warning": 0.8, "life": 12.0})
	game.try_dash(Vector2.RIGHT)
	game.advance_game(0.08, Vector2.ZERO)
	await create_timer(0.03).timeout
	expect(game.broken_obstacles == 1 and shatter.playing, "Shatter plays at the actual collision")
	game.pickup = game.player
	game.pickup_active = true
	game._update_pickup(0.001)
	await create_timer(0.01).timeout
	expect(collect.playing and shatter.playing, "Collecting does not cut off a shatter")
	await create_timer(0.3).timeout
	capture.clear_buffer()
	for index in 6:
		game._play_sound(game.shatter_sound)
	await create_timer(0.22).timeout
	var samples := capture.get_buffer(capture.get_frames_available())
	var mixed_peak := 0.0
	for sample in samples:
		mixed_peak = maxf(mixed_peak, maxf(absf(sample.x), absf(sample.y)))
	expect(samples.size() > 0 and mixed_peak > 0.5 and mixed_peak <= 0.90, "Six overlapping shatters are audible and limited without clipping")
	game.finish_run()
	await create_timer(0.03).timeout
	expect(death.playing, "Death plays when the run ends")
	await create_timer(0.42).timeout
	AudioServer.remove_bus_effect(bus, AudioServer.get_bus_effect_count(bus) - 1)
	var report := {"checks": checks, "shatter": shatter_stats, "death": death_stats,
		"overlap_peak": mixed_peak, "passed": failures.is_empty()}
	var file := FileAccess.open("res://artifacts/sound-check.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
