class_name FarmerControls
extends Control

signal look_changed(motion: Vector2)
var movement := Vector2.ZERO
var enabled := false
var joystick_finger := -1
var look_finger := -1
var stick_origin := Vector2.ZERO
var stick_tip := Vector2.ZERO
var mouse_look := false
const RADIUS := 64.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func center() -> Vector2:
	return Vector2(122, size.y - 126)

func clear_input() -> void:
	movement = Vector2.ZERO
	joystick_finger = -1
	look_finger = -1
	mouse_look = false
	queue_redraw()

func set_enabled(value: bool) -> void:
	if enabled != value:
		enabled = value
		clear_input()

func _unhandled_input(event: InputEvent) -> void:
	if not enabled: return
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(center()) < 115 and joystick_finger == -1:
				joystick_finger = event.index
				stick_origin = center()
				update_stick(event.position)
			elif event.position.x > size.x * 0.45 and look_finger == -1:
				look_finger = event.index
		else:
			if event.index == joystick_finger:
				joystick_finger = -1
				movement = Vector2.ZERO
			if event.index == look_finger: look_finger = -1
		queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == joystick_finger: update_stick(event.position)
		elif event.index == look_finger: look_changed.emit(event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		mouse_look = event.pressed
	elif event is InputEventMouseMotion and mouse_look:
		look_changed.emit(event.relative)

func update_stick(pos: Vector2) -> void:
	var offset := (pos - stick_origin).limit_length(RADIUS)
	stick_tip = stick_origin + offset
	movement = offset / RADIUS
	if movement.length() < 0.12: movement = Vector2.ZERO
	queue_redraw()

func _input(event: InputEvent) -> void:
	# Releases must be handled even when a finger moves over a HUD button.
	if event is InputEventScreenTouch and not event.pressed:
		if event.index == joystick_finger:
			joystick_finger = -1
			movement = Vector2.ZERO
		if event.index == look_finger: look_finger = -1
		queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		mouse_look = false

func _draw() -> void:
	if not enabled: return
	var origin := center()
	draw_circle(origin, RADIUS + 9, Color(0.07, 0.17, 0.18, 0.4))
	draw_arc(origin, RADIUS, 0, TAU, 48, Color(1, 0.96, 0.85, 0.6), 2, true)
	draw_circle(stick_tip if joystick_finger != -1 else origin, 27, Color(0.92, 0.91, 0.77, 0.7))
	draw_string(ThemeDB.fallback_font, origin + Vector2(-26, 100), "MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff3db"))
