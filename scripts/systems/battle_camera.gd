class_name BattleCamera
extends Camera2D
## Battle camera, zoomed in so units read on a phone. It follows its target horizontally inside
## the battlefield bounds (looking a little ahead of where the target faces), keeps the ground
## line low on screen, and lifts the view when touch controls need room at the bottom.
## Only the view changes: gameplay positions, ranges and hitboxes never depend on the camera.

@export var battle_zoom: float = 1.5
## World y of the ground line.
@export var ground_y: float = 880.0
## Where the ground line sits on screen without touch controls (fraction of screen height).
@export var ground_screen_fraction: float = 0.8
## World x range the view may show: a bit of wall behind the gate, the portal on the right.
@export var bounds_left: float = -260.0
@export var bounds_right: float = 2160.0
@export var look_ahead: float = 140.0
## How quickly the view catches up with the target (1/s).
@export var follow_rate: float = 5.0

## Followed node (the player). Freed or unset = hold the centre of the field.
var target: Node2D

var _base_y: float = 540.0


func _ready() -> void:
	zoom = Vector2(battle_zoom, battle_zoom)
	update_base()
	snap()


## Recomputes the resting height (call when the viewport size changes).
func update_base() -> void:
	_base_y = ground_y - (ground_screen_fraction - 0.5) * get_viewport_rect().size.y / battle_zoom
	position.y = _base_y


## Screen y of the ground line before any lift.
func get_ground_screen_y() -> float:
	return (ground_y - _base_y) * battle_zoom + get_viewport_rect().size.y * 0.5


## Moves the view down by `screen_lift` screen pixels (the world goes up by that much).
func set_lift(screen_lift: float) -> void:
	position.y = _base_y + screen_lift / battle_zoom


## Current lift in world units.
func get_lift() -> float:
	return position.y - _base_y


## World size the screen shows.
func get_view_size() -> Vector2:
	return get_viewport_rect().size / battle_zoom


## World rect the screen shows right now (includes screen shake).
func get_view_rect() -> Rect2:
	var view: Vector2 = get_view_size()
	return Rect2(get_screen_center_position() - view * 0.5, view)


## Where the view wants to be: the target plus look-ahead, kept inside the bounds.
func get_desired_x() -> float:
	var x: float = (bounds_left + bounds_right) * 0.5
	if is_instance_valid(target):
		var facing: Variant = target.get("facing")
		x = target.global_position.x + look_ahead * (float(facing) if facing is int or facing is float else 0.0)
	var half: float = get_view_size().x * 0.5
	var low: float = bounds_left + half
	var high: float = bounds_right - half
	if low > high:
		return (bounds_left + bounds_right) * 0.5
	return clampf(x, low, high)


func snap() -> void:
	position.x = get_desired_x()


func _process(delta: float) -> void:
	position.x = lerpf(position.x, get_desired_x(), 1.0 - exp(-follow_rate * delta))
