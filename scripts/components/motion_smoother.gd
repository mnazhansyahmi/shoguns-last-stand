class_name MotionSmoother
extends Node
## Draws a node that moves in physics ticks (60/s) at its in-between position on every rendered
## frame, so it glides on monitors that refresh faster (or slower) than the physics rate instead
## of standing still for a frame or two and then jumping a whole tick.
## Add as a child of the moving node (`attach()`): the drawn children in `visuals` get an offset
## that places them at lerp(previous tick, latest tick, fraction through the current tick).
## A node that draws itself reads `get_draw_offset()` in `_draw()` instead.
## Only the view changes: the body, its hitboxes and every gameplay position stay on the tick.
## Moving the body outside physics (spawn, respawn) or by more than SNAP_DISTANCE in one tick
## snaps the view to it instead of sliding there.

const SNAP_DISTANCE: float = 160.0

var visuals: Array[Node2D] = []
## Redraw the body every frame (for a body that draws itself with the offset).
var redraw_body: bool = false

var _body: Node2D
var _previous: Vector2 = Vector2.ZERO
var _latest: Vector2 = Vector2.ZERO
## The offset currently added to each visual's position (local to the body).
var _applied: Vector2 = Vector2.ZERO
var _started: bool = false


## Creates a smoother under `body` for its drawn children `p_visuals`.
static func attach(body: Node2D, p_visuals: Array[Node2D] = [], p_redraw_body: bool = false) -> MotionSmoother:
	var smoother: MotionSmoother = MotionSmoother.new()
	smoother.name = "MotionSmoother"
	smoother.visuals = p_visuals
	smoother.redraw_body = p_redraw_body
	body.add_child(smoother)
	return smoother


func _ready() -> void:
	_body = get_parent() as Node2D
	# Before the visuals process (a figure plants its feet from its drawn position); its physics
	# step runs after the body's own, which comes first in tree order.
	process_priority = -10
	snap()


## Puts the view on the body's current position, with no in-between.
func snap() -> void:
	if _body == null:
		return
	_previous = _body.global_position
	_latest = _previous
	_started = true


## Where the body is drawn this frame (global).
func get_display_position() -> Vector2:
	if _body == null:
		return Vector2.ZERO
	var now: Vector2 = _body.global_position
	if not _started or not now.is_equal_approx(_latest):
		# Moved since the last tick record (outside physics): show it where it is.
		return now
	return _previous.lerp(_latest, Engine.get_physics_interpolation_fraction())


## The offset from the body to where it is drawn, in the body's own space.
func get_draw_offset() -> Vector2:
	if _body == null:
		return Vector2.ZERO
	return _body.global_transform.basis_xform_inv(get_display_position() - _body.global_position)


func _physics_process(_delta: float) -> void:
	if _body == null:
		return
	var now: Vector2 = _body.global_position
	if not _started or now.distance_to(_latest) > SNAP_DISTANCE:
		snap()
		return
	_previous = _latest
	_latest = now


func _process(_delta: float) -> void:
	if _body == null:
		return
	if not _body.global_position.is_equal_approx(_latest):
		snap()
	var offset: Vector2 = get_draw_offset()
	if offset == _applied:
		# Standing still (or the same step): touching the transforms would only redo them.
		return
	for i: int in range(visuals.size() - 1, -1, -1):
		var visual: Node2D = visuals[i]
		if not is_instance_valid(visual):
			visuals.remove_at(i)
			continue
		visual.position += offset - _applied
	_applied = offset
	if redraw_body:
		_body.queue_redraw()
