class_name DamageData
extends RefCounted

var amount: int
var knockback: Vector2


func _init(value: int = 1, impulse: Vector2 = Vector2.ZERO) -> void:
	amount = value
	knockback = impulse
