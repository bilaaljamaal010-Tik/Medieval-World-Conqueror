extends Node3D

@export var rotation_speed := 1.2
@export var pan_speed := 1.2
@export var max_zoom := 80.0
@export var min_zoom := 12.0

var camera: Camera3D
var target_yaw := 0.0
var target_pitch := 35.0
var target_distance := 34.0
var drag_active := false
var last_drag := Vector2.ZERO
var pinch_start_distance := 0.0
var pinch_active := false

func _ready() -> void:
    camera = $Camera3D
    _apply_camera_transform()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            target_distance = max(min_zoom, target_distance - 4.0)
            _apply_camera_transform()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            target_distance = min(max_zoom, target_distance + 4.0)
            _apply_camera_transform()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            if event.pressed:
                drag_active = true
                last_drag = event.position
            else:
                drag_active = false

    if event is InputEventMouseMotion:
        if drag_active:
            var delta = event.position - last_drag
            last_drag = event.position
            target_yaw -= delta.x * 0.01 * rotation_speed
            target_pitch = clamp(target_pitch - delta.y * 0.01 * rotation_speed, 15.0, 60.0)
            _apply_camera_transform()

    if event is InputEventScreenDrag:
        if event.index == 0:
            var delta = event.relative
            target_yaw -= delta.x * 0.004
            target_pitch = clamp(target_pitch - delta.y * 0.003, 15.0, 60.0)
            _apply_camera_transform()

    if event is InputEventMagnifyGesture:
        target_distance = clamp(target_distance / event.factor, min_zoom, max_zoom)
        _apply_camera_transform()

func _apply_camera_transform() -> void:
    var offset := Vector3(
        sin(target_yaw) * target_distance,
        target_distance * 0.9,
        cos(target_yaw) * target_distance
    )
    var target_position := Vector3(0, 0, 0)
    var look_target := Vector3(0, 0, 0)
    camera.position = target_position + offset
    camera.look_at(look_target, Vector3.UP)
