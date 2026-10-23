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
const BUILDING_COSTS := {
    "farm": {"food": 0, "wood": 80, "stone": 40, "iron": 10},
    "house": {"food": 0, "wood": 100, "stone": 50, "iron": 15},
    "lumber_camp": {"food": 0, "wood": 120, "stone": 60, "iron": 15},
    "quarry": {"food": 0, "wood": 120, "stone": 80, "iron": 20},
    "barracks": {"food": 0, "wood": 180, "stone": 120, "iron": 40},
    "watchtower": {"food": 0, "wood": 160, "stone": 180, "iron": 60},
    "keep": {"food": 0, "wood": 220, "stone": 240, "iron": 90},
}
const UNIT_COSTS := {
    "infantry": {"gold": 80, "food": 30, "wood": 20, "stone": 10, "iron": 20},
    "archer": {"gold": 110, "food": 30, "wood": 25, "stone": 10, "iron": 25},
    "cavalry": {"gold": 180, "food": 45, "wood": 30, "stone": 20, "iron": 35},
    "knight": {"gold": 260, "food": 60, "wood": 35, "stone": 25, "iron": 50},
}
const CITY_CAPTURE_DISTANCE := 5.0
const FOG_VISIBILITY_RADIUS := 24.0
const SEIGE_RANGE := 12.0

var world_root: Node3D
var terrain_root: Node3D
var kingdom_data: Array = []
var city_nodes: Dictionary = {}
var player_units: Array = []
var enemy_units: Array = []
var selected_units: Array = []
var buildings: Array = []
var active_build_type: String = ""
var unit_scene: PackedScene = preload("res://scenes/Unit.tscn")
var building_scene: PackedScene = preload("res://scenes/Building.tscn")
var rng := RandomNumberGenerator.new()
var paused := false
var day_phase := 0.0
var recruitment_panel_visible := false
var diplomacy_panel_visible := false
var selected_enemy_kingdom_id: int = -1
var city_panel_visible := false
var save_version := 2

@onready var resource_label: Label = $CanvasLayer/HUD/TopBar/ResourceLabel
@onready var objectives_label: Label = $CanvasLayer/HUD/Objectives/ObjectivesLabel
@onready var army_status_label: Label = $CanvasLayer/HUD/BottomBar/ArmyStatusLabel
@onready var city_status_label: Label = $CanvasLayer/HUD/BottomBar/CityStatusLabel
@onready var build_farm_button: Button = $CanvasLayer/HUD/BuildPanel/FarmButton
@onready var build_house_button: Button = $CanvasLayer/HUD/BuildPanel/HouseButton
@onready var build_lumber_button: Button = $CanvasLayer/HUD/BuildPanel/LumberButton
@onready var build_quarry_button: Button = $CanvasLayer/HUD/BuildPanel/QuarryButton
@onready var build_barracks_button: Button = $CanvasLayer/HUD/BuildPanel/BarracksButton
@onready var build_watchtower_button: Button = $CanvasLayer/HUD/BuildPanel/WatchtowerButton
@onready var build_keep_button: Button = $CanvasLayer/HUD/BuildPanel/KeepButton
@onready var recruit_button: Button = $CanvasLayer/HUD/BuildPanel/RecruitButton
@onready var diplomacy_button: Button = $CanvasLayer/HUD/BuildPanel/DiplomacyButton
@onready var recruit_panel: Panel = $CanvasLayer/HUD/RecruitPanel
@onready var diplomacy_panel: Panel = $CanvasLayer/HUD/DiplomacyPanel
@onready var recruit_infantry_button: Button = $CanvasLayer/HUD/RecruitPanel/InfantryButton
@onready var recruit_archer_button: Button = $CanvasLayer/HUD/RecruitPanel/ArcherButton
@onready var recruit_cavalry_button: Button = $CanvasLayer/HUD/RecruitPanel/CavalryButton
@onready var recruit_knight_button: Button = $CanvasLayer/HUD/RecruitPanel/KnightButton
@onready var diplomacy_list: VBoxContainer = $CanvasLayer/HUD/DiplomacyPanel/List
@onready var diplomacy_message_label: Label = $CanvasLayer/HUD/DiplomacyPanel/MessageLabel
@onready var city_panel: Panel = $CanvasLayer/HUD/CityPanel
@onready var tax_slider: HSlider = $CanvasLayer/HUD/CityPanel/TaxSlider
@onready var tax_value_label: Label = $CanvasLayer/HUD/CityPanel/TaxValue
@onready var workers_slider: HSlider = $CanvasLayer/HUD/CityPanel/WorkersSlider
@onready var workers_value_label: Label = $CanvasLayer/HUD/CityPanel/WorkersValue
@onready var city_name_label: Label = $CanvasLayer/HUD/CityPanel/CityName
@onready var ownership_label: Label = $CanvasLayer/HUD/CityPanel/Ownership
@onready var kingdom_summary_label: Label = $CanvasLayer/HUD/CityPanel/KingdomSummary
@onready var camera_rig: Node3D = $CameraRig

func _ready() -> void:
    rng.randomize()
    world_root = $WorldRoot
    terrain_root = $WorldRoot/Terrain
    _generate_world()
    _initialize_diplomacy()
    _spawn_player_units()
    _spawn_enemy_units()
    _connect_build_buttons()
    _connect_recruit_buttons()
    _connect_city_controls()
    _spawn_initial_city_buildings()
    recruit_panel.visible = false
    diplomacy_panel.visible = false
    city_panel.visible = false
    _update_ui()

func _connect_build_buttons() -> void:
    build_farm_button.pressed.connect(_on_farm_button_pressed)
    build_house_button.pressed.connect(_on_house_button_pressed)
    build_lumber_button.pressed.connect(_on_lumber_button_pressed)
    build_quarry_button.pressed.connect(_on_quarry_button_pressed)
    build_barracks_button.pressed.connect(_on_barracks_button_pressed)
    build_watchtower_button.pressed.connect(_on_watchtower_button_pressed)
    build_keep_button.pressed.connect(_on_keep_button_pressed)
    recruit_button.pressed.connect(_toggle_recruit_panel)
    diplomacy_button.pressed.connect(_toggle_diplomacy_panel)

func _connect_recruit_buttons() -> void:
    recruit_infantry_button.pressed.connect(func(): _spawn_unit_of_type("infantry"))
    recruit_archer_button.pressed.connect(func(): _spawn_unit_of_type("archer"))
    recruit_cavalry_button.pressed.connect(func(): _spawn_unit_of_type("cavalry"))
    recruit_knight_button.pressed.connect(func(): _spawn_unit_of_type("knight"))

func _connect_city_controls() -> void:
    tax_slider.value_changed.connect(_on_tax_changed)
    workers_slider.value_changed.connect(_on_workers_changed)
    _on_tax_changed(tax_slider.value)
    _on_workers_changed(workers_slider.value)

func _on_tax_changed(value: float) -> void:
    var player_kingdom := _get_player_kingdom()
    player_kingdom["tax_rate"] = int(value)
    tax_value_label.text = "Tax: %s%%" % str(int(value))

func _on_workers_changed(value: float) -> void:
    var player_kingdom := _get_player_kingdom()
    player_kingdom["workers"] = int(value)
    workers_value_label.text = "Workers: %s" % str(int(value))

func _toggle_recruit_panel() -> void:
    recruitment_panel_visible = !recruitment_panel_visible
    recruit_panel.visible = recruitment_panel_visible

func _toggle_diplomacy_panel() -> void:
    diplomacy_panel_visible = !diplomacy_panel_visible
    diplomacy_panel.visible = diplomacy_panel_visible
    if diplomacy_panel_visible:
        _refresh_diplomacy_panel()

func _refresh_diplomacy_panel() -> void:
    for child in diplomacy_list.get_children():
        child.queue_free()

    var player_kingdom := _get_player_kingdom()
    for kingdom in kingdom_data:
        if kingdom["id"] == player_kingdom["id"]:
            continue
        var relation := _get_relation_value(player_kingdom["id"], kingdom["id"])
        var row := HBoxContainer.new()
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var label := Label.new()
        label.text = "%s (%s)" % [kingdom["name"], kingdom["diplomacy_state"]]
        label.custom_minimum_size = Vector2(180, 0)
        row.add_child(label)

        var send_tribute := Button.new()
        send_tribute.text = "Tribute"
        send_tribute.pressed.connect(func(): _trigger_tribute(player_kingdom["id"], kingdom["id"]))
        row.add_child(send_tribute)

        var declare_war := Button.new()
        declare_war.text = "War"
        declare_war.pressed.connect(func(): _set_kingdom_relations(player_kingdom["id"], kingdom["id"], "war"))
        row.add_child(declare_war)

        var offer_alliance := Button.new()
        offer_alliance.text = "Alliance"
        offer_alliance.pressed.connect(func(): _set_kingdom_relations(player_kingdom["id"], kingdom["id"], "allied"))
        row.add_child(offer_alliance)

        var neutralize := Button.new()
        neutralize.text = "Neutral"
        neutralize.pressed.connect(func(): _set_kingdom_relations(player_kingdom["id"], kingdom["id"], "neutral"))
        row.add_child(neutralize)

        diplomacy_list.add_child(row)

func _trigger_tribute(from_id: int, target_id: int) -> void:
    var source := _get_kingdom_by_id(from_id)
    var target := _get_kingdom_by_id(target_id)
    if source.is_empty() or target.is_empty():
        return
    var tribute_amount := int(min(10000, source["gold"] * 0.05))
    if tribute_amount <= 0:
        return
    source["gold"] -= tribute_amount
    target["gold"] += tribute_amount
    var relation := _get_relation_value(from_id, target_id)
    _set_relation(from_id, target_id, relation + 10)
    diplomacy_message_label.text = "Tribute sent: %s gold to %s." % [format_number_display(tribute_amount), target["name"]]

func _set_kingdom_relations(source_id: int, target_id: int, state: String) -> void:
    var source := _get_kingdom_by_id(source_id)
    var target := _get_kingdom_by_id(target_id)
    if source.is_empty() or target.is_empty():
        return

    match state:
        "war":
            source["diplomacy_state"] = "war"
            target["diplomacy_state"] = "war"
            _set_relation(source_id, target_id, -80)
            source["war_state"] = true
            target["war_state"] = true
            diplomacy_message_label.text = "%s declared war on %s." % [source["name"], target["name"]]
        "allied":
            source["diplomacy_state"] = "allied"
            target["diplomacy_state"] = "allied"
            _set_relation(source_id, target_id, 75)
            source["war_state"] = false
            target["war_state"] = false
            diplomacy_message_label.text = "%s formed an alliance with %s." % [source["name"], target["name"]]
        "neutral":
            source["diplomacy_state"] = "neutral"
            target["diplomacy_state"] = "neutral"
            _set_relation(source_id, target_id, 0)
            source["war_state"] = false
            target["war_state"] = false
            diplomacy_message_label.text = "%s restored neutrality with %s." % [source["name"], target["name"]]

func _process(delta: float) -> void:
    if paused:
        return

    day_phase += delta * 0.08
    _update_world_simulation(delta)
    _update_diplomacy(delta)
    _run_ai_expansion_logic(delta)
    _check_city_capture()
    _check_siege_warfare(delta)
    _update_fog_of_war()
    _update_ai_units(delta)
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
            "tax_rate": 15,
            "workers": 20,
            "diplomacy_state": "neutral",
            "war_state": false,
            "expansion_threat": 0.0,
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

func _initialize_diplomacy() -> void:
    for kingdom in kingdom_data:
        for other in kingdom_data:
            if kingdom["id"] == other["id"]:
                continue
            var relation_value := -15 + rng.randi_range(-30, 30)
            if kingdom["is_player"] or other["is_player"]:
                relation_value = -20 + rng.randi_range(-20, 30)
            kingdom["relations"][str(other["id"])] = relation_value

        if kingdom["is_player"]:
            kingdom["diplomacy_state"] = "neutral"
        elif kingdom["relations"].values().filter(func(value): return value < -30).size() > 0:
            kingdom["diplomacy_state"] = "war"
        elif kingdom["relations"].values().filter(func(value): return value > 60).size() > 0:
            kingdom["diplomacy_state"] = "allied"
        else:
            kingdom["diplomacy_state"] = "neutral"

func _get_player_kingdom() -> Dictionary:
    for kingdom in kingdom_data:
        if kingdom["is_player"]:
            return kingdom
    return kingdom_data[0]

func _get_kingdom_by_id(kingdom_id: int) -> Dictionary:
    for kingdom in kingdom_data:
        if kingdom["id"] == kingdom_id:
            return kingdom
    return {}

func _get_relation_value(source_id: int, target_id: int) -> int:
    var source = _get_kingdom_by_id(source_id)
    if source.is_empty():
        return 0
    return int(source.get("relations", {}).get(str(target_id), 0))

func _set_relation(source_id: int, target_id: int, value: int) -> void:
    var source = _get_kingdom_by_id(source_id)
    var target = _get_kingdom_by_id(target_id)
    if source.is_empty() or target.is_empty():
        return
    source["relations"][str(target_id)] = value
    target["relations"][str(source_id)] = value

func _update_diplomacy(delta: float) -> void:
    var player_kingdom := _get_player_kingdom()
    for kingdom in kingdom_data:
        if kingdom["is_player"]:
            continue

        var relation := _get_relation_value(player_kingdom["id"], kingdom["id"])
        if relation <= -30:
            kingdom["diplomacy_state"] = "war"
            kingdom["war_state"] = true
        elif relation >= 60:
            kingdom["diplomacy_state"] = "allied"
            kingdom["war_state"] = false
        else:
            kingdom["diplomacy_state"] = "neutral"
            kingdom["war_state"] = false

        if kingdom["ai_goal"] == "expand" and rng.randf() < 0.02:
            kingdom["expansion_threat"] = clamp(kingdom.get("expansion_threat", 0.0) + 0.1, 0.0, 1.0)
        if kingdom["ai_goal"] == "defend" and rng.randf() < 0.015:
            kingdom["military_power"] += 1

func _build_diplomacy_summary() -> String:
    var player_kingdom := _get_player_kingdom()
    var entries := []
    for kingdom in kingdom_data:
        if kingdom["is_player"]:
            continue
        var relation := _get_relation_value(player_kingdom["id"], kingdom["id"])
        entries.append("%s:%s" % [kingdom["name"].substr(0, 4), kingdom["diplomacy_state"]])
        if entries.size() >= 4:
            break
    return "Diplomacy: %s" % ", ".join(entries)

func _run_ai_expansion_logic(delta: float) -> void:
    for kingdom in kingdom_data:
        if kingdom["is_player"]:
            continue
        if kingdom["ai_goal"] == "expand" and rng.randf() < 0.03:
            if kingdom["gold"] > 20000 and kingdom["military_power"] > 30:
                kingdom["gold"] -= 4000
                kingdom["territory"] += 1
                kingdom["expansion_threat"] = clamp(kingdom["expansion_threat"] + 0.15, 0.0, 1.0)
        elif kingdom["ai_goal"] == "defend" and rng.randf() < 0.025:
            kingdom["military_power"] += 3
        elif kingdom["ai_goal"] == "fortify" and rng.randf() < 0.02:
            kingdom["steel"] = kingdom.get("stone", 0) + 250 if not kingdom.has("steel") else kingdom["steel"]

func _spawn_initial_city_buildings() -> void:
    _place_building_for_type("farm", Vector3(-22, 0.0, 12))
    _place_building_for_type("house", Vector3(-15, 0.0, 12))
    _place_building_for_type("lumber_camp", Vector3(-18, 0.0, 16))
    _place_building_for_type("quarry", Vector3(-22, 0.0, 4))
    _place_building_for_type("watchtower", Vector3(-12, 0.0, 18))

func _spawn_city_marker(city_data: Dictionary, color: Color) -> void:
    var city_root := Node3D.new()
    city_root.position = city_data["position"]
    city_root.name = "City_%s" % city_data["id"]
    city_root.set_meta("owner_id", city_data["owner_id"])
    city_root.set_meta("capture_progress", 0.0)
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

func _spawn_enemy_units() -> void:
    for i in range(6):
        var unit = unit_scene.instantiate()
        unit.add_to_group("unit")
        unit.team_id = 1
        unit.is_enemy = true
        unit.unit_name = "Raider"
        unit.set_team_color(Color(0.82, 0.19, 0.19))
        var radius := 4.0 + (i * 1.2)
        var angle := TAU * float(i) / 6.0
        var spawn_pos := Vector3(26, 0.5, 18) + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        unit.global_position = spawn_pos
        world_root.add_child(unit)
        enemy_units.append(unit)

func _update_world_simulation(delta: float) -> void:
    for kingdom in kingdom_data:
        if kingdom["is_player"]:
            _simulate_player_kingdom(kingdom, delta)
        else:
            _simulate_ai_kingdom(kingdom, delta)

func _simulate_player_kingdom(kingdom: Dictionary, delta: float) -> void:
    var tax_income := int(kingdom.get("population", 0) * float(kingdom.get("tax_rate", 15)) * 0.35)
    kingdom["gold"] += int(12.0 * delta * 20.0) + tax_income
    kingdom["food"] += int(15.0 * delta * 20.0) + int(kingdom.get("workers", 0) * 0.15)
    kingdom["wood"] += int(14.0 * delta * 20.0) + int(kingdom.get("workers", 0) * 0.1)
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

func _update_ai_units(delta: float) -> void:
    for enemy in enemy_units:
        if not is_instance_valid(enemy):
            continue

        var target := _get_nearest_player_target(enemy)
        if target == null:
            continue

        var distance := enemy.global_position.distance_to(target.global_position)
        if distance <= enemy.attack_range:
            enemy.set_attack_target(target)
        else:
            enemy.move_to(target.global_position)
            enemy.attack_target = null

func _get_nearest_player_target(unit: Node3D) -> Node3D:
    var best_target: Node3D = null
    var best_distance := INF

    for candidate in player_units:
        if not is_instance_valid(candidate):
            continue
        var distance := unit.global_position.distance_to(candidate.global_position)
        if distance < best_distance:
            best_distance = distance
            best_target = candidate

    return best_target

func _update_fog_of_war() -> void:
    var revealed_positions: Array = []
    for unit in player_units:
        if is_instance_valid(unit):
            revealed_positions.append(unit.global_position)
    for building in buildings:
        if is_instance_valid(building):
            revealed_positions.append(building.global_position)

    for enemy in enemy_units:
        if not is_instance_valid(enemy):
            continue
        var visible := false
        for position in revealed_positions:
            if enemy.global_position.distance_to(position) <= FOG_VISIBILITY_RADIUS:
                visible = true
                break
        enemy.visible = visible
        enemy.modulate = Color(1, 1, 1, 1.0 if visible else 0.15)

func _check_siege_warfare(delta: float) -> void:
    for city_id in city_nodes:
        var city_root: Node3D = city_nodes[city_id]
        if city_root == null:
            continue

        var owner_id := int(city_root.get_meta("owner_id", -1))
        if owner_id == _get_player_kingdom()["id"]:
            continue

        var enemy_kingdom := _get_kingdom_by_id(owner_id)
        if enemy_kingdom.is_empty():
            continue

        var siege_units_nearby := false
        for unit in player_units:
            if not is_instance_valid(unit):
                continue
            if unit.global_position.distance_to(city_root.global_position) <= SEIGE_RANGE:
                siege_units_nearby = true
                break

        if siege_units_nearby:
            var garrison := city_root.get_meta("garrison", 20)
            city_root.set_meta("garrison", max(0, garrison - 1))
            if city_root.get_meta("garrison", 0) <= 0:
                city_root.set_meta("owner_id", _get_player_kingdom()["id"])
                city_root.set_meta("garrison", 20)
                city_root.set_meta("capture_progress", 0.0)
                enemy_kingdom["territory"] = max(0, enemy_kingdom.get("territory", 0) - 1)
                _get_player_kingdom()["territory"] += 1
                _set_relation(_get_player_kingdom()["id"], enemy_kingdom["id"], -100)
                enemy_kingdom["diplomacy_state"] = "war"
                _get_player_kingdom()["gold"] += 5000

func _check_city_capture() -> void:
    var player_kingdom := _get_player_kingdom()
    for city_id in city_nodes:
        var city_root: Node3D = city_nodes[city_id]
        if city_root == null:
            continue

        var city_owner_id = int(city_root.get_meta("owner_id", -1))
        if city_owner_id == player_kingdom["id"]:
            continue

        var enemy_kingdom := _get_kingdom_by_id(city_owner_id)
        if enemy_kingdom.is_empty():
            continue

        var capture_progress := city_root.get_meta("capture_progress", 0.0)
        var any_player_nearby := false
        for unit in player_units:
            if not is_instance_valid(unit):
                continue
            if unit.global_position.distance_to(city_root.global_position) <= CITY_CAPTURE_DISTANCE:
                any_player_nearby = true
                break

        if any_player_nearby:
            city_root.set_meta("capture_progress", capture_progress + 0.02)
            if city_root.get_meta("capture_progress", 0.0) >= 1.0:
                city_root.set_meta("owner_id", player_kingdom["id"])
                city_root.set_meta("capture_progress", 0.0)
                var wall_node := city_root.get_child(0)
                if wall_node is MeshInstance3D:
                    var wall_material := StandardMaterial3D.new()
                    wall_material.albedo_color = player_kingdom["color"]
                    wall_node.material_override = wall_material
                var label_node := city_root.get_child(2)
                if label_node is Label3D:
                    label_node.modulate = player_kingdom["color"]
                enemy_kingdom["territory"] = max(0, enemy_kingdom.get("territory", 0) - 1)
                player_kingdom["territory"] += 1
                _set_relation(player_kingdom["id"], enemy_kingdom["id"], -100)
                enemy_kingdom["diplomacy_state"] = "war"
                player_kingdom["gold"] += 5000

func _spawn_unit_of_type(unit_type: String) -> void:
    if not _can_afford(UNIT_COSTS.get(unit_type, {})):
        return

    _pay_cost(UNIT_COSTS.get(unit_type, {}))
    var unit = unit_scene.instantiate()
    unit.add_to_group("unit")
    unit.team_id = 0
    unit.unit_name = unit_type.capitalize()
    unit.set_team_color(_get_unit_color(unit_type))
    var spawn_pos := Vector3(-18, 0.5, 8) + Vector3(rng.randf_range(-2.0, 2.0), 0.0, rng.randf_range(-2.0, 2.0))
    unit.global_position = spawn_pos
    unit.move_speed = _get_unit_speed(unit_type)
    unit.max_hp = _get_unit_hp(unit_type)
    unit.hp = unit.max_hp
    unit.attack_damage = _get_unit_damage(unit_type)
    unit.attack_range = _get_unit_range(unit_type)
    world_root.add_child(unit)
    player_units.append(unit)
    _update_ui()

func _get_unit_color(unit_type: String) -> Color:
    match unit_type:
        "infantry": return Color(0.1, 0.75, 0.3)
        "archer": return Color(0.85, 0.8, 0.25)
        "cavalry": return Color(0.4, 0.55, 0.9)
        "knight": return Color(0.75, 0.35, 0.15)
        _: return Color(0.7, 0.7, 0.7)

func _get_unit_speed(unit_type: String) -> float:
    match unit_type:
        "infantry": return 5.5
        "archer": return 4.8
        "cavalry": return 7.2
        "knight": return 6.6
        _: return 5.0

func _get_unit_hp(unit_type: String) -> int:
    match unit_type:
        "infantry": return 28
        "archer": return 22
        "cavalry": return 34
        "knight": return 48
        _: return 20

func _get_unit_damage(unit_type: String) -> int:
    match unit_type:
        "infantry": return 7
        "archer": return 9
        "cavalry": return 11
        "knight": return 15
        _: return 6

func _get_unit_range(unit_type: String) -> float:
    match unit_type:
        "infantry": return 2.4
        "archer": return 8.0
        "cavalry": return 3.0
        "knight": return 3.4
        _: return 2.0

func _can_afford(cost: Dictionary) -> bool:
    var player_kingdom = _get_player_kingdom()
    for key in cost.keys():
        if player_kingdom.get(key, 0) < int(cost[key]):
            return false
    return true

func _pay_cost(cost: Dictionary) -> void:
    var player_kingdom = _get_player_kingdom()
    for key in cost.keys():
        player_kingdom[key] = int(player_kingdom.get(key, 0)) - int(cost[key])

func _place_building_for_type(building_type: String, position: Vector3) -> void:
    if building_type == "":
        return

    var cost := BUILDING_COSTS.get(building_type, {})
    if not _can_afford(cost):
        return

    _pay_cost(cost)
    var building = building_scene.instantiate()
    building.set_building_type(building_type)
    building.global_position = position
    world_root.add_child(building)
    buildings.append(building)
    active_build_type = ""
    _update_ui()

func format_number_display(value: int) -> String:
    if abs(value) >= 1000:
        var scaled := float(value) / 1000.0
        var suffix := "k"
        if value >= 1000000:
            scaled = float(value) / 1000000.0
            suffix = "m"
        var text := String.num(scaled, 1)
        if text.ends_with(".0"):
            text = text.substr(0, text.length() - 2)
        return text + suffix
    return str(value)

func _update_ui() -> void:
    var player_kingdom = _get_player_kingdom()
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
    city_status_label.text = "City: Stonegate | Buildings: %s | Tax: %s%%" % [format_number_display(buildings.size()), str(player_kingdom.get("tax_rate", 15))]
    objectives_label.text = "%s\n%s" % [
        "Objectives\n- Build a prosperous kingdom\n- Explore the world\n- Conquer or dominate the realm",
        _build_diplomacy_summary()
    ]

    if city_panel_visible:
        city_name_label.text = "City: Stonegate"
        ownership_label.text = "Owner: %s" % player_kingdom["name"]
        kingdom_summary_label.text = "Territory: %s | Wealth: %s | Army: %s" % [
            player_kingdom["territory"],
            format_number_display(player_kingdom["gold"]),
            format_number_display(player_units.size())
        ]

func save_game() -> void:
    var data := {
        "save_version": save_version,
        "kingdoms": kingdom_data,
        "day_phase": day_phase,
        "structures": buildings.size(),
        "player_units": player_units.size(),
        "enemy_units": enemy_units.size(),
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
        if not parsed.has("save_version"):
            save_version = 1
        _initialize_diplomacy()
        _update_ui()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
        paused = not paused

    if event is InputEventKey and event.pressed and event.keycode == KEY_S:
        save_game()

    if event is InputEventKey and event.pressed and event.keycode == KEY_L:
        load_game()

    if event is InputEventKey and event.pressed and event.keycode == KEY_C:
        city_panel_visible = !city_panel_visible
        city_panel.visible = city_panel_visible

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if active_build_type != "":
            _handle_build_placement(event.position)
            return
        _handle_left_click(event.position)

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        _handle_right_click(event.position)

func _handle_build_placement(mouse_position: Vector2) -> void:
    var ground_pos := _raycast_ground(mouse_position)
    if ground_pos == null:
        return
    _place_building_for_type(active_build_type, ground_pos)

func _raycast_ground(mouse_position: Vector2) -> Vector3:
    var camera := get_viewport().get_camera_3d()
    var from := camera.project_ray_origin(mouse_position)
    var dir := camera.project_ray_normal(mouse_position)
    var t := -from.y / dir.y
    if is_nan(t) or is_inf(t):
        return Vector3.ZERO
    return from + dir * t

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
        var parent := hit_node.get_parent()
        if parent != null and parent.is_in_group("unit"):
            _select_unit(parent)
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

    var target_node = result["collider"]
    var target_entity: Node3D = null
    var parent := target_node.get_parent()
    if parent != null and parent.is_in_group("unit"):
        target_entity = parent

    if target_entity != null and target_entity.team_id != 0:
        for unit in selected_units:
            if is_instance_valid(unit):
                unit.set_attack_target(target_entity)
        return

    var target_position := result["position"]
    if selected_units.is_empty():
        return

    for unit in selected_units:
        if is_instance_valid(unit):
            unit.move_to(target_position)
            unit.attack_target = null

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

func _on_farm_button_pressed() -> void:
    active_build_type = "farm"

func _on_house_button_pressed() -> void:
    active_build_type = "house"

func _on_lumber_button_pressed() -> void:
    active_build_type = "lumber_camp"

func _on_quarry_button_pressed() -> void:
    active_build_type = "quarry"

func _on_barracks_button_pressed() -> void:
    active_build_type = "barracks"

func _on_watchtower_button_pressed() -> void:
    active_build_type = "watchtower"

func _on_keep_button_pressed() -> void:
    active_build_type = "keep"

func _unhandled_input(event: InputEvent) -> void:
    _input(event)

