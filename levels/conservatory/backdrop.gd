class_name GardenBackdrop
extends Node2D

const DEPTH := preload("res://assets/backgrounds/conservatory_depth.png")
const ROOTS := preload("res://assets/backgrounds/conservatory_roots.png")

var camera: Camera2D


func _ready() -> void:
	z_index = -30
	_add_layer("DistantGlasshouse", DEPTH, Vector2(0.20, 0.15), Color(0.82, 0.91, 0.95, 1))
	_add_layer("HangingRoots", ROOTS, Vector2(0.55, 0.30), Color(0.65, 0.77, 0.79, 0.42))


func _add_layer(layer_name: String, texture: Texture2D, speed: Vector2, tint: Color) -> void:
	var layer := Parallax2D.new()
	layer.name = layer_name
	layer.scroll_scale = speed
	layer.repeat_size = Vector2(texture.get_width(), 0)
	layer.repeat_times = 2
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.modulate = tint
	layer.add_child(sprite)
	add_child(layer)
