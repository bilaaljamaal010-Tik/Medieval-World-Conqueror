extends RefCounted

class_name WorldGenerator

var rng := RandomNumberGenerator.new()

func _init() -> void:
    rng.randomize()

func generate_kingdoms(count: int, player_is_first: bool = true) -> Array:
    var kingdoms: Array = []
    for i in range(count):
        var kingdom_name := "Kingdom %d" % (i + 1)
        if player_is_first and i == 0:
            kingdom_name = "Your Kingdom"
        var kingdom := Kingdom.new(i, kingdom_name, Color.from_hsv((float(i) / float(max(count, 1))) * 1.0, 0.8, 0.8), player_is_first and i == 0)
        kingdoms.append(kingdom)
    return kingdoms
