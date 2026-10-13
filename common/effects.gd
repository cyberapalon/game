class_name LumenEffects
extends Node2D

const VFX := preload("res://assets/vfx/garden_frames.tres")
const WALKER := preload("res://assets/characters/moss_walker_frames.tres")
const SPRITE_EFFECT := preload("res://common/sprite_effect.gd")


class Mote:
	var point: Vector2
	var velocity: Vector2
	var color: Color
	var life: float
	var maximum: float
	var radius: float
	var gravity: float
	var texture: Texture2D
	var direction: float = 1.0


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


func trail(at: Vector2, direction: float = 1.0) -> void:
	if _motes.size() >= 160:
		return
	var mote := Mote.new()
	mote.point = at
	mote.velocity = Vector2.ZERO
	mote.color = Color("84ddc7")
	mote.maximum = 0.22
	mote.life = 0.22
	mote.radius = 15.0
	mote.gravity = 0.0
	mote.texture = VFX.get_frame_texture(&"dash", 0)
	mote.direction = direction
	_motes.append(mote)


func animate(kind: StringName, at: Vector2, direction: float = 1.0) -> void:
	var effect := SPRITE_EFFECT.new() as SpriteEffect
	effect.sprite_frames = VFX
	effect.position = at
	effect.flip_h = direction < 0.0
	effect.scale = Vector2.ONE * 0.32
	if kind == &"dust":
		effect.offset.y = -float(VFX.get_frame_texture(kind, 0).get_height()) * 0.43
	elif kind == &"slash":
		effect.scale = Vector2.ONE * 0.36
	add_child(effect)
	effect.play(kind)


func enemy_death(at: Vector2, direction: float) -> void:
	var effect := SPRITE_EFFECT.new() as SpriteEffect
	effect.sprite_frames = WALKER
	effect.position = at
	effect.offset = Vector2(0, -112)
	effect.scale = Vector2.ONE * 0.23
	effect.flip_h = direction < 0.0
	add_child(effect)
	effect.play(&"death")


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
		if mote.texture != null:
			color.a *= 0.28
			draw_set_transform(mote.point, 0.0, Vector2(mote.direction, 1.0))
			draw_texture_rect(mote.texture, Rect2(-42, -22, 84, 44), false, color)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_line(mote.point, mote.point - mote.velocity * 0.025, color, mote.radius, true)
