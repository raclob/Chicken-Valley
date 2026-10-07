extends Node3D

var game := FarmMatch.new()
var birds: Array[Node3D] = []
var buildings: Array[Node3D] = []
var raider_nodes: Dictionary = {}
var stats: Label
var enemy_stats: Label
var timer_label: Label
var notice_label: Label
var result_panel: PanelContainer
var result_label: Label
var buttons: Dictionary = {}
var clock := 0.0
var refresh := 0.0
var paused := true
var pause_button: Button
var intro: PanelContainer
var farmer: ValleyFarmer
var camera_pivot: Node3D
var camera: Camera3D
var controls: FarmerControls
var action_panel: PanelContainer
var farm_button: Button
var camera_yaw := 0.0
var camera_pitch := -0.22
var preview_mode := false
var preview_frames := 0

func _ready() -> void:
	build_world()
	build_farmer()
	build_ui()
	update_ui()
	sync_farms()
	preview_mode = "--preview" in OS.get_cmdline_user_args()
	if preview_mode:
		intro.hide()
		paused = false
		game.farms[0].fence = 1
		game.farms[0].coops = 2
		sync_farms()
		update_ui()

func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	return m

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = material(color)
	n.position = pos
	parent.add_child(n)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		n.add_child(body)
	return n

func sphere(parent: Node3D, pos: Vector3, scale_v: Vector3, color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = 12
	mesh.rings = 6
	n.mesh = mesh
	n.material_override = material(color)
	n.scale = scale_v
	n.position = pos
	parent.add_child(n)
	return n

func build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("76b3dd")
	sky_material.sky_horizon_color = Color("d4e8ea")
	sky_material.ground_horizon_color = Color("c8debf")
	sky_material.ground_bottom_color = Color("669151")
	sky.sky_material = sky_material
	e.sky = sky
	e.fog_enabled = true
	e.fog_light_color = Color("cadfd5")
	e.fog_density = 0.003
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("fff0d5")
	e.ambient_light_energy = 0.65
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	box(self, Vector3(0, -0.5, 0), Vector3(180, 0.1, 180), Color("719b53"))
	box(self, Vector3(0, -0.4, 0), Vector3(34, 0.8, 21), Color("78aa59"), true)
	box(self, Vector3(0, 0.015, 0), Vector3(5, 0.08, 21), Color("ddc798"))
	for side in 2:
		var x := -10.0 if side == 0 else 10.0
		box(self, Vector3(x, 0.03, 1), Vector3(12, 0.12, 13), Color("aacb70"), true)
		var barn := Node3D.new()
		add_child(barn)
		barn.position = Vector3(x, 0, -6)
		box(barn, Vector3(0, 1.4, 0), Vector3(4.5, 2.8, 3.2), Color("287a91") if side == 0 else Color("d26b50"), true)
		for roof_side in [-1, 1]:
			var roof := box(barn, Vector3(roof_side * 1.15, 3.17, 0), Vector3(2.65, 0.25, 3.8), Color("40494f"))
			roof.rotation_degrees.z = -roof_side * 25
		box(barn, Vector3(0, 0.9, 1.64), Vector3(1.2, 1.8, 0.1), Color("f3dda5"))
		for dx in [-1.6, 1.6]:
			box(barn, Vector3(dx, 1.7, 1.65), Vector3(0.65, 0.7, 0.1), Color("c3eef0"))
		var title := Label3D.new()
		title.text = "YOUR FARM" if side == 0 else "RIVAL FARM"
		title.position = Vector3(x, 4.6, -6)
		title.font_size = 48
		title.pixel_size = 0.012
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(title)
		var flock := Node3D.new()
		add_child(flock)
		birds.append(flock)
		var structures := Node3D.new()
		add_child(structures)
		buildings.append(structures)
	for i in 14:
		var x := -15.8 if i % 2 == 0 else 15.8
		var z := -8.0 + (i / 2) * 2.5
		box(self, Vector3(x, 0.7, z), Vector3(0.28, 1.4, 0.28), Color("946b42"))
	for i in 6:
		var x := -13.0 + i * 5.2
		box(self, Vector3(x, 0.8, -9), Vector3(0.4, 1.6, 0.4), Color("7b613e"), true)
		sphere(self, Vector3(x, 2.3, -9), Vector3(2.2, 2.4, 2.2), Color("477c45"))
	for i in 18:
		var angle := i * TAU / 18.0
		var pos := Vector3(cos(angle) * 37, 0, sin(angle) * 32)
		box(self, pos + Vector3(0, 2, 0), Vector3(0.7, 4, 0.7), Color("7b613e"))
		sphere(self, pos + Vector3(0, 5, 0), Vector3(5, 5.5, 5), Color("4b8048"))

func build_farmer() -> void:
	farmer = ValleyFarmer.new()
	add_child(farmer)
	farmer.reset_farmer()
	camera_pivot = Node3D.new()
	add_child(camera_pivot)
	camera_pivot.position = farmer.position + Vector3(0, 1.65, 0)
	camera_pivot.rotation = Vector3(camera_pitch, camera_yaw, 0)
	var arm := SpringArm3D.new()
	arm.spring_length = 5.2
	arm.margin = 0.25
	var shape := SphereShape3D.new()
	shape.radius = 0.22
	arm.shape = shape
	arm.add_excluded_object(farmer.get_rid())
	camera_pivot.add_child(arm)
	camera = Camera3D.new()
	camera.current = true
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 72
	camera.near = 0.1
	camera.far = 160
	arm.add_child(camera)

func turn_camera(motion: Vector2) -> void:
	if paused or game.finished or action_panel.visible: return
	camera_yaw -= motion.x * 0.005
	camera_pitch = clampf(camera_pitch - motion.y * 0.0035, -0.65, 0.12)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(controls): return
	farmer.active = not paused and not game.finished and not action_panel.visible
	var keyboard := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	farmer.travel_input = (keyboard + controls.movement).limit_length()
	farmer.view_yaw = camera_yaw

func chicken(parent: Node3D, pos: Vector3) -> Node3D:
	var c := Node3D.new()
	parent.add_child(c)
	c.position = pos
	sphere(c, Vector3(0, 0.4, 0), Vector3(0.58, 0.65, 0.7), Color("fff3d6"))
	sphere(c, Vector3(0, 0.75, 0.2), Vector3(0.4, 0.42, 0.4), Color("ffffff"))
	box(c, Vector3(0, 1.0, 0.18), Vector3(0.12, 0.15, 0.25), Color("e65442"))
	box(c, Vector3(0, 0.73, 0.44), Vector3(0.16, 0.12, 0.22), Color("efb444"))
	for x in [-0.11, 0.11]:
		box(c, Vector3(x, 0.1, 0), Vector3(0.06, 0.2, 0.1), Color("dca53b"))
		box(c, Vector3(x * 1.65, 0.8, 0.32), Vector3(0.055, 0.06, 0.06), Color("333c40"))
	return c

func sync_farms() -> void:
	for side in 2:
		var f := game.farms[side]
		var flock := birds[side]
		if flock.get_child_count() != f.chickens:
			for child in flock.get_children():
				flock.remove_child(child)
				child.queue_free()
			for i in f.chickens:
				var x: float = (-10.0 if side == 0 else 10.0) + (i % 6 - 2.5) * 1.25
				var z: float = -1.6 + floorf(i / 6.0) * 0.95
				chicken(flock, Vector3(x, 0, z))
		var structure := buildings[side]
		var key := "%d:%d" % [f.coops, f.fence]
		if structure.get_meta("key", "") == key: continue
		structure.set_meta("key", key)
		for child in structure.get_children():
			structure.remove_child(child)
			child.queue_free()
		var home_x := -10.0 if side == 0 else 10.0
		for i in f.coops:
			var cx: float = home_x - 4.2 + i * 2.8
			box(structure, Vector3(cx, 0.5, 6), Vector3(2, 1, 1.6), Color("e4bd7c"), true)
			box(structure, Vector3(cx, 1.1, 6), Vector3(2.2, 0.25, 1.9), Color("98774f"))
			box(structure, Vector3(cx, 0.35, 6.82), Vector3(0.6, 0.65, 0.04), Color("69513a"))
		if f.fence > 0:
			var edge := -3.5 if side == 0 else 3.5
			for i in 10:
				if i == 4 or i == 5: continue
				box(structure, Vector3(edge, 0.65, -4.5 + i), Vector3(0.2, 1.3 + f.fence * 0.15, 0.18), Color("c7a274"))
			for level in f.fence:
				for z in [-3.0, 3.0]:
					box(structure, Vector3(edge, 0.5 + level * 0.45, z), Vector3(0.15, 0.14, 4), Color("b58c5e"), true)

func label(text_value: String, size: int = 20) -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color("fff3db"))
	return l

func panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("203c3c")
	s.corner_radius_top_left = 14
	s.corner_radius_top_right = 14
	s.corner_radius_bottom_left = 14
	s.corner_radius_bottom_right = 14
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	controls = FarmerControls.new()
	root.add_child(controls)
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls.look_changed.connect(turn_camera)
	var top := PanelContainer.new()
	root.add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 12
	top.add_theme_stylebox_override("panel", panel_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	top.add_child(row)
	stats = label("")
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stats)
	timer_label = label("", 26)
	row.add_child(timer_label)
	enemy_stats = label("")
	enemy_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(enemy_stats)
	farm_button = Button.new()
	farm_button.text = "Farm & raids"
	farm_button.custom_minimum_size = Vector2(150, 48)
	farm_button.pressed.connect(func():
		if intro.visible or game.finished: return
		action_panel.visible = not action_panel.visible
		farm_button.text = "Close actions" if action_panel.visible else "Farm & raids"
		controls.clear_input()
		update_ui())
	row.add_child(farm_button)
	var center_button := Button.new()
	center_button.text = "Center view"
	center_button.custom_minimum_size = Vector2(125, 48)
	center_button.pressed.connect(func():
		camera_yaw = farmer.visual.rotation.y
		camera_pitch = -0.22)
	row.add_child(center_button)
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.custom_minimum_size = Vector2(90, 48)
	pause_button.pressed.connect(func():
		if game.finished or intro.visible: return
		paused = not paused
		pause_button.text = "Resume" if paused else "Pause"
		update_ui())
	row.add_child(pause_button)
	var bottom := PanelContainer.new()
	action_panel = bottom
	root.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 16
	bottom.offset_right = -16
	bottom.offset_top = -142
	bottom.offset_bottom = -12
	bottom.add_theme_stylebox_override("panel", panel_style())
	bottom.hide()
	var column := VBoxContainer.new()
	bottom.add_child(column)
	column.add_child(label("Build your economy • Launch a raider to steal chickens", 18))
	# Status stays visible while the action panel is closed.
	notice_label = label("", 18)
	root.add_child(notice_label)
	notice_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	notice_label.offset_top = 99
	notice_label.offset_bottom = 127
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_label.add_theme_color_override("font_shadow_color", Color("203c3c"))
	notice_label.add_theme_constant_override("shadow_offset_x", 2)
	notice_label.add_theme_constant_override("shadow_offset_y", 2)
	var hint := label("Drag right side to look\nWASD + right mouse on desktop", 17)
	root.add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_left = -345
	hint.offset_top = -82
	hint.offset_right = -25
	hint.offset_bottom = -25
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_color_override("font_shadow_color", Color("203c3c"))
	hint.add_theme_constant_override("shadow_offset_x", 2)
	hint.add_theme_constant_override("shadow_offset_y", 2)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)
	for action in ["chicken", "coop", "fence", "boots", "raid"]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 76)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 19)
		b.pressed.connect(func():
			if paused: return
			game.buy(0, action)
			sync_farms()
			update_ui())
		actions.add_child(b)
		buttons[action] = b
	intro = make_modal(root)
	var intro_col := VBoxContainer.new()
	intro_col.add_theme_constant_override("separation", 14)
	intro.add_child(intro_col)
	intro_col.add_child(label("CHICKEN VALLEY", 36))
	intro_col.add_child(label("Third-person farm rivalry • v0.2", 22))
	intro_col.add_child(label("Left thumbstick: walk your farmer.\nDrag right side: turn the camera.\nFarm & raids: buy chickens, coops and defenses.\nLaunch raiders to steal chickens from your rival.\nMost chickens after 4 minutes wins.", 20))
	var start := Button.new()
	start.text = "Start match vs AI"
	start.custom_minimum_size = Vector2(0, 60)
	start.pressed.connect(func(): intro.hide(); paused = false; update_ui())
	intro_col.add_child(start)
	result_panel = make_modal(root)
	var result_col := VBoxContainer.new()
	result_col.add_theme_constant_override("separation", 18)
	result_panel.add_child(result_col)
	result_label = label("", 30)
	result_col.add_child(result_label)
	var restart := Button.new()
	restart.text = "Play again"
	restart.custom_minimum_size = Vector2(0, 60)
	restart.pressed.connect(func():
		game = FarmMatch.new()
		farmer.reset_farmer()
		camera_yaw = 0
		camera_pitch = -0.22
		camera_pivot.position = farmer.position + Vector3(0, 1.65, 0)
		action_panel.hide()
		farm_button.text = "Farm & raids"
		controls.clear_input()
		paused = false
		pause_button.text = "Pause"
		result_panel.hide()
		sync_farms()
		update_ui())
	result_col.add_child(restart)
	result_panel.hide()

func make_modal(root: Control) -> PanelContainer:
	var p := PanelContainer.new()
	root.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.offset_left = -280
	p.offset_right = 280
	p.offset_top = -205
	p.offset_bottom = 155
	p.add_theme_stylebox_override("panel", panel_style())
	return p

func update_ui() -> void:
	var f := game.farms[0]
	var e := game.farms[1]
	stats.text = "YOU • %d coins\n%d/%d chickens • +%.1f/s" % [f.coins, f.chickens, game.capacity(0), f.chickens * 0.65]
	enemy_stats.text = "RIVAL • %d chickens\nFence level %d" % [e.chickens, e.fence]
	controls.set_enabled(not paused and not game.finished and not action_panel.visible)
	farm_button.disabled = paused or game.finished
	var seconds := ceili(game.remaining)
	timer_label.text = "%d:%02d" % [seconds / 60, seconds % 60]
	notice_label.text = "Match paused" if paused and not intro.visible else game.notice
	var names := {"chicken": "Buy chicken", "coop": "Build coop", "fence": "Upgrade fence", "boots": "Raider boots", "raid": "LAUNCH RAID"}
	for action in buttons:
		var detail := "%d coins" % game.cost(0, action)
		if action == "raid" and f.cooldown > 0: detail = "Ready in %ds" % ceili(f.cooldown)
		if action == "coop" and f.coops == 4: detail = "Max level"
		if action == "fence" and f.fence == 3: detail = "Max level"
		if action == "boots" and f.boots == 3: detail = "Max level"
		if action == "chicken" and f.chickens >= game.capacity(0): detail = "Build a coop first"
		buttons[action].text = names[action] + "\n" + detail
		buttons[action].disabled = paused or not game.available(0, action)
	if game.finished:
		result_label.text = "%s\n\nYour flock: %d\nRival flock: %d" % [game.notice, f.chickens, e.chickens]
		result_panel.show()

func sync_raiders() -> void:
	var active: Array[int] = []
	for r in game.raids:
		active.append(r.id)
		if not raider_nodes.has(r.id):
			var runner := Node3D.new()
			add_child(runner)
			box(runner, Vector3(0, 0.8, 0), Vector3(0.6, 0.9, 0.5), Color("247aaf") if r.side == 0 else Color("d45745"))
			sphere(runner, Vector3(0, 1.55, 0), Vector3(0.5, 0.5, 0.5), Color("f1c797"))
			box(runner, Vector3(0, 1.8, 0), Vector3(0.85, 0.14, 0.7), Color("d6b275"))
			var badge := Label3D.new()
			badge.name = "Badge"
			badge.position.y = 2.5
			badge.font_size = 40
			badge.pixel_size = 0.012
			badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			runner.add_child(badge)
			raider_nodes[r.id] = runner
		var t := clampf(r.elapsed / r.duration, 0, 1)
		var from_x := -9.0 if r.side == 0 else 9.0
		var to_x := -from_x
		if r.leg == 1:
			var temp := from_x
			from_x = to_x
			to_x = temp
		var runner: Node3D = raider_nodes[r.id]
		runner.position = Vector3(lerpf(from_x, to_x, t), absf(sin(clock * 12)) * 0.16, 2.7 if r.side == 0 else 4.0)
		runner.get_node("Badge").text = "%d stolen" % r.loot if r.leg == 1 else "RAID"
	for id in raider_nodes.keys():
		if id not in active:
			raider_nodes[id].queue_free()
			raider_nodes.erase(id)

func _process(delta: float) -> void:
	if is_instance_valid(camera_pivot):
		camera_pivot.position = camera_pivot.position.lerp(farmer.position + Vector3(0, 1.65, 0), 1 - exp(-12 * delta))
		camera_pivot.rotation = Vector3(camera_pitch, camera_yaw, 0)
	if not paused:
		clock += delta
		game.tick(delta)
		for flock in birds:
			for i in flock.get_child_count():
				var c: Node3D = flock.get_child(i)
				c.rotation.y = sin(clock * 0.7 + i * 1.7) * 0.65
				c.position.y = absf(sin(clock * 3 + i)) * 0.05
		sync_raiders()
	refresh -= delta
	if refresh <= 0:
		refresh = 0.15
		sync_farms()
		update_ui()
	if preview_mode:
		preview_frames += 1
		if preview_frames == 90:
			var picture := get_viewport().get_texture().get_image()
			DirAccess.make_dir_recursive_absolute("res://builds")
			picture.save_png("res://builds/third-person-preview.png")
			get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		paused = true
		if is_instance_valid(controls): controls.clear_input()
		if is_instance_valid(pause_button): pause_button.text = "Resume"
