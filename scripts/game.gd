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
const MOBILE_WORLD_SCALE := 3.0
const MOBILE_MOVEMENT_SCALE := 1.5
const MOBILE_SPIN_SCALE := 0.5
const PLAYER_SPEED := 335.0
const SAVE_PATH := "user://records.cfg"
const LINE_SPEED := 90.0
const DashRipple = preload("res://scripts/dash_ripple.gd")
const MusicClock = preload("res://scripts/music_clock.gd")
const MUSIC_WAVE_DURATION := 0.44
const MUSIC_INPUT_BUFFER := 0.08
const RECORD_LABEL_WIDTH := 264.0
const MUSIC_WAVE_RADII := [110.0, 180.0, 250.0]
const MUSIC_MODE_BUTTON := Rect2(742, 662, 146, 36)
const MobileControls = preload("res://scripts/mobile_controls.gd")
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
const JOYSTICK_MODE_BUTTON := Rect2(600, 455, 220, 62)
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
		"settings": "设置", "background_music": "背景音乐", "language": "语言", "game_mode": "游戏模式",
		"settings_hint": "音乐开关不影响音效", "close_settings": "关闭 / ESC",
		"joystick": "移动轮盘", "joystick_fixed": "固定轮盘", "joystick_follow": "跟随轮盘",
		"mobile_start": "开始游戏", "mobile_restart": "重新开始", "mobile_resume": "继续游戏",
		"mobile_close": "关闭", "mobile_dash": "冲刺",
		"super_dash": "超级冲刺 %.1f 秒", "super_progress": "超级冲刺 %d/%d",
		"protection": "保护壳 %.1f 秒",
		"music_mode": "音乐模式", "normal_mode": "普通模式", "wave_controls": "左键 / 空格  波纹",
		"wave": "波纹", "beat_wait": "等待下一拍", "beat_hit": "合拍", "beat_miss": "未合拍",
		"super_music": "超级共振 %.1f 秒", "music_progress": "超级共振 %d/%d",
		"mode_hint": "切换模式会重开本局", "music_hint": "踩拍释放波纹 · 虚化后可击碎"
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
		"settings": "Settings", "background_music": "Background music", "language": "Language", "game_mode": "Game mode",
		"settings_hint": "Sound effects remain enabled", "close_settings": "Close / Esc",
		"joystick": "Joystick", "joystick_fixed": "Fixed", "joystick_follow": "Following",
		"mobile_start": "Start game", "mobile_restart": "Play again", "mobile_resume": "Resume",
		"mobile_close": "Close", "mobile_dash": "Dash",
		"super_dash": "Super dash %.1fs", "super_progress": "Super dash %d/%d",
		"protection": "Shield %.1fs",
		"music_mode": "Music mode", "normal_mode": "Normal mode", "wave_controls": "LMB / Space  Wave",
		"wave": "Wave", "beat_wait": "Next beat", "beat_hit": "On beat", "beat_miss": "Off beat",
		"super_music": "Resonance %.1fs", "music_progress": "Resonance %d/%d",
		"mode_hint": "Switching mode restarts this run", "music_hint": "On-beat waves shatter phased lines"
	}
}

enum Phase { READY, PLAYING, PAUSED, DEAD }
enum LineKind { HORIZONTAL, VERTICAL, ROTATING }

var phase: Phase = Phase.READY
var arena_rect := ARENA
var player := arena_rect.get_center()
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
var music_mode := false
var music_clock = MusicClock.new()
var music_wave_ready := true
var music_wave_used_beat := -2
var music_wave_buffered_beat := -1
var music_ghost_remaining := 0.0
var music_waves: Array[Dictionary] = []
var music_feedback := ""
var music_feedback_remaining := 0.0
var music_output_latency := 0.0
var music_wave_layer: Node2D
var world_clip: Control
var world_layer: Node2D
var music_player: AudioStreamPlayer
var web_audio
var web_sound_names: Dictionary = {}
var settings_open := false
var settings_resume_playing := false
var mobile_ui := OS.has_feature("android") or "mobile-preview" in OS.get_cmdline_user_args()
var touch_controls = MobileControls.new()
var mobile_text_labels: Array[Label] = []
var mobile_text_cursor := 0
var mobile_overlay_text := false


func _ready() -> void:
	if mobile_ui:
		get_tree().quit_on_go_back = false
		get_window().content_scale_size = Vector2i(1440, 810)
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		get_viewport().size_changed.connect(_layout_mobile)
		_layout_mobile()
		Input.emulate_mouse_from_touch = false
	if OS.has_feature("web") or mobile_ui:
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
	background_layer.z_index = -2 if mobile_ui else -1
	background_layer.draw.connect(_draw_background)
	add_child(background_layer)
	if mobile_ui:
		world_clip = Control.new()
		world_clip.position = arena_rect.position
		world_clip.size = arena_rect.size
		world_clip.clip_contents = true
		world_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world_clip.z_index = -1
		add_child(world_clip)
		world_layer = Node2D.new()
		world_layer.position = -world_clip.position
		world_layer.draw.connect(_draw_mobile_world)
		world_clip.add_child(world_layer)
	ripple_clip = Control.new()
	ripple_clip.position = arena_rect.position + Vector2(3, 3)
	ripple_clip.size = arena_rect.size - Vector2(6, 6)
	ripple_clip.clip_contents = true
	ripple_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ripple_clip.z_index = -1 if mobile_ui else 0
	add_child(ripple_clip)
	dash_ripple.position = -ripple_clip.position
	dash_ripple.visual_scale = _world_scale()
	ripple_clip.add_child(dash_ripple)
	dash_ripple.hide()
	music_wave_layer = Node2D.new()
	music_wave_layer.position = -ripple_clip.position
	music_wave_layer.draw.connect(_draw_music_waves)
	ripple_clip.add_child(music_wave_layer)
	_load_language()
	if not test_mode:
		_load_mode_preference()
		_load_record()
		_load_music_preference()
		_load_joystick_preference()
		_setup_audio()
		_setup_music()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if mobile_ui and event is InputEventScreenTouch:
		_handle_mobile_touch(event)
		return
	if mobile_ui and event is InputEventScreenDrag:
		touch_controls.drag(event.index, get_global_transform_with_canvas().affine_inverse() * event.position)
		return
	if mobile_ui and event is InputEventMouseButton:
		return
	if settings_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_close_settings()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
			_handle_ui_press(click)
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
		if _handle_ui_press(click):
			return
		if phase == Phase.PLAYING:
			var aim: Vector2 = click - player
			if not aim.is_zero_approx():
				try_dash(aim)


func _handle_ui_press(at: Vector2) -> bool:
	if settings_open:
		if _music_button().has_point(at):
			set_music_enabled(not music_enabled)
		elif mobile_ui and _music_mode_button().has_point(at):
			set_music_mode(not music_mode)
		elif _language_button().has_point(at):
			_start_music_if_enabled()
			set_language("en" if language == "zh" else "zh")
		elif mobile_ui and _joystick_button().has_point(at):
			set_joystick_following(not touch_controls.following)
		elif _settings_close_button().has_point(at) or _settings_button().has_point(at):
			_close_settings()
		return true
	if _settings_button().has_point(at):
		_open_settings()
		return true
	if not mobile_ui and _music_mode_button().has_point(at):
		set_music_mode(not music_mode)
		return true
	if not mobile_ui and music_mode and phase == Phase.PLAYING and Rect2(420, 654, 226, 45).has_point(at):
		try_dash()
		return true
	if phase != Phase.PLAYING and _primary_button().has_point(at):
		if phase == Phase.READY or phase == Phase.DEAD:
			begin_run()
		elif phase == Phase.PAUSED:
			_reset_movement_input()
			phase = Phase.PLAYING
		return true
	return false


func _handle_mobile_touch(event: InputEventScreenTouch) -> void:
	if not event.pressed or event.canceled:
		touch_controls.release(event.index)
		return
	var at: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
	_start_music_if_enabled()
	if _handle_ui_press(at) or phase != Phase.PLAYING:
		return
	if touch_controls.press(event.index, at) == "dash":
		try_dash(_movement_input())


func _layout_mobile() -> void:
	if not mobile_ui:
		return
	var view_size := get_viewport_rect().size
	position = (view_size - Vector2(1080, 720)) * 0.5
	var view := Rect2(-position, view_size)
	var safe := view
	if OS.has_feature("android"):
		var display_safe := DisplayServer.get_display_safe_area()
		var inverse := get_viewport().get_screen_transform().affine_inverse()
		var safe_start := inverse * Vector2(display_safe.position) - position
		var safe_end := inverse * Vector2(display_safe.end) - position
		if safe_end.x > safe_start.x and safe_end.y > safe_start.y:
			safe = view.intersection(Rect2(safe_start, safe_end - safe_start))
	arena_rect = safe.grow(-16)
	for item in obstacles:
		_fit_mobile_obstacle(item)
	touch_controls.configure(view, safe, arena_rect)
	player = _clamp_player(player)
	if ripple_clip != null:
		ripple_clip.position = arena_rect.position
		ripple_clip.size = arena_rect.size
		dash_ripple.position = -ripple_clip.position
		dash_ripple.visual_scale = _world_scale()
		music_wave_layer.position = -ripple_clip.position
	if world_clip != null:
		world_clip.position = arena_rect.position
		world_clip.size = arena_rect.size
		world_layer.position = -world_clip.position
		world_layer.queue_redraw()
	if grid_dots != null:
		_build_grid()
	if background_layer != null:
		background_layer.queue_redraw()
	velocity = Vector2.ZERO


func _settings_button() -> Rect2:
	if mobile_ui:
		var inset := _mobile_header_inset()
		return Rect2(touch_controls.safe_bounds.end.x - inset - 184, touch_controls.safe_bounds.position.y + 24, 184, 72)
	return SETTINGS_BUTTON


func _mobile_header_inset() -> float:
	return clampf(touch_controls.safe_bounds.size.x * 0.055, 64, 108)


func _music_mode_button() -> Rect2:
	if mobile_ui:
		return _mobile_setting_button(1)
	return MUSIC_MODE_BUTTON


func _load_mode_preference(path: String = SAVE_PATH) -> void:
	var config := ConfigFile.new()
	music_mode = config.load(path) == OK and bool(config.get_value("settings", "music_mode", false))


func _save_mode_preference(path: String = SAVE_PATH) -> void:
	var config := ConfigFile.new()
	config.load(path)
	config.set_value("settings", "music_mode", music_mode)
	config.save(path)


func set_music_mode(enabled: bool) -> void:
	if music_mode == enabled:
		return
	var restart := phase != Phase.READY
	var keep_settings := mobile_ui and settings_open
	var resume_after_switch := settings_resume_playing or phase == Phase.DEAD
	music_mode = enabled
	if not test_mode:
		_save_mode_preference()
		_load_record()
	if restart:
		begin_run()
	else:
		_reset_music_run()
	if keep_settings:
		settings_open = true
		settings_resume_playing = resume_after_switch
		if restart:
			phase = Phase.PAUSED
	_sync_music_transport()
	if background_layer != null:
		background_layer.queue_redraw()
	queue_redraw()


func _reset_music_run() -> void:
	music_clock.reset(_music_position())
	music_clock.update(_music_position())
	music_wave_ready = true
	music_wave_used_beat = -2
	music_wave_buffered_beat = -1
	music_ghost_remaining = 0.0
	music_waves.clear()
	music_feedback = ""
	music_feedback_remaining = 0.0


func _music_position() -> float:
	if web_audio != null:
		return float(web_audio.position())
	if music_player != null and music_player.playing:
		return maxf(0.0, music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - music_output_latency)
	return music_clock.position


func _sync_music_transport() -> void:
	var paused := music_mode and (phase == Phase.PAUSED or settings_open)
	if web_audio != null:
		web_audio.setRhythmMode(music_mode)
		web_audio.setPaused(paused)
	if music_player != null:
		music_player.volume_db = -3.0 if music_enabled else -80.0
		if music_mode:
			music_player.stream_paused = paused
			if not paused and not music_player.playing:
				music_player.play()
		elif not music_enabled:
			music_player.stream_paused = true
		else:
			music_player.stream_paused = false


func _update_music_beat(delta: float) -> void:
	if not music_mode or phase == Phase.PAUSED or settings_open:
		return
	var at := _music_position()
	if test_mode and music_player == null and web_audio == null:
		at = music_clock.position + delta
	if music_clock.update(at):
		if phase == Phase.PLAYING:
			_on_music_beat()
	if background_layer != null:
		background_layer.queue_redraw()


func _on_music_beat() -> void:
	if music_clock.beat_index > music_wave_used_beat:
		music_wave_ready = true
	if music_wave_buffered_beat >= 0:
		var buffered := music_wave_buffered_beat
		music_wave_buffered_beat = -1
		# A stalled frame may skip the target beat; do not release stale inputs.
		if buffered == music_clock.beat_index and music_wave_ready and music_clock.on_beat():
			_emit_music_wave(true, music_clock.beat_index)
	if super_dash_active:
		_emit_ring(player, GOLD, 95.0)
		for index in range(obstacles.size() - 1, -1, -1):
			var ends := obstacle_endpoints(obstacles[index])
			var visible := _clip_to_arena(ends[0], ends[1])
			var impact := (ends[0] + ends[1]) * 0.5 if visible.is_empty() else (visible[0] + visible[1]) * 0.5
			_shatter_obstacle(index, ends, impact)


func _music_wave_radius() -> float:
	return MUSIC_WAVE_RADII[clampi(lives - 1, 0, 2)] * _world_scale()


func _try_music_wave() -> bool:
	_update_music_beat(0.0)
	if not music_wave_ready:
		var next_beat: int = music_clock.beat_index + 1
		if music_wave_buffered_beat < 0 and next_beat > music_wave_used_beat and music_clock.time_to_next_beat() <= MUSIC_INPUT_BUFFER + 0.000001:
			music_wave_buffered_beat = next_beat
			return true
		return false
	var aligned: bool = music_clock.on_beat()
	_emit_music_wave(aligned, music_clock.nearest_beat() if aligned else music_clock.beat_index)
	return true


func _emit_music_wave(aligned: bool, used_beat: int) -> void:
	music_wave_ready = false
	music_wave_used_beat = used_beat
	music_wave_buffered_beat = -1
	music_feedback = "beat_hit" if aligned else "beat_miss"
	music_feedback_remaining = 0.45
	if aligned:
		music_ghost_remaining = MUSIC_WAVE_DURATION + 0.05
		for item in obstacles:
			item["ghost_remaining"] = maxf(float(item.get("ghost_remaining", 0.0)), music_ghost_remaining)
	music_waves.append({"position": player, "age": 0.0, "previous_radius": 0.0,
		"radius": 0.0, "limit": _music_wave_radius(), "aligned": aligned})


func _advance_music_waves(delta: float) -> void:
	music_ghost_remaining = maxf(0.0, music_ghost_remaining - delta)
	music_feedback_remaining = maxf(0.0, music_feedback_remaining - delta)
	for index in range(music_waves.size() - 1, -1, -1):
		var wave := music_waves[index]
		if wave["age"] >= MUSIC_WAVE_DURATION:
			music_waves.remove_at(index)
			continue
		wave["previous_radius"] = wave["radius"]
		wave["age"] += delta
		var progress := minf(1.0, float(wave["age"]) / MUSIC_WAVE_DURATION)
		wave["radius"] = float(wave["limit"]) * (1.0 - pow(1.0 - progress, 2.0))


func _music_wave_impact(before: PackedVector2Array, after: PackedVector2Array) -> Vector2:
	for wave in music_waves:
		var center: Vector2 = wave["position"]
		for sample in range(3):
			var fraction := sample * 0.5
			var a := before[0].lerp(after[0], fraction)
			var b := before[1].lerp(after[1], fraction)
			var closest := Geometry2D.get_closest_point_to_segment(center, a, b)
			var farthest := maxf(center.distance_to(a), center.distance_to(b))
			if center.distance_to(closest) <= float(wave["radius"]) + 3.0 * _world_scale() and farthest >= float(wave["previous_radius"]) - 3.0 * _world_scale():
				return closest
	return Vector2.INF


func _best_record_label() -> String:
	return "%05d / %03d / %.1f%s" % [best, best_broken, best_time, ui_text("seconds")]


func _best_record_font_size() -> int:
	var size := 22
	while size > 11 and font.get_string_size(_best_record_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > RECORD_LABEL_WIDTH:
		size -= 1
	return size


func _music_button() -> Rect2:
	if mobile_ui:
		return _mobile_setting_button(0)
	return MUSIC_BUTTON


func _language_button() -> Rect2:
	if mobile_ui:
		return _mobile_setting_button(2)
	return LANGUAGE_BUTTON


func _settings_close_button() -> Rect2:
	if mobile_ui:
		var panel := _mobile_settings_panel()
		var factor := panel.size.y / 680.0
		return Rect2(panel.get_center().x - 220, panel.end.y - 92 * factor, 440, 72 * factor)
	return SETTINGS_CLOSE_BUTTON


func _joystick_button() -> Rect2:
	return _mobile_setting_button(3)


func _mobile_setting_button(row: int) -> Rect2:
	var panel := _mobile_settings_panel()
	var factor := panel.size.y / 680.0
	return Rect2(panel.end.x - 408, panel.position.y + (128 + row * 96) * factor, 360, 76 * factor)


func _mobile_settings_panel() -> Rect2:
	var safe: Rect2 = touch_controls.safe_bounds
	var size := Vector2(minf(1080, safe.size.x - 96), minf(680, safe.size.y - 96))
	return Rect2(safe.get_center() - size * 0.5, size)


func _primary_button() -> Rect2:
	if mobile_ui:
		var center: Vector2 = touch_controls.safe_bounds.get_center()
		return Rect2(center + Vector2(-260, 130 if phase == Phase.DEAD else 90), Vector2(520, 96))
	return Rect2(410, 468, 260, 54)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and mobile_ui:
		if settings_open:
			_close_settings()
		elif phase == Phase.PLAYING:
			_reset_movement_input()
			phase = Phase.PAUSED
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		settings_resume_playing = false
		_reset_movement_input()
		if phase == Phase.PLAYING:
			phase = Phase.PAUSED
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_reset_movement_input()


func _reset_movement_input() -> void:
	music_wave_buffered_beat = -1
	touch_controls.reset()
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
	player = arena_rect.get_center()
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
	_reset_music_run()
	_sync_music_transport()


func _movement_input() -> Vector2:
	if mobile_ui:
		return touch_controls.direction
	return Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	).normalized()


func try_dash(direction: Vector2 = Vector2.ZERO) -> bool:
	if phase != Phase.PLAYING:
		return false
	if music_mode:
		return _try_music_wave()
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
	if not music_mode and not super_dash_active and dash_remaining <= 0:
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
	_sync_music_transport()
	if phase == Phase.PAUSED or settings_open:
		dash_ripple.hide()
		music_wave_layer.hide()
		return
	visual_time += delta
	_update_music_beat(delta)
	_update_effects(delta)
	if phase == Phase.PLAYING:
		advance_game(delta, _movement_input())
	elif phase == Phase.DEAD:
		death_age += delta
	dash_ripple.visible = phase == Phase.PLAYING
	music_wave_layer.visible = music_mode and phase == Phase.PLAYING


func _process(_delta: float) -> void:
	# Submit custom geometry once per displayed frame, not once per physics catch-up step.
	queue_redraw()
	_sync_music_transport()
	dash_ripple.queue_redraw()
	music_wave_layer.queue_redraw()
	if world_layer != null:
		world_layer.queue_redraw()


func _update_score() -> void:
	score = int(elapsed * 10.0) + collected * 50 + broken_obstacles * SHATTER_SCORE


func advance_game(delta: float, direction: Vector2) -> void:
	if music_mode:
		_advance_music_waves(delta)
	elapsed += delta
	hit_grace = maxf(0.0, hit_grace - delta)
	_update_score()
	var previous_player := player
	var super_dash_this_frame := super_dash_active
	var super_time := minf(delta, super_dash_remaining)
	var dash_time := minf(delta, dash_remaining)
	var dash_end_player := player
	dash_cooldown_remaining = maxf(0, dash_cooldown_remaining - delta)
	var move_direction := direction.limit_length(1.0) if mobile_ui else direction.normalized()
	if not move_direction.is_zero_approx():
		last_move_direction = move_direction.normalized()
		if super_dash_active and dash_remaining > 0:
			dash_direction = move_direction.normalized()
	var normal_time := delta
	var super_move_time := 0.0 if music_mode else minf(maxf(0.0, delta - dash_time), maxf(0.0, super_time - dash_time))
	if dash_remaining > 0:
		velocity = dash_direction * _dash_speed()
		player += velocity * dash_time
		dash_end_player = _clamp_player(player)
		dash_remaining = maxf(0, dash_remaining - dash_time)
		normal_time -= dash_time
		if dash_remaining == 0:
			velocity = move_direction * _player_speed() * (SUPER_MOVE_MULTIPLIER if super_time > dash_time else 1.0)
	var super_walk_start := dash_end_player if dash_time > 0 else previous_player
	var super_walk_end := super_walk_start
	if super_move_time > 0:
		velocity = velocity.move_toward(move_direction * _player_speed() * SUPER_MOVE_MULTIPLIER, 2400.0 * _movement_scale() * SUPER_MOVE_MULTIPLIER * super_move_time)
		player += velocity * super_move_time
		super_walk_end = _clamp_player(player)
	var ordinary_move_time := maxf(0.0, normal_time - super_move_time)
	if ordinary_move_time > 0:
		if super_move_time > 0:
			velocity /= SUPER_MOVE_MULTIPLIER
		velocity = velocity.move_toward(move_direction * _player_speed(), 2400.0 * _movement_scale() * ordinary_move_time)
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
		if music_mode:
			var ghost := super_dash_active or float(item["ghost_remaining"]) > 0
			var impact := _music_wave_impact(before, ends) if ghost else Vector2.INF
			if impact != Vector2.INF:
				_shatter_obstacle(index, ends, impact)
				continue
			if not ghost and item["age"] >= item["warning"] and _path_hits_obstacle(previous_player, player, before, ends):
				_take_hit()
				if phase == Phase.DEAD:
					return
			if item["age"] > item["life"]:
				obstacles.remove_at(index)
			continue
		var dash_fraction := dash_time / delta if delta > 0 else 0.0
		var dash_ends := PackedVector2Array([before[0].lerp(ends[0], dash_fraction), before[1].lerp(ends[1], dash_fraction)])
		if super_dash_this_frame and super_time > 0:
			var super_dash_time := minf(dash_time, super_time)
			var super_fraction := super_time / delta if delta > 0 else 0.0
			var super_ends := PackedVector2Array([before[0].lerp(ends[0], super_fraction), before[1].lerp(ends[1], super_fraction)])
			var super_dash_end := _clamp_player(previous_player + dash_direction * _dash_speed() * super_dash_time)
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
	var margin := 10.0 * _world_scale()
	return Vector2(clampf(at.x, arena_rect.position.x + margin, arena_rect.end.x - margin),
		clampf(at.y, arena_rect.position.y + margin, arena_rect.end.y - margin))


func _world_scale() -> float:
	return MOBILE_WORLD_SCALE if mobile_ui else 1.0


func _movement_scale() -> float:
	return MOBILE_MOVEMENT_SCALE if mobile_ui else 1.0


func _player_speed() -> float:
	return PLAYER_SPEED * _movement_scale()


func _dash_speed() -> float:
	return DASH_SPEED * _movement_scale()


func _path_hits_obstacle(start: Vector2, end: Vector2, before: PackedVector2Array, after: PackedVector2Array) -> bool:
	for sample in range(3):
		var fraction := float(sample) * 0.5
		if segment_distance(start, end, before[0].lerp(after[0], fraction), before[1].lerp(after[1], fraction)) <= (PLAYER_RADIUS + 1.5) * _world_scale():
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
			"velocity": (away * lerpf(50, 110, proximity) + normal * side * rng.randf_range(140, 280) + dash_direction * rng.randf_range(35, 95)) * _world_scale(),
			"drag": 3.2, "spin": rng.randf_range(-4.5, 4.5), "age": 0.0, "life": rng.randf_range(0.4, 0.7), "color": color})
	# A concentrated white-hot spray marks the contact point; heavier shards carry the line away.
	for spark in 18:
		if fragments.size() >= 256:
			fragments.pop_front()
		var direction_out := dash_direction.rotated(rng.randf_range(-1.15, 1.15))
		if spark % 5 == 0:
			direction_out = -direction_out
		fragments.append({"kind": "spark", "position": impact + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)) * _world_scale(),
			"angle": direction_out.angle(), "half_length": rng.randf_range(2, 5), "width": rng.randf_range(1.0, 1.6),
			"velocity": direction_out * rng.randf_range(230, 560) * _world_scale(), "drag": 4.0, "spin": 0.0, "age": 0.0,
			"life": rng.randf_range(0.18, 0.38), "color": color.lerp(WHITE, 0.6)})


func _spawn_obstacle() -> void:
	var speed := LINE_SPEED
	var length := rng.randf_range(135.0, 245.0) * _world_scale()
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
		length = rng.randf_range(145, 225) * _world_scale()
		if mobile_ui:
			length = minf(length, minf(arena_rect.size.x, arena_rect.size.y) - 16.0 * _world_scale())
		var clearance := maxf(200.0, length * 0.5 + PLAYER_RADIUS * _world_scale() + 60.0)
		if mobile_ui:
			var centers := arena_rect.grow(-length * 0.5 - 8.0 * _world_scale())
			var found := false
			for attempt in 20:
				center = Vector2(rng.randf_range(centers.position.x, centers.end.x), rng.randf_range(centers.position.y, centers.end.y))
				if center.distance_to(player) >= clearance:
					found = true
					break
			if not found:
				return
		else:
			center = Vector2(rng.randf_range(arena_rect.position.x + 152, arena_rect.end.x - 152), rng.randf_range(arena_rect.position.y + 92, arena_rect.end.y - 92))
			if center.distance_to(player) < clearance:
				center = arena_rect.get_center() * 2.0 - player
				center.x = clampf(center.x, arena_rect.position.x + 142, arena_rect.end.x - 142)
				center.y = clampf(center.y, arena_rect.position.y + 102, arena_rect.end.y - 102)
				if center.distance_to(player) < maxf(180.0, clearance - 20.0):
					return
		angle = rng.randf_range(0, TAU)
		spin = rng.randf_range(0.55, 1.1) * (-1.0 if rng.randf() < 0.5 else 1.0) * (MOBILE_SPIN_SCALE if mobile_ui else 1.0)
		warning = 1.15
		life = 7.0
	else:
		match side:
			0:
				center = Vector2(rng.randf_range(arena_rect.position.x + 122, arena_rect.end.x - 122), arena_rect.position.y - 25)
				travel = Vector2(0, speed)
			1:
				center = Vector2(rng.randf_range(arena_rect.position.x + 122, arena_rect.end.x - 122), arena_rect.end.y + 25)
				travel = Vector2(0, -speed)
			2:
				center = Vector2(arena_rect.position.x - 25, rng.randf_range(arena_rect.position.y + 77, arena_rect.end.y - 78))
				travel = Vector2(speed, 0)
				angle = PI / 2.0
			3:
				center = Vector2(arena_rect.end.x + 25, rng.randf_range(arena_rect.position.y + 77, arena_rect.end.y - 78))
				travel = Vector2(-speed, 0)
				angle = PI / 2.0
	var kind := LineKind.ROTATING if rotating else (LineKind.HORIZONTAL if side < 2 else LineKind.VERTICAL)
	if mobile_ui and not rotating:
		var padding := 8.0 * _world_scale()
		var span := arena_rect.size.x if side < 2 else arena_rect.size.y
		length = minf(length, span - padding * 2.0)
		var margin := length * 0.5 + padding
		if side < 2:
			center.x = rng.randf_range(arena_rect.position.x + margin, arena_rect.end.x - margin)
		else:
			center.y = rng.randf_range(arena_rect.position.y + margin, arena_rect.end.y - margin)
		life = maxf(life, (arena_rect.size.x if side >= 2 else arena_rect.size.y) / speed + 2.0)
	var item := {"center": center, "velocity": travel, "angle": angle, "kind": kind,
		"spin": spin, "length": length, "age": 0.0, "warning": warning, "life": life,
		"ghost_remaining": music_ghost_remaining if music_mode else 0.0}
	obstacles.append(item)


func _fit_mobile_obstacle(item: Dictionary) -> void:
	var padding := 8.0 * _world_scale()
	var kind: int = item.get("kind", LineKind.ROTATING)
	var at: Vector2 = item["center"]
	if kind == LineKind.ROTATING:
		item["length"] = minf(item["length"], minf(arena_rect.size.x, arena_rect.size.y) - padding * 2)
		var margin := float(item["length"]) * 0.5 + padding
		at.x = clampf(at.x, arena_rect.position.x + margin, arena_rect.end.x - margin)
		at.y = clampf(at.y, arena_rect.position.y + margin, arena_rect.end.y - margin)
	elif kind == LineKind.HORIZONTAL:
		item["length"] = minf(item["length"], arena_rect.size.x - padding * 2)
		var margin := float(item["length"]) * 0.5 + padding
		at.x = clampf(at.x, arena_rect.position.x + margin, arena_rect.end.x - margin)
	else:
		item["length"] = minf(item["length"], arena_rect.size.y - padding * 2)
		var margin := float(item["length"]) * 0.5 + padding
		at.y = clampf(at.y, arena_rect.position.y + margin, arena_rect.end.y - margin)
	item["center"] = at


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
		if point_segment_distance(pickup, start, player) < 20.0 * _world_scale():
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
				var padding := maxf(52.0, 19.0 * _world_scale() + 8.0)
				var candidate := Vector2(rng.randf_range(arena_rect.position.x + padding, arena_rect.end.x - padding), rng.randf_range(arena_rect.position.y + padding, arena_rect.end.y - padding - 1))
				var safe := candidate.distance_to(player) > 85.0
				if mobile_ui and (candidate.y < touch_controls.safe_bounds.position.y + 108 + 19 * _world_scale() or candidate.distance_to(touch_controls.fixed_center) < MobileControls.RADIUS + 19 * _world_scale() + 8 or candidate.distance_to(touch_controls.dash_center) < MobileControls.DASH_RADIUS + 19 * _world_scale() + 8):
					safe = false
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
	music_wave_buffered_beat = -1
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
	var section := "music_record" if music_mode else "record"
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


func _load_joystick_preference(path: String = SAVE_PATH) -> void:
	var config := ConfigFile.new()
	var following := false
	if config.load(path) == OK:
		following = bool(config.get_value("settings", "joystick_following", false))
	touch_controls.set_following(following)


func _save_joystick_preference(path: String = SAVE_PATH) -> void:
	var config := ConfigFile.new()
	config.load(path)
	config.set_value("settings", "joystick_following", touch_controls.following)
	var result := config.save(path)
	if result != OK:
		push_warning("Could not save joystick mode: %s" % error_string(result))


func set_joystick_following(enabled: bool) -> void:
	touch_controls.set_following(enabled)
	_reset_movement_input()
	if not test_mode:
		_save_joystick_preference()
	queue_redraw()


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
		elif not music_mode:
			music_player.stream_paused = true
	_sync_music_transport()
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
	music_output_latency = AudioServer.get_output_latency()
	# If a playback backend reports an end, continue while the user's switch is on.
	music_player.finished.connect(_start_music_if_enabled)
	# Use its own player on Master; the SFX bus and its limiter stay independent.
	add_child(music_player)
	if autoplay and not OS.has_feature("web"):
		_start_music_if_enabled()


func _start_music_if_enabled() -> void:
	if music_mode and (phase == Phase.PAUSED or settings_open):
		return
	if web_audio != null:
		if music_enabled or music_mode:
			web_audio.startMusic()
		return
	if music_player == null or (not music_enabled and not music_mode):
		return
	music_player.stream_paused = false
	if not music_player.playing:
		music_player.play()


func _save_record(path: String = SAVE_PATH) -> void:
	var config := ConfigFile.new()
	config.load(path)
	var section := "music_record" if music_mode else "record"
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
		sparks.append({"position": at, "velocity": direction * rng.randf_range(45, 230) * _world_scale(),
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
	mobile_text_cursor = 0
	mobile_overlay_text = false
	if not mobile_ui:
		_draw_header()
	var offset := Vector2(sin(visual_time * 71.0), cos(visual_time * 59.0)) * shake
	draw_set_transform(offset)
	if phase == Phase.READY:
		_draw_demo()
	elif not mobile_ui:
		_draw_world()
	draw_set_transform(Vector2.ZERO)
	_draw_footer()
	if mobile_ui:
		_draw_mobile_header()
	if settings_open:
		_draw_settings()
	elif phase == Phase.READY or phase == Phase.PAUSED or (phase == Phase.DEAD and death_age > 0.4):
		_draw_overlay()
	for index in range(mobile_text_cursor, mobile_text_labels.size()):
		mobile_text_labels[index].hide()


func _draw_mobile_world() -> void:
	if phase == Phase.READY:
		return
	var offset := Vector2(sin(visual_time * 71.0), cos(visual_time * 59.0)) * shake
	world_layer.draw_set_transform(offset)
	_draw_world(world_layer)


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
	for x in range(int(arena_rect.position.x + 24), int(arena_rect.end.x - 2), 28):
		for y in range(int(arena_rect.position.y + 22), int(arena_rect.end.y - 10), 28):
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
	background_layer.draw_rect(touch_controls.view_bounds if mobile_ui else Rect2(0, 0, 1080, 720), BACKGROUND)
	background_layer.draw_rect(arena_rect, ARENA_BACKGROUND)
	background_layer.draw_multimesh(grid_dots, null)
	if music_mode:
		var pulse: float = music_clock.pulse
		background_layer.draw_rect(arena_rect, CYAN * Color(1, 1, 1, pulse * 0.018))
		background_layer.draw_rect(arena_rect.grow(-2), CYAN * Color(1, 1, 1, 0.12 + pulse * 0.30), false, 1.0 + pulse)
	if mobile_ui:
		return
	background_layer.draw_rect(arena_rect, Color(0.55, 0.59, 0.62, 0.2), false, 1.0)
	for corner in [arena_rect.position, Vector2(arena_rect.end.x, arena_rect.position.y), arena_rect.end, Vector2(arena_rect.position.x, arena_rect.end.y)]:
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
	_text(ui_text("best"), Vector2(768, 36), 12, MUTED)
	_text(_best_record_label(), Vector2(768, 77), _best_record_font_size(), GOLD)


func _draw_mobile_header() -> void:
	var safe: Rect2 = touch_controls.safe_bounds
	var inset := _mobile_header_inset()
	var at := safe.position + Vector2(inset, 40)
	var width := safe.size.x - inset * 2 - 216
	_text(ui_text("name"), at + Vector2(0, 16), 30, WHITE)
	for index in MAX_LIVES:
		var dot := at + Vector2(8 + index * 24, 42)
		var color := CYAN if index == 0 else GOLD
		draw_circle(dot, 4, color if index < lives else SEPARATOR)
	var broken_at := at + Vector2(width * 0.16, 0)
	_text(ui_text("broken"), broken_at, 18, MUTED)
	_text("%03d" % broken_obstacles, broken_at + Vector2(0, 42), 40, WHITE)
	var score_at := at + Vector2(width * 0.30, 0)
	_text(ui_text("score"), score_at, 18, MUTED)
	_text("%05d" % score, score_at + Vector2(0, 42), 40, CYAN)
	var time_at := at + Vector2(width * 0.44, 0)
	_text(ui_text("survived"), time_at, 18, MUTED)
	_text("%.1f" % elapsed, time_at + Vector2(0, 42), 40, WHITE)
	var best_at := at + Vector2(width * 0.61, 0)
	_text(ui_text("best"), best_at, 16, MUTED)
	var record_width := _settings_button().position.x - 20 - best_at.x
	_text(_best_record_label(), best_at + Vector2(0, 42), _fit_text_size(_best_record_label(), record_width, 32), GOLD)


func _draw_demo() -> void:
	var t := visual_time
	var world_scale := _world_scale()
	for index in range(4):
		var center := Vector2(200 if index % 2 == 0 else 880, 242 + index * 69)
		var direction := Vector2.from_angle(t * 0.2 + index * 1.1)
		var a := center - direction * 62.0 * world_scale
		var b := center + direction * 62.0 * world_scale
		draw_line(a, b, WHITE * Color(1, 1, 1, 0.38), 2.0 * world_scale, true)
		draw_circle(a, 2.5 * world_scale, WHITE * Color(1, 1, 1, 0.5))
		draw_circle(b, 2.5 * world_scale, WHITE * Color(1, 1, 1, 0.5))
	draw_arc(Vector2(540, 229), (24 + sin(t * 2) * 2) * world_scale, 0, TAU, 64, Color(0.4, 0.97, 0.86, 0.35), world_scale, true)
	draw_circle(Vector2(540, 229), 7 * world_scale, CYAN, true, -1, true)


func _draw_world(canvas: Node2D = null) -> void:
	if canvas == null:
		canvas = self
	var world_scale := _world_scale()
	# Clip moving barriers to the arena so they never cross the HUD.
	for item in obstacles:
		var ends := obstacle_endpoints(item)
		var clipped := _clip_to_arena(ends[0], ends[1])
		if clipped.is_empty():
			continue
		var ghost: bool = float(item.get("ghost_remaining", 0.0)) > 0 or (music_mode and super_dash_active)
		var active: bool = item["age"] >= item["warning"] and not ghost
		var color := WHITE if active else Color(1, 0.83, 0.54, 0.55 + 0.2 * sin(visual_time * 18))
		if music_mode and ghost:
			color = (GOLD if super_dash_active else CYAN) * Color(1, 1, 1, 0.48 + music_clock.pulse * 0.3)
		if active:
			canvas.draw_line(clipped[0], clipped[1], WHITE * Color(1, 1, 1, 0.065), 8.0 * world_scale, true)
			canvas.draw_line(clipped[0], clipped[1], color, 2.5 * world_scale, true)
		else:
			canvas.draw_dashed_line(clipped[0], clipped[1], color, 1.5 * world_scale, 7 * world_scale, true, true)
		for endpoint in ends:
			if arena_rect.has_point(endpoint):
				canvas.draw_circle(endpoint, (3.0 if active else 2.0) * world_scale, color)
		if absf(item["spin"]) > 0.01 and arena_rect.has_point(item["center"]):
			canvas.draw_circle(item["center"], 3.0 * world_scale, color)
	if pickup_active:
		var alpha := 1.0 if pickup_age < 7.0 else 0.5 + 0.5 * sin(visual_time * 15)
		var tint := GOLD * Color(1, 1, 1, alpha)
		var breath: float = music_clock.pulse * 4.0 if music_mode else sin(visual_time * 4) * 2
		canvas.draw_arc(pickup, (12 + breath) * world_scale, 0, TAU, 40, tint * Color(1, 1, 1, 0.4), world_scale, true)
		canvas.draw_circle(pickup, 4.0 * world_scale, tint, true, -1, true)
		canvas.draw_line(pickup + Vector2(-19, 0) * world_scale, pickup + Vector2(-15, 0) * world_scale, tint, world_scale, true)
		canvas.draw_line(pickup + Vector2(15, 0) * world_scale, pickup + Vector2(19, 0) * world_scale, tint, world_scale, true)
	if phase != Phase.DEAD:
		var trail_color := GOLD if super_dash_active else CYAN
		for index in range(1, trail.size()):
			var alpha := (1.0 - float(index) / trail.size()) * 0.32
			canvas.draw_line(trail[index - 1], trail[index], trail_color * Color(1, 1, 1, alpha), (3 if dash_remaining > 0 else 2) * world_scale, true)
		if lives >= 2:
			_draw_gold_ring(player, 17 * world_scale, canvas)
		if hit_grace > 0 or super_dash_active:
			canvas.draw_arc(player, (18 + _ring_layers() * 6) * world_scale, visual_time * 3, visual_time * 3 + TAU * 0.8, 48,
				(GOLD if super_dash_active else CYAN) * Color(1, 1, 1, 0.8 if super_dash_active else 0.35 + hit_grace / HIT_GRACE * 0.45), 1.5 * world_scale, true)
		var breath: float = music_clock.pulse if music_mode else 0.0
		canvas.draw_circle(player, (13 + breath * 5) * world_scale, CYAN * Color(1, 1, 1, 0.07 + breath * 0.08))
		canvas.draw_arc(player, (11 + breath * 4) * world_scale, 0, TAU, 40, CYAN * Color(1, 1, 1, 0.35 + breath * 0.35), world_scale, true)
		canvas.draw_circle(player, PLAYER_RADIUS * world_scale, WHITE if dash_remaining > 0 else CYAN, true, -1, true)
	for ring in rings:
		var progress: float = ring["age"] / 0.6
		canvas.draw_arc(ring["position"], lerpf(8, ring["radius"], 1.0 - pow(1.0 - progress, 3)) * world_scale, 0, TAU, 64,
			ring["color"] * Color(1, 1, 1, (1.0 - progress) * 0.65), 1.4 * world_scale, true)
	var spark_points := PackedVector2Array()
	var spark_colors := PackedColorArray()
	for spark in sparks:
		var alpha: float = 1.0 - spark["age"] / spark["life"]
		var at: Vector2 = spark["position"]
		spark_points.append(at)
		spark_points.append(at - spark["velocity"] * 0.025)
		spark_colors.append(spark["color"] * Color(1, 1, 1, alpha))
	if not spark_points.is_empty():
		canvas.draw_multiline_colors(spark_points, spark_colors, 1.5 * world_scale, true)
	_draw_fragments(canvas)
	if flash > 0.0:
		canvas.draw_rect(arena_rect, RED * Color(1, 1, 1, flash * 0.08))


func _draw_fragments(canvas: Node2D = null) -> void:
	if canvas == null:
		canvas = self
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
		var offset := Vector2.from_angle(fragment["angle"]) * float(fragment["half_length"]) * (1.0 - progress * 0.5) * _world_scale()
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
			canvas.draw_multiline_colors(points[bucket], glows[bucket], (4.0 + bucket * 0.25) * _world_scale(), true)
	for bucket in 6:
		if not points[bucket].is_empty():
			canvas.draw_multiline_colors(points[bucket], colors[bucket], (1.0 + bucket * 0.25) * _world_scale(), true)


func _draw_gold_ring(at: Vector2, radius: float, canvas: Node2D = null) -> void:
	if canvas == null:
		canvas = self
	if lives == 2:
		for segment in 12:
			var start := TAU * segment / 12.0
			canvas.draw_arc(at, radius, start, start + TAU / 12.0 * 0.55, 8,
				GOLD * Color(1, 1, 1, 0.35), _world_scale(), true)
	else:
		canvas.draw_arc(at, radius, 0, TAU, 64, GOLD * Color(1, 1, 1, 0.95), 1.5 * _world_scale(), true)


func _clip_to_arena(a: Vector2, b: Vector2) -> PackedVector2Array:
	var direction := b - a
	var lower := 0.0
	var upper := 1.0
	var p := [-direction.x, direction.x, -direction.y, direction.y]
	var q := [a.x - arena_rect.position.x, arena_rect.end.x - a.x, a.y - arena_rect.position.y, arena_rect.end.y - a.y]
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
	if mobile_ui:
		_draw_mobile_controls()
		return
	_text(ui_text("move"), Vector2(48, 680), 13, MUTED)
	_text(ui_text("pause_restart"), Vector2(48, 704), 11, MUTED)
	if music_mode:
		_draw_music_footer()
		return
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
	_draw_mode_button()


func _draw_mode_button() -> void:
	_draw_settings_button(_music_mode_button(), ui_text("music_mode"), GOLD if music_mode else MUTED)
	_text(ui_text("mode_hint"), Vector2(742, 713), 10, MUTED)


func _draw_music_footer() -> void:
	_text(ui_text("wave_controls"), Vector2(420, 650), 10, MUTED)
	var ready: bool = music_wave_ready and phase == Phase.PLAYING
	var color := (GOLD if super_dash_active else CYAN) if ready else MUTED
	var label := ui_text("wave") + " · " + ui_text("ready" if ready else "beat_wait")
	_draw_settings_button(Rect2(420, 654, 226, 42), label, color)
	var progress: float = music_clock.progress()
	draw_line(Vector2(420, 702), Vector2(646, 702), SEPARATOR, 2, true)
	draw_line(Vector2(420, 702), Vector2(420 + 226 * progress, 702), color, 2, true)
	draw_circle(Vector2(646, 702), 3.0 + music_clock.pulse * 3, CYAN * Color(1, 1, 1, 0.4 + music_clock.pulse * 0.6))
	_text(ui_text("music_progress") % [collected % SUPER_DASH_ORBS, SUPER_DASH_ORBS], Vector2(420, 718), 10, MUTED)
	if super_dash_active:
		_text(ui_text("super_music") % super_dash_remaining, Vector2(660, 653), 12, GOLD)
	elif music_feedback_remaining > 0:
		_text(ui_text(music_feedback), Vector2(660, 686), 12, CYAN if music_feedback == "beat_hit" else MUTED)
	_draw_settings_button(SETTINGS_BUTTON, ui_text("settings"), CYAN)
	_draw_mode_button()


func _draw_music_waves() -> void:
	if not music_mode or phase != Phase.PLAYING or settings_open:
		return
	for wave in music_waves:
		var alpha := pow(maxf(0.0, 1.0 - float(wave["age"]) / MUSIC_WAVE_DURATION), 0.65)
		var tint := CYAN if wave["aligned"] else MUTED
		if super_dash_active:
			tint = GOLD
		var at: Vector2 = wave["position"]
		var radius: float = maxf(1.0, wave["radius"])
		music_wave_layer.draw_arc(at, radius, 0, TAU, 128, tint * Color(1, 1, 1, alpha * 0.1), 9.0 * _world_scale(), true)
		music_wave_layer.draw_arc(at, radius, 0, TAU, 128, tint * Color(1, 1, 1, alpha * 0.85), 2.0 * _world_scale(), true)


func _draw_settings_button(rect: Rect2, label: String, color: Color) -> void:
	var hover := rect.has_point(get_global_mouse_position())
	draw_rect(rect, color * Color(1, 1, 1, 0.07 if hover else 0.025))
	draw_rect(rect, color * Color(1, 1, 1, 0.7 if hover else 0.3), false, 1.0)
	var text_size := _fit_text_size(label, rect.size.x - 24, mini(40, int(rect.size.y * 0.55))) if mobile_ui else 13
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	_text(label, rect.get_center() + Vector2(-width * 0.5, text_size * 0.35), text_size, color)


func _draw_settings() -> void:
	draw_rect(arena_rect.grow(-1), BACKGROUND * Color(1, 1, 1, 0.96))
	if mobile_ui:
		_draw_mobile_settings()
		return
	var panel := Rect2(340, 222, 400, 326)
	draw_rect(panel, BACKGROUND)
	draw_rect(panel, CYAN * Color(1, 1, 1, 0.25), false, 1.0)
	_center_text(ui_text("settings"), 279, 32, WHITE)
	draw_line(Vector2(372, 299), Vector2(708, 299), SEPARATOR, 1.0)
	_text(ui_text("background_music"), Vector2(372, 339), 16, WHITE)
	_draw_settings_button(_music_button(), ui_text("music_on" if music_enabled else "music_off"), CYAN if music_enabled else MUTED)
	_text(ui_text("settings_hint"), Vector2(372, 376), 12, MUTED)
	_text(ui_text("language"), Vector2(372, 421), 16, WHITE)
	_draw_settings_button(_language_button(), ui_text("switch_language"), CYAN)
	_draw_settings_button(_settings_close_button(), ui_text("close_settings"), CYAN)


func _mobile_dash_ready() -> bool:
	if music_mode:
		return phase == Phase.PLAYING and not settings_open and music_wave_ready
	return phase == Phase.PLAYING and not settings_open and (super_dash_active or (dash_remaining <= 0 and dash_cooldown_remaining <= 0))


func _draw_mobile_settings() -> void:
	mobile_overlay_text = true
	var panel := _mobile_settings_panel()
	var factor := panel.size.y / 680.0
	draw_rect(panel, BACKGROUND)
	draw_rect(panel, CYAN * Color(1, 1, 1, 0.25), false, 2.0)
	_text_at_center(ui_text("settings"), Vector2(panel.get_center().x, panel.position.y + 76 * factor), int(60 * factor), WHITE)
	draw_line(panel.position + Vector2(48, 102 * factor), Vector2(panel.end.x - 48, panel.position.y + 102 * factor), SEPARATOR, 2.0)
	_text(ui_text("background_music"), Vector2(panel.position.x + 48, _music_button().get_center().y + 12 * factor), int(36 * factor), WHITE)
	_draw_settings_button(_music_button(), ui_text("music_on" if music_enabled else "music_off"), CYAN if music_enabled else MUTED)
	_text(ui_text("game_mode"), Vector2(panel.position.x + 48, _music_mode_button().get_center().y + 12 * factor), int(36 * factor), WHITE)
	_draw_settings_button(_music_mode_button(), ui_text("music_mode" if music_mode else "normal_mode"), GOLD if music_mode else CYAN)
	_text(ui_text("language"), Vector2(panel.position.x + 48, _language_button().get_center().y + 12 * factor), int(36 * factor), WHITE)
	_draw_settings_button(_language_button(), ui_text("switch_language"), CYAN)
	_text(ui_text("joystick"), Vector2(panel.position.x + 48, _joystick_button().get_center().y + 12 * factor), int(36 * factor), WHITE)
	_draw_settings_button(_joystick_button(), ui_text("joystick_follow" if touch_controls.following else "joystick_fixed"), CYAN)
	_text(ui_text("mode_hint"), panel.position + Vector2(48, 538 * factor), int(26 * factor), MUTED)
	_text(ui_text("settings_hint"), panel.position + Vector2(48, 571 * factor), int(24 * factor), MUTED)
	_draw_settings_button(_settings_close_button(), ui_text("mobile_close"), CYAN)
	_draw_settings_button(_settings_button(), ui_text("settings"), CYAN)
	mobile_overlay_text = false


func _draw_mobile_controls() -> void:
	_draw_settings_button(_settings_button(), ui_text("settings"), CYAN)
	if phase != Phase.PLAYING or settings_open:
		return
	_draw_mobile_joystick()
	_draw_mobile_dash_button()


func _draw_mobile_joystick() -> void:
	var center: Vector2 = touch_controls.center
	var active: bool = touch_controls.move_touch != -1
	if touch_controls.following and not active:
		return
	var color := CYAN if active else MUTED
	draw_circle(center, MobileControls.RADIUS, Color(0.02, 0.05, 0.05, 0.2))
	draw_arc(center, MobileControls.RADIUS, 0, TAU, 80, color * Color(1, 1, 1, 0.65), 2.0 * MobileControls.CONTROL_SCALE, true)
	draw_arc(center, MobileControls.RADIUS * MobileControls.DEAD_ZONE, 0, TAU, 32, color * Color(1, 1, 1, 0.2), MobileControls.CONTROL_SCALE, true)
	draw_circle(center + touch_controls.knob, 24 * MobileControls.CONTROL_SCALE, color * Color(1, 1, 1, 0.18))
	draw_arc(center + touch_controls.knob, 24 * MobileControls.CONTROL_SCALE, 0, TAU, 40, color, 2.0 * MobileControls.CONTROL_SCALE, true)


func _draw_mobile_dash_button() -> void:
	var dash_at: Vector2 = touch_controls.dash_center
	var ready := _mobile_dash_ready()
	var dash_color := (GOLD if super_dash_active else CYAN) if ready else MUTED
	draw_circle(dash_at, MobileControls.DASH_RADIUS, Color(0.02, 0.05, 0.05, 0.25))
	draw_arc(dash_at, MobileControls.DASH_RADIUS, 0, TAU, 80, dash_color, 2.5 * MobileControls.CONTROL_SCALE, true)
	var label := ui_text("mobile_dash") if ready else ("%.1f" % maxf(0.1, dash_cooldown_remaining) if dash_cooldown_remaining > 0 else ui_text("dashing"))
	if music_mode:
		label = ui_text("wave" if ready else "beat_wait")
		var progress: float = music_clock.progress()
		draw_arc(dash_at, MobileControls.DASH_RADIUS + 12, -PI * 0.5, -PI * 0.5 + TAU * progress, 80, dash_color * Color(1, 1, 1, 0.75), 4.0, true)
		if music_feedback_remaining > 0:
			_text_at_center(ui_text(music_feedback), dash_at - Vector2(0, MobileControls.DASH_RADIUS + 24), 26, CYAN if music_feedback == "beat_hit" else MUTED)
	_text_at_center(label, dash_at + Vector2(0, 20), _fit_text_size(label, MobileControls.DASH_RADIUS * 2 - 36, 60), dash_color)
	if super_dash_active:
		_center_text(ui_text("super_music" if music_mode else "super_dash") % super_dash_remaining, touch_controls.safe_bounds.end.y - 18, 28, GOLD)
	else:
		_center_text(ui_text("music_progress" if music_mode else "super_progress") % [collected % SUPER_DASH_ORBS, SUPER_DASH_ORBS], touch_controls.safe_bounds.end.y - 18, 26, MUTED)
	if hit_grace > 0:
		_text(ui_text("protection") % hit_grace, Vector2(touch_controls.safe_bounds.end.x - 280, touch_controls.safe_bounds.end.y - 18), 26, CYAN)


func _draw_overlay() -> void:
	if mobile_ui:
		_draw_mobile_overlay()
		return
	if phase != Phase.READY:
		draw_rect(arena_rect.grow(-1), BACKGROUND * Color(1, 1, 1, 0.94))
	var title := ui_text("title")
	var button := ui_text("mobile_start" if mobile_ui else "start")
	if phase == Phase.DEAD:
		title = ui_text("dead")
		button = ui_text("mobile_restart" if mobile_ui else "restart")
	elif phase == Phase.PAUSED:
		title = ui_text("paused")
		button = ui_text("mobile_resume" if mobile_ui else "resume")
	_center_text(title, 332 if phase == Phase.DEAD else 360, 60 if phase == Phase.READY else 42, WHITE)
	if phase == Phase.DEAD:
		_center_text(ui_text("stats") % [elapsed, collected, broken_obstacles], 383, 18, MUTED)
		_center_text(ui_text("final_score") % score, 423, 15, CYAN)
	elif music_mode:
		_center_text(ui_text("music_hint"), 410, 17, CYAN)
	var button_rect := _primary_button()
	var hover := button_rect.has_point(get_global_mouse_position())
	draw_rect(button_rect, CYAN * Color(1, 1, 1, 0.07 if hover else 0.025))
	draw_rect(button_rect, CYAN * Color(1, 1, 1, 0.85 if hover else 0.4), false, 1.0)
	_center_text(button, 502, 18, CYAN)
	if phase == Phase.DEAD and (score > old_best or broken_obstacles > old_best_broken):
		_center_text(ui_text("new_best"), 559, 15, GOLD)
	_center_text("Bumba Crossing — Kevin MacLeod (incompetech.com)", 593, 12, MUTED)
	_center_text("CC BY 4.0 · creativecommons.org/licenses/by/4.0/", 615, 11, MUTED)


func _text(value: String, at: Vector2, size: int, color: Color) -> void:
	if mobile_ui:
		# Separate text canvases keep menu glyphs independent of world geometry.
		if mobile_text_cursor == mobile_text_labels.size():
			var label := Label.new()
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.z_index = 10
			label.add_theme_font_override("font", font)
			add_child(label)
			mobile_text_labels.append(label)
		var label := mobile_text_labels[mobile_text_cursor]
		mobile_text_cursor += 1
		label.text = value
		if label.get_theme_font_size("font_size") != size:
			label.add_theme_font_size_override("font_size", size)
		var tint := color
		if not mobile_overlay_text and (settings_open or phase == Phase.PAUSED or (phase == Phase.DEAD and death_age > 0.4)):
			tint.a *= 0.06
		if label.get_theme_color("font_color") != tint:
			label.add_theme_color_override("font_color", tint)
		label.position = at - Vector2(0, font.get_ascent(size))
		label.size = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size) + Vector2(4, font.get_height(size))
		label.show()
		return
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _text_at_center(value: String, at: Vector2, size: int, color: Color) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(value, at - Vector2(width * 0.5, 0), size, color)


func _fit_text_size(value: String, max_width: float, preferred: int) -> int:
	var size := preferred
	while size > 11 and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_width:
		size -= 1
	return size


func _draw_mobile_overlay() -> void:
	mobile_overlay_text = true
	if phase != Phase.READY:
		draw_rect(arena_rect.grow(-1), BACKGROUND * Color(1, 1, 1, 0.94))
	var center: Vector2 = touch_controls.safe_bounds.get_center()
	var title := ui_text("title")
	var button := ui_text("mobile_start")
	if phase == Phase.DEAD:
		title = ui_text("dead")
		button = ui_text("mobile_restart")
		_text_at_center(ui_text("stats") % [elapsed, collected, broken_obstacles], center + Vector2(0, -35), 30, MUTED)
		_text_at_center(ui_text("final_score") % score, center + Vector2(0, 35), 36, CYAN)
	elif phase == Phase.PAUSED:
		title = ui_text("paused")
		button = ui_text("mobile_resume")
	_text_at_center(title, center + Vector2(0, -95 if phase == Phase.DEAD else -40), 96 if phase == Phase.READY else 84, WHITE)
	var rect := _primary_button()
	draw_rect(rect, CYAN * Color(1, 1, 1, 0.025))
	draw_rect(rect, CYAN * Color(1, 1, 1, 0.4), false, 2.0)
	_text_at_center(button, rect.get_center() + Vector2(0, 15), 40, CYAN)
	if phase == Phase.DEAD and (score > old_best or broken_obstacles > old_best_broken):
		_text_at_center(ui_text("new_best"), center + Vector2(0, 280), 30, GOLD)
	var credits_y: float = touch_controls.safe_bounds.end.y - 54
	_text_at_center("Bumba Crossing — Kevin MacLeod (incompetech.com)", Vector2(center.x, credits_y), 22, MUTED)
	_text_at_center("CC BY 4.0 · creativecommons.org/licenses/by/4.0/", Vector2(center.x, credits_y + 28), 20, MUTED)
	_draw_settings_button(_settings_button(), ui_text("settings"), CYAN)
	mobile_overlay_text = false


func _center_text(value: String, baseline: float, size: int, color: Color) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(value, Vector2((1080 - width) * 0.5, baseline), size, color)
