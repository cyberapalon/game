class_name SpriteEffect
extends AnimatedSprite2D
## Disposable visual only: never owns damage, movement, or entity lifetime.


func _ready() -> void:
	animation_finished.connect(queue_free)


func _process(_delta: float) -> void:
	var count := sprite_frames.get_frame_count(animation)
	if frame == count - 1:
		modulate.a = 1.0 - frame_progress
