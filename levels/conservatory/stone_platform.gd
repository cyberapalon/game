class_name StonePlatform
extends StaticBody2D

const STONES := preload("res://assets/environment/conservatory_tileset.tres")
const IVY := preload("res://assets/environment/prop_2_2.tres")

@export var size := Vector2(180, 40)
@export var ground: bool = false


func _ready() -> void:
	# Tile art has no physics; the exact-size collision stays authoritative.
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = size * 0.5
	add_child(collider)
	var columns := maxi(2, ceili(size.x / 64.0))
	var rows := maxi(1, ceili(size.y / 64.0)) if ground else 1
	var cell := size / Vector2(columns, rows)
	var tiles := TileMapLayer.new()
	tiles.name = "PaintedStones"
	tiles.tile_set = STONES
	tiles.collision_enabled = false
	tiles.scale = cell / 256.0
	for y in range(rows):
		for x in range(columns):
			var tile_x := 1 + x % 2
			if y == 0 and x == 0:
				tile_x = 0
			elif y == 0 and x == columns - 1:
				tile_x = 3
			elif y > 0:
				tile_x = (x + y) % 4
			tiles.set_cell(Vector2i(x, y), 0, Vector2i(tile_x, 0 if y == 0 else 1))
	add_child(tiles)
	if not ground:
		for index in range(maxi(1, int(size.x / 100.0))):
			var vine := Sprite2D.new()
			vine.texture = IVY
			vine.centered = false
			vine.scale = Vector2(0.13, 0.23 + index % 2 * 0.04)
			vine.position = Vector2(18 + index * 95, size.y - 4)
			vine.modulate = Color(0.65, 0.85, 0.77, 0.85)
			add_child(vine)
	queue_redraw()


func _draw() -> void:
	# A bright rim marks the exact gameplay surface in the painted scene.
	draw_line(Vector2.ZERO, Vector2(size.x, 0), Color(0.51, 0.68, 0.56, 0.6), 1.0, true)
