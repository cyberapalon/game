class_name Conservatory
extends Node2D

const PLATFORM_SCRIPT := preload("res://levels/conservatory/stone_platform.gd")
const BACKDROP_SCRIPT := preload("res://levels/conservatory/backdrop.gd")
const EFFECTS_SCRIPT := preload("res://common/effects.gd")
const HOME_ART := preload("res://assets/environment/prop_0_3.tres")
const SEED_ART := preload("res://assets/environment/prop_1_3.tres")
const FERN_ART := preload("res://assets/environment/prop_0_2.tres")
const MUSHROOM_ART := preload("res://assets/environment/prop_1_2.tres")
const COLUMN_ART := preload("res://assets/environment/prop_3_2.tres")
const ARCH_ART := preload("res://assets/environment/prop_2_3.tres")
const FLOWER_ART := preload("res://assets/environment/prop_3_3.tres")
const SHRINE := Vector2(2520, 540)
const BEACON := Vector2(290, 520)
const PLATFORMS: Array[Rect2] = [
	Rect2(-100, 840, 920, 350),
	Rect2(1000, 840, 1920, 350),
	Rect2(530, 740, 170, 38),
	Rect2(790, 650, 160, 38),
	Rect2(1030, 720, 130, 36),
	Rect2(1770, 740, 180, 38),
	Rect2(2000, 640, 180, 38),
	Rect2(2220, 540, 200, 44),
	Rect2(2440, 540, 270, 44),
	Rect2(2030, 440, 210, 40),
	Rect2(1460, 440, 230, 40),
	Rect2(1140, 480, 200, 40),
	Rect2(870, 450, 180, 40),
	Rect2(520, 480, 210, 40),
	Rect2(180, 520, 230, 50)
]

var _effects: LumenEffects
var _time: float = 0.0
var _trauma: float = 0.0
var _hit_stop_active: bool = false
var _respawning: bool = false
var _intro_time: float = 9.0
var _visibility_callback: JavaScriptObject

@onready var player: LumenPlayer = %Player
@onready var enemy: MossWalker = %MossWalker
@onready var camera: Camera2D = %Camera
@onready var hud: LumenHud = %Hud


func _enter_tree() -> void:
	_configure_input()


func _ready() -> void:
	for index in range(PLATFORMS.size()):
		var rect := PLATFORMS[index]
		var platform := PLATFORM_SCRIPT.new() as StonePlatform
		platform.name = "Stone%02d" % index
		platform.position = rect.position
		platform.size = rect.size
		platform.ground = index < 2
		add_child(platform)
	_add_boundary(Vector2(-40, 500), Vector2(80, 1400))
	_add_boundary(Vector2(2860, 500), Vector2(80, 1400))
	var backdrop := BACKDROP_SCRIPT.new() as GardenBackdrop
	backdrop.camera = camera
	add_child(backdrop)
	_effects = EFFECTS_SCRIPT.new() as LumenEffects
	add_child(_effects)
	player.effect_requested.connect(_on_effect)
	player.respawn_requested.connect(_respawn)
	enemy.effect_requested.connect(_on_effect)
	enemy.target = player
	enemy.defeated.connect(
		func() -> void: hud.toast("The garden grows quiet.", "MOSS WALKER DEFEATED")
	)
	hud.bind_player(player)
	hud.game = self
	Progress.changed.connect(_on_progress_changed)
	player.respawn(Progress.checkpoint)
	# Native focus notifications cover desktop; visibilitychange also covers browser tabs.
	if OS.has_feature("web"):
		_visibility_callback = JavaScriptBridge.create_callback(_on_visibility_changed)
		var window := JavaScriptBridge.get_interface("window")
		window.lumenVisibility = _visibility_callback
		(
			JavaScriptBridge
			. eval(
				"""
			window.lumenOnVisibility = () => window.lumenVisibility(document.hidden);
			document.addEventListener('visibilitychange', window.lumenOnVisibility);
			window.lumenOnKey = e => {
				if (['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.code))
					e.preventDefault();
			};
			document.querySelector('canvas').addEventListener('keydown', window.lumenOnKey);
		"""
			)
		)
	queue_redraw()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	if OS.has_feature("web"):
		(
			JavaScriptBridge
			. eval(
				"""
			document.removeEventListener('visibilitychange', window.lumenOnVisibility);
			document.querySelector('canvas').removeEventListener('keydown', window.lumenOnKey);
			window.lumenVisibility = null;
		"""
			)
		)


func _configure_input() -> void:
	var bindings: Dictionary[StringName, Array] = {
		&"move_left": [KEY_A, KEY_LEFT],
		&"move_right": [KEY_D, KEY_RIGHT],
		&"jump": [KEY_SPACE, KEY_W, KEY_UP],
		&"dash": [KEY_SHIFT, KEY_K],
		&"attack": [KEY_J, KEY_X],
		&"pause": [KEY_ESCAPE, KEY_P],
		&"restart": [KEY_R],
		&"mute": [KEY_M],
		&"motion": [KEY_Q]
	}
	for action: StringName in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)


func _add_boundary(at: Vector2, dimensions: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	var collider := CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)
	add_child(body)


func _physics_process(_delta: float) -> void:
	if player.dead or _respawning:
		return
	if (
		not Progress.dash_unlocked
		and player.global_position.distance_to(SHRINE - Vector2(0, 25)) < 65.0
	):
		Progress.unlock_dash()
		player.health.restore()
		_on_effect(&"pickup", SHRINE - Vector2(0, 55), 1.0)
		hud.toast(
			"SHIFT / K  ·  Dash through the air. Return by the upper path.",
			"THE WINDSEED AWAKENS",
			6.5
		)
	if (
		Progress.dash_unlocked
		and not Progress.beacon_lit
		and player.global_position.distance_to(BEACON) < 65.0
	):
		Progress.beacon_lit = true
		Progress.changed.emit()
		_on_effect(&"beacon", BEACON - Vector2(0, 70), 1.0)
		hud.show_completion()


func _process(delta: float) -> void:
	_time += delta
	_intro_time -= delta
	var look := player.facing * 75.0 if absf(player.velocity.x) > 30.0 else 0.0
	camera.position = player.position + Vector2(look, -160.0)
	_trauma = maxf(0.0, _trauma - delta * 2.8)
	var shake := 0.0 if Progress.reduced_motion else _trauma * _trauma
	camera.offset = Vector2(sin(_time * 73.0) * 12.0, cos(_time * 89.0) * 7.0) * shake
	queue_redraw()


func _on_progress_changed() -> void:
	queue_redraw()


func _on_effect(kind: StringName, at: Vector2, direction: float) -> void:
	Sound.play(kind)
	match kind:
		&"trail":
			_effects.trail(at, direction)
		&"jump", &"land":
			_effects.burst(at, Color("99b69a"), 7, 90.0)
			_effects.animate(&"dust", at)
		&"swing":
			_effects.animate(&"slash", at + Vector2(direction * 29, -4), direction)
		&"dash":
			_effects.burst(at, Color("8ce2c7"), 13, 180.0)
			_effects.animate(&"dash", at, direction)
		&"hit":
			_effects.burst(at, Color("e9cd88"), 15, 230.0)
			_effects.animate(&"impact", at)
			_trauma = minf(1.0, _trauma + 0.38)
			_hit_stop()
		&"hurt", &"death":
			_effects.burst(at, Color("e4a57b"), 20, 230.0)
			_trauma = minf(1.0, _trauma + 0.6)
		&"enemy_death":
			_effects.burst(at, Color("b8cf96"), 30, 230.0)
			_effects.enemy_death(at + Vector2(0, 22), direction)
			_trauma = minf(1.0, _trauma + 0.5)
		&"pickup", &"beacon":
			_effects.burst(at, Color("f0d39a"), 45, 270.0)
			_trauma = minf(1.0, _trauma + 0.25)


func _hit_stop() -> void:
	if _hit_stop_active or Progress.reduced_motion:
		return
	_hit_stop_active = true
	Engine.time_scale = 0.12
	await get_tree().create_timer(0.045, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false


func _respawn() -> void:
	if _respawning:
		return
	_respawning = true
	var refill := player.dead
	if not refill:
		player.health.take_damage(DamageData.new(1))
		if player.dead:
			# The death animation owns the next respawn; avoid scheduling it twice.
			_respawning = false
			return
	player.respawn(Progress.checkpoint, refill)
	camera.position = player.position + Vector2(0, -160)
	camera.reset_smoothing()
	hud.toast("Your light returns to the last sanctuary.", "A NEW BREATH", 2.7)
	_respawning = false


func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	hud.paused = get_tree().paused
	Sound.set_process_mode(Node.PROCESS_MODE_PAUSABLE)


func restart() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	Progress.reset()
	get_tree().reload_current_scene()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud):
		get_tree().paused = true
		hud.paused = true


func _on_visibility_changed(arguments: Array) -> void:
	if not arguments.is_empty() and bool(arguments[0]):
		get_tree().paused = true
		hud.paused = true


func _draw() -> void:
	var font := ThemeDB.fallback_font
	# Low pools below the broken causeway; mist makes the hazard legible.
	draw_rect(Rect2(820, 983, 180, 130), Color("153d44"))
	for index in range(12):
		var x := 825.0 + index * 16.0
		draw_colored_polygon(
			PackedVector2Array([Vector2(x, 1040), Vector2(x + 7, 1003), Vector2(x + 15, 1040)]),
			Color("699080")
		)
	for index in range(4):
		var y := 994.0 + index * 12.0
		draw_line(Vector2(822, y), Vector2(998, y), Color(0.4, 0.7, 0.66, 0.15), 1.0, true)
	_draw_sanctuary(BEACON, Progress.beacon_lit, false)
	_draw_sanctuary(SHRINE, not Progress.dash_unlocked, true)
	_draw_sign(Vector2(380, 825), "THE WINDSEED", true)
	_draw_sign(Vector2(1720, 824), "FOLLOW THE GLOW", true)
	_draw_sign(Vector2(2170, 425), "JUMP + DASH", false)
	# Carved route markers along the return path.
	for x in [580, 960, 1230, 1570]:
		draw_line(Vector2(x + 12, 417), Vector2(x - 12, 417), Color("607d70"), 1.5, true)
		draw_line(Vector2(x - 12, 417), Vector2(x - 5, 411), Color("607d70"), 1.5, true)
		draw_line(Vector2(x - 12, 417), Vector2(x - 5, 423), Color("607d70"), 1.5, true)
	# Original mushrooms and ferns placed away from landing edges.
	for x in [90, 440, 700, 1100, 1620, 1930, 2320, 2720]:
		_draw_plant(Vector2(x, 840), float(x) * 0.01)
	for x in [45, 1690, 2770]:
		draw_texture_rect(COLUMN_ART, Rect2(x - 60, 651, 120, 189), false, Color(0.65, 0.78, 0.75))
	draw_texture_rect(ARCH_ART, Rect2(1635, 615, 180, 225), false, Color(0.58, 0.72, 0.69))
	draw_texture_rect(FLOWER_ART, Rect2(2360, 773, 76, 67), false)
	for index in range(64):
		var x := fposmod(index * 137.53 + sin(_time * 0.19 + index) * 24.0, 2800.0)
		var y := 250.0 + fposmod(index * 83.7 - _time * (4.0 + index % 3), 650.0)
		var alpha := 0.15 + 0.25 * (0.5 + 0.5 * sin(_time * 1.4 + index))
		draw_circle(Vector2(x, y), 1.5 if index % 3 == 0 else 0.9, Color(0.65, 0.85, 0.68, alpha))
	if _intro_time > 0.0 and player.position.x < 520:
		var alpha := clampf(_intro_time / 2.0, 0.0, 1.0)
		draw_string(
			font,
			Vector2(85, 701),
			"A garden forgot the sun.",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			Color(0.73, 0.80, 0.72, alpha)
		)
		draw_string(
			font,
			Vector2(85, 729),
			"Carry its last light home.",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			Color(0.46, 0.62, 0.59, alpha)
		)


func _draw_sanctuary(at: Vector2, active: bool, seed: bool) -> void:
	var art: Texture2D = SEED_ART if seed and active else HOME_ART
	draw_texture_rect(art, Rect2(at - Vector2(80, 165), Vector2(160, 165)), false)
	var glow := Color("9edfc1") if seed else Color("edcb87")
	var center := at + Vector2(0, -76 + sin(_time * 2.0) * 2.0)
	if active:
		for index in range(5, 0, -1):
			var color := glow
			color.a = 0.012 + (5 - index) * 0.006
			draw_circle(center, index * 21.0, color)
		if not seed:
			draw_colored_polygon(
				PackedVector2Array(
					[
						center + Vector2(0, -18),
						center + Vector2(10, 0),
						center + Vector2(0, 18),
						center + Vector2(-10, 0)
					]
				),
				glow
			)
	var label := "WINDSEED" if seed else "THE HOME LANTERN"
	var width := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(
		ThemeDB.fallback_font,
		at + Vector2(-width / 2, -177),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		12,
		Color("a7b89b")
	)


func _draw_sign(at: Vector2, text: String, right: bool) -> void:
	draw_line(at, at + Vector2(0, -55), Color("56716a"), 2.0, true)
	var side := 1.0 if right else -1.0
	draw_line(at + Vector2(0, -45), at + Vector2(side * 35, -45), Color("b5b184"), 1.5, true)
	draw_line(
		at + Vector2(side * 35, -45), at + Vector2(side * 27, -51), Color("b5b184"), 1.5, true
	)
	draw_string(
		ThemeDB.fallback_font,
		at + Vector2(-48, -65),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		Color("8b9d88")
	)


func _draw_plant(at: Vector2, phase: float) -> void:
	var sway := 0.0 if Progress.reduced_motion else sin(_time * 1.2 + phase) * 1.4
	draw_texture_rect(FERN_ART, Rect2(at + Vector2(-47 + sway, -64), Vector2(81, 64)), false)
	draw_texture_rect(MUSHROOM_ART, Rect2(at + Vector2(7, -66), Vector2(60, 66)), false)
	draw_circle(at + Vector2(34, -38), 31, Color(0.4, 0.8, 0.6, 0.028))
