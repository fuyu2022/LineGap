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
	expect(controls.direction == Vector2.ZERO, "Thumb jitter inside the dead zone does not move")
	controls.drag(0, origin + Vector2(41.04 * Controls.CONTROL_SCALE, 0))
	expect(is_equal_approx(controls.direction.x, 0.5), "Analog half deflection gives half movement strength")
	controls.drag(0, origin + Vector2(300, 300))
	expect(is_equal_approx(controls.direction.length(), 1) and is_equal_approx(controls.knob.length(), Controls.RADIUS), "Fixed knob clamps and diagonal input cannot exceed full speed")
	expect(controls.center == origin, "Fixed mode never follows the finger")
	expect(controls.press(1, origin) == "", "Second left touch cannot steal movement")
	controls.drag(1, origin - Vector2(300, 0))
	expect(controls.direction.x > 0, "Unowned finger drags are ignored")
	expect(controls.press(2, controls.dash_center + Vector2(100, 0)) == "dash" and controls.move_touch == 0, "The doubled dash button accepts a second finger at its enlarged edge without disturbing movement")
	controls.release(2)
	expect(controls.move_touch == 0 and controls.direction.x > 0, "Releasing dash leaves movement active")
	controls.release(0)
	controls.drag(1, origin + Vector2(300, 0))
	expect(controls.direction == Vector2.ZERO and controls.move_touch == -1, "A previously ignored held finger is not adopted after release")
	controls.set_following(true)
	origin = Vector2(-50, 350)
	expect(controls.press(4, origin) == "move" and controls.center == origin and controls.direction == Vector2.ZERO, "Following mode establishes a neutral center at the touch landing point")
	controls.drag(4, origin + Vector2(30, 0))
	expect(controls.center == origin and controls.direction.x > 0, "Small drag moves the knob while the following center stays stable")
	controls.drag(4, origin + Vector2(200 * Controls.CONTROL_SCALE, 0))
	expect(controls.center.is_equal_approx(origin + Vector2(128 * Controls.CONTROL_SCALE, 0)) and controls.direction == Vector2.RIGHT, "Long drag follows the finger while preserving full speed")
	controls.drag(4, controls.center + Vector2(-Controls.RADIUS, 0))
	expect(controls.direction == Vector2.LEFT, "Crossing the center reverses direction immediately")
	controls.drag(4, Vector2(1200, 600))
	expect(controls.move_touch == 4 and controls.center.x <= controls.center_bounds.end.x, "Crossing the screen midpoint keeps ownership and bounds the following center")
	controls.release(4)
	expect(controls.direction == Vector2.ZERO and controls.center == controls.fixed_center, "Release recenters and removes all movement strength")
	controls.press(5, origin)
	controls.set_following(false)
	expect(controls.move_touch == -1 and controls.dash_touch == -1 and controls.direction == Vector2.ZERO, "Changing modes cancels captured fingers")
	expect(controls.press(6, Vector2(800, 200)) == "", "Unassigned right-side touch cannot trigger a dash")
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
	drag(game, 1, origin + Vector2(41.04 * Controls.CONTROL_SCALE, 0))
	var player_before: Vector2 = game.player
	game._physics_process(0.2)
	expect(is_equal_approx(game.player.x - player_before.x, 33.5), "Gameplay preserves analog half speed instead of normalizing every touch")
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
		expect(safe.encloses(Rect2(game.touch_controls.fixed_center - Vector2.ONE * Controls.RADIUS, Vector2.ONE * Controls.RADIUS * 2)) and safe.encloses(Rect2(game.touch_controls.dash_center - Vector2.ONE * Controls.DASH_RADIUS, Vector2.ONE * Controls.DASH_RADIUS * 2)), "Doubled touch controls remain fully visible at %s" % str(size))
		expect(game.arena_rect.get_area() > game.touch_controls.view_bounds.get_area() * 0.9, "Mobile playfield fills over 90 percent of viewport at %s" % str(size))
		expect(game.touch_controls.move_touch == -1 and game._movement_input() == Vector2.ZERO, "Resizing cancels old touch ownership at %s" % str(size))
		var clipped: PackedVector2Array = game._clip_to_arena(Vector2(game.arena_rect.position.x - 100, game.arena_rect.get_center().y), Vector2(game.arena_rect.end.x + 100, game.arena_rect.get_center().y))
		expect(clipped.size() == 2 and is_equal_approx(clipped[0].x, game.arena_rect.position.x) and is_equal_approx(clipped[1].x, game.arena_rect.end.x), "Obstacle clipping uses the full mobile playfield at %s" % str(size))
	game.begin_run()
	var barrier := PackedVector2Array([Vector2(30, -100), Vector2(30, 100)])
	expect(game._path_hits_obstacle(Vector2.ZERO, Vector2.ZERO, barrier, barrier), "Visible enlarged player makes contact at the mobile radius")
	var desktop = Game.new()
	expect(not desktop._path_hits_obstacle(Vector2.ZERO, Vector2.ZERO, barrier, barrier), "Desktop collision radius stays unchanged")
	game.rng.seed = 1234
	desktop.rng.seed = 1234
	game._spawn_obstacle()
	desktop._spawn_obstacle()
	expect(is_equal_approx(game.obstacles.back()["length"], desktop.obstacles.back()["length"] * 4.0), "Mobile barrier geometry is four times desktop size")
	desktop.dash_ripple.free()
	desktop.free()
	game.obstacles.clear()
	game.pickup = game.player + Vector2(70, 0)
	game.pickup_active = true
	game._update_pickup(0.01)
	expect(game.collected == 1 and not game.pickup_active, "Enlarged mobile orb can be collected at its visible halo")
	game.pickup = game.player + Vector2(81, 0)
	game.pickup_active = true
	game._update_pickup(0.01)
	expect(game.collected == 1 and game.pickup_active, "Orb outside the enlarged pickup range is not collected")
	var edge: Vector2 = game._clamp_player(game.arena_rect.position)
	expect(edge.is_equal_approx(game.arena_rect.position + Vector2(40, 40)), "Enlarged player keeps its full body inside the playfield")
	game.begin_run()
	var spawned_outside_old_box := false
	var all_pickups_safe := true
	for attempt in 100:
		game.pickup_active = false
		game.pickup_wait = 0
		game._update_pickup(0.01)
		if game.pickup_active:
			spawned_outside_old_box = spawned_outside_old_box or not Game.ARENA.has_point(game.pickup)
			all_pickups_safe = all_pickups_safe and game.arena_rect.has_point(game.pickup) and game.pickup.y >= game.touch_controls.safe_bounds.position.y + 184 and game.pickup.distance_to(game.touch_controls.fixed_center) >= 228 and game.pickup.distance_to(game.touch_controls.dash_center) >= 212
	expect(spawned_outside_old_box and all_pickups_safe, "Orbs use the expanded mobile playfield while avoiding HUD and touch buttons")
	game.queue_free()
	await process_frame
	print("%s: %d mobile checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)
