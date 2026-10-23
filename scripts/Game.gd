extends Node3D

const KINGDOM_COUNT := 30
const STARTING_RESOURCES := {
    "gold": 1_000_000,
    "food": 1_000_000,
    "wood": 1_000_000,
    "stone": 1_000_000,
    "iron": 1_000_000,
}
const PLAYER_UNIT_COUNT := 10

var world_root: Node3D
var terrain_root: Node3D
var kingdom_data: Array = []
var city_nodes: Dictionary = {}
var player_units: Array = []
var selected_units: Array = []
var unit_scene: PackedScene = preload("res://scenes/Unit.tscn")
var rng := RandomNumberGenerator.new()
var paused := false
var day_phase := 0.0

@onready var resource_label: Label = $CanvasLayer/HUD/TopBar/ResourceLabel
@onready var objectives_label: Label = $CanvasLayer/HUD/Objectives/ObjectivesLabel
@onready var army_status_label: Label = $CanvasLayer/HUD/BottomBar/ArmyStatusLabel
@onready var camera_rig: Node3D = $CameraRig

func _ready() -> void:
    rng.randomize()
    world_root = $WorldRoot
    terrain_root = $WorldRoot/Terrain
    _generate_world()
    _spawn_player_units()
    _update_ui()

func _process(delta: float) -> void:
    if paused:
        return

    day_phase += delta * 0.08
    _update_world_simulation(delta)
    _update_ui()

func _generate_world() -> void:
    _build_terrain()
    _generate_kingdoms()

func _build_terrain() -> void:
    var plane := PlaneMesh.new()
    plane.size = Vector2(220, 220)
    plane.subdivide_depth = 24
    plane.subdivide_width = 24

    var terrain := MeshInstance3D.new()
    terrain.mesh = plane
    terrain.material_override = StandardMaterial3D.new()
    terrain.material_override.albedo_color = Color(0.26, 0.46, 0.24)
    terrain.position = Vector3(0, -0.75, 0)
    terrain_root.add_child(terrain)

    for i in range(24):
        var tree := MeshInstance3D.new()
        tree.mesh = CapsuleMesh.new()
        tree.mesh.height = 1.4
        tree.mesh.radius = 0.35
        var tree_material := StandardMaterial3D.new()
        tree_material.albedo_color = Color(0.17, 0.35, 0.18)
        tree.material_override = tree_material
        tree.position = Vector3(rng.randf_range(-90, 90), 0.6, rng.randf_range(-90, 90))
        terrain_root.add_child(tree)

    for i in range(10):
        var mountain := MeshInstance3D.new()
        mountain.mesh = SphereMesh.new()
        mountain.mesh.radius = rng.randf_range(4, 9)
        mountain.mesh.height = rng.randf_range(8, 18)
        var mountain_material := StandardMaterial3D.new()
        mountain_material.albedo_color = Color(0.46, 0.44, 0.42)
        mountain.material_override = mountain_material
        mountain.position = Vector3(rng.randf_range(-90, 90), 3.5, rng.randf_range(-90, 90))
        terrain_root.add_child(mountain)

func _generate_kingdoms() -> void:
    var palette := [
        Color.MEDIUM_SEA_GREEN,
        Color.CORNFLOWER_BLUE,
        Color.CRIMSON,
        Color.GOLDENROD,
        Color.DARK_ORANGE,
        Color.INDIGO,
        Color.FIREBRICK,
        Color.DARK_VIOLET,
        Color.TOMATO,
        Color.SEA_GREEN,
    ]

    for kingdom_index in range(KINGDOM_COUNT):
        var kingdom := {
            "id": kingdom_index,
            "name": "Kingdom %d" % (kingdom_index + 1),
            "is_player": kingdom_index == 0,
            "color": palette[kingdom_index % palette.size()],
            "gold": STARTING_RESOURCES.gold if kingdom_index == 0 else rng.randi_range(40000, 150000),
            "food": STARTING_RESOURCES.food if kingdom_index == 0 else rng.randi_range(30000, 120000),
            "wood": STARTING_RESOURCES.wood if kingdom_index == 0 else rng.randi_range(30000, 120000),
            "stone": STARTING_RESOURCES.stone if kingdom_index == 0 else rng.randi_range(20000, 100000),
            "iron": STARTING_RESOURCES.iron if kingdom_index == 0 else rng.randi_range(20000, 100000),
            "population": 140 if kingdom_index == 0 else rng.randi_range(80, 220),
            "territory": 1,
            "cities": [],
            "relations": {},
            "military_power": rng.randi_range(20, 90),
            "ai_goal": ["expand", "trade", "defend", "fortify"][rng.randi_range(0, 3)],
        }

        for city_index in range(1):
            var city_position := Vector3(
                rng.randf_range(-80, 80),
                0.5,
                rng.randf_range(-80, 80)
            )
            if kingdom_index == 0:
                city_position = Vector3(-18, 0.5, 8)

            var city := {
                "id": kingdom_index * 10 + city_index,
                "name": "%s Capital" % kingdom["name"],
                "owner_id": kingdom_index,
                "position": city_position,
                "population": kingdom["population"],
                "buildings": ["farm", "house", "market"],
                "garrison": 20 if kingdom_index == 0 else rng.randi_range(12, 45),
            }
            kingdom["cities"].append(city)
            _spawn_city_marker(city, kingdom["color"])

        kingdom_data.append(kingdom)

    if kingdom_data.size() > 0:
        var player_kingdom = kingdom_data[0]
        player_kingdom["name"] = "Your Kingdom"
        player_kingdom["city_name"] = "Stonegate"
        objectives_label.text = "Objectives\n- Build a prosperous kingdom\n- Explore the world\n- Conquer or dominate the realm"

func _spawn_city_marker(city_data: Dictionary, color: Color) -> void:
    var city_root := Node3D.new()
    city_root.position = city_data["position"]
    city_root.name = "City_%s" % city_data["id"]
    terrain_root.add_child(city_root)

    var wall := MeshInstance3D.new()
    wall.mesh = CylinderMesh.new()
    wall.mesh.top_radius = 1.4
    wall.mesh.bottom_radius = 2.0
    wall.mesh.height = 3.0
    var wall_material := StandardMaterial3D.new()
    wall_material.albedo_color = color
    wall.material_override = wall_material
    wall.position = Vector3(0, 1.5, 0)
    city_root.add_child(wall)

    var banner := MeshInstance3D.new()
    banner.mesh = CubeMesh.new()
    banner.mesh.size = Vector3(0.2, 1.8, 0.2)
    var banner_material := StandardMaterial3D.new()
    banner_material.albedo_color = Color(1, 0.96, 0.8)
    banner.material_override = banner_material
    banner.position = Vector3(0, 3.2, 0)
    city_root.add_child(banner)

    var label := Label3D.new()
    label.text = city_data["name"]
    label.position = Vector3(0, 5.0, 0)
    label.modulate = color
    city_root.add_child(label)

    city_nodes[city_data["id"]] = city_root

func _spawn_player_units() -> void:
    for i in range(PLAYER_UNIT_COUNT):
        var unit = unit_scene.instantiate()
        unit.add_to_group("unit")
        unit.team_id = 0
        unit.unit_name = "Infantry"
        unit.set_team_color(Color(0.1, 0.75, 0.3))
        var radius := 3.0 + (i * 0.55)
        var angle := TAU * float(i) / float(PLAYER_UNIT_COUNT)
        var spawn_pos := Vector3(-18, 0.5, 8) + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        unit.global_position = spawn_pos
        world_root.add_child(unit)
        player_units.append(unit)

func _update_world_simulation(delta: float) -> void:
    for kingdom in kingdom_data:
        if kingdom["is_player"]:
            _simulate_player_kingdom(kingdom, delta)
        else:
            _simulate_ai_kingdom(kingdom, delta)

func _simulate_player_kingdom(kingdom: Dictionary, delta: float) -> void:
    kingdom["gold"] += int(12.0 * delta * 20.0)
    kingdom["food"] += int(15.0 * delta * 20.0)
    kingdom["wood"] += int(14.0 * delta * 20.0)
    kingdom["stone"] += int(12.0 * delta * 12.0)
    kingdom["iron"] += int(15.0 * delta * 12.0)
    kingdom["population"] += int(delta * 0.8)

func _simulate_ai_kingdom(kingdom: Dictionary, delta: float) -> void:
    kingdom["gold"] += int(rng.randi_range(50, 200) * delta)
    kingdom["food"] += int(rng.randi_range(40, 180) * delta)
    kingdom["wood"] += int(rng.randi_range(35, 170) * delta)
    kingdom["stone"] += int(rng.randi_range(30, 160) * delta)
    kingdom["iron"] += int(rng.randi_range(25, 150) * delta)
    kingdom["military_power"] += int(rng.randi_range(0, 4) * delta)

func format_number_display(value: int) -> String:
    if abs(value) >= 1000:
        var thousands := float(value) / 1000.0
        var suffix := "k"
        if value >= 1000000:
            thousands = float(value) / 1000000.0
            suffix = "m"
        var text := String.num(thousands, 1)
        if text.ends_with(".0"):
            text = text.substr(0, text.length() - 2)
        return text + suffix
    return str(value)

func _update_ui() -> void:
    var player_kingdom = kingdom_data[0]
    resource_label.text = (
        "Gold: %s | Food: %s | Wood: %s | Stone: %s | Iron: %s | Population: %s" % [
            format_number_display(player_kingdom["gold"]),
            format_number_display(player_kingdom["food"]),
            format_number_display(player_kingdom["wood"]),
            format_number_display(player_kingdom["stone"]),
            format_number_display(player_kingdom["iron"]),
            format_number_display(player_kingdom["population"]),
        ]
    )
    army_status_label.text = "Army: %s" % format_number_display(player_units.size())

func save_game() -> void:
    var data := {
        "kingdoms": kingdom_data,
        "day_phase": day_phase,
    }
    var file := FileAccess.open("user://savegame.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data, "  "))
        file.close()

func load_game() -> void:
    var file_path := "user://savegame.json"
    if not FileAccess.file_exists(file_path):
        return

    var file := FileAccess.open(file_path, FileAccess.READ)
    if not file:
        return

    var content := file.get_as_text()
    file.close()
    var parsed = JSON.parse_string(content)
    if parsed and parsed.has("kingdoms"):
        kingdom_data = parsed["kingdoms"]
        day_phase = float(parsed.get("day_phase", 0.0))
        _update_ui()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
        paused = not paused

    if event is InputEventKey and event.pressed and event.keycode == KEY_S:
        save_game()

    if event is InputEventKey and event.pressed and event.keycode == KEY_L:
        load_game()

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _handle_left_click(event.position)

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        _handle_right_click(event.position)

func _handle_left_click(mouse_position: Vector2) -> void:
    var camera := get_viewport().get_camera_3d()
    var from := camera.project_ray_origin(mouse_position)
    var to := from + camera.project_ray_normal(mouse_position) * 200.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.collide_with_areas = false
    query.collide_with_bodies = true
    var result := get_world_3d().direct_space_state.intersect_ray(query)

    if result and result.has("collider") and is_instance_valid(result["collider"]):
        var hit_node := result["collider"]
        if hit_node.is_in_group("unit"):
            _select_unit(hit_node)
            return

    _clear_selection()

func _handle_right_click(mouse_position: Vector2) -> void:
    var camera := get_viewport().get_camera_3d()
    var from := camera.project_ray_origin(mouse_position)
    var to := from + camera.project_ray_normal(mouse_position) * 200.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.collide_with_areas = false
    query.collide_with_bodies = true
    var result := get_world_3d().direct_space_state.intersect_ray(query)

    if not result:
        return

    var target_position := result["position"]
    if selected_units.is_empty():
        return

    for unit in selected_units:
        if is_instance_valid(unit):
            unit.move_to(target_position)

func _select_unit(unit: Node) -> void:
    for existing in selected_units:
        if is_instance_valid(existing):
            existing.set_selected(false)
    selected_units.clear()
    selected_units.append(unit)
    unit.set_selected(true)
    army_status_label.text = "Army: %s" % format_number_display(selected_units.size())

func _clear_selection() -> void:
    for existing in selected_units:
        if is_instance_valid(existing):
            existing.set_selected(false)
    selected_units.clear()
    army_status_label.text = "Army: %s" % format_number_display(player_units.size())

func _unhandled_input(event: InputEvent) -> void:
    _input(event)
