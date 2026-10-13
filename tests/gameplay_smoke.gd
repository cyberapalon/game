extends Node
## Headless behavior tests against real scene physics. No testing addons required.

const LEVEL := preload("res://levels/conservatory/conservatory.tscn")
var _game: Conservatory
var _player: LumenPlayer
var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_progress().reduced_motion = true
	_game = LEVEL.instantiate() as Conservatory
	get_tree().root.add_child(_game)

	_player = _game.player
	await _frames(30)
	_check(
		_player.is_on_floor() and absf(_player.position.y - 840.0) < 1.0,
		"Spawn lands on the world collision"
	)
	var start_x := _player.position.x
	_action(&"move_right", true)
	await _frames(30)
	_action(&"move_right", false)
	_check(_player.position.x > start_x + 100, "Horizontal movement accelerates to running speed")
	await _frames(12)
	_check(absf(_player.velocity.x) < 1.0, "Releasing movement brakes precisely")
	await _jump_segment(Vector2(500, 840), Vector2(600, 740), &"move_right")
	await _jump_segment(Vector2(680, 740), Vector2(850, 650), &"move_right")
	await _jump_segment(Vector2(920, 650), Vector2(1090, 720), &"move_right")
	var full_height := await _measure_jump(false)
	var short_height := await _measure_jump(true)
	_check(full_height > 125 and full_height < 155, "Full jump clears the authored 100px steps")
	_check(short_height < full_height * 0.65, "Early release produces a short hop")
	_player.respawn(Vector2(350, 830))
	_player.velocity.y = 200
	await _frames(1)
	_action(&"jump", true)
	await _frames(7)
	_check(_player.velocity.y < -400, "A buffered jump fires just after landing")
	_action(&"jump", false)
	_player.respawn(Vector2(806, 840))
	await _frames(3)
	_action(&"move_right", true)
	for index in range(20):
		await _frames(1)
		if not _player.is_on_floor():
			break
	_action(&"jump", true)
	await _frames(2)
	_check(_player.velocity.y < -500, "Coyote time permits jumping just beyond an edge")
	_action(&"jump", false)
	_action(&"move_right", false)
	# Test health through the public damage interface, including repeated contact.
	_player.respawn(Vector2(350, 840))
	_player.health.immunity = 0
	_player.take_damage(DamageData.new(1, Vector2(120, -120)))
	_player.take_damage(DamageData.new(1))
	_check(_player.health.current == 4, "Damage immunity prevents contact damage every frame")
	await _frames(70)
	# The actual attack Area2D must hit once, and only once, per swing.
	var walker := _game.enemy
	walker.target = null
	walker.patrol_speed = 0
	walker.position = Vector2(1400, 840)
	_player.respawn(Vector2(1347, 840))
	await _frames(4)
	_action(&"move_right", true)
	await _frames(1)
	_action(&"move_right", false)
	_action(&"attack", true)
	await _frames(18)
	_action(&"attack", false)
	_check(walker.health.current == 2, "A real attack overlap applies exactly one damage")
	# Reset spacing between strikes so knockback does not turn the test into a chase.
	for index in range(2):
		await _frames(15)
		walker.position = Vector2(1400, 840)
		walker.velocity = Vector2.ZERO
		_player.respawn(Vector2(1347, 840))
		await _frames(3)
		_action(&"attack", true)
		await _frames(18)
		_action(&"attack", false)
	_check(not is_instance_valid(walker), "Three successful strikes defeat the moss walker")
	_check(_progress().enemy_defeated, "Enemy defeat remains recorded during the expedition")
	# Each required ascending segment is simulated with real input and collisions.
	await _jump_segment(Vector2(1740, 840), Vector2(1840, 740), &"move_right")
	await _jump_segment(Vector2(1920, 740), Vector2(2070, 640), &"move_right")
	await _jump_segment(Vector2(2150, 640), Vector2(2290, 540), &"move_right")
	_player.respawn(Vector2(2400, 540))
	await _frames(4)
	_action(&"move_right", true)
	await _frames(25)
	_action(&"move_right", false)
	await _frames(8)
	_check(_progress().dash_unlocked, "Touching the shrine unlocks dash through the level trigger")
	_check(_progress().checkpoint.x > 2400, "The shrine activates a recovery checkpoint")
	await _jump_segment(Vector2(2450, 540), Vector2(2190, 440), &"move_left", true)
	_player.respawn(Vector2(2540, 540))
	await _frames(4)
	_action(&"move_right", true)
	await _frames(1)
	_action(&"move_right", false)
	_action(&"jump", true)
	await _frames(8)
	_action(&"dash", true)
	await _frames(2)
	_check(_player.dash_remaining > 0, "The unlocked dash activates in midair")
	_player.health.immunity = 0
	_player.take_damage(DamageData.new(1))
	_check(_player.health.current == 5, "Dash invulnerability avoids incoming damage")
	_action(&"dash", false)
	_action(&"jump", false)
	# The wide return gap is unreachable without the newly acquired ability.
	_progress().dash_unlocked = false
	await _cross_return_gap(false)
	_check(
		_player.position.x > 1702 or _player.position.y > 480,
		"The return gap gates ordinary jumping"
	)
	_progress().dash_unlocked = true
	await _cross_return_gap(true)
	_check(
		_player.position.x < 1695 and _player.position.y < 450 and _player.is_on_floor(),
		"Jump plus dash crosses the return gap"
	)
	await _jump_segment(Vector2(1490, 440), Vector2(1280, 480), &"move_left")
	await _jump_segment(Vector2(1170, 480), Vector2(1005, 450), &"move_left")
	await _jump_segment(Vector2(900, 450), Vector2(680, 480), &"move_left")
	await _jump_segment(Vector2(550, 480), Vector2(390, 520), &"move_left")
	_player.respawn(Vector2(2500, 510))
	_player.health.immunity = 0
	_player.take_damage(DamageData.new(5))
	await _frames(45)
	_check(
		not _player.dead and _player.health.current == 5, "Death restores health at the checkpoint"
	)
	_check(
		_progress().dash_unlocked and _progress().enemy_defeated,
		"Death preserves acquired ability and defeated enemy"
	)
	_player.health.immunity = 0
	_player.global_position = Vector2(900, 1090)
	await _frames(4)
	_check(
		_player.health.current == 4 and _player.position.x > 2400,
		"Falling costs one health and returns to the windseed checkpoint"
	)
	_player.health.immunity = 0
	_player.take_damage(DamageData.new(3))
	_player.health.immunity = 0
	_player.global_position = Vector2(900, 1090)
	await _frames(45)
	_check(
		not _player.dead and _player.health.current == 5 and _player.position.x > 2400,
		"A fatal fall completes one death/recovery cycle"
	)
	_player.respawn(Vector2(320, 520))
	await _frames(3)
	_check(
		_progress().beacon_lit and _game.hud.completed,
		"Returning to the lantern completes the playable loop"
	)
	_check(get_tree().paused, "Completion pauses the world for the result screen")
	get_tree().paused = false
	_game.queue_free()
	await get_tree().process_frame
	print("GAMEPLAY SMOKE: %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _measure_jump(short: bool) -> float:
	_player.respawn(Vector2(350, 840))
	await _frames(4)
	var minimum_y := _player.position.y
	_action(&"jump", true)
	for index in range(58):
		await _frames(1)
		minimum_y = minf(minimum_y, _player.position.y)
		if short and index == 4:
			_action(&"jump", false)
	_action(&"jump", false)
	return 840.0 - minimum_y


func _jump_segment(
	start: Vector2, finish: Vector2, direction: StringName, with_dash: bool = false
) -> void:
	_player.respawn(start)
	await _frames(4)
	_action(direction, true)
	_action(&"jump", true)
	for index in range(55):
		if with_dash and index == 16:
			_action(&"dash", true)
		if index == 20:
			_action(&"dash", false)
		await _frames(1)
		var arrived := _player.position.x >= finish.x
		if direction == &"move_left":
			arrived = _player.position.x <= finish.x
		if arrived:
			_action(direction, false)
	_action(direction, false)
	_action(&"jump", false)
	await _frames(15)
	_check(
		_player.is_on_floor() and absf(_player.position.y - finish.y) < 2,
		"Route reaches ledge at %s" % finish
	)


func _cross_return_gap(with_dash: bool) -> void:
	_player.respawn(Vector2(2040, 440))
	await _frames(4)
	_action(&"move_left", true)
	await _frames(1)
	_action(&"jump", true)
	for index in range(65):
		if with_dash and index == 20:
			_action(&"dash", true)
		if index == 24:
			_action(&"dash", false)
		await _frames(1)
		if _player.position.x < 1640:
			_action(&"move_left", false)
	_action(&"jump", false)
	_action(&"move_left", false)


func _progress() -> Node:
	return get_tree().root.get_node("Progress")


func _action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _frames(count: int) -> void:
	for index in range(count):
		await get_tree().physics_frame
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		_failures += 1
		push_error("FAIL: " + message)
