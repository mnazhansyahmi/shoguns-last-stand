class_name UnitVisual
extends Node2D
## Animation interface for units, drawn by a child InkFigure ("Figure").
## Gameplay only calls set_facing / play_state / flash_hit / set_blinking / set_tint, so the art
## can change without touching combat logic. Every frame the live pose blends toward the pose of
## the current state (FigureKinds), and procedural motion (breathing, stride, recoil, falling,
## dissolving) is layered on top. Nothing here affects gameplay.

const FLASH_TIME: float = 0.15
## A windup this soon after a strike continues the combo (next cut in the sequence).
const COMBO_WINDOW: float = 0.7
const FALL_TIME: float = 0.35
const DISSOLVE_END: float = 0.78
const SPAWN_FADE_TIME: float = 0.4
const BREATH_HZ: float = 0.3
## Blade samples along a slash trail.
const TRAIL_SAMPLES: int = 10
## Dash afterimages are left this far apart in time.
const AFTERIMAGE_INTERVAL: float = 0.05
const AFTERIMAGE_COUNT: int = 3
## A figure further than this outside the screen (screen pixels) is not re-posed each frame;
## it catches up the moment it comes back into view. The largest figure is under 350 px tall.
const CULL_MARGIN: float = 360.0
const STATES: Array[StringName] = [&"idle", &"run", &"windup", &"heavy_windup", &"strike", &"cast",
		&"dash", &"hurt", &"spawn", &"dead"]

@export var figure_kind: InkFigure.Kind = InkFigure.Kind.SAMURAI
## Figure height in pixels.
@export var figure_height: float = 110.0
## Draw a ring in the figure's accent on the ground under it (the player, so it reads in a crowd).
@export var ground_marker: bool = false

var _figure: InkFigure
## While the figure is see-through it is drawn inside this group, so it fades as one shape
## instead of showing its overlapping parts.
var _fade_group: CanvasGroup
var _pose: FigurePose = FigurePose.new()
var _target: FigurePose = FigurePose.new()
var _state: StringName = &""
var _state_time: float = 0.0
var _time: float = 0.0
var _breath_phase: float = 0.0
var _combo_step: int = 0
var _heavy: bool = false
var _last_strike_time: float = -10.0
var _alpha: float = 1.0
var _base_tint: Color = Color.WHITE
var _blinking: bool = false
var _blink_clock: float = 0.0
var _dissolve_spawned: bool = false
var _afterimages_left: int = 0


func _ready() -> void:
	_figure = get_node_or_null("Figure") as InkFigure
	if _figure == null:
		_figure = InkFigure.new()
		_figure.name = "Figure"
		add_child(_figure)
	_breath_phase = randf() * TAU
	configure(figure_kind, figure_height)


## Sets which figure is drawn and its height in pixels. Returns the local y of the head top.
func configure(kind: InkFigure.Kind, height: float) -> float:
	figure_kind = kind
	figure_height = height
	if _figure == null:
		return -height
	_figure.height = height
	_figure.kind = kind
	_figure.ground_marker = Color(InkPalette.SAMURAI_RED, 0.85) if ground_marker else Color(0.0, 0.0, 0.0, 0.0)
	_target = FigureKinds.pose(kind, _state if _state != &"" else &"idle", _combo_step, _heavy)
	_pose.copy_from(_target)
	_apply()
	return _figure.get_head_top_y()


func get_figure() -> InkFigure:
	return _figure


func get_state() -> StringName:
	return _state


func set_facing(direction: int) -> void:
	if direction != 0:
		scale.x = signf(direction)


func play_state(state: StringName) -> void:
	if state == _state:
		return
	if not STATES.has(state):
		push_warning("UnitVisual: unknown state '%s'." % state)
		return
	var previous: StringName = _state
	var swing_from: FigurePose = FigurePose.new()
	swing_from.copy_from(_pose)
	_state = state
	_state_time = 0.0
	match state:
		&"windup":
			_combo_step = (_combo_step + 1) % 3 if _time - _last_strike_time < COMBO_WINDOW else 0
			_heavy = false
		&"heavy_windup":
			_heavy = true
		&"spawn":
			_alpha = 0.0
			_figure.squash = 0.35
			_spawn_entrance()
		&"dead":
			_dissolve_spawned = false
		&"dash":
			_afterimages_left = AFTERIMAGE_COUNT
		&"idle", &"run":
			if previous == &"dead":
				# Respawn: stand up again out of an ink splash.
				_figure.fall = 0.0
				_alpha = 0.0
				_spawn_entrance()
			_heavy = false
	_target = FigureKinds.pose(figure_kind, state, _combo_step, _heavy)
	if state == &"strike":
		_last_strike_time = _time
		_spawn_slash(swing_from, _target)
	if state == &"hurt" or state == &"strike" or state == &"dash":
		# Snap most of the way so the change reads on the very next frame.
		_pose.blend_toward(_target, 0.55)


## Brief paper-white flash so damage is visible.
func flash_hit() -> void:
	_figure.flash = 1.0


func set_blinking(enabled: bool) -> void:
	_blinking = enabled
	if not enabled:
		_blink_clock = 0.0


func set_tint(color: Color) -> void:
	_base_tint = color


func _process(delta: float) -> void:
	_time += delta
	_state_time += delta
	_pose.blend_toward(_target, 1.0 - exp(-_blend_rate() * delta))
	_update_motion(delta)
	if is_on_screen():
		_apply()


## True when the figure is on screen or near it (off-screen figures skip posing).
func is_on_screen() -> bool:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return true
	var rect: Rect2 = viewport.get_visible_rect()
	if rect.size.x < 2.0:
		return true
	return rect.grow(CULL_MARGIN).has_point(get_global_transform_with_canvas().origin)


func _blend_rate() -> float:
	match _state:
		&"strike":
			return 45.0
		&"windup", &"heavy_windup":
			return _figure.spec.windup_rate if _figure != null else 20.0
		&"hurt", &"dash":
			return 30.0
		&"cast":
			return 14.0
		&"dead":
			return 8.0
	return 10.0


func _update_motion(delta: float) -> void:
	var fig: InkFigure = _figure
	fig.clock += delta
	fig.flash = maxf(fig.flash - delta / FLASH_TIME, 0.0)
	var running: bool = _state == &"run"
	var settle: float = 1.0 - exp(-10.0 * delta)
	fig.stride = lerpf(fig.stride, 1.0 if running else 0.0, settle)
	fig.trail = lerpf(fig.trail, 1.0 if running or _state == &"dash" else 0.0, 1.0 - exp(-4.0 * delta))
	if running:
		var cadence: float = fig.spec.cadence
		if figure_kind == InkFigure.Kind.HOLLOW_SOLDIER:
			# Shambling: uneven steps.
			cadence *= 0.7 + 0.6 * absf(sin(fig.stride_phase))
		fig.stride_phase = fmod(fig.stride_phase + delta * cadence, TAU)
	fig.bob = absf(sin(fig.stride_phase)) * 2.5 * fig.stride
	fig.breath = sin(_time * TAU * BREATH_HZ + _breath_phase)

	match _state:
		&"dead":
			fig.fall = ease(clampf(_state_time / FALL_TIME, 0.0, 1.0), 0.4)
			_alpha = 1.0 - smoothstep(FALL_TIME, DISSOLVE_END, _state_time)
			if not _dissolve_spawned and _state_time >= FALL_TIME * 0.8:
				_dissolve_spawned = true
				_spawn_dissolve()
		&"dash":
			_alpha = minf(_alpha + delta / SPAWN_FADE_TIME, 1.0)
			if _afterimages_left > 0 and _state_time >= float(AFTERIMAGE_COUNT - _afterimages_left) * AFTERIMAGE_INTERVAL:
				_afterimages_left -= 1
				_spawn_afterimage()
		&"spawn":
			fig.squash = lerpf(fig.squash, 1.0, 1.0 - exp(-9.0 * delta))
			_alpha = minf(_alpha + delta / SPAWN_FADE_TIME, 1.0)
		_:
			fig.squash = lerpf(fig.squash, 1.0, 1.0 - exp(-12.0 * delta))
			_alpha = minf(_alpha + delta / SPAWN_FADE_TIME, 1.0)

	var shown: float = _alpha
	if _blinking:
		_blink_clock += delta
		if fmod(_blink_clock, 0.12) < 0.06:
			shown *= 0.35
	modulate = Color(_base_tint, 1.0)
	_set_opacity(shown)


func _set_opacity(opacity: float) -> void:
	var fading: bool = opacity < 0.999
	if fading and _figure.get_parent() == self:
		if _fade_group == null:
			_fade_group = CanvasGroup.new()
			_fade_group.name = "Fade"
			add_child(_fade_group)
		_figure.reparent(_fade_group, false)
	elif not fading and _fade_group != null and _figure.get_parent() == _fade_group:
		_figure.reparent(self, false)
	if _fade_group != null:
		_fade_group.self_modulate.a = opacity


## Copies the blended pose to the figure with idle sway and breathing on top, then redraws.
func _apply() -> void:
	if _figure == null:
		return
	var live: FigurePose = _figure.pose
	live.copy_from(_pose)
	var calm: float = 1.0 - _figure.stride
	if _state == &"idle" or _state == &"run":
		live.blade += sin(_time * 1.7 + _breath_phase) * 0.04 * calm
		live.lean += _figure.breath * 0.012 * calm
	_figure.refresh()


# --- Effects (visual only) ----------------------------------------------------

## Slash trail along the swing from the pose at the end of the windup to the strike pose.
func _spawn_slash(from_pose: FigurePose, to_pose: FigurePose) -> void:
	var spec: FigureKinds.Spec = _figure.spec
	if spec.slam_radius > 0.0:
		var ring: ShockRing = ShockRing.new()
		ring.setup(spec.slam_radius * _figure.get_unit_scale() / 1.9)
		var impact: PackedVector2Array = _figure.weapon_points_for(to_pose, spec.trail_span.y, spec.trail_span.y)
		ring.position = Vector2(impact[0].x, 0.0)
		add_child(ring)
	if spec.trail_span.y <= 0.0:
		return
	var bases: PackedVector2Array = PackedVector2Array()
	var tips: PackedVector2Array = PackedVector2Array()
	var sample: FigurePose = FigurePose.new()
	for i: int in TRAIL_SAMPLES:
		sample.copy_from(from_pose)
		sample.blend_toward(to_pose, ease(float(i) / float(TRAIL_SAMPLES - 1), 0.6))
		var points: PackedVector2Array = _figure.weapon_points_for(sample, spec.trail_span.x, spec.trail_span.y)
		bases.append(points[0])
		tips.append(points[1])
	var trail: SlashTrail = SlashTrail.new()
	trail.setup(bases, tips, spec.trail_core, spec.trail_edge, _heavy)
	add_child(trail)


## Ink splash (defenders) or portal smoke (enemies) at the feet, behind the figure.
func _spawn_entrance() -> void:
	var splash: InkSplash = InkSplash.new()
	var spec: FigureKinds.Spec = _figure.spec
	splash.setup(InkSplash.Style.PORTAL_SMOKE if spec.is_enemy else InkSplash.Style.SUMMON,
			spec.shadow_width * 2.0 * _figure.get_unit_scale())
	add_child(splash)
	move_child(splash, 0)


func _spawn_dissolve() -> void:
	var dissolve: InkDissolve = InkDissolve.new()
	dissolve.setup(_figure.get_body_points(), _figure.spec.death_accent, _figure.get_unit_scale())
	add_child(dissolve)


func _spawn_afterimage() -> void:
	var ghost: Afterimage = Afterimage.new()
	ghost.setup(_figure)
	add_child(ghost)
	ghost.global_transform = global_transform
	move_child(ghost, 0)

