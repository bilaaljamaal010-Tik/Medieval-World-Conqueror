extends RefCounted

class_name ResourceEconomy

func get_starting_resources() -> Dictionary:
    return {
        "gold": 1_000_000,
        "food": 1_000_000,
        "wood": 1_000_000,
        "stone": 1_000_000,
        "iron": 1_000_000,
    }

func tick_kingdom(kingdom: Kingdom, delta: float) -> void:
    kingdom.gold += int(120.0 * delta)
    kingdom.food += int(130.0 * delta)
    kingdom.wood += int(110.0 * delta)
    kingdom.stone += int(90.0 * delta)
    kingdom.iron += int(80.0 * delta)
