class_name LumenEffects
extends Node2D


class Mote:
	var point: Vector2
	var velocity: Vector2
	var color: Color
	var life: float
	var maximum: float
	var radius: float
	var gravity: float


var _motes: Array[Mote] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = 20
	_rng.seed = 813


func burst(at: Vector2, color: Color, count: int = 12, force: float = 150.0) -> void:
	for index in range(count):
		if _motes.size() >= 160:
			break
		var mote := Mote.new()
		mote.point = at
		mote.velocity = (
			Vector2.from_angle(_rng.randf_range(-PI, PI)) * _rng.randf_range(force * 0.3, force)
		)
		mote.color = color
		mote.maximum = _rng.randf_range(0.3, 0.7)
		mote.life = mote.maximum
		mote.radius = _rng.randf_range(1.3, 3.3)
		mote.gravity = 110.0
		_motes.append(mote)


func trail(at: Vector2) -> void:
	var mote := Mote.new()
	mote.point = at
	mote.velocity = Vector2.ZERO
	mote.color = Color("84ddc7")
	mote.maximum = 0.22
	mote.life = 0.22
	mote.radius = 15.0
	mote.gravity = 0.0
	_motes.append(mote)


func _process(delta: float) -> void:
	for index in range(_motes.size() - 1, -1, -1):
		var mote := _motes[index]
		mote.life -= delta
		if mote.life <= 0.0:
			_motes.remove_at(index)
			continue
		mote.velocity.y += mote.gravity * delta
		mote.point += mote.velocity * delta
	queue_redraw()


func _draw() -> void:
	for mote in _motes:
		var color := mote.color
		color.a *= mote.life / mote.maximum
		if mote.radius > 8.0:
			color.a *= 0.28
			draw_circle(mote.point, mote.radius, color)
		else:
			draw_line(mote.point, mote.point - mote.velocity * 0.025, color, mote.radius, true)
