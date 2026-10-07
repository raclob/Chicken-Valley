extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run_checks")

func wait_frames(count: int) -> void:
	for i in count:
		await physics_frame

func run_checks() -> void:
	var scene = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	await wait_frames(3)
	check(scene.camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Third person uses perspective camera")
	check(scene.farmer is CharacterBody3D, "Farmer uses a physical character controller")
	scene.intro.hide()
	scene.paused = false
	scene.update_ui()
	await wait_frames(15)
	check(scene.farmer.is_on_floor(), "Farmer stands on farm ground")
	var start: Vector3 = scene.farmer.position
	scene.controls.movement = Vector2(0, -1)
	await wait_frames(30)
	check(scene.farmer.position.z < start.z - 1, "Thumbstick moves farmer forward")
	scene.controls.movement = Vector2.ZERO
	scene.farmer.position = Vector3(-10, 0.15, -3.0)
	scene.controls.movement = Vector2(0, -1)
	await wait_frames(60)
	check(scene.farmer.position.z > -4.2, "Farmer cannot walk through barn")
	scene.controls.movement = Vector2.ZERO
	scene.turn_camera(Vector2(80, 0))
	check(scene.camera_yaw < -0.3, "Camera drag rotates around farmer")
	scene.turn_camera(Vector2(0, 10000))
	check(is_equal_approx(scene.camera_pitch, -0.65), "Camera pitch is clamped")
	scene.camera_yaw = PI / 2
	scene.camera_pitch = -0.22
	scene.farmer.reset_farmer()
	scene.controls.movement = Vector2(0, -1)
	await wait_frames(30)
	check(scene.farmer.position.x < -11, "Movement follows camera direction")
	scene.paused = true
	scene.update_ui()
	await wait_frames(3)
	start = scene.farmer.position
	await wait_frames(15)
	check(scene.farmer.position.distance_to(start) < 0.03, "Pause stops farmer movement")
	check(scene.controls.movement == Vector2.ZERO, "Pause clears touch movement")
	scene.paused = false
	scene.update_ui()
	var touch := InputEventScreenTouch.new()
	touch.index = 7
	touch.pressed = true
	touch.position = scene.controls.center()
	scene.controls._unhandled_input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.position = scene.controls.center() + Vector2(64, 0)
	scene.controls._unhandled_input(drag)
	check(scene.controls.movement.x > 0.9, "Touch drag operates joystick")
	touch.pressed = false
	touch.position = Vector2(0, 0)
	scene.controls._input(touch)
	check(scene.controls.movement == Vector2.ZERO, "Finger release over HUD clears joystick")
	scene.action_panel.show()
	scene.update_ui()
	check(not scene.controls.enabled, "Action panel suspends farmer input")
	scene.queue_free()
	await process_frame
	print("Third-person integration tests: %s" % ("PASS" if failures == 0 else "%d FAILURES" % failures))
	quit(0 if failures == 0 else 1)
