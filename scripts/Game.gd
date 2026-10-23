extends Node3D

const KINGDOM_COUNT := 30
const STARTING_RESOURCES := {
    "gold": 1_000_000,
    "food": 1_000_000,
    "wood": 1_000_000,
    "stone": 1_000_000,
    "iron": 1_000_000,
}

var world_root: Node3D
var terrain_root: Node3D
var kingdom_data: Array = []
var city_nodes: Dictionary = {}
var rng := RandomNumberGenerator.new()
var paused := false
var day_phase := 0.0

@onready var resource_label: Label = $CanvasLayer/HUD/TopBar/ResourceLabel
@onready var objectives_label: Label = $CanvasLayer/HUD/Objectives/ObjectivesLabel
@onready var camera_rig: Node3D = $CameraRig

func _ready() -> void:
    rng.randomize()
    world_root = $WorldRoot
    terrain_root = $WorldRoot/Terrain
    _generate_world()
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

    # Give the player a clear starting city and nearby neutral settlements.
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

func _update_world_simulation(delta: float) -> void:
    for kingdom in kingdom_data:
        if kingdom["is_player"]:
            _simulate_player_kingdom(kingdom, delta)
        else:
            _simulate_ai_kingdom(kingdom, delta)

func _simulate_player_kingdom(kingdom: Dictionary, delta: float) -> void:
    var income := Vector3(
        12.0,
        15.0,
        14.0,
    )
    kingdom["gold"] += int(income.x * delta * 20.0)
    kingdom["food"] += int(income.y * delta * 20.0)
    kingdom["wood"] += int(income.z * delta * 20.0)
    kingdom["stone"] += int(income.x * delta * 12.0)
    kingdom["iron"] += int(income.y * delta * 12.0)
    kingdom["population"] += int(delta * 0.8)

func _simulate_ai_kingdom(kingdom: Dictionary, delta: float) -> void:
    kingdom["gold"] += int(rng.randi_range(50, 200) * delta)
    kingdom["food"] += int(rng.randi_range(40, 180) * delta)
    kingdom["wood"] += int(rng.randi_range(35, 170) * delta)
    kingdom["stone"] += int(rng.randi_range(30, 160) * delta)
    kingdom["iron"] += int(rng.randi_range(25, 150) * delta)
    kingdom["military_power"] += int(rng.randi_range(0, 4) * delta)

func _update_ui() -> void:
    var player_kingdom = kingdom_data[0]
    resource_label.text = (
        "Gold: %d | Food: %d | Wood: %d | Stone: %d | Iron: %d | Population: %d" % [
            player_kingdom["gold"],
            player_kingdom["food"],
            player_kingdom["wood"],
            player_kingdom["stone"],
            player_kingdom["iron"],
            player_kingdom["population"],
        ]
    )

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
