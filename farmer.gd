class_name ValleyFarmer
extends CharacterBody3D

var visual := Node3D.new()
var limbs: Array[Node3D] = []
var walk_phase := 0.0
var travel_input := Vector2.ZERO
var view_yaw := 0.0
var active := false
const WALK_SPEED := 4.5

func _ready() -> void:
	name = "Farmer"
	add_child(visual)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.9
	collision.shape = capsule
	collision.position.y = 0.96
	add_child(collision)
	part(visual, Vector3(0, 1.15, 0), Vector3(0.65, 0.65, 0.4), Color("e8d0a0"))
	part(visual, Vector3(0, 0.96, -0.23), Vector3(0.49, 0.44, 0.08), Color("267ba2"))
	for x in [-0.22, 0.22]:
		part(visual, Vector3(x, 1.32, -0.22), Vector3(0.09, 0.4, 0.06), Color("267ba2"))
	part(visual, Vector3(0, 1.65, 0), Vector3(0.48, 0.46, 0.46), Color("eab586"))
	for x in [-0.12, 0.12]:
		part(visual, Vector3(x, 1.71, -0.24), Vector3(0.055, 0.07, 0.025), Color("26363b"))
	part(visual, Vector3(0, 1.59, -0.26), Vector3(0.12, 0.055, 0.04), Color("a55e42"))
	# Straw hat gives the farmer a clear silhouette from behind.
	for dimensions in [Vector3(0.57, 0.09, 0), Vector3(0.35, 0.25, 0)]:
		var hat := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = dimensions.x
		cylinder.bottom_radius = dimensions.x
		cylinder.height = dimensions.y
		cylinder.radial_segments = 16
		hat.mesh = cylinder
		hat.material_override = colored(Color("d8b461"))
		hat.position.y = 1.91 if dimensions.y < 0.1 else 2.06
		visual.add_child(hat)
	part(visual, Vector3(0, 1.3, 0.28), Vector3(0.45, 0.45, 0.22), Color("987247"))
	for side in [-1, 1]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.18, 0.77, 0)
		visual.add_child(leg)
		part(leg, Vector3(0, -0.29, 0), Vector3(0.23, 0.58, 0.25), Color("326f8a"))
		part(leg, Vector3(0, -0.62, -0.07), Vector3(0.26, 0.22, 0.4), Color("67513e"))
		limbs.append(leg)
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.44, 1.43, 0)
		visual.add_child(arm)
		part(arm, Vector3(0, -0.19, 0), Vector3(0.2, 0.38, 0.25), Color("e8d0a0"))
		part(arm, Vector3(0, -0.44, 0), Vector3(0.18, 0.22, 0.22), Color("eab586"))
		limbs.append(arm)

func colored(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	return m

func part(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = colored(color)
	n.position = pos
	parent.add_child(n)

func _physics_process(delta: float) -> void:
	var move := travel_input.limit_length() if active else Vector2.ZERO
	var direction := Basis(Vector3.UP, view_yaw) * Vector3(move.x, 0, move.y)
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0
	move_and_slide()
	position.x = clampf(position.x, -16, 16)
	position.z = clampf(position.z, -8.3, 9.4)
	if direction.length_squared() > 0.01:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), 1 - exp(-12 * delta))
		walk_phase += delta * 9.0
	for i in limbs.size():
		var target := sin(walk_phase + (0.0 if i == 0 or i == 3 else PI)) * 0.48 * move.length()
		limbs[i].rotation.x = lerpf(limbs[i].rotation.x, target, 1 - exp(-14 * delta))

func reset_farmer() -> void:
	position = Vector3(-10, 0.15, 3.5)
	velocity = Vector3.ZERO
	travel_input = Vector2.ZERO
	visual.rotation = Vector3.ZERO
