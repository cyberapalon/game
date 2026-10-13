extends Node
## Session progression survives death. A new expedition explicitly resets it.

signal changed

var dash_unlocked: bool = false
var beacon_lit: bool = false
var enemy_defeated: bool = false
var checkpoint := Vector2(220, 810)
var reduced_motion: bool = false


func unlock_dash() -> void:
	dash_unlocked = true
	checkpoint = Vector2(2500, 510)
	changed.emit()


func reset() -> void:
	dash_unlocked = false
	beacon_lit = false
	enemy_defeated = false
	checkpoint = Vector2(220, 810)
	changed.emit()
