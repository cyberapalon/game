class_name GardenBackdrop
extends Node2D

var camera: Camera2D


func _ready() -> void:
	z_index = -20
	queue_redraw()


func _process(_delta: float) -> void:
	if is_instance_valid(camera):
		position = camera.get_screen_center_position() * Vector2(0.12, 0.06)


func _draw() -> void:
	draw_rect(Rect2(-1300, -1000, 6000, 2800), Color("08171f"))
	# Layered architectural silhouettes, with restrained painted light shafts.
	for index in range(12):
		var x := -700.0 + index * 410.0
		draw_rect(Rect2(x, 240, 48, 850), Color("102a32"))
		draw_rect(Rect2(x + 7, 245, 9, 850), Color("19343a"))
		draw_arc(Vector2(x + 229, 615), 205, PI, TAU, 48, Color("163139"), 33.0, true)
		draw_arc(Vector2(x + 229, 615), 182, PI, TAU, 48, Color("203d40"), 2.0, true)
		draw_rect(Rect2(x + 185, 120, 3, 560), Color("123038"))
		draw_line(Vector2(x + 48, 350), Vector2(x + 410, 350), Color("16343a"), 8.0, true)
		draw_line(Vector2(x + 48, 570), Vector2(x + 410, 570), Color("112a32"), 5.0, true)
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(x + 100, 130),
					Vector2(x + 155, 100),
					Vector2(x + 450, 930),
					Vector2(x + 180, 930)
				]
			),
			Color(0.36, 0.65, 0.59, 0.022)
		)
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(x + 110, 140),
					Vector2(x + 133, 125),
					Vector2(x + 300, 850),
					Vector2(x + 210, 850)
				]
			),
			Color(0.49, 0.72, 0.60, 0.025)
		)
	var rng := RandomNumberGenerator.new()
	rng.seed = 419
	for index in range(54):
		var x := rng.randf_range(-600, 3500)
		var height := rng.randf_range(70, 240)
		var y := rng.randf_range(850, 1040)
		var color := Color("102930") if index % 2 == 0 else Color("173238")
		var stem := PackedVector2Array(
			[Vector2(x, y), Vector2(x - 12, y - height * 0.55), Vector2(x + 7, y - height)]
		)
		draw_polyline(stem, color, 4.0, true)
		for leaf in range(5):
			var ly := y - height * (0.2 + leaf * 0.13)
			var side := -1.0 if leaf % 2 == 0 else 1.0
			draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(x - 5, ly + 10),
						Vector2(x + side * 40, ly - 25),
						Vector2(x + side * 24, ly + 6)
					]
				),
				color
			)
	for index in range(19):
		var x := -200.0 + index * 187.0
		var length := rng.randf_range(80, 240)
		var points := PackedVector2Array()
		for step in range(18):
			points.append(Vector2(x + sin(step * 0.55 + index) * 15, -80 + step * length / 17))
		draw_polyline(points, Color("1b3d3d"), 3.0, true)
		for leaf in range(6):
			var p := points[leaf * 2 + 4]
			draw_circle(p + Vector2(8, 3), 5, Color("24483f"))
