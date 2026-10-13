class_name HealthComponent
extends Node

signal changed(current: int, maximum: int)
signal damaged(data: DamageData)
signal died

@export var maximum: int = 5
@export var immunity_duration: float = 1.0
var current: int = 5
var immunity: float = 0.0


func _ready() -> void:
	current = maximum


func _physics_process(delta: float) -> void:
	immunity = maxf(0.0, immunity - delta)


func take_damage(data: DamageData) -> bool:
	if immunity > 0.0 or current <= 0:
		return false
	current = maxi(0, current - data.amount)
	immunity = immunity_duration
	damaged.emit(data)
	changed.emit(current, maximum)
	if current == 0:
		died.emit()
	return true


func restore() -> void:
	current = maximum
	immunity = 1.0
	changed.emit(current, maximum)
