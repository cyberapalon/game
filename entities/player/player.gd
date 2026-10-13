class_name LumenPlayer
extends CharacterBody2D

signal effect_requested(kind: StringName, at: Vector2, direction: float)
signal respawn_requested

@export var speed: float = 285.0
@export var acceleration: float = 2300.0
@export var braking: float = 2700.0
@export var jump_speed: float = 670.0
@export var gravity: float = 1550.0
@export var dash_speed: float = 880.0
@export var dash_duration: float = 0.18

var facing: float = 1.0
var dash_remaining: float = 0.0
var dash_cooldown: float = 0.0
var dead: bool = false
var _air_dash_used: bool = false
var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _dash_buffer: float = 0.0
var _attack_buffer: float = 0.0
var _attack_time: float = 0.0
var _attack_direction: float = 1.0
var _attack_cooldown: float = 0.0
var _stun: float = 0.0
var _trail_time: float = 0.0
var _animation_time: float = 0.0
var _squash := Vector2.ONE
var _hit_targets: Array[Node2D] = []
var _jump_cut: bool = false

@onready var health: HealthComponent = %Health
@onready var _attack: Area2D = %Attack
@onready var _sprite: AnimatedSprite2D = %Sprite


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_attack.body_entered.connect(_hit_enemy)
	_sprite.play(&"idle")


func _process(_delta: float) -> void:
	_sprite.visible = not dead
	if health.immunity > 0.0 and int(_animation_time * 16.0) % 2 == 0:
		_sprite.modulate.a = 0.35
	else:
		_sprite.modulate.a = 1.0
	_sprite.scale = Vector2.ONE * 0.28 * _squash
	_sprite.flip_h = (_attack_direction if _attack_time > 0.0 else facing) < 0.0
	var animation: StringName = &"idle"
	if dash_remaining > 0.0:
		animation = &"dash"
	elif _attack_time > 0.0:
		animation = &"attack"
	elif not is_on_floor():
		animation = &"jump" if velocity.y < 0.0 else &"fall"
	elif absf(velocity.x) > 20.0:
		animation = &"run"
	if _sprite.animation != animation:
		_sprite.play(animation)


func _unhandled_input(event: InputEvent) -> void:
	if dead:
		return
	if event.is_action_pressed(&"jump") and not event.is_echo():
		_jump_buffer = 0.14
		_jump_cut = false
	if event.is_action_released(&"jump"):
		_jump_cut = true
	if event.is_action_pressed(&"dash") and not event.is_echo():
		_dash_buffer = 0.12
	if event.is_action_pressed(&"attack") and not event.is_echo():
		_attack_buffer = 0.15


func _physics_process(delta: float) -> void:
	_animation_time += delta
	_squash = _squash.lerp(Vector2.ONE, 1.0 - exp(-16.0 * delta))
	queue_redraw()
	if dead:
		return
	_jump_buffer -= delta
	_dash_buffer -= delta
	_attack_buffer -= delta
	_attack_cooldown -= delta
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	_stun -= delta
	_coyote = 0.11 if is_on_floor() else _coyote - delta
	if is_on_floor():
		_air_dash_used = false
	var axis := Input.get_axis(&"move_left", &"move_right")
	if axis != 0.0 and dash_remaining <= 0.0 and _stun <= 0.0:
		facing = signf(axis)
	if _dash_buffer > 0.0 and can_dash() and _stun <= 0.0:
		start_dash()
	if _attack_buffer > 0.0 and _attack_cooldown <= 0.0 and dash_remaining <= 0.0 and _stun <= 0.0:
		start_attack()
	_update_attack(delta)
	var was_grounded := is_on_floor()
	var falling_speed := velocity.y
	if dash_remaining > 0.0:
		dash_remaining = maxf(0.0, dash_remaining - delta)
		velocity = Vector2(facing * dash_speed, 0.0)
		_trail_time -= delta
		if _trail_time <= 0.0:
			_trail_time = 0.025
			effect_requested.emit(&"trail", global_position - Vector2(0, 24), facing)
	else:
		if _stun <= 0.0:
			var rate := acceleration if axis != 0.0 else braking
			velocity.x = move_toward(velocity.x, axis * speed, rate * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
		if not is_on_floor():
			velocity.y = minf(velocity.y + gravity * delta, 950.0)
		if _jump_buffer > 0.0 and _coyote > 0.0 and _stun <= 0.0:
			velocity.y = -jump_speed
			_jump_buffer = 0.0
			_coyote = 0.0
			_squash = Vector2(0.8, 1.2)
			effect_requested.emit(&"jump", global_position, facing)
		if _jump_cut and velocity.y < -260.0:
			velocity.y = -260.0
			_jump_cut = false
	move_and_slide()
	if is_on_ceiling():
		velocity.y = maxf(0.0, velocity.y)
	if is_on_wall() and dash_remaining > 0.0:
		dash_remaining = 0.0
	if is_on_floor() and not was_grounded and falling_speed > 180.0:
		_squash = Vector2(1.22, 0.78)
		effect_requested.emit(&"land", global_position, facing)
	if global_position.y > 1080.0:
		respawn_requested.emit()


func can_dash() -> bool:
	return Progress.dash_unlocked and dash_cooldown <= 0.0 and not _air_dash_used and not dead


func start_dash() -> void:
	_dash_buffer = 0.0
	_air_dash_used = true
	dash_remaining = dash_duration
	dash_cooldown = 0.55
	_jump_cut = false
	_attack_time = 0.0
	_attack.set_deferred(&"monitoring", false)
	effect_requested.emit(&"dash", global_position - Vector2(0, 22), facing)


func start_attack() -> void:
	_attack_buffer = 0.0
	_attack_time = 0.22
	_attack_cooldown = 0.34
	_attack_direction = facing
	_hit_targets.clear()
	_attack.position.x = facing * 46.0
	_attack.set_deferred(&"monitoring", true)
	effect_requested.emit(&"swing", global_position - Vector2(0, 24), facing)


func _update_attack(delta: float) -> void:
	if _attack_time <= 0.0:
		return
	_attack_time -= delta
	if _attack.monitoring:
		for body in _attack.get_overlapping_bodies():
			_hit_enemy(body)
	if _attack_time <= 0.0:
		_attack.set_deferred(&"monitoring", false)


func _hit_enemy(body: Node2D) -> void:
	if _attack_time <= 0.0 or _hit_targets.has(body) or not body.has_method(&"take_damage"):
		return
	_hit_targets.append(body)
	body.call(&"take_damage", DamageData.new(1, Vector2(_attack_direction * 240.0, -180.0)))


func take_damage(data: DamageData) -> void:
	if dash_remaining <= 0.0 and not dead:
		health.take_damage(data)


func _on_damaged(data: DamageData) -> void:
	velocity = data.knockback
	_stun = 0.22
	_attack_time = 0.0
	_attack.set_deferred(&"monitoring", false)
	effect_requested.emit(&"hurt", global_position - Vector2(0, 25), facing)


func _on_died() -> void:
	dead = true
	effect_requested.emit(&"death", global_position - Vector2(0, 25), facing)
	await get_tree().create_timer(0.65).timeout
	respawn_requested.emit()


func respawn(at: Vector2, refill: bool = true) -> void:
	global_position = at
	velocity = Vector2.ZERO
	dead = false
	dash_remaining = 0.0
	dash_cooldown = 0.0
	_air_dash_used = false
	_jump_buffer = 0.0
	_dash_buffer = 0.0
	_attack_buffer = 0.0
	_attack_time = 0.0
	_coyote = 0.0
	_stun = 0.0
	_jump_cut = false
	_attack.set_deferred(&"monitoring", false)
	if refill:
		health.restore()
	else:
		health.immunity = 1.0
	reset_physics_interpolation()


func _draw() -> void:
	if dead:
		return
	draw_circle(Vector2(0, -29), 44.0, Color(0.40, 0.85, 0.72, 0.045))
	draw_circle(Vector2(0, -29), 28.0, Color(0.40, 0.85, 0.72, 0.06))
	if is_on_floor():
		draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, 16.0, Color(0.01, 0.03, 0.035, 0.4))
		draw_set_transform(Vector2.ZERO)
