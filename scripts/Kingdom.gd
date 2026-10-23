class_name Kingdom
extends RefCounted

var id: int
var name: String
var color: Color
var gold: int = 0
var food: int = 0
var wood: int = 0
var stone: int = 0
var iron: int = 0
var population: int = 0
var territory: int = 0
var military_power: int = 0
var is_player: bool = false
var relations: Dictionary = {}
var ai_goal: String = "expand"

func _init(p_id: int, p_name: String, p_color: Color, player: bool = false) -> void:
    id = p_id
    name = p_name
    color = p_color
    is_player = player
    gold = 1_000_000 if player else 250_000
    food = 1_000_000 if player else 250_000
    wood = 1_000_000 if player else 250_000
    stone = 1_000_000 if player else 250_000
    iron = 1_000_000 if player else 250_000
    population = 150 if player else 80
    territory = 1
    military_power = 25 if player else 18

func to_dict() -> Dictionary:
    return {
        "id": id,
        "name": name,
        "color": {"r": color.r, "g": color.g, "b": color.b, "a": color.a},
        "gold": gold,
        "food": food,
        "wood": wood,
        "stone": stone,
        "iron": iron,
        "population": population,
        "territory": territory,
        "military_power": military_power,
        "is_player": is_player,
        "relations": relations,
        "ai_goal": ai_goal,
    }

static func from_dict(data: Dictionary) -> Kingdom:
    var kingdom := Kingdom.new(data.get("id", 0), data.get("name", "Unknown"), Color(data.get("color", {}).get("r", 1.0), data.get("color", {}).get("g", 1.0), data.get("color", {}).get("b", 1.0), data.get("color", {}).get("a", 1.0)), data.get("is_player", false))
    kingdom.gold = int(data.get("gold", 0))
    kingdom.food = int(data.get("food", 0))
    kingdom.wood = int(data.get("wood", 0))
    kingdom.stone = int(data.get("stone", 0))
    kingdom.iron = int(data.get("iron", 0))
    kingdom.population = int(data.get("population", 0))
    kingdom.territory = int(data.get("territory", 0))
    kingdom.military_power = int(data.get("military_power", 0))
    kingdom.relations = data.get("relations", {})
    kingdom.ai_goal = str(data.get("ai_goal", "expand"))
    return kingdom
