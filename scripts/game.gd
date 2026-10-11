extends Node2D
## All artwork is drawn with points, lines and circles. No image assets.

const ARENA := Rect2(48, 128, 984, 510)
const CYAN := Color("65f6dc")
const WHITE := Color("dfebf2")
const MUTED := Color("92999f")
const BACKGROUND := Color("000000")
const ARENA_BACKGROUND := Color("000000")
const SEPARATOR := Color("343a40")
const RED := Color("ff758e")
const GOLD := Color("ffd38a")
const PLAYER_RADIUS := 7.0
const PLAYER_SPEED := 335.0
const SAVE_PATH := "user://records.cfg"
const LINE_SPEED := 90.0
const DashRipple = preload("res://scripts/dash_ripple.gd")
const DASH_SPEED := 1000.0
const DASH_DURATION := 0.16
const DASH_COOLDOWN := 1.5
const MAX_LIVES := 3
const DASH_FULL_DURATION := 0.28
const HIT_GRACE := 2.0
const SUPER_DASH_ORBS := 7
const SUPER_DASH_DURATION := 7.0
const SUPER_MOVE_MULTIPLIER := 2.0
const SHATTER_SCORE := 15
const MOVE_KEYS := [KEY_A, KEY_D, KEY_W, KEY_S, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
const SETTINGS_BUTTON := Rect2(900, 662, 132, 36)
const MUSIC_BUTTON := Rect2(558, 313, 148, 40)
const LANGUAGE_BUTTON := Rect2(558, 395, 148, 40)
const SETTINGS_CLOSE_BUTTON := Rect2(410, 482, 260, 44)
const BACKGROUND_MUSIC_PATH := "res://assets/music/bumba-crossing.mp3"
const WEB_FONT_PATH := "res://assets/fonts/LineGapSans-Regular.ttf"
const UI_TEXT := {
	"zh": {
		"name": "线隙", "title": "线 隙", "broken": "击碎", "score": "得分",
		"survived": "存活", "seconds": "秒", "best": "最高纪录",
		"move": "WASD / 方向键  移动", "pause_restart": "ESC  暂停    R  重开",
		"dash_controls": "左键 / 空格  冲刺", "dashing": "冲刺中", "ready": "就绪",
		"cooldown": "冷却 %.1f 秒", "dead": "本局结束", "paused": "已暂停",
		"start": "空格  开始", "restart": "空格  重开", "resume": "空格  继续",
		"stats": "存活 %.1f 秒   ·   收集 %d   ·   击碎 %d", "final_score": "得分  %05d",
		"new_best": "新纪录", "switch_language": "English",
		"music_on": "音乐：开", "music_off": "音乐：关",
		"settings": "设置", "background_music": "背景音乐", "language": "语言",
		"settings_hint": "音乐开关不影响音效", "close_settings": "关闭 / ESC",
		"super_dash": "超级冲刺 %.1f 秒", "super_progress": "超级冲刺 %d/%d",
		"protection": "保护壳 %.1f 秒"
	},
	"en": {
		"name": "LINE GAP", "title": "LINE GAP", "broken": "BROKEN", "score": "SCORE",
		"survived": "SURVIVED", "seconds": "s", "best": "BEST RECORDS",
		"move": "WASD / Arrows  Move", "pause_restart": "ESC  Pause    R  Restart",
		"dash_controls": "LMB / Space  Dash", "dashing": "Dashing", "ready": "Ready",
		"cooldown": "Cooldown %.1fs", "dead": "RUN OVER", "paused": "PAUSED",
		"start": "Space  Start", "restart": "Space  Restart", "resume": "Space  Resume",
		"stats": "Survived %.1fs   ·   Orbs %d   ·   Broken %d", "final_score": "Score  %05d",
		"new_best": "NEW BEST", "switch_language": "中文",
		"music_on": "Music: On", "music_off": "Music: Off",
		"settings": "Settings", "background_music": "Background music", "language": "Language",
		"settings_hint": "Sound effects remain enabled", "close_settings": "Close / Esc",
		"super_dash": "Super dash %.1fs", "super_progress": "Super dash %d/%d",
		"protection": "Shield %.1fs"
	}
}

enum Phase { READY, PLAYING, PAUSED, DEAD }
enum LineKind { HORIZONTAL, VERTICAL, ROTATING }

var phase: Phase = Phase.READY
var player := ARENA.get_center()
var velocity := Vector2.ZERO
var obstacles: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var fragments: Array[Dictionary] = []
var broken_obstacles := 0
var rings: Array[Dictionary] = []
var trail: Array[Vector2] = []
var pickup := Vector2.ZERO
var pickup_active := false
var pickup_wait := 1.4
var pickup_age := 0.0
var elapsed := 0.0
var visual_time := 0.0
var spawn_wait := 0.65
var score := 0
var collected := 0
var lives := 1
var hit_grace := 0.0
var best := 0
var old_best := 0
var best_broken := 0
var old_best_broken := 0
var best_time := 0.0
var flash := 0.0
var death_age := 0.0
var shake := 0.0
var test_mode := false
var rng := RandomNumberGenerator.new()
var font: Font
var sound_players: Dictionary = {}
var collect_sound: AudioStreamWAV
var death_sound: AudioStreamWAV
var shatter_sound: AudioStreamWAV
var hit_sound: AudioStreamWAV
var dash_ripple = DashRipple.new()
var ripple_clip: Control
var dash_remaining := 0.0
var super_dash_active := false
var super_dash_remaining := 0.0
var dash_cooldown_remaining := 0.0
var dash_cooldown_duration := DASH_COOLDOWN
var dash_direction := Vector2.UP
var last_move_direction := Vector2.UP
var background_layer: Node2D
var grid_dots: MultiMesh
var language := "zh"
var music_enabled := true
var music_player: AudioStreamPlayer
var web_audio
var web_sound_names: Dictionary = {}
var settings_open := false
var settings_resume_playing := false


func _ready() -> void:
	if OS.has_feature("web"):
		font = load(WEB_FONT_PATH)
	else:
		var system_font := SystemFont.new()
		system_font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
		system_font.multichannel_signed_distance_field = true
		system_font.msdf_size = 96
		font = system_font
	rng.randomize()
	_build_grid()
	background_layer = Node2D.new()
	background_layer.z_index = -1
	background_layer.draw.connect(_draw_background)
	add_child(background_layer)
	ripple_clip = Control.new()
	ripple_clip.position = ARENA.position + Vector2(3, 3)
	ripple_clip.size = ARENA.size - Vector2(6, 6)
	ripple_clip.clip_contents = true
	ripple_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ripple_clip)
	dash_ripple.position = -ripple_clip.position
	ripple_clip.add_child(dash_ripple)
	dash_ripple.hide()
	_load_language()
	if not test_mode:
		_load_record()
		_load_music_preference()
		_setup_audio()
		_setup_music()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if settings_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_close_settings()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
			if MUSIC_BUTTON.has_point(click):
				set_music_enabled(not music_enabled)
			elif LANGUAGE_BUTTON.has_point(click):
				_start_music_if_enabled()
				set_language("en" if language == "zh" else "zh")
			elif SETTINGS_CLOSE_BUTTON.has_point(click) or SETTINGS_BUTTON.has_point(click):
				_close_settings()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_start_music_if_enabled()
		if event.keycode == KEY_SPACE:
			if phase == Phase.READY or phase == Phase.DEAD:
				begin_run()
			elif phase == Phase.PAUSED:
				_reset_movement_input()
				phase = Phase.PLAYING
			elif phase == Phase.PLAYING:
				try_dash(_movement_input())
		elif event.keycode == KEY_ESCAPE:
			if phase == Phase.PLAYING:
				_reset_movement_input()
				phase = Phase.PAUSED
			elif phase == Phase.PAUSED:
				_reset_movement_input()
				phase = Phase.PLAYING
		elif event.keycode == KEY_R and phase != Phase.READY:
			begin_run()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		_start_music_if_enabled()
		if SETTINGS_BUTTON.has_point(click):
			_open_settings()
			return
		if phase == Phase.PLAYING:
			var aim: Vector2 = click - player
			if not aim.is_zero_approx():
				try_dash(aim)
		elif Rect2(410, 468, 260, 54).has_point(click):
			if phase == Phase.READY or phase == Phase.DEAD:
				begin_run()
			elif phase == Phase.PAUSED:
				_reset_movement_input()
				phase = Phase.PLAYING


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		settings_resume_playing = false
		_reset_movement_input()
		if phase == Phase.PLAYING:
			phase = Phase.PAUSED
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_reset_movement_input()


func _reset_movement_input() -> void:
	# A key released outside the canvas/window may never deliver its key-up event.
	for code in MOVE_KEYS:
		if Input.is_physical_key_pressed(code):
			var release := InputEventKey.new()
			release.keycode = code
			release.physical_keycode = code
			release.pressed = false
			Input.parse_input_event(release)
	Input.flush_buffered_events()
	velocity = Vector2.ZERO


func _open_settings() -> void:
	if settings_open:
		return
	settings_open = true
	settings_resume_playing = phase == Phase.PLAYING
	_reset_movement_input()
	if settings_resume_playing:
		phase = Phase.PAUSED
	queue_redraw()


func _close_settings() -> void:
	if not settings_open:
		return
	settings_open = false
	_reset_movement_input()
	if settings_resume_playing and phase == Phase.PAUSED:
		phase = Phase.PLAYING
	settings_resume_playing = false
	queue_redraw()


func begin_run() -> void:
	settings_open = false
	settings_resume_playing = false
	_reset_movement_input()
	phase = Phase.PLAYING
	player = ARENA.get_center()
	velocity = Vector2.ZERO
	obstacles.clear()
	sparks.clear()
	fragments.clear()
	broken_obstacles = 0
	rings.clear()
	trail.clear()
	pickup_active = false
	pickup_wait = 1.4
	pickup_age = 0.0
	elapsed = 0.0
	spawn_wait = 0.65
	score = 0
	collected = 0
	lives = 1
	hit_grace = 0.0
	old_best = best
	old_best_broken = best_broken
	flash = 0.0
	shake = 0.0
	death_age = 0.0
	dash_ripple.reset()
	dash_ripple.show()
	dash_remaining = 0.0
	super_dash_active = false
	super_dash_remaining = 0.0
	dash_cooldown_remaining = 0.0
	dash_cooldown_duration = DASH_COOLDOWN
	dash_direction = Vector2.UP
	last_move_direction = Vector2.UP
	_emit_ring(player, CYAN, 36.0)


func _movement_input() -> Vector2:
	return Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	).normalized()


func try_dash(direction: Vector2 = Vector2.ZERO) -> bool:
	if phase != Phase.PLAYING:
		return false
	if super_dash_active and dash_remaining > 0:
		dash_direction = direction.normalized() if not direction.is_zero_approx() else last_move_direction
		last_move_direction = dash_direction
		return true
	if dash_remaining > 0 or (not super_dash_active and dash_cooldown_remaining > 0):
		return false
	dash_direction = direction.normalized() if not direction.is_zero_approx() else last_move_direction
	last_move_direction = dash_direction
	dash_remaining = DASH_FULL_DURATION if lives >= 3 else DASH_DURATION
	dash_cooldown_duration = DASH_COOLDOWN * (0.5 if lives >= 2 else 1.0)
	dash_cooldown_remaining = 0.0 if super_dash_active else dash_cooldown_duration
	dash_ripple.emit_at(player)
	return true


func _begin_super_dash() -> void:
	if not super_dash_active and dash_remaining <= 0:
		velocity *= SUPER_MOVE_MULTIPLIER
	super_dash_active = true
	super_dash_remaining = SUPER_DASH_DURATION
	dash_cooldown_remaining = 0.0
	_emit_ring(player, GOLD, 72.0)


func _end_super_dash(protection_elapsed: float = 0.0) -> void:
	super_dash_active = false
	super_dash_remaining = 0.0
	dash_cooldown_remaining = 0.0
	hit_grace = maxf(hit_grace, maxf(0.0, HIT_GRACE - protection_elapsed))
	_emit_ring(player, CYAN, 40.0)


func _physics_process(delta: float) -> void:
	if phase == Phase.PAUSED or settings_open:
		dash_ripple.hide()
		return
	visual_time += delta
	_update_effects(delta)
	if phase == Phase.PLAYING:
		advance_game(delta, _movement_input())
	elif phase == Phase.DEAD:
		death_age += delta
	dash_ripple.visible = phase == Phase.PLAYING


func _process(_delta: float) -> void:
	# Submit custom geometry once per displayed frame, not once per physics catch-up step.
	queue_redraw()
	dash_ripple.queue_redraw()


func _update_score() -> void:
	score = int(elapsed * 10.0) + collected * 50 + broken_obstacles * SHATTER_SCORE


func advance_game(delta: float, direction: Vector2) -> void:
	elapsed += delta
	hit_grace = maxf(0.0, hit_grace - delta)
	_update_score()
	var previous_player := player
	var super_dash_this_frame := super_dash_active
	var super_time := minf(delta, super_dash_remaining)
	var dash_time := minf(delta, dash_remaining)
	var dash_end_player := player
	dash_cooldown_remaining = maxf(0, dash_cooldown_remaining - delta)
	var move_direction := direction.normalized()
	if not move_direction.is_zero_approx():
		last_move_direction = move_direction
		if super_dash_active and dash_remaining > 0:
			dash_direction = move_direction
	var normal_time := delta
	var super_move_time := minf(maxf(0.0, delta - dash_time), maxf(0.0, super_time - dash_time))
	if dash_remaining > 0:
		velocity = dash_direction * DASH_SPEED
		player += velocity * dash_time
		dash_end_player = _clamp_player(player)
		dash_remaining = maxf(0, dash_remaining - dash_time)
		normal_time -= dash_time
		if dash_remaining == 0:
			velocity = move_direction * PLAYER_SPEED * (SUPER_MOVE_MULTIPLIER if super_time > dash_time else 1.0)
	var super_walk_start := dash_end_player if dash_time > 0 else previous_player
	var super_walk_end := super_walk_start
	if super_move_time > 0:
		velocity = velocity.move_toward(move_direction * PLAYER_SPEED * SUPER_MOVE_MULTIPLIER, 2400.0 * SUPER_MOVE_MULTIPLIER * super_move_time)
		player += velocity * super_move_time
		super_walk_end = _clamp_player(player)
	var ordinary_move_time := maxf(0.0, normal_time - super_move_time)
	if ordinary_move_time > 0:
		if super_move_time > 0:
			velocity /= SUPER_MOVE_MULTIPLIER
		velocity = velocity.move_toward(move_direction * PLAYER_SPEED, 2400.0 * ordinary_move_time)
		player += velocity * ordinary_move_time
	player = _clamp_player(player)
	if super_dash_this_frame:
		super_dash_remaining = maxf(0.0, super_dash_remaining - delta)
		if super_dash_remaining < 0.000001:
			if dash_remaining <= 0 and super_move_time > 0 and ordinary_move_time <= 0:
				velocity /= SUPER_MOVE_MULTIPLIER
			_end_super_dash(maxf(0.0, delta - super_time))
	trail.push_front(player)
	if trail.size() > 22:
		trail.pop_back()
	spawn_wait -= delta
	if spawn_wait <= 0.0:
		_spawn_obstacle()
		spawn_wait = maxf(0.43, 1.3 - elapsed * 0.013) * rng.randf_range(0.8, 1.15)
	for index in range(obstacles.size() - 1, -1, -1):
		var item := obstacles[index]
		var before := obstacle_endpoints(item)
		item["age"] += delta
		item["ghost_remaining"] = maxf(0.0, float(item.get("ghost_remaining", 0.0)) - delta)
		item["center"] += item["velocity"] * delta
		if item["age"] >= item["warning"] and item.get("kind", LineKind.ROTATING) == LineKind.ROTATING:
			item["angle"] += item["spin"] * delta
		var ends := obstacle_endpoints(item)
		var dash_fraction := dash_time / delta if delta > 0 else 0.0
		var dash_ends := PackedVector2Array([before[0].lerp(ends[0], dash_fraction), before[1].lerp(ends[1], dash_fraction)])
		if super_dash_this_frame and super_time > 0:
			var super_dash_time := minf(dash_time, super_time)
			var super_fraction := super_time / delta if delta > 0 else 0.0
			var super_ends := PackedVector2Array([before[0].lerp(ends[0], super_fraction), before[1].lerp(ends[1], super_fraction)])
			var super_dash_end := _clamp_player(previous_player + dash_direction * DASH_SPEED * super_dash_time)
			var super_dash_fraction := super_dash_time / delta if delta > 0 else 0.0
			var super_dash_ends := PackedVector2Array([before[0].lerp(ends[0], super_dash_fraction), before[1].lerp(ends[1], super_dash_fraction)])
			var struck_during_super := super_dash_time > 0 and _path_hits_obstacle(previous_player, super_dash_end, before, super_dash_ends)
			if not struck_during_super and super_move_time > 0:
				struck_during_super = _path_hits_obstacle(super_walk_start, super_walk_end, dash_ends, super_ends)
			if struck_during_super:
				var impact := Geometry2D.get_closest_point_to_segment(super_walk_end if super_move_time > 0 else super_dash_end, ends[0], ends[1])
				_shatter_obstacle(index, ends, impact)
				continue
		if dash_time > 0 and _path_hits_obstacle(previous_player, dash_end_player, before, dash_ends):
			var crossing = Geometry2D.segment_intersects_segment(previous_player, dash_end_player, ends[0], ends[1])
			var impact: Vector2 = crossing if crossing is Vector2 else ends[0] + (ends[1] - ends[0]) * clampf((dash_end_player - ends[0]).dot(ends[1] - ends[0]) / maxf(0.001, ends[0].distance_squared_to(ends[1])), 0, 1)
			if lives >= 2:
				_shatter_obstacle(index, ends, impact)
			elif item["ghost_remaining"] <= 0:
				item["ghost_remaining"] = float(item["warning"])
				_emit_ring(impact, GOLD, 28.0)
				_play_sound(hit_sound)
			continue
		if item["age"] >= item["warning"] and normal_time > 0 and hit_grace <= 0 and item["ghost_remaining"] <= 0:
			var normal_start := dash_end_player if dash_time > 0 else previous_player
			if _path_hits_obstacle(normal_start, player, dash_ends, ends):
				_take_hit()
				if phase == Phase.DEAD:
					return
		if item["age"] > item["life"]:
			obstacles.remove_at(index)
	_update_pickup(delta, previous_player)


func _ring_layers() -> int:
	return 1 if lives >= 2 else 0


func _gain_ring() -> void:
	if lives >= MAX_LIVES:
		return
	lives += 1
	_emit_ring(player, GOLD, 28.0 + _ring_layers() * 6)


func _take_hit() -> void:
	if phase != Phase.PLAYING or hit_grace > 0 or super_dash_active:
		return
	lives -= 1
	if lives <= 0:
		finish_run()
		return
	hit_grace = HIT_GRACE
	flash = 0.35
	shake = 3.0
	_emit_sparks(player, GOLD, 18)
	_emit_ring(player, GOLD, 65.0)
	_play_sound(hit_sound)


func _clamp_player(at: Vector2) -> Vector2:
	return Vector2(clampf(at.x, ARENA.position.x + 10, ARENA.end.x - 10),
		clampf(at.y, ARENA.position.y + 10, ARENA.end.y - 10))


func _path_hits_obstacle(start: Vector2, end: Vector2, before: PackedVector2Array, after: PackedVector2Array) -> bool:
	for sample in range(3):
		var fraction := float(sample) * 0.5
		if segment_distance(start, end, before[0].lerp(after[0], fraction), before[1].lerp(after[1], fraction)) <= PLAYER_RADIUS + 1.5:
			return true
	return false


func _shatter_obstacle(index: int, ends: PackedVector2Array, impact: Vector2) -> void:
	var item := obstacles[index]
	var color := WHITE if item["age"] >= item["warning"] else GOLD
	obstacles.remove_at(index)
	broken_obstacles += 1
	_update_score()
	_play_sound(shatter_sound)
	var visible := _clip_to_arena(ends[0], ends[1])
	if visible.is_empty():
		return
	var line := visible[1] - visible[0]
	var direction := line.normalized()
	var normal := Vector2(-direction.y, direction.x)
	var count := clampi(int(line.length() / 27), 5, 12)
	var weights: Array[float] = []
	var total := 0.0
	for piece in count:
		var weight := rng.randf_range(0.5, 1.6)
		weights.append(weight)
		total += weight
	var cursor := 0.0
	for piece in count:
		if fragments.size() >= 256:
			fragments.pop_front()
		var span := weights[piece] / total
		var center := visible[0].lerp(visible[1], cursor + span * 0.5)
		cursor += span
		var away := (center - impact).normalized()
		var proximity := 1.0 - clampf(center.distance_to(impact) / maxf(1, line.length() * 0.5), 0, 1)
		var side := -1.0 if piece % 2 == 0 else 1.0
		fragments.append({"kind": "shard", "position": center, "angle": line.angle() + rng.randf_range(-1.15, 1.15),
			"half_length": minf(line.length() * span * 0.3, rng.randf_range(3, 7)), "width": rng.randf_range(1.3, 2.1),
			"velocity": away * lerpf(50, 110, proximity) + normal * side * rng.randf_range(140, 280) + dash_direction * rng.randf_range(35, 95),
			"drag": 3.2, "spin": rng.randf_range(-4.5, 4.5), "age": 0.0, "life": rng.randf_range(0.4, 0.7), "color": color})
	# A concentrated white-hot spray marks the contact point; heavier shards carry the line away.
	for spark in 18:
		if fragments.size() >= 256:
			fragments.pop_front()
		var direction_out := dash_direction.rotated(rng.randf_range(-1.15, 1.15))
		if spark % 5 == 0:
			direction_out = -direction_out
		fragments.append({"kind": "spark", "position": impact + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)),
			"angle": direction_out.angle(), "half_length": rng.randf_range(2, 5), "width": rng.randf_range(1.0, 1.6),
			"velocity": direction_out * rng.randf_range(230, 560), "drag": 4.0, "spin": 0.0, "age": 0.0,
			"life": rng.randf_range(0.18, 0.38), "color": color.lerp(WHITE, 0.6)})


func _spawn_obstacle() -> void:
	var speed := LINE_SPEED
	var length := rng.randf_range(135.0, 245.0)
	var side := rng.randi_range(0, 3)
	var center := Vector2.ZERO
	var travel := Vector2.ZERO
	var angle := 0.0
	var spin := 0.0
	var warning := 0.8
	var life := 12.0
	var rotating := elapsed > 9.0 and rng.randf() < 0.25
	if rotating:
		# Announced rotating bars are placed well away from the player.
		center = Vector2(rng.randf_range(200, 880), rng.randf_range(220, 546))
		if center.distance_to(player) < 200.0:
			center = Vector2(1080.0 - player.x, 766.0 - player.y)
			center.x = clampf(center.x, 190, 890)
			center.y = clampf(center.y, 230, 536)
			if center.distance_to(player) < 180.0:
				return
		angle = rng.randf_range(0, TAU)
		spin = rng.randf_range(0.55, 1.1) * (-1.0 if rng.randf() < 0.5 else 1.0)
		length = rng.randf_range(145, 225)
		warning = 1.15
		life = 7.0
	else:
		match side:
			0:
				center = Vector2(rng.randf_range(170, 910), ARENA.position.y - 25)
				travel = Vector2(0, speed)
			1:
				center = Vector2(rng.randf_range(170, 910), ARENA.end.y + 25)
				travel = Vector2(0, -speed)
			2:
				center = Vector2(ARENA.position.x - 25, rng.randf_range(205, 560))
				travel = Vector2(speed, 0)
				angle = PI / 2.0
			3:
				center = Vector2(ARENA.end.x + 25, rng.randf_range(205, 560))
				travel = Vector2(-speed, 0)
				angle = PI / 2.0
	var kind := LineKind.ROTATING if rotating else (LineKind.HORIZONTAL if side < 2 else LineKind.VERTICAL)
	var item := {"center": center, "velocity": travel, "angle": angle, "kind": kind,
		"spin": spin, "length": length, "age": 0.0, "warning": warning, "life": life}
	obstacles.append(item)


func obstacle_endpoints(item: Dictionary) -> PackedVector2Array:
	var offset := Vector2.from_angle(item["angle"]) * float(item["length"]) * 0.5
	return PackedVector2Array([item["center"] - offset, item["center"] + offset])


static func point_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	if ab.length_squared() < 0.00001:
		return point.distance_to(a)
	return point.distance_to(a + ab * clampf((point - a).dot(ab) / ab.length_squared(), 0.0, 1.0))


static func segment_distance(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
	if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
		return 0.0
	return minf(minf(point_segment_distance(a, c, d), point_segment_distance(b, c, d)),
		minf(point_segment_distance(c, a, b), point_segment_distance(d, a, b)))


func _update_pickup(delta: float, previous_player: Vector2 = Vector2.INF) -> void:
	if pickup_active:
		pickup_age += delta
		var start := player if previous_player == Vector2.INF else previous_player
		if point_segment_distance(pickup, start, player) < 20.0:
			collected += 1
			_gain_ring()
			_update_score()
			pickup_active = false
			pickup_wait = 2.2
			dash_cooldown_remaining = 0.0
			_emit_ring(pickup, GOLD, 58.0)
			_emit_sparks(pickup, GOLD, 12)
			_play_sound(collect_sound)
			if collected % SUPER_DASH_ORBS == 0:
				_begin_super_dash()
		elif pickup_age > 9.0:
			pickup_active = false
			pickup_wait = 0.8
	else:
		pickup_wait -= delta
		if pickup_wait <= 0.0:
			for attempt in range(20):
				var candidate := Vector2(rng.randf_range(100, 980), rng.randf_range(180, 585))
				var safe := candidate.distance_to(player) > 85.0
				for item in obstacles:
					var ends := obstacle_endpoints(item)
					if point_segment_distance(candidate, ends[0], ends[1]) < 65.0:
						safe = false
				if safe:
					pickup = candidate
					pickup_active = true
					pickup_age = 0.0
					break
			pickup_wait = 0.5


func finish_run() -> void:
	if phase != Phase.PLAYING:
		return
	phase = Phase.DEAD
	if super_dash_active:
		dash_remaining = 0.0
	super_dash_active = false
	super_dash_remaining = 0.0
	lives = 0
	hit_grace = 0.0
	death_age = 0.0
	flash = 0.65
	shake = 5.0
	_emit_sparks(player, CYAN, 34)
	_emit_ring(player, RED, 95.0)
	_play_sound(death_sound)
	best = maxi(best, score)
	best_broken = maxi(best_broken, broken_obstacles)
	best_time = maxf(best_time, elapsed)
	if not test_mode:
		_save_record()


func _load_record(path: String = SAVE_PATH) -> void:
	var config := ConfigFile.new()
	best = 0
	best_broken = 0
	best_time = 0.0
	var section := "record"
	if config.load(path) == OK:
		best = int(config.get_value(section, "score", 0))
		best_broken = int(config.get_value(section, "broken", 0))
		best_time = float(config.get_value(section, "seconds", 0.0))
	old_best = best
	old_best_broken = best_broken


static func language_for_locale(locale: String) -> String:
	return "zh" if locale.to_lower().begins_with("zh") else "en"


func _load_language() -> void:
	var locale := OS.get_locale()
	var selected := language_for_locale(locale)
	if not test_mode:
		var config := ConfigFile.new()
		if config.load(SAVE_PATH) == OK:
			var saved = config.get_value("settings", "language", "")
			if saved == "zh" or saved == "en":
				selected = saved
	set_language(selected, false)


func set_language(selected: String, save_preference: bool = true) -> void:
	if selected != "zh" and selected != "en":
		return
	language = selected
	if not test_mode:
		get_window().title = "%s %s" % ["线隙 · LINE GAP" if language == "zh" else "LINE GAP", ProjectSettings.get_setting("application/config/version", "")]
		if save_preference:
			var config := ConfigFile.new()
			config.load(SAVE_PATH)
			config.set_value("settings", "language", language)
			var result := config.save(SAVE_PATH)
			if result != OK:
				push_warning("Could not save language: %s" % error_string(result))
	queue_redraw()


func ui_text(key: String) -> String:
	return UI_TEXT[language][key]


func _load_music_preference(path: String = SAVE_PATH) -> void:
	var config := ConfigFile.new()
	music_enabled = true
	if config.load(path) == OK:
		music_enabled = bool(config.get_value("settings", "music_enabled", true))


func _save_music_preference(path: String = SAVE_PATH) -> void:
	var config := ConfigFile.new()
	config.load(path)
	config.set_value("settings", "music_enabled", music_enabled)
	var result := config.save(path)
	if result != OK:
		push_warning("Could not save music preference: %s" % error_string(result))


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if web_audio != null:
		web_audio.setMusicEnabled(music_enabled)
	if music_player != null:
		if music_enabled:
			_start_music_if_enabled()
		else:
			music_player.stream_paused = true
	if not test_mode:
		_save_music_preference()
	queue_redraw()


func _setup_music(autoplay: bool = true) -> void:
	if OS.has_feature("web"):
		web_audio = JavaScriptBridge.get_interface("LineGapAudio")
		if web_audio != null:
			web_audio.setMusicEnabled(music_enabled)
		else:
			push_error("LineGap Web audio script is missing.")
		return
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	var stream := load(BACKGROUND_MUSIC_PATH).duplicate() as AudioStreamMP3
	stream.loop = true
	stream.loop_offset = 0.0
	music_player.stream = stream
	music_player.volume_db = -3.0
	# If a playback backend reports an end, continue while the user's switch is on.
	music_player.finished.connect(_start_music_if_enabled)
	# Use its own player on Master; the SFX bus and its limiter stay independent.
	add_child(music_player)
	if autoplay and not OS.has_feature("web"):
		_start_music_if_enabled()


func _start_music_if_enabled() -> void:
	if web_audio != null:
		if music_enabled:
			web_audio.startMusic()
		return
	if music_player == null or not music_enabled:
		return
	music_player.stream_paused = false
	if not music_player.playing:
		music_player.play()


func _save_record(path: String = SAVE_PATH) -> void:
	var config := ConfigFile.new()
	config.load(path)
	var section := "record"
	config.set_value(section, "score", best)
	config.set_value(section, "broken", best_broken)
	config.set_value(section, "seconds", best_time)
	var result := config.save(path)
	if result != OK:
		push_warning("Could not save record: %s" % error_string(result))


func _emit_ring(at: Vector2, color: Color, radius: float) -> void:
	rings.append({"position": at, "color": color, "radius": radius, "age": 0.0})


func _emit_sparks(at: Vector2, color: Color, count: int) -> void:
	for index in count:
		var direction := Vector2.from_angle(rng.randf_range(0, TAU))
		sparks.append({"position": at, "velocity": direction * rng.randf_range(45, 230),
			"age": 0.0, "life": rng.randf_range(0.3, 0.9), "color": color})


func _update_effects(delta: float) -> void:
	dash_ripple.advance(delta)
	for index in range(fragments.size() - 1, -1, -1):
		var fragment := fragments[index]
		fragment["age"] += delta
		fragment["position"] += fragment["velocity"] * delta
		fragment["velocity"] *= exp(-float(fragment["drag"]) * delta)
		fragment["angle"] += fragment["spin"] * delta
		if fragment["age"] >= fragment["life"]:
			fragments.remove_at(index)
	flash = maxf(0.0, flash - delta * 2.0)
	shake = maxf(0.0, shake - delta * 14.0)
	for index in range(sparks.size() - 1, -1, -1):
		var spark := sparks[index]
		spark["age"] += delta
		spark["position"] += spark["velocity"] * delta
		spark["velocity"] *= exp(-2.0 * delta)
		if spark["age"] > spark["life"]:
			sparks.remove_at(index)
	for index in range(rings.size() - 1, -1, -1):
		rings[index]["age"] += delta
		if rings[index]["age"] > 0.6:
			rings.remove_at(index)


func _setup_audio() -> void:
	collect_sound = _make_sound(720, 1180, 0.12)
	shatter_sound = _make_impact_sound(false)
	death_sound = _make_impact_sound(true)
	hit_sound = _make_sound(340, 150, 0.1)
	if OS.has_feature("web"):
		web_sound_names = {
			collect_sound.get_instance_id(): "collect",
			shatter_sound.get_instance_id(): "shatter",
			death_sound.get_instance_id(): "death",
			hit_sound.get_instance_id(): "hit",
		}
		return
	var bus := AudioServer.get_bus_index("LineGapSFX")
	if bus < 0:
		AudioServer.add_bus()
		bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, "LineGapSFX")
		AudioServer.set_bus_send(bus, "Master")
		var limiter := AudioEffectHardLimiter.new()
		limiter.ceiling_db = -1.0
		limiter.release = 0.06
		AudioServer.add_bus_effect(bus, limiter)
	for stream in [collect_sound, shatter_sound, death_sound, hit_sound]:
		var player_node := AudioStreamPlayer.new()
		player_node.stream = stream
		player_node.bus = "LineGapSFX"
		player_node.volume_db = 0.0
		player_node.max_polyphony = 6 if stream == shatter_sound else 2
		add_child(player_node)
		sound_players[stream.get_instance_id()] = player_node


func _make_impact_sound(death: bool) -> AudioStreamWAV:
	var rate := 44100
	var duration := 0.38 if death else 0.15
	var count := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var noise_rng := RandomNumberGenerator.new()
	noise_rng.seed = 1701 if death else 2718
	var low_noise := 0.0
	var phase_angle := 0.0
	var peak := 0.0
	for index in count:
		var t := float(index) / rate
		var noise := noise_rng.randf_range(-1, 1)
		low_noise += (noise - low_noise) * (0.16 if death else 0.55)
		var attack := minf(1, t / (0.0008 if death else 0.00025))
		var tail := clampf((duration - t) / 0.015, 0, 1)
		var value := 0.0
		if death:
			phase_angle += TAU * (42 + 195 * exp(-t * 18)) / rate
			value = sin(phase_angle) * exp(-t * 11) * 0.72
			value += low_noise * exp(-t * 17) * 0.85 + noise * exp(-t * 160) * 0.42
		else:
			# A sharp crack followed by tiny glass-like ticks, without a bass thud.
			value = (noise - low_noise) * exp(-t * 95) * 0.9
			value += sin(TAU * 2460 * t) * exp(-t * 65) * 0.29
			value += sin(TAU * 3890 * t) * exp(-t * 80) * 0.22
			value += sin(TAU * 5730 * t) * exp(-t * 100) * 0.12
			for tick in 3:
				var tick_time := t - (0.007 + tick * 0.008)
				if tick_time >= 0:
					var tick_attack := minf(1, tick_time / 0.0003)
					value += sin(TAU * (3210 + tick * 1170) * tick_time) * exp(-tick_time * 130) * tick_attack * 0.13
		value = tanh(value * (1.7 if death else 1.1)) * attack * tail
		samples[index] = value
		peak = maxf(peak, absf(value))
	var data := PackedByteArray()
	data.resize(count * 2)
	for index in count:
		data.encode_s16(index * 2, int(samples[index] / maxf(peak, 0.001) * 0.94 * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream


func _make_sound(start_hz: float, end_hz: float, duration: float) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(duration * rate)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var wave_phase := 0.0
	for index in frames:
		var progress := float(index) / frames
		wave_phase += TAU * lerpf(start_hz, end_hz, progress) / rate
		var envelope := minf(progress * 35.0, 1.0) * pow(1.0 - progress, 2.0)
		var sample := int(sin(wave_phase) * envelope * 18000.0)
		data.encode_s16(index * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream


func _play_sound(stream: AudioStreamWAV) -> void:
	if stream == null:
		return
	if web_audio != null:
		var sound_name: String = web_sound_names.get(stream.get_instance_id(), "")
		if not sound_name.is_empty():
			web_audio.playEffect(sound_name)
		return
	var player_node = sound_players.get(stream.get_instance_id())
	if player_node != null:
		player_node.play()


func _draw() -> void:
	_draw_header()
	var offset := Vector2(sin(visual_time * 71.0), cos(visual_time * 59.0)) * shake
	draw_set_transform(offset)
	if phase == Phase.READY:
		_draw_demo()
	else:
		_draw_world()
	draw_set_transform(Vector2.ZERO)
	_draw_footer()
	if settings_open:
		_draw_settings()
	elif phase == Phase.READY or phase == Phase.PAUSED or (phase == Phase.DEAD and death_age > 0.4):
		_draw_overlay()


func _build_grid() -> void:
	var vertices := PackedVector3Array()
	for segment in 16:
		var a := Vector2.from_angle(TAU * segment / 16.0) * 0.7
		var b := Vector2.from_angle(TAU * (segment + 1) / 16.0) * 0.7
		vertices.append(Vector3.ZERO)
		vertices.append(Vector3(a.x, a.y, 0))
		vertices.append(Vector3(b.x, b.y, 0))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var positions := PackedVector2Array()
	for x in range(72, 1030, 28):
		for y in range(150, 628, 28):
			positions.append(Vector2(x, y))
	grid_dots = MultiMesh.new()
	grid_dots.transform_format = MultiMesh.TRANSFORM_2D
	grid_dots.use_colors = true
	grid_dots.mesh = mesh
	grid_dots.instance_count = positions.size()
	for index in positions.size():
		grid_dots.set_instance_transform_2d(index, Transform2D(0, positions[index]))
		grid_dots.set_instance_color(index, Color(0.46, 0.48, 0.50, 0.1))


func _draw_background() -> void:
	background_layer.draw_rect(Rect2(0, 0, 1080, 720), BACKGROUND)
	background_layer.draw_rect(ARENA, ARENA_BACKGROUND)
	background_layer.draw_multimesh(grid_dots, null)
	background_layer.draw_rect(ARENA, Color(0.55, 0.59, 0.62, 0.2), false, 1.0)
	for corner in [ARENA.position, Vector2(ARENA.end.x, ARENA.position.y), ARENA.end, Vector2(ARENA.position.x, ARENA.end.y)]:
		var sx := 1.0 if corner.x < 540 else -1.0
		var sy := 1.0 if corner.y < 383 else -1.0
		background_layer.draw_line(corner, corner + Vector2(20 * sx, 0), CYAN * Color(1, 1, 1, 0.32), 1.5, true)
		background_layer.draw_line(corner, corner + Vector2(0, 20 * sy), CYAN * Color(1, 1, 1, 0.32), 1.5, true)


func _draw_header() -> void:
	draw_circle(Vector2(55, 43), 3.0, CYAN)
	draw_line(Vector2(67, 43), Vector2(88, 43), CYAN, 1.5, true)
	_text(ui_text("name"), Vector2(100, 53), 22 if language == "en" else 26, WHITE)
	for index in MAX_LIVES:
		var at := Vector2(105 + index * 24, 77)
		var color := CYAN if index == 0 else GOLD
		var active := index < lives
		if index > 0 and lives == 2:
			color *= Color(1, 1, 1, 0.35)
		draw_circle(at, 3.5, color if active else SEPARATOR, true, -1, true)
		if active:
			if index > 0:
				_draw_gold_ring(at, 7)
			else:
				draw_arc(at, 7, 0, TAU, 32, color * Color(1, 1, 1, 0.65), 1, true)
	_text(ui_text("broken"), Vector2(245, 36), 12, MUTED)
	_text("%03d" % broken_obstacles, Vector2(245, 77), 32, WHITE)
	_text(ui_text("score"), Vector2(415, 36), 12, MUTED)
	_text("%05d" % score, Vector2(415, 77), 32, CYAN)
	draw_line(Vector2(585, 28), Vector2(585, 80), SEPARATOR, 1)
	_text(ui_text("survived"), Vector2(620, 36), 12, MUTED)
	_text("%04.1f" % elapsed, Vector2(620, 77), 32, WHITE)
	_text(ui_text("seconds"), Vector2(714, 76), 13, MUTED)
	_text(ui_text("best"), Vector2(842, 36), 12, MUTED)
	_text(ui_text("score"), Vector2(842, 62), 11, MUTED)
	_text("%05d" % best, Vector2(898, 65), 23, GOLD)
	_text(ui_text("broken"), Vector2(842, 89), 11, MUTED)
	_text("%03d" % best_broken, Vector2(898, 91), 20, GOLD)


func _draw_demo() -> void:
	var t := visual_time
	for index in range(4):
		var center := Vector2(200 if index % 2 == 0 else 880, 242 + index * 69)
		var direction := Vector2.from_angle(t * 0.2 + index * 1.1)
		var a := center - direction * 62.0
		var b := center + direction * 62.0
		draw_line(a, b, WHITE * Color(1, 1, 1, 0.38), 2.0, true)
		draw_circle(a, 2.5, WHITE * Color(1, 1, 1, 0.5))
		draw_circle(b, 2.5, WHITE * Color(1, 1, 1, 0.5))
	draw_arc(Vector2(540, 229), 24 + sin(t * 2) * 2, 0, TAU, 64, Color(0.4, 0.97, 0.86, 0.35), 1.0, true)
	draw_circle(Vector2(540, 229), 7, CYAN, true, -1, true)


func _draw_world() -> void:
	# Clip moving barriers to the arena so they never cross the HUD.
	for item in obstacles:
		var ends := obstacle_endpoints(item)
		var clipped := _clip_to_arena(ends[0], ends[1])
		if clipped.is_empty():
			continue
		var ghost: bool = float(item.get("ghost_remaining", 0.0)) > 0
		var active: bool = item["age"] >= item["warning"] and not ghost
		var color := WHITE if active else Color(1, 0.83, 0.54, 0.55 + 0.2 * sin(visual_time * 18))
		if active:
			draw_line(clipped[0], clipped[1], WHITE * Color(1, 1, 1, 0.065), 8.0, true)
			draw_line(clipped[0], clipped[1], color, 2.5, true)
		else:
			draw_dashed_line(clipped[0], clipped[1], color, 1.5, 7, true, true)
		for endpoint in ends:
			if ARENA.has_point(endpoint):
				draw_circle(endpoint, 3.0 if active else 2.0, color)
		if absf(item["spin"]) > 0.01 and ARENA.has_point(item["center"]):
			draw_circle(item["center"], 3.0, color)
	if pickup_active:
		var alpha := 1.0 if pickup_age < 7.0 else 0.5 + 0.5 * sin(visual_time * 15)
		var tint := GOLD * Color(1, 1, 1, alpha)
		draw_arc(pickup, 12 + sin(visual_time * 4) * 2, 0, TAU, 40, tint * Color(1, 1, 1, 0.4), 1, true)
		draw_circle(pickup, 4.0, tint, true, -1, true)
		draw_line(pickup + Vector2(-19, 0), pickup + Vector2(-15, 0), tint, 1, true)
		draw_line(pickup + Vector2(15, 0), pickup + Vector2(19, 0), tint, 1, true)
	if phase != Phase.DEAD:
		var trail_color := GOLD if super_dash_active else CYAN
		for index in range(1, trail.size()):
			var alpha := (1.0 - float(index) / trail.size()) * 0.32
			draw_line(trail[index - 1], trail[index], trail_color * Color(1, 1, 1, alpha), 3 if dash_remaining > 0 else 2, true)
		if lives >= 2:
			_draw_gold_ring(player, 17)
		if hit_grace > 0 or super_dash_active:
			draw_arc(player, 18 + _ring_layers() * 6, visual_time * 3, visual_time * 3 + TAU * 0.8, 48,
				(GOLD if super_dash_active else CYAN) * Color(1, 1, 1, 0.8 if super_dash_active else 0.35 + hit_grace / HIT_GRACE * 0.45), 1.5, true)
		draw_circle(player, 13, CYAN * Color(1, 1, 1, 0.07))
		draw_arc(player, 11, 0, TAU, 40, CYAN * Color(1, 1, 1, 0.35), 1, true)
		draw_circle(player, PLAYER_RADIUS, WHITE if dash_remaining > 0 else CYAN, true, -1, true)
	for ring in rings:
		var progress: float = ring["age"] / 0.6
		draw_arc(ring["position"], lerpf(8, ring["radius"], 1.0 - pow(1.0 - progress, 3)), 0, TAU, 64,
			ring["color"] * Color(1, 1, 1, (1.0 - progress) * 0.65), 1.4, true)
	var spark_points := PackedVector2Array()
	var spark_colors := PackedColorArray()
	for spark in sparks:
		var alpha: float = 1.0 - spark["age"] / spark["life"]
		var at: Vector2 = spark["position"]
		spark_points.append(at)
		spark_points.append(at - spark["velocity"] * 0.025)
		spark_colors.append(spark["color"] * Color(1, 1, 1, alpha))
	if not spark_points.is_empty():
		draw_multiline_colors(spark_points, spark_colors, 1.5, true)
	_draw_fragments()
	if flash > 0.0:
		draw_rect(ARENA, RED * Color(1, 1, 1, flash * 0.08))


func _draw_fragments() -> void:
	# Group nearby widths to preserve shards and glow with a handful of draw commands.
	var points: Array[PackedVector2Array] = []
	var colors: Array[PackedColorArray] = []
	var glows: Array[PackedColorArray] = []
	for bucket in 6:
		points.append(PackedVector2Array())
		colors.append(PackedColorArray())
		glows.append(PackedColorArray())
	for fragment in fragments:
		var progress: float = fragment["age"] / fragment["life"]
		var alpha := pow(1.0 - progress, 1.5)
		var tint: Color = fragment["color"].lerp(WHITE, maxf(0, 1.0 - float(fragment["age"]) / 0.09) * 0.65)
		var center: Vector2 = fragment["position"]
		var offset := Vector2.from_angle(fragment["angle"]) * float(fragment["half_length"]) * (1.0 - progress * 0.5)
		var a := center - offset
		var b := center + offset
		if fragment["kind"] == "spark":
			a = center - Vector2(fragment["velocity"]) * 0.018
			b = center
		var ends := _clip_to_arena(a, b)
		if ends.size() == 2:
			var width: float = fragment["width"]
			var bucket := clampi(roundi((width - 1.0) * 4.0), 0, 5)
			points[bucket].append(ends[0])
			points[bucket].append(ends[1])
			colors[bucket].append(tint * Color(1, 1, 1, alpha))
			glows[bucket].append(tint * Color(1, 1, 1, alpha * 0.12))
	for bucket in 6:
		if not points[bucket].is_empty():
			draw_multiline_colors(points[bucket], glows[bucket], 4.0 + bucket * 0.25, true)
	for bucket in 6:
		if not points[bucket].is_empty():
			draw_multiline_colors(points[bucket], colors[bucket], 1.0 + bucket * 0.25, true)


func _draw_gold_ring(at: Vector2, radius: float) -> void:
	if lives == 2:
		for segment in 12:
			var start := TAU * segment / 12.0
			draw_arc(at, radius, start, start + TAU / 12.0 * 0.55, 8,
				GOLD * Color(1, 1, 1, 0.35), 1.0, true)
	else:
		draw_arc(at, radius, 0, TAU, 64, GOLD * Color(1, 1, 1, 0.95), 1.5, true)


func _clip_to_arena(a: Vector2, b: Vector2) -> PackedVector2Array:
	var direction := b - a
	var lower := 0.0
	var upper := 1.0
	var p := [-direction.x, direction.x, -direction.y, direction.y]
	var q := [a.x - ARENA.position.x, ARENA.end.x - a.x, a.y - ARENA.position.y, ARENA.end.y - a.y]
	for index in 4:
		if absf(p[index]) < 0.00001:
			if q[index] < 0:
				return PackedVector2Array()
		else:
			var ratio: float = q[index] / p[index]
			if p[index] < 0:
				lower = maxf(lower, ratio)
			else:
				upper = minf(upper, ratio)
			if lower > upper:
				return PackedVector2Array()
	return PackedVector2Array([a + direction * lower, a + direction * upper])


func _draw_footer() -> void:
	_text(ui_text("move"), Vector2(48, 680), 13, MUTED)
	_text(ui_text("pause_restart"), Vector2(48, 704), 11, MUTED)
	_text(ui_text("dash_controls"), Vector2(420, 679), 12, CYAN)
	var dash_label := ui_text("dashing") if dash_remaining > 0 else (ui_text("ready") if dash_cooldown_remaining <= 0 else ui_text("cooldown") % dash_cooldown_remaining)
	if super_dash_active:
		dash_label = ui_text("super_dash") % super_dash_remaining
	var dash_color := GOLD if super_dash_active else CYAN
	_text(dash_label, Vector2(552, 679), 11, dash_color if dash_cooldown_remaining <= 0 else MUTED)
	draw_line(Vector2(420, 695), Vector2(646, 695), SEPARATOR, 2, true)
	var ready_fraction := clampf(1.0 - dash_cooldown_remaining / dash_cooldown_duration, 0.0, 1.0)
	if super_dash_active:
		ready_fraction = clampf(super_dash_remaining / SUPER_DASH_DURATION, 0.0, 1.0)
	if ready_fraction > 0:
		draw_line(Vector2(420, 695), Vector2(420 + 226 * ready_fraction, 695), dash_color, 2, true)
	_text(ui_text("super_progress") % [collected % SUPER_DASH_ORBS, SUPER_DASH_ORBS], Vector2(420, 713), 10, MUTED)
	if hit_grace > 0:
		_text(ui_text("protection") % hit_grace, Vector2(660, 713), 10, CYAN)
	_draw_settings_button(SETTINGS_BUTTON, ui_text("settings"), CYAN)


func _draw_settings_button(rect: Rect2, label: String, color: Color) -> void:
	var hover := rect.has_point(get_global_mouse_position())
	draw_rect(rect, color * Color(1, 1, 1, 0.07 if hover else 0.025))
	draw_rect(rect, color * Color(1, 1, 1, 0.7 if hover else 0.3), false, 1.0)
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	_text(label, rect.get_center() + Vector2(-width * 0.5, 5), 13, color)


func _draw_settings() -> void:
	draw_rect(ARENA.grow(-1), BACKGROUND * Color(1, 1, 1, 0.96))
	var panel := Rect2(340, 222, 400, 326)
	draw_rect(panel, BACKGROUND)
	draw_rect(panel, CYAN * Color(1, 1, 1, 0.25), false, 1.0)
	_center_text(ui_text("settings"), 279, 32, WHITE)
	draw_line(Vector2(372, 299), Vector2(708, 299), SEPARATOR, 1.0)
	_text(ui_text("background_music"), Vector2(372, 339), 16, WHITE)
	_draw_settings_button(MUSIC_BUTTON, ui_text("music_on" if music_enabled else "music_off"), CYAN if music_enabled else MUTED)
	_text(ui_text("settings_hint"), Vector2(372, 376), 12, MUTED)
	_text(ui_text("language"), Vector2(372, 421), 16, WHITE)
	_draw_settings_button(LANGUAGE_BUTTON, ui_text("switch_language"), CYAN)
	_draw_settings_button(SETTINGS_CLOSE_BUTTON, ui_text("close_settings"), CYAN)


func _draw_overlay() -> void:
	if phase != Phase.READY:
		draw_rect(ARENA.grow(-1), BACKGROUND * Color(1, 1, 1, 0.94))
	var title := ui_text("title")
	var button := ui_text("start")
	if phase == Phase.DEAD:
		title = ui_text("dead")
		button = ui_text("restart")
	elif phase == Phase.PAUSED:
		title = ui_text("paused")
		button = ui_text("resume")
	_center_text(title, 332 if phase == Phase.DEAD else 360, 60 if phase == Phase.READY else 42, WHITE)
	if phase == Phase.DEAD:
		_center_text(ui_text("stats") % [elapsed, collected, broken_obstacles], 383, 18, MUTED)
		_center_text(ui_text("final_score") % score, 423, 15, CYAN)
	var button_rect := Rect2(410, 468, 260, 54)
	var hover := button_rect.has_point(get_global_mouse_position())
	draw_rect(button_rect, CYAN * Color(1, 1, 1, 0.07 if hover else 0.025))
	draw_rect(button_rect, CYAN * Color(1, 1, 1, 0.85 if hover else 0.4), false, 1.0)
	_center_text(button, 502, 18, CYAN)
	if phase == Phase.DEAD and (score > old_best or broken_obstacles > old_best_broken):
		_center_text(ui_text("new_best"), 559, 15, GOLD)
	_center_text("Bumba Crossing — Kevin MacLeod (incompetech.com)", 593, 12, MUTED)
	_center_text("CC BY 4.0 · creativecommons.org/licenses/by/4.0/", 615, 11, MUTED)


func _text(value: String, at: Vector2, size: int, color: Color) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _center_text(value: String, baseline: float, size: int, color: Color) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(value, Vector2((1080 - width) * 0.5, baseline), size, color)
