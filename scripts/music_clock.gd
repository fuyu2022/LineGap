extends RefCounted
## Track time, rather than accumulated frame time, drives the rhythm grid.

const WINDOW := 0.23
var grid: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/music/beat_grid.json"))
var period := 60.0 / float(grid["bpm"])
var offset := float(grid["beat_offset"])
var duration := float(grid["duration"])
var position := 0.0
var beat_index := -1
var cycles := 0
var initialized := false
var pulse := 0.0


func reset(at: float = 0.0) -> void:
	position = at
	cycles = 0
	initialized = false
	beat_index = -1
	pulse = 0.0


func update(at: float) -> bool:
	at = maxf(0.0, at)
	if initialized and at < position - 0.5:
		cycles += 1
	elif initialized:
		at = maxf(at, position) # Ignore small audio-thread timing jitter.
	position = at
	var local_beat := floori((position - offset) / period)
	var next := cycles * ceili(duration / period) + local_beat
	var crossed := initialized and next > beat_index
	beat_index = next
	initialized = true
	var age := position - (offset + local_beat * period)
	pulse = exp(-age * 12.0) if local_beat >= 0 else 0.0
	return crossed


func nearest_beat() -> int:
	return cycles * ceili(duration / period) + roundi((position - offset) / period)


func on_beat() -> bool:
	var nearest := roundi((position - offset) / period)
	return nearest >= 0 and absf(position - offset - nearest * period) <= WINDOW + 0.000001


func time_to_next_beat() -> float:
	var next := offset + (floori((position - offset) / period) + 1) * period
	if next >= duration:
		return maxf(0.0, duration - position + offset)
	return maxf(0.0, next - position)


func progress() -> float:
	return fposmod(position - offset, period) / period
