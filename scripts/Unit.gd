extends CharacterBody3D

@export var move_speed: float = 6.0

var team_id: int = 0
var unit_name: String = "Infantry"
var move_target: Vector3 = Vector3.ZERO
var selected: bool = false
var body_mesh: MeshInstance3D
var selection_ring: MeshInstance3D

func _ready() -> void:
    add_to_group("unit")
    body_mesh = $Body
    selection_ring = $SelectionRing
    selection_ring.visible = false
    if body_mesh != null:
        var material := StandardMaterial3D.new()
        material.albedo_color = Color(0.1, 0.7, 0.3)
        body_mesh.material_override = material

func set_team_color(color: Color) -> void:
    if body_mesh != null:
        var material := StandardMaterial3D.new()
        material.albedo_color = color
        body_mesh.material_override = material

func set_selected(value: bool) -> void:
    selected = value
    if selection_ring != null:
        selection_ring.visible = value

func move_to(world_position: Vector3) -> void:
    move_target = world_position

func _physics_process(delta: float) -> void:
    if move_target != Vector3.ZERO:
        var direction := move_target - global_position
        direction.y = 0.0
        if direction.length() > 0.2:
            velocity = direction.normalized() * move_speed
            move_and_slide()
        else:
            velocity = Vector3.ZERO
            move_target = Vector3.ZERO
    else:
        velocity = Vector3.ZERO

func _process(delta: float) -> void:
    if selected and selection_ring != null:
        selection_ring.rotation_degrees.x = 90.0
