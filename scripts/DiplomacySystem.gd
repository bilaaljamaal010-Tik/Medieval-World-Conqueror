extends RefCounted

class_name DiplomacySystem

var relations: Dictionary = {}

func set_relation(kingdom_a: int, kingdom_b: int, value: int) -> void:
    relations["%d:%d" % [kingdom_a, kingdom_b]] = value
    relations["%d:%d" % [kingdom_b, kingdom_a]] = value

func get_relation(kingdom_a: int, kingdom_b: int) -> int:
    return int(relations.get("%d:%d" % [kingdom_a, kingdom_b], 0))

func can_request_support(kingdom_a: int, kingdom_b: int) -> bool:
    return get_relation(kingdom_a, kingdom_b) > 40
