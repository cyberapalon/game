class_name MossWalker
extends CharacterBody2D

signal effect_requested(kind: StringName, at: Vector2, direction: float)
signal defeated

enum State { PATROL, WINDUP, LUNGE, REST, STUNNED }

@export var patrol_left: float = 1190.0
@export var patrol_right: float = 1570.0
@export var patrol_speed: float = 72.0
var target: LumenPlayer

var _state: State = State.PATROL
var _timer: float = 0.0
var _direction: float = -1.0
var _time: float = 0.0
var _dead: bool = false

@onready var health: HealthComponent = %Health
@onready var _contact: Area2D = %Contact
@onready var _sprite: AnimatedSprite2D = %Sprite


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_sprite.play(&"idle")


func _process(_delta: float) -> void:
	_sprite.flip_h = _direction < 0.0
	var animation: StringName = &"idle"
	if _state == State.STUNNED:
		animation = &"hit"
	elif absf(velocity.x) > 15.0:
		animation = &"move"
	if _sprite.animation != animation:
		_sprite.play(animation)
	_sprite.speed_scale = 1.8 if _state == State.LUNGE else 1.0
	_sprite.modulate = Color("ffe0a5") if _state == State.WINDUP else Color.WHITE


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_time += delta
	_timer -= delta
	if not is_on_floor():
		velocity.y = minf(velocity.y + 1550.0 * delta, 900.0)
	match _state:
		State.PATROL:
			if position.x <= patrol_left:
				_direction = 1.0
			elif position.x >= patrol_right:
				_direction = -1.0
			velocity.x = _direction * patrol_speed
			if is_instance_valid(target) and not target.dead:
				var distance := target.global_position - global_position
				if absf(distance.x) < 150.0 and absf(distance.y) < 55.0:
					_direction = 1.0 if distance.x > 0.0 else -1.0
					_state = State.WINDUP
					_timer = 0.48
		State.WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
			if _timer <= 0.0:
				_state = State.LUNGE
				_timer = 0.32
		State.LUNGE:
			velocity.x = _direction * 260.0
			if _timer <= 0.0 or position.x < patrol_left - 45.0 or position.x > patrol_right + 45.0:
				_state = State.REST
				_timer = 0.8
		State.REST:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_state = State.PATROL
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 550.0 * delta)
			if _timer <= 0.0:
				_state = State.REST
				_timer = 0.35
	move_and_slide()
	for body in _contact.get_overlapping_bodies():
		if body is LumenPlayer and _state != State.STUNNED:
			var away := signf(body.global_position.x - global_position.x)
			if away == 0.0:
				away = _direction
			body.take_damage(DamageData.new(1, Vector2(away * 330.0, -320.0)))
	queue_redraw()


func take_damage(data: DamageData) -> void:
	if not _dead:
		health.take_damage(data)


func _on_damaged(data: DamageData) -> void:
	velocity = data.knockback
	_state = State.STUNNED
	_timer = 0.25
	effect_requested.emit(&"hit", global_position - Vector2(0, 24), _direction)


func _on_died() -> void:
	_dead = true
	Progress.enemy_defeated = true
	%BodyShape.set_deferred(&"disabled", true)
	_contact.set_deferred(&"monitoring", false)
	effect_requested.emit(&"enemy_death", global_position - Vector2(0, 22), _direction)
	defeated.emit()
	queue_free()


func _draw() -> void:
	if _state == State.WINDUP:
		draw_arc(Vector2(0, -24), 42, PI, TAU, 24, Color(0.95, 0.54, 0.35, 0.8), 2.0, true)
		draw_line(Vector2(0, -73), Vector2(0, -64), Color("f2b27b"), 3.0, true)
		draw_circle(Vector2(0, -59), 1.8, Color("f2b27b"))
	if health.current < health.maximum:
		for index in range(health.maximum):
			draw_circle(
				Vector2(-10 + index * 10, -66),
				2.6,
				Color("d2c89a") if index < health.current else Color("344b4d")
			)
