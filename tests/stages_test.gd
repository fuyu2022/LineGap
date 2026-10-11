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


func quiet_run(game) -> void:
	game.begin_run()
	game.spawn_wait = 999
	game.pickup_wait = 999


func collect(game) -> void:
	game.pickup = game.player
	game.pickup_active = true
	game.dash_cooldown_remaining = 1
	game._update_pickup(0.001)


func barrier(at: Vector2, warning: bool = false) -> Dictionary:
	return {"center": at, "velocity": Vector2.ZERO, "angle": PI / 2, "spin": 0.0,
		"length": 120.0, "age": 0.0 if warning else 2.0, "warning": 0.8, "life": 12.0}


func run() -> void:
	var game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	quiet_run(game)
	expect(game.lives == 1 and game._ring_layers() == 0, "Initial stage is one life with no gold rings")
	game.obstacles.append(barrier(game.player))
	game.advance_game(0.01, Vector2.ZERO)
	expect(game.phase == Game.Phase.DEAD, "Normal collision at initial stage ends the run")
	quiet_run(game)
	for stage in range(2, 4):
		collect(game)
		expect(game.lives == stage and game._ring_layers() == 1, "Stage %d uses one gold ring" % stage)
	for index in 5:
		collect(game)
	expect(game.lives == 3 and game._ring_layers() == 1 and game.collected == 7 and game.score == 350, "Stage caps at three lives and one ring while more orbs still score")
	expect(game.dash_cooldown_remaining == 0, "Pickups still refill dash at maximum stage")
	for warning in [false, true]:
		quiet_run(game)
		game.obstacles.append(barrier(game.player + Vector2(70, 0), warning))
		game.try_dash(Vector2.RIGHT)
		game.advance_game(0.1, Vector2.ZERO)
		expect(game.lives == 1 and game.phase == Game.Phase.PLAYING and game.obstacles.size() == 1, "Initial-stage dash preserves the player and struck barrier")
		expect(game.obstacles[0]["ghost_remaining"] == 0.8 and game.broken_obstacles == 0 and game.fragments.is_empty(), "Initial-stage dash uses the obstacle's spawn warning duration without shattering")
		game.advance_game(0.06, Vector2.ZERO)
		expect(game.hit_grace == 0 and game.obstacles[0]["ghost_remaining"] < 0.8, "Phasing does not consume life or repeatedly reset its timer")
	quiet_run(game)
	var origin: Vector2 = game.player
	game.obstacles.append(barrier(origin + Vector2(70, 0)))
	game.try_dash(Vector2.RIGHT)
	game.advance_game(0.16, Vector2.ZERO)
	game.obstacles[0]["velocity"] = Vector2(10, 0)
	game.advance_game(0.2, Vector2.ZERO)
	expect(game.obstacles[0]["center"].is_equal_approx(origin + Vector2(72, 0)), "Phased barriers keep moving")
	game.player = game.obstacles[0]["center"]
	game.advance_game(0.1, Vector2.ZERO)
	expect(game.phase == Game.Phase.PLAYING, "A phased barrier cannot collide even without player protection")
	game.obstacles[0]["velocity"] = Vector2.ZERO
	game.phase = Game.Phase.PAUSED
	var ghost: float = game.obstacles[0]["ghost_remaining"]
	game._physics_process(1)
	expect(game.obstacles[0]["ghost_remaining"] == ghost, "Pause freezes obstacle phasing")
	game.phase = Game.Phase.PLAYING
	game.advance_game(ghost + 0.01, Vector2.ZERO)
	expect(game.phase == Game.Phase.DEAD and game.obstacles[0]["ghost_remaining"] == 0, "After its spawn warning duration the obstacle recovers collision")
	quiet_run(game)
	game.obstacles.append(barrier(game.player + Vector2(70, 0)))
	game.obstacles[0]["warning"] = 1.15
	game.obstacles[0]["spin"] = 0.7
	game.try_dash(Vector2.RIGHT)
	game.advance_game(0.08, Vector2.ZERO)
	expect(game.obstacles[0]["ghost_remaining"] == 1.15, "Rotating obstacles retain their longer 1.15 second warning duration when phased")
	game.advance_game(1.14, Vector2.ZERO)
	expect(game.obstacles[0]["ghost_remaining"] > 0, "Longer warning duration does not recover early")
	game.advance_game(0.02, Vector2.ZERO)
	expect(game.obstacles[0]["ghost_remaining"] == 0, "Longer phasing recovers after 1.15 seconds")
	quiet_run(game)
	game.lives = 3
	game.obstacles.append(barrier(game.player))
	game.obstacles.append(barrier(game.player + Vector2(3, 0)))
	game.advance_game(0.01, Vector2.ZERO)
	expect(game.lives == 2 and game.hit_grace == 2, "Multiple overlapping normal collisions cost one life and give two seconds of protection")
	expect(game.obstacles[0]["ghost_remaining"] == 0 and game.obstacles[1]["ghost_remaining"] == 0, "Normal collision does not phase obstacles")
	game.advance_game(1.99, Vector2.ZERO)
	expect(game.lives == 2 and game.hit_grace > 0, "Protection lasts almost two full seconds")
	game.phase = Game.Phase.PAUSED
	var grace: float = game.hit_grace
	game._physics_process(1)
	expect(game.hit_grace == grace, "Pause freezes player protection")
	game.phase = Game.Phase.PLAYING
	game.advance_game(0.02, Vector2.ZERO)
	expect(game.lives == 1, "Normal collision can take another life after protection expires")
	game.hit_grace = 0
	game.advance_game(0.01, Vector2.ZERO)
	expect(game.phase == Game.Phase.DEAD, "Last life ends the run on normal collision")
	for stage in range(1, 4):
		for heading in [Vector2.RIGHT, Vector2.ONE]:
			quiet_run(game)
			game.lives = stage
			origin = game.player
			game.try_dash(heading)
			expect(is_equal_approx(game.dash_cooldown_remaining, 0.75 if stage >= 2 else 1.5), "Stage %d cooldown is correct" % stage)
			game.advance_game(game.dash_remaining, Vector2.ZERO)
			expect(is_equal_approx(game.player.distance_to(origin), 280 if stage == 3 else 160), "Stage %d has correct straight and diagonal distance" % stage)
	for stage in [2, 3]:
		quiet_run(game)
		game.lives = stage
		game.obstacles.append(barrier(game.player + Vector2(70, 0)))
		game.try_dash(Vector2.RIGHT)
		game.advance_game(0.08, Vector2.ZERO)
		expect(game.lives == stage and game.broken_obstacles == 1 and game.obstacles.is_empty(), "Stage %d keeps the original dash shatter effect" % stage)
	quiet_run(game)
	game.lives = 2
	game.try_dash(Vector2.RIGHT)
	game.pickup = game.player + Vector2(40, 0)
	game.pickup_active = true
	game.advance_game(0.08, Vector2.ZERO)
	expect(game.lives == 3 and is_equal_approx(game.dash_remaining, 0.08), "Mid-dash upgrade preserves the current burst distance")
	game.advance_game(0.08, Vector2.ZERO)
	game.try_dash(Vector2.LEFT)
	expect(is_equal_approx(game.dash_remaining, 0.28) and game.dash_cooldown_remaining == 0.75, "Next dash gets stage-three distance and half cooldown")
	quiet_run(game)
	game.lives = 3
	game._take_hit()
	game.try_dash(Vector2.RIGHT)
	expect(game.lives == 2 and game.dash_remaining == 0.16 and game.dash_cooldown_remaining == 0.75, "Damage fades the solid ring and removes distance bonus but keeps half cooldown")
	game.hit_grace = 0
	game._take_hit()
	game.dash_remaining = 0
	game.dash_cooldown_remaining = 0
	game.try_dash(Vector2.LEFT)
	expect(game.lives == 1 and game.dash_remaining == 0.16 and game.dash_cooldown_remaining == 1.5, "Damage removes the faint ring and restores initial stage")
	quiet_run(game)
	game.lives = 3
	game.obstacles.append(barrier(game.player + Vector2(20, 0)))
	game.advance_game(0.01, Vector2.ZERO)
	expect(game.lives == 3, "Rings do not enlarge the collision radius")
	game.player = Game.ARENA.end - Vector2(12, 12)
	game.try_dash(Vector2.ONE)
	game.advance_game(0.28, Vector2.ZERO)
	expect(game.player == Game.ARENA.end - Vector2(10, 10), "Long dash remains within bounds")
	quiet_run(game)
	expect(game.lives == 1 and game._ring_layers() == 0 and game.hit_grace == 0 and game.obstacles.is_empty(), "Restart restores initial stage and removes ghost barriers")
	game.queue_free()
	await process_frame
	print("%s: %d stage checks" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)
