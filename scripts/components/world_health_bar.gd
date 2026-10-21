class_name WorldHealthBar
extends Node2D
## Simple health bar drawn in world space, centered on this node.
## Enemy and ally bars use `hide_until_damaged` (a full-health crowd shows no bars) and `stagger`: bars
## that would overlap are stacked upward so each stays readable in a melee. Allies stack among themselves
## (their own `stagger_group`), so the enemies' layout is unchanged by allies nearby.

## A bar that hides until damaged goes away again this long after the unit was last hit.
const HIDE_DELAY: float = 2.0
## It fades over the last part of that time.
const FADE_TIME: float = 0.4

## Height of one stagger step (bar plus frame and a gap).
const STAGGER_STEP: float = 16.0
## Bars closer than this (plus their half widths) count as overlapping.
const STAGGER_GAP: float = 6.0

@export var bar_size: Vector2 = Vector2(120.0, 12.0)
@export var fill_color: Color = Color("#d0453a")
@export var back_color: Color = Color(InkPalette.INK, 0.75)
## Stay hidden while at full health; appear on the first damage.
@export var hide_until_damaged: bool = false
## Stack upward when overlapping other staggering bars.
@export var stagger: bool = false
## Bars only stack with bars of the same group (0 = enemies, 1 = allies).
@export var stagger_group: int = 0

static var _stagger_bars: Array[WorldHealthBar] = []
static var _layout_frame: int = -1

var _ratio: float = 1.0
var _base_position: Vector2 = Vector2.ZERO
var _has_base: bool = false
var _level: int = 0
var _last_current: float = -1.0
var _since_hit: float = 0.0


func _enter_tree() -> void:
	if stagger and not _stagger_bars.has(self):
		_stagger_bars.append(self)


func _exit_tree() -> void:
	_stagger_bars.erase(self)


func _ready() -> void:
	if not _has_base:
		_base_position = position
	if hide_until_damaged and _ratio >= 1.0:
		visible = false


## Resting position (above the unit's head); staggering moves the bar up from here.
func set_base_position(value: Vector2) -> void:
	_base_position = value
	_has_base = true
	position = value - Vector2(0.0, STAGGER_STEP * _level)


func get_stagger_level() -> int:
	return _level


func set_values(current: float, maximum: float) -> void:
	set_ratio(current / maxf(maximum, 0.001))
	var was_hit: bool = _last_current >= 0.0 and current < _last_current - 0.001
	_last_current = current
	if hide_until_damaged and current < maximum - 0.001 and (was_hit or not visible):
		# Every hit brings the bar back and restarts the two-second timer.
		visible = true
		_since_hit = 0.0
		modulate.a = 1.0


## True while the bar is on screen because the unit was hit recently.
func is_showing_recent_hit() -> bool:
	return visible and _since_hit < HIDE_DELAY


func set_ratio(ratio: float) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	if hide_until_damaged and visible:
		_since_hit += delta
		if _since_hit >= HIDE_DELAY:
			visible = false
		else:
			modulate.a = clampf((HIDE_DELAY - _since_hit) / FADE_TIME, 0.0, 1.0)
	if stagger and Engine.get_process_frames() != _layout_frame:
		_layout_frame = Engine.get_process_frames()
		layout_staggered()


## Stacks the visible staggering bars: left to right, each takes the lowest level not used by
## an overlapping bar already placed.
static func layout_staggered() -> void:
	var shown: Array[WorldHealthBar] = []
	for bar: WorldHealthBar in _stagger_bars:
		if is_instance_valid(bar) and bar.is_visible_in_tree():
			shown.append(bar)
	shown.sort_custom(func(a: WorldHealthBar, b: WorldHealthBar) -> bool: return a._base_x() < b._base_x())
	for i: int in shown.size():
		var bar: WorldHealthBar = shown[i]
		var used: Dictionary = {}
		for j: int in i:
			var other: WorldHealthBar = shown[j]
			if other.stagger_group != bar.stagger_group:
				continue
			var reach: float = (bar.bar_size.x + other.bar_size.x) * 0.5 + STAGGER_GAP
			if absf(bar._base_x() - other._base_x()) < reach:
				# Different unit heights have different baseline y values. Reserve
				# levels that actually touch the already placed bar, not its level
				# number (which is relative to that other unit's own baseline).
				var clearance: float = (bar.bar_size.y + other.bar_size.y) * 0.5 + STAGGER_GAP
				var delta_y: float = bar._base_y() - other.global_position.y
				var first: int = maxi(0, floori((delta_y - clearance) / STAGGER_STEP) + 1)
				var last: int = ceili((delta_y + clearance) / STAGGER_STEP) - 1
				for occupied: int in range(first, last + 1): used[occupied] = true
		var level: int = 0
		while used.has(level):
			level += 1
		# Moved by the change of level only, so an offset someone else adds (MotionSmoother) is kept.
		bar.position.y += STAGGER_STEP * float(bar._level - level)
		bar._level = level


func _base_x() -> float:
	return global_position.x + (_base_position.x - position.x)


func _base_y() -> float:
	return global_position.y + (_base_position.y - position.y)


func _draw() -> void:
	var origin: Vector2 = -bar_size * 0.5
	draw_rect(Rect2(origin - Vector2(3.0, 3.0), bar_size + Vector2(6.0, 6.0)), back_color)
	draw_rect(Rect2(origin, Vector2(bar_size.x * _ratio, bar_size.y)), fill_color)
	draw_rect(Rect2(origin - Vector2(3.0, 3.0), bar_size + Vector2(6.0, 6.0)), Color(InkPalette.PARCHMENT, 0.35), false, 1.5)
