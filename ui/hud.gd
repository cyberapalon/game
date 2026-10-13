class_name LumenHud
extends Control

const CREAM := Color("d6ddc5")
const DIM := Color("7a9992")
const GOLD := Color("ccb784")
const MINT := Color("9bd9be")

var player: LumenPlayer
var game: Conservatory
var paused: bool = false
var completed: bool = false
var _font: Font
var _health: int = 5
var _maximum_health: int = 5
var _toast_title: String = ""
var _toast_text: String = ""
var _toast_time: float = 0.0
var _visited_x: float = 220.0
var _resume_button: Button
var _restart_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = ThemeDB.fallback_font
	_resume_button = _make_button("CONTINUE  ·  ESC", _resume)
	_restart_button = _make_button("NEW EXPEDITION  ·  R", _restart)


func bind_player(value: LumenPlayer) -> void:
	player = value
	player.health.changed.connect(_on_health_changed)
	_on_health_changed(player.health.current, player.health.maximum)


func _on_health_changed(current: int, maximum: int) -> void:
	_health = current
	_maximum_health = maximum
	queue_redraw()


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override(&"font_size", 14)
	button.add_theme_color_override(&"font_color", CREAM)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("203c3e")
	style.border_color = Color("617b68")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	button.add_theme_stylebox_override(&"normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("34534d")
	hover.border_color = GOLD
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"focus", hover)
	button.add_theme_stylebox_override(&"pressed", hover)
	button.pressed.connect(callback)
	button.visible = false
	add_child(button)
	return button


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(game) or event.is_echo():
		return
	if event.is_action_pressed(&"restart"):
		_restart()
	elif event.is_action_pressed(&"pause") and not completed:
		game.toggle_pause()
	elif event.is_action_pressed(&"mute"):
		Sound.toggle_mute()
	elif event.is_action_pressed(&"motion"):
		Progress.reduced_motion = not Progress.reduced_motion
		toast(
			(
				"Camera shake and impact freeze are disabled."
				if Progress.reduced_motion
				else "Full movement feedback restored."
			),
			"GENTLE MOTION" if Progress.reduced_motion else "FULL MOTION",
			2.5
		)
	else:
		return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not paused and not completed:
		_toast_time = maxf(0.0, _toast_time - delta)
	if is_instance_valid(player):
		_visited_x = maxf(_visited_x, player.position.x)
	var overlay := paused or completed
	_resume_button.visible = paused and not completed
	_restart_button.visible = overlay
	_resume_button.position = size * 0.5 + Vector2(-155, 52)
	_resume_button.size = Vector2(310, 43)
	_restart_button.position = size * 0.5 + Vector2(-155, 108 if paused and not completed else 65)
	_restart_button.size = Vector2(310, 43)
	queue_redraw()


func toast(message: String, title: String, duration: float = 3.5) -> void:
	_toast_title = title
	_toast_text = message
	_toast_time = duration


func show_completion() -> void:
	completed = true
	paused = false
	get_tree().paused = true


func _resume() -> void:
	if get_tree().paused:
		game.toggle_pause()


func _restart() -> void:
	# Finish dispatching the key/button event before replacing its scene.
	game.restart.call_deferred()


func _draw() -> void:
	if not is_instance_valid(player) or _font == null:
		return
	var width := size.x
	var height := size.y
	draw_rect(Rect2(0, 0, width, 97), Color(0.025, 0.065, 0.08, 0.94))
	draw_line(Vector2(32, 96), Vector2(width - 32, 96), Color(0.47, 0.59, 0.49, 0.3), 1.0, true)
	_text(Vector2(34, 28), "THE KEEPER", 10, DIM)
	for index in range(_maximum_health):
		var p := Vector2(43 + index * 27, 48)
		var color := MINT if index < _health else Color("254044")
		draw_colored_polygon(
			PackedVector2Array(
				[p + Vector2(0, -10), p + Vector2(7, 0), p + Vector2(0, 10), p + Vector2(-7, 0)]
			),
			color
		)
		if index < _health:
			draw_line(p + Vector2(0, -5), p + Vector2(0, 5), Color("e7edc6"), 1, true)
	var ability := "WINDSEED  /  DORMANT"
	if Progress.dash_unlocked:
		ability = "WINDSEED  /  READY" if player.can_dash() else "WINDSEED  /  RECOVERING"
	_text(Vector2(34, 80), ability, 10, MINT if Progress.dash_unlocked else DIM)
	_centered(Vector2(width * 0.5, 44), "L U M E N   H O L L O W", 22, CREAM)
	_centered(
		Vector2(width * 0.5, 68), "T H E   S L E E P I N G   C O N S E R V A T O R Y", 9, GOLD
	)
	var objective := "Find the windseed"
	if Progress.dash_unlocked:
		objective = "Return to the home lantern"
	if Progress.beacon_lit:
		objective = "The garden remembers"
	_text(
		Vector2(width - 280, 31),
		(
			"0%d  /  %s"
			% [
				2 if Progress.dash_unlocked else 1,
				"RETURN" if Progress.dash_unlocked else "EXPLORE"
			]
		),
		10,
		GOLD
	)
	_text(Vector2(width - 280, 56), objective, 16, CREAM)
	_text(
		Vector2(width - 280, 79),
		"M  sound %s     P / ESC  pause" % ["off" if Sound.muted else "on"],
		10,
		DIM
	)
	# A tiny schematic makes the loop and the unexplored route readable.
	var map_origin := Vector2(width - 222, height - 156)
	draw_rect(
		Rect2(map_origin - Vector2(14, 22), Vector2(204, 112)), Color(0.025, 0.065, 0.08, 0.86)
	)
	_text(map_origin - Vector2(0, 4), "CONSERVATORY  /  ROUTE", 9, DIM)
	for rect in Conservatory.PLATFORMS:
		var p := map_origin + Vector2(rect.position.x * 0.061, (rect.position.y - 400) * 0.11)
		var color := Color("547a68") if rect.position.x <= _visited_x + 120 else Color("253d3d")
		draw_line(p, p + Vector2(rect.size.x * 0.061, 0), color, 2.0, true)
	var dot := map_origin + Vector2(player.position.x * 0.061, (player.position.y - 400) * 0.11 - 3)
	draw_circle(dot, 2.8, CREAM)
	draw_circle(map_origin + Vector2(290 * 0.061, 120 * 0.11 - 4), 2.3, GOLD)
	draw_circle(map_origin + Vector2(2520 * 0.061, 140 * 0.11 - 4), 2.3, MINT)
	if _toast_time > 0.0:
		var rect := Rect2(width * 0.5 - 350, 116, 700, 72)
		draw_rect(rect, Color(0.035, 0.10, 0.12, 0.96))
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), GOLD, 1.0, true)
		_centered(Vector2(width * 0.5, 141), _toast_title, 12, GOLD)
		_centered(Vector2(width * 0.5, 168), _toast_text, 15, CREAM)
	var hint := "Follow the small lanterns to the east."
	var heading := "A LIGHT IN THE ROOTS"
	if player.position.x > 1050 and player.position.x < 1690 and not Progress.enemy_defeated:
		heading = "SOMETHING STIRS"
		hint = "J / X to strike. Watch for the amber warning."
	elif Progress.dash_unlocked:
		heading = "THE WAY HOME"
		hint = "Jump, then SHIFT / K across the upper gap."
	elif player.position.x > 1690:
		heading = "THE WINDSEED CALLS"
		hint = "Climb the mossy steps. Touch the floating seed."
	draw_rect(Rect2(32, height - 145, 390, 67), Color(0.025, 0.065, 0.08, 0.82))
	draw_line(Vector2(32, height - 145), Vector2(32, height - 78), GOLD, 2.0, true)
	_text(Vector2(49, height - 121), heading, 10, GOLD)
	_text(Vector2(49, height - 96), hint, 14, CREAM)
	draw_rect(Rect2(0, height - 56, width, 56), Color(0.025, 0.065, 0.08, 0.96))
	draw_line(
		Vector2(32, height - 56),
		Vector2(width - 32, height - 56),
		Color(0.47, 0.59, 0.49, 0.3),
		1.0,
		true
	)
	_centered(
		Vector2(width * 0.5, height - 23),
		(
			"A D / ARROWS   move       SPACE / W   jump       J / X   strike       "
			+ "SHIFT / K   dash       Q   gentle motion       R   restart"
		),
		12,
		DIM
	)
	if paused or completed:
		_draw_overlay()


func _draw_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.055, 0.075, 0.91))
	var center := size * 0.5
	draw_arc(center + Vector2(0, -123), 32, 0, TAU, 48, GOLD, 1.0, true)
	var p := center + Vector2(0, -123)
	draw_colored_polygon(
		PackedVector2Array(
			[p + Vector2(0, -20), p + Vector2(11, 0), p + Vector2(0, 20), p + Vector2(-11, 0)]
		),
		MINT
	)
	_centered(
		center + Vector2(0, -53),
		"THE GARDEN REMEMBERS" if completed else "A MOMENT OF STILLNESS",
		30,
		CREAM
	)
	_centered(
		center + Vector2(0, -13),
		(
			"You carried the windseed home. A small world, awake again."
			if completed
			else "Your light will wait here."
		),
		16,
		DIM
	)
	if completed:
		_centered(
			center + Vector2(0, 22), "PROTOTYPE COMPLETE  /  THANK YOU FOR EXPLORING", 10, GOLD
		)


func _text(at: Vector2, value: String, font_size: int, color: Color) -> void:
	draw_string(_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _centered(at: Vector2, value: String, font_size: int, color: Color) -> void:
	var width := _font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_text(at - Vector2(width * 0.5, 0), value, font_size, color)
