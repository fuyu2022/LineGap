extends SceneTree
const Game = preload("res://scripts/game.gd")
const Controls = preload("res://scripts/mobile_controls.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)

func touch(game, index: int, at: Vector2, pressed: bool = true, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = game.get_global_transform_with_canvas() * at
	event.pressed = pressed
	event.canceled = canceled
	game._unhandled_input(event)

func drag(game, index: int, at: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = game.get_global_transform_with_canvas() * at
	game._unhandled_input(event)

func run() -> void:
	var controls = Controls.new()
	controls.configure(Rect2(-180, -45, 1440, 810), Rect2(-180, -45, 1440, 810), Game.ARENA)
	var origin: Vector2 = controls.fixed_center
	expect(controls.press(0, origin) == "move" and controls.direction == Vector2.ZERO, "Fixed joystick starts neutral at its center")
	controls.drag(0, origin + Vector2(5, 0))
	expect(controls.direction == Vector2.RIGHT, "Small fixed joystick movement requests full speed")
	controls.drag(0, origin)
	expect(controls.direction == Vector2.ZERO, "Returning exactly to the fixed center stops movement")
	controls.drag(0, origin + Vector2(0.001, 0))
	expect(controls.direction == Vector2.RIGHT, "Tiny nonzero fixed joystick movement requests full speed")
	controls.drag(0, origin + Vector2(41.04 * Controls.CONTROL_SCALE, 0))
	expect(controls.direction == Vector2.RIGHT, "Half deflection gives full speed")
	controls.drag(0, origin + Vector2(300, 300))
	expect(is_equal_approx(controls.direction.length(), 1) and is_equal_approx(controls.knob.length(), controls.radius), "Fixed knob clamps and diagonal input cannot exceed full speed")
	expect(controls.center == origin, "Fixed mode never follows the finger")
	expect(controls.press(1, origin) == "", "Second left touch cannot steal movement")
	controls.drag(1, origin - Vector2(300, 0))
	expect(controls.direction.x > 0, "Unowned finger drags are ignored")
	expect(controls.press(2, controls.dash_center + Vector2(controls.dash_radius - 1, 0)) == "dash" and controls.move_touch == 0, "Resized dash button accepts a second finger near its edge without disturbing movement")
	controls.release(2)
	expect(controls.move_touch == 0 and controls.direction.x > 0, "Releasing dash leaves movement active")
	expect(controls.press(2, controls.dash_center + Vector2(controls.dash_radius + 12 * controls.visual_scale + 1, 0)) == "" and controls.dash_touch == -1, "Outside the resized dash hit area does not capture or trigger a dash")
	controls.release(0)
	controls.drag(1, origin + Vector2(300, 0))
	expect(controls.direction == Vector2.ZERO and controls.move_touch == -1, "A previously ignored held finger is not adopted after release")
	controls.set_following(true)
	origin = Vector2(-50, 350)
	expect(controls.press(4, origin) == "move" and controls.center == origin and controls.direction == Vector2.ZERO, "Following mode establishes a neutral center at the touch landing point")
	controls.drag(4, origin + Vector2(0, -0.001))
	expect(controls.center == origin and controls.direction == Vector2.UP, "Tiny following joystick movement requests full speed without moving its center")
	controls.drag(4, origin)
	expect(controls.direction == Vector2.ZERO, "Returning exactly to the following center stops movement")
	controls.drag(4, origin + Vector2(30, 0))
	expect(controls.center == origin and controls.direction.x > 0, "Small drag moves the knob while the following center stays stable")
	controls.drag(4, origin + Vector2(200 * Controls.CONTROL_SCALE, 0))
	expect(controls.center == origin and controls.direction == Vector2.RIGHT and is_equal_approx(controls.knob.length(), controls.radius), "Long drag keeps the touchdown center anchored and clamps the knob at full speed")
	controls.drag(4, controls.center + Vector2(-controls.radius, 0))
	expect(controls.direction == Vector2.LEFT, "Crossing the center reverses direction immediately")
	controls.drag(4, Vector2(1200, 600))
	expect(controls.move_touch == 4 and controls.center == origin, "Crossing the screen midpoint keeps ownership and the original center")
	controls.release(4)
	expect(controls.direction == Vector2.ZERO and controls.move_touch == -1 and controls.center == origin, "Release ends the anchored gesture and waits for a new touchdown")
	var next_origin := origin + Vector2(90, 10)
	expect(controls.press(8, next_origin) == "move" and controls.center == next_origin and controls.direction == Vector2.ZERO, "Next touchdown establishes a new neutral center")
	controls.drag(4, origin)
	expect(controls.move_touch == 8 and controls.center == next_origin and controls.direction == Vector2.ZERO, "Old finger cannot move the new gesture")
	controls.release(8)
	controls.press(5, origin)
	controls.set_following(false)
	expect(controls.move_touch == -1 and controls.dash_touch == -1 and controls.direction == Vector2.ZERO, "Changing modes cancels captured fingers")
	expect(controls.press(6, Vector2(800, 200)) == "", "Unassigned right-side touch cannot trigger a dash")
	var adaptive = Controls.new()
	for dimensions in [Vector2(1440, 810), Vector2(1440, 1080), Vector2(2560, 1600), Vector2(1200, 600)]:
		var bounds := Rect2(Vector2.ZERO, dimensions)
		adaptive.configure(bounds, bounds, bounds)
		var move_bounds := Rect2(adaptive.fixed_center - Vector2.ONE * adaptive.radius, Vector2.ONE * adaptive.radius * 2)
		var dash_bounds := Rect2(adaptive.dash_center - Vector2.ONE * adaptive.dash_radius, Vector2.ONE * adaptive.dash_radius * 2)
		expect(bounds.encloses(move_bounds) and bounds.encloses(dash_bounds), "Adaptive controls remain inside safe bounds at %s" % dimensions)
		adaptive.press(0, adaptive.fixed_center)
		adaptive.drag(0, adaptive.fixed_center + Vector2(adaptive.radius * 0.2, 0))
		expect(adaptive.direction == Vector2.RIGHT, "Small deflection requests the same full speed at %s" % dimensions)
		adaptive.drag(0, adaptive.fixed_center + Vector2(adaptive.radius * 0.05, 0))
		expect(adaptive.direction == Vector2.RIGHT, "Very small deflection still requests full speed at %s" % dimensions)
	adaptive.configure(Rect2(0, 0, 1440, 810), Rect2(0, 0, 1440, 810), Game.ARENA)
	var phone_radius: float = adaptive.radius
	adaptive.configure(Rect2(0, 0, 1440, 1080), Rect2(0, 0, 1440, 1080), Game.ARENA)
	expect(adaptive.radius <= phone_radius and adaptive.dash_radius * 2 <= Controls.MAX_DASH_DIAMETER_DP and adaptive.visual_scale <= Controls.CONTROL_SCALE * Controls.MAX_SIZE_FACTOR, "Tablet controls remain capped instead of enlarging without a display limit")
	# Exercise actual canvas stretch and Android density independently of logical viewport size.
	for screen_scale in [0.75, 1.0, 1.5, 2.0, 3.0, 4.0]:
		for density in [0.75, 1.0, 1.5, 2.0, 3.0, 4.0]:
			var bounds := Rect2(0, 0, 1440, 1080)
			adaptive.configure(bounds, bounds, bounds, screen_scale, density)
			var joystick_dp: float = adaptive.radius * 2 * screen_scale / density
			var dash_dp: float = adaptive.dash_radius * 2 * screen_scale / density
			expect(joystick_dp <= Controls.MAX_JOYSTICK_DIAMETER_DP + 0.001 and dash_dp <= Controls.MAX_DASH_DIAMETER_DP + 0.001, "Rendered controls respect display caps at stretch %s density %s" % [screen_scale, density])
			adaptive.press(0, adaptive.fixed_center)
			adaptive.drag(0, adaptive.fixed_center + Vector2(adaptive.radius * 0.2, 0))
			expect(adaptive.direction == Vector2.RIGHT and adaptive.press(1, adaptive.dash_center + Vector2(adaptive.dash_radius - 0.01, 0)) == "dash", "Capped controls preserve full-speed movement and simultaneous edge dash at stretch %s density %s" % [screen_scale, density])
	var game = Game.new()
	game.mobile_ui = true
	game.test_mode = true
	root.size = Vector2i(1440, 810)
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	expect(not quit_on_go_back, "Android back is handled by pause/settings instead of automatically quitting")
	expect(game.font != null and game._settings_button().position.y < 128 and game._settings_button().position.x > game.touch_controls.view_bounds.get_center().x + game.touch_controls.view_bounds.size.x * 0.25, "Mobile font loads and settings sits in the top-right quarter")
	expect(game._settings_button().end.x <= game.touch_controls.safe_bounds.end.x - 64 and game._mobile_header_inset() >= 64, "Title and settings keep an inward margin from both screen edges")
	touch(game, 0, Vector2(540, 495))
	expect(game.phase == Game.Phase.PLAYING, "Touch starts the game without a keyboard")
	game.spawn_wait = 999
	game.pickup_wait = 999
	origin = game.touch_controls.fixed_center
	touch(game, 1, origin)
	drag(game, 1, origin + Vector2(0.001, 0))
	var player_before: Vector2 = game.player
	game._physics_process(0.2)
	expect(is_equal_approx(game.player.x - player_before.x, 100.5), "Tiny deflection moves at the full 1.5-times base speed")
	touch(game, 2, game.touch_controls.dash_center)
	expect(game.dash_remaining > 0 and game.dash_direction == Vector2.RIGHT and game.touch_controls.move_touch == 1, "Dash button uses joystick heading during simultaneous movement")
	expect(not game._mobile_dash_ready() and game.dash_cooldown_remaining > 0, "Dash button becomes inactive during cooldown")
	game._physics_process(1.6)
	expect(game._mobile_dash_ready() and game.dash_remaining == 0, "Button activates after cooldown without automatically dashing while held")
	touch(game, 2, game.touch_controls.dash_center, false)
	touch(game, 2, game.touch_controls.dash_center)
	expect(game.dash_remaining > 0, "A fresh dash press triggers the next burst")
	touch(game, 1, origin, true, true)
	expect(game._movement_input() == Vector2.ZERO, "Canceled movement touch clears its direction")
	touch(game, 3, game._settings_button().get_center())
	expect(game.settings_open and game.phase == Game.Phase.PAUSED and game.touch_controls.move_touch == -1 and game.touch_controls.dash_touch == -1, "Settings touch pauses and cancels both fingers")
	var super_before: float = game.super_dash_remaining
	var elapsed_before: float = game.elapsed
	game._physics_process(5)
	expect(game.elapsed == elapsed_before and game.super_dash_remaining == super_before, "Mobile settings freezes gameplay")
	touch(game, 4, game._joystick_button().get_center())
	expect(game.touch_controls.following and game.settings_open, "Settings switches to following mode without closing")
	touch(game, 5, game._settings_close_button().get_center())
	expect(not game.settings_open and game.phase == Game.Phase.PLAYING and game._movement_input() == Vector2.ZERO, "Closing mobile settings resumes without stale movement")
	touch(game, 6, Vector2(-50, 350))
	drag(game, 6, Vector2(30, 350))
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	expect(game.phase == Game.Phase.PAUSED and game._movement_input() == Vector2.ZERO and game.touch_controls.move_touch == -1, "App suspension releases floating input and pauses")
	game.begin_run()
	game._begin_super_dash()
	touch(game, 7, game.touch_controls.dash_center)
	expect(game._mobile_dash_ready() and game.dash_cooldown_remaining == 0, "Super dash leaves the touch button active with zero cooldown")
	touch(game, 7, game.touch_controls.dash_center, false)
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	expect(game.phase == Game.Phase.PAUSED, "Android back button pauses")
	game._open_settings()
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	expect(not game.settings_open and game.phase == Game.Phase.PAUSED, "Android back closes settings while preserving a prior pause")
	var path := "user://mobile-settings-test.cfg"
	var config := ConfigFile.new()
	config.set_value("record", "score", 4321)
	config.set_value("settings", "music_enabled", false)
	config.save(path)
	game.set_joystick_following(true)
	game._save_joystick_preference(path)
	game.set_joystick_following(false)
	game._load_joystick_preference(path)
	expect(game.touch_controls.following, "Following preference persists across reload")
	config.load(path)
	expect(config.get_value("record", "score") == 4321 and config.get_value("settings", "music_enabled") == false, "Saving joystick mode preserves records and music")
	DirAccess.remove_absolute(path)
	for size in [Vector2i(1440, 810), Vector2i(1920, 864), Vector2i(1280, 960)]:
		game.touch_controls.press(20, game.touch_controls.fixed_center)
		root.size = size
		await process_frame
		game._layout_mobile()
		var safe: Rect2 = game.touch_controls.safe_bounds
		expect(safe.encloses(game._mobile_settings_panel()) and safe.encloses(game._primary_button()), "Large settings and pause buttons fit the safe area at %s" % str(size))
		expect(safe.encloses(Rect2(game.touch_controls.fixed_center - Vector2.ONE * game.touch_controls.radius, Vector2.ONE * game.touch_controls.radius * 2)) and safe.encloses(Rect2(game.touch_controls.dash_center - Vector2.ONE * game.touch_controls.dash_radius, Vector2.ONE * game.touch_controls.dash_radius * 2)), "Resized touch controls remain fully visible at %s" % str(size))
		expect(game.arena_rect.get_area() > game.touch_controls.view_bounds.get_area() * 0.9, "Mobile playfield fills over 90 percent of viewport at %s" % str(size))
		expect(game.touch_controls.move_touch == -1 and game._movement_input() == Vector2.ZERO, "Resizing cancels old touch ownership at %s" % str(size))
		var clipped: PackedVector2Array = game._clip_to_arena(Vector2(game.arena_rect.position.x - 100, game.arena_rect.get_center().y), Vector2(game.arena_rect.end.x + 100, game.arena_rect.get_center().y))
		expect(clipped.size() == 2 and is_equal_approx(clipped[0].x, game.arena_rect.position.x) and is_equal_approx(clipped[1].x, game.arena_rect.end.x), "Obstacle clipping uses the full mobile playfield at %s" % str(size))
	game.begin_run()
	var barrier := PackedVector2Array([Vector2(22, -100), Vector2(22, 100)])
	expect(game._path_hits_obstacle(Vector2.ZERO, Vector2.ZERO, barrier, barrier), "Visible enlarged player makes contact at the mobile radius")
	var desktop = Game.new()
	expect(not desktop._path_hits_obstacle(Vector2.ZERO, Vector2.ZERO, barrier, barrier), "Desktop collision radius stays unchanged")
	game.rng.seed = 1234
	desktop.rng.seed = 1234
	game._spawn_obstacle()
	desktop._spawn_obstacle()
	expect(is_equal_approx(game.obstacles.back()["length"], desktop.obstacles.back()["length"] * 3.0), "Mobile barrier geometry is three times desktop size")
	desktop.dash_ripple.free()
	desktop.free()
	game.obstacles.clear()
	game.pickup = game.player + Vector2(50, 0)
	game.pickup_active = true
	game._update_pickup(0.01)
	expect(game.collected == 1 and not game.pickup_active, "Enlarged mobile orb can be collected at its visible halo")
	game.pickup = game.player + Vector2(61, 0)
	game.pickup_active = true
	game._update_pickup(0.01)
	expect(game.collected == 1 and game.pickup_active, "Orb outside the enlarged pickup range is not collected")
	var edge: Vector2 = game._clamp_player(game.arena_rect.position)
	expect(edge.is_equal_approx(game.arena_rect.position + Vector2(30, 30)), "Three-times player keeps its full body inside the playfield")
	game.begin_run()
	var spawned_outside_old_box := false
	var all_pickups_safe := true
	for attempt in 100:
		game.pickup_active = false
		game.pickup_wait = 0
		game._update_pickup(0.01)
		if game.pickup_active:
			spawned_outside_old_box = spawned_outside_old_box or not Game.ARENA.has_point(game.pickup)
			all_pickups_safe = all_pickups_safe and game.arena_rect.has_point(game.pickup) and game.pickup.y >= game.touch_controls.safe_bounds.position.y + 165 and game.pickup.distance_to(game.touch_controls.fixed_center) >= game.touch_controls.radius + 65 and game.pickup.distance_to(game.touch_controls.dash_center) >= game.touch_controls.dash_radius + 65
	expect(spawned_outside_old_box and all_pickups_safe, "Orbs use the expanded mobile playfield while avoiding HUD and touch buttons")
	for stage in range(1, 4):
		game.begin_run()
		game.spawn_wait = 999
		game.pickup_wait = 999
		game.lives = stage
		var start: Vector2 = game.player
		game.try_dash(Vector2.RIGHT)
		game.advance_game(game.dash_remaining, Vector2.ZERO)
		expect(is_equal_approx(game.player.distance_to(start), 420 if stage == 3 else 240), "Stage %d mobile dash travels 1.5 times the desktop distance" % stage)
	for size in [Vector2i(1440, 810), Vector2i(1920, 864), Vector2i(1280, 960)]:
		root.size = size
		await process_frame
		game._layout_mobile()
		var panel: Rect2 = game._mobile_settings_panel()
		var buttons := [game._music_button(), game._music_mode_button(), game._language_button(), game._joystick_button(), game._settings_close_button()]
		var fit := true
		for index in buttons.size():
			fit = fit and panel.encloses(buttons[index])
			for other in range(index + 1, buttons.size()):
				fit = fit and not buttons[index].intersects(buttons[other])
		expect(fit, "Four settings rows and close button fit without overlap at %s" % size)
		expect(game.world_clip.clip_contents and game.world_clip.position == game.arena_rect.position and game.world_layer.position == -game.arena_rect.position and game.music_wave_layer.position == -game.ripple_clip.position and game.dash_ripple.position == -game.ripple_clip.position, "World and effect clip transforms follow viewport size %s" % size)
		game.begin_run()
		game.elapsed = 20.0
		var valid := true
		var rotations := 0
		for attempt in 400:
			game.obstacles.clear()
			game._spawn_obstacle()
			if game.obstacles.is_empty():
				continue
			var item: Dictionary = game.obstacles[0]
			if item["kind"] == Game.LineKind.ROTATING:
				rotations += 1
				valid = valid and absf(item["spin"]) >= 0.275 and absf(item["spin"]) <= 0.55
				for angle_step in 24:
					item["angle"] = angle_step * TAU / 24.0
					var ends: PackedVector2Array = game.obstacle_endpoints(item)
					valid = valid and game.arena_rect.has_point(ends[0]) and game.arena_rect.has_point(ends[1])
			else:
				var ends: PackedVector2Array = game.obstacle_endpoints(item)
				if item["kind"] == Game.LineKind.HORIZONTAL:
					valid = valid and ends[0].x >= game.arena_rect.position.x and ends[1].x <= game.arena_rect.end.x
				else:
					valid = valid and ends[0].y >= game.arena_rect.position.y and ends[1].y <= game.arena_rect.end.y
		expect(valid and rotations > 0, "Long moving barriers fit and half-speed rotating barriers stay inside through all angles at %s" % size)
	game.begin_run()
	game._open_settings()
	touch(game, 30, game._music_mode_button().get_center())
	expect(game.music_mode and game.settings_open and game.phase == Game.Phase.PAUSED and game.elapsed == 0, "Mode switches inside settings, restarts and stays paused until closing")
	touch(game, 31, game._settings_close_button().get_center())
	expect(game.phase == Game.Phase.PLAYING and not game.settings_open, "Closing settings resumes the selected music mode")
	game.spawn_wait = 999
	game.pickup_wait = 999
	game.music_clock.reset()
	game.music_clock.update(game.music_clock.offset + 4 * game.music_clock.period)
	game.obstacles.clear()
	game.obstacles.append({"center": game.player + Vector2(200, 0), "angle": PI / 2, "length": 50.0, "velocity": Vector2.ZERO, "spin": 0.0, "age": 2.0, "warning": 0.8, "life": 20.0})
	var start: Vector2 = game.player
	touch(game, 32, game.touch_controls.fixed_center)
	drag(game, 32, game.touch_controls.fixed_center + Vector2(50, 0))
	touch(game, 33, game.touch_controls.dash_center)
	expect(game.music_waves.size() == 1 and game.dash_remaining == 0 and not game._mobile_dash_ready() and game.touch_controls.move_touch == 32, "Two-finger on-beat wave grays the button and preserves movement ownership")
	touch(game, 32, game.touch_controls.fixed_center, false)
	game.advance_game(0.25, Vector2.ZERO)
	expect(game.broken_obstacles == 1 and game.player == start, "Mobile wave reaches scaled range and shatters a phased barrier without dash displacement")
	touch(game, 33, game.touch_controls.dash_center, false)
	game.music_clock.update(game.music_clock.position + game.music_clock.period - 0.06)
	touch(game, 34, game.touch_controls.dash_center)
	expect(game.music_wave_buffered_beat == 5 and game.music_waves.size() == 1, "Gray touch button accepts the 80ms early buffer")
	game._update_music_beat(0.07)
	expect(game.music_waves.size() == 2 and not game._mobile_dash_ready(), "Buffered touch fires one on-beat wave and consumes that beat")
	game._update_music_beat(game.music_clock.period)
	expect(game._mobile_dash_ready() and game.music_waves.size() == 2, "Next beat restores button without automatically firing from a held touch")
	for stage in range(1, 4):
		game.lives = stage
		expect(game._music_wave_radius() == Game.MUSIC_WAVE_RADII[stage - 1] * 3.0, "Stage %d music wave radius is three times base" % stage)
	game._begin_super_dash()
	game.obstacles.append({"center": game.player + Vector2(400, 0), "angle": 0.0, "length": 100.0, "velocity": Vector2.ZERO, "spin": 0.0, "age": 2.0, "warning": 0.8, "life": 20.0})
	game._update_music_beat(game.music_clock.period)
	expect(game.obstacles.is_empty() and game.super_dash_active, "Mobile super resonance automatically shatters phased obstacles on beat")
	game._open_settings()
	touch(game, 35, game._music_mode_button().get_center())
	expect(not game.music_mode and game.settings_open and game.phase == Game.Phase.PAUSED, "Settings can switch back to ordinary mode without releasing a dash")
	game.queue_free()
	await process_frame
	print("%s: %d mobile checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)
