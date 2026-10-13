class_name StonePlatform
extends StaticBody2D

@export var size := Vector2(180, 40)
@export var ground: bool = false


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = size * 0.5
	add_child(collider)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("142b32"))
	draw_rect(Rect2(0, 5, size.x, minf(27, size.y - 5)), Color("2a4648"))
	draw_line(Vector2(0, 2), Vector2(size.x, 2), Color("7b9c83"), 3.0, true)
	draw_line(Vector2(0, 7), Vector2(size.x, 7), Color("3f6b60"), 3.0, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x * 31.0 + position.y * 17.0)
	for index in range(int(size.x / 32)):
		var x := 12.0 + index * 32.0
		var y := rng.randf_range(12, minf(size.y - 3, 26))
		draw_line(
			Vector2(x, y), Vector2(x + rng.randf_range(10, 23), y), Color("3e5652"), 1.0, true
		)
		if index % 3 == 0:
			draw_line(Vector2(x, 9), Vector2(x - 4, minf(size.y, 33)), Color("142e34"), 1.5, true)
	for index in range(int(size.x / 17)):
		var x := 5.0 + index * 17.0
		var height := rng.randf_range(3, 11)
		draw_line(Vector2(x, 1), Vector2(x - 4, -height), Color("547b65"), 1.5, true)
		draw_line(Vector2(x + 3, 1), Vector2(x + 6, -height * 0.7), Color("749376"), 1.2, true)
		if index % 7 == 0:
			draw_circle(Vector2(x - 4, -height - 2), 2.1, Color("b4c699"))
	if not ground:
		for index in range(int(size.x / 55)):
			var x := 18.0 + index * 55.0
			var length := rng.randf_range(18, 70)
			var line := PackedVector2Array(
				[
					Vector2(x, size.y),
					Vector2(x + 4, size.y + length * 0.45),
					Vector2(x - 5, size.y + length)
				]
			)
			draw_polyline(line, Color("315b51"), 2.0, true)
			draw_circle(Vector2(x - 5, size.y + length), 2.0, Color("6ca98b"))
