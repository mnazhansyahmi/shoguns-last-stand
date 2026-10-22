class_name EnemyProp
extends Node2D
## A weapon or effect drawn with an enemy's figure, for the Region 2 enemies that reuse another enemy's painted body until
## they have art of their own: the Spectral Archer's bow, the Shield Bearer's shield, the Flying Spirit's glowing ink wisp
## (its body is hidden) and the Burning General's fire. The bow and the shield replace the body's own weapon and follow
## its front hand every frame. A child of the unit's UnitVisual, so it turns with it. Visual only.

enum Kind { NONE, BOW, SHIELD, WISP, FIRE_AURA }

## A broken shield's halves fall and fade over this long.
const SHIELD_FALL_TIME: float = 0.7
const WISP_FADE_TIME: float = 0.6
const SPAWN_FADE_TIME: float = 0.4

var kind: Kind = Kind.NONE
var _visual: UnitVisual
var _figure: InkFigure
var _height: float = 110.0
var _hover: float = 0.0
var _clock: float = 0.0
var _broken_time: float = -1.0
var _dying_time: float = -1.0


## Call before adding to the visual. `height` is the figure's height, `hover` how high a flyer floats.
func setup(p_kind: Kind, visual: UnitVisual, height: float, hover: float = 0.0) -> void:
	kind = p_kind
	_visual = visual
	_figure = visual.get_figure()
	_height = height
	_hover = hover


func _ready() -> void:
	name = "Prop"
	_clock = randf() * 10.0
	if _figure == null:
		return
	if kind == Kind.BOW or kind == Kind.SHIELD:
		hide_weapon(_figure)
	elif kind == Kind.WISP:
		_figure.visible = false


## Hides the figure's own held weapon (its "weapon" part), so the prop's weapon stands in for it.
static func hide_weapon(figure: InkFigure) -> void:
	for node: Node in figure.find_children("*", "", true, false):
		var part: FigurePart = node as FigurePart
		if part != null and part.part_name == &"weapon":
			part.visible = false


func is_shield_up() -> bool:
	return kind == Kind.SHIELD and _broken_time < 0.0


## The shield splits in two and falls away.
func break_shield() -> void:
	if _broken_time < 0.0:
		_broken_time = 0.0


## The wisp fades out with its owner.
func fade_out() -> void:
	if _dying_time < 0.0:
		_dying_time = 0.0


func _process(delta: float) -> void:
	_clock += delta
	if _broken_time >= 0.0:
		_broken_time += delta
	if _dying_time >= 0.0:
		_dying_time += delta
	if _visual == null or _visual.is_on_screen():
		queue_redraw()


## Where the bow or the shield is held: in front of the chest, following the figure's front hand a little (the Hollow
## Soldier's hands hang low as it hunches, so the hand alone would put them at its knees).
func _hand() -> Vector2:
	var chest: Vector2 = Vector2(_height * 0.2, -_height * 0.55)
	if _figure == null:
		return chest
	return chest.lerp(to_local(_figure.to_global(_figure.front_hand)), 0.25)


func _state() -> StringName:
	return _visual.get_state() if _visual != null else &"idle"


func _draw() -> void:
	match kind:
		Kind.BOW:
			_draw_bow()
		Kind.SHIELD:
			_draw_shield()
		Kind.WISP:
			_draw_wisp()
		Kind.FIRE_AURA:
			_draw_fire_aura()


## A longbow held upright in the front hand; at full draw the string comes back with a pale arrow on it.
func _draw_bow() -> void:
	var hand: Vector2 = _hand()
	var reach: float = _height * 0.3
	var drawn: bool = _state() == &"windup"
	var limb: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var t: float = lerpf(-1.0, 1.0, float(i) / 12.0)
		limb.append(hand + Vector2(reach * 0.3 * (1.0 - t * t) + 2.0, t * reach))
	var top: Vector2 = limb[0]
	var bottom: Vector2 = limb[limb.size() - 1]
	var nock: Vector2 = hand + Vector2(-reach * 0.5 if drawn else 0.0, 0.0)
	InkBrush.glow(self, hand, reach * 0.9, Color(InkPalette.SPIRIT, 0.12))
	draw_polyline(PackedVector2Array([top, nock, bottom]), Color(InkPalette.PAPER, 0.6), 1.5, true)
	InkBrush.stroke(self, limb, 3.0, 4.5, InkPalette.INK_DETAIL)
	draw_polyline(limb, Color(InkPalette.SPIRIT, 0.45), 1.2, true)
	if drawn:
		draw_line(nock, hand + Vector2(reach * 0.55, 0.0), Color(InkPalette.SPIRIT, 0.85), 2.0, true)


## A tall wooden tate shield in front of the body, iron-rimmed with a pale crest; once broken its halves fall and fade.
func _draw_shield() -> void:
	var center: Vector2 = _hand() + Vector2(_height * 0.02, _height * 0.08)
	var half: Vector2 = Vector2(_height * 0.15, _height * 0.27)
	var alpha: float = 1.0
	var drop: float = 0.0
	var spin: float = 0.0
	if _broken_time >= 0.0:
		var u: float = _broken_time / SHIELD_FALL_TIME
		if u >= 1.0:
			return
		alpha = 1.0 - u
		drop = 260.0 * u * u
		spin = 0.9 * u
	for side: float in ([-1.0, 1.0] if _broken_time >= 0.0 else [0.0]):
		var xf: Transform2D = Transform2D(spin * side, center + Vector2(side * (6.0 + drop * 0.15), drop))
		var body: PackedVector2Array = _shield_outline(half, side)
		var rim: PackedVector2Array = body.duplicate()
		rim.append(rim[0])
		draw_colored_polygon(xf * body, Color(InkPalette.INK_BACK, alpha))
		draw_polyline(xf * rim, Color(InkPalette.STEEL.darkened(0.35), alpha), 3.0, true)
		if side <= 0.0:
			draw_circle(xf * Vector2(side * half.x * 0.0, -half.y * 0.25), half.x * 0.42, Color(InkPalette.HOLLOW_PURPLE, 0.75 * alpha))
		# Planks.
		for k: int in 2:
			var x: float = lerpf(-half.x, half.x, (float(k) + 1.0) / 3.0)
			if side == 0.0 or signf(x) == side:
				draw_line(xf * Vector2(x, -half.y + 4.0), xf * Vector2(x, half.y - 4.0), Color(InkPalette.INK, 0.6 * alpha), 1.5)


## The shield's outline (whole, or the half on `side` when it has split down a jagged crack).
static func _shield_outline(half: Vector2, side: float) -> PackedVector2Array:
	if side == 0.0:
		return PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	var crack: PackedVector2Array = PackedVector2Array([Vector2(2.0, -half.y), Vector2(-3.0, -half.y * 0.4), Vector2(3.0, half.y * 0.2),
			Vector2(-2.0, half.y)])
	var outline: PackedVector2Array = PackedVector2Array([Vector2(side * half.x, -half.y)])
	outline.append_array(crack)
	outline.append(Vector2(side * half.x, half.y))
	return outline


## A glowing ink wisp: a dark flame of ink with a spirit-blue glow and two pale eyes, floating and bobbing, its tail
## streaming behind; it swells as it winds up and dives when it strikes.
func _draw_wisp() -> void:
	var alpha: float = 1.0
	if _dying_time >= 0.0:
		alpha = maxf(1.0 - _dying_time / WISP_FADE_TIME, 0.0)
	alpha *= clampf(_clock / SPAWN_FADE_TIME, 0.0, 1.0) if _clock < SPAWN_FADE_TIME else 1.0
	if alpha <= 0.0:
		return
	var state: StringName = _state()
	var radius: float = _height * 0.22 * (1.18 if state == &"windup" else 1.0)
	var bob: float = sin(_clock * 2.6) * 6.0
	var dive: float = _hover * 0.55 if state == &"strike" else 0.0
	var center: Vector2 = Vector2(0.0, -_hover - _height * 0.45 + bob + dive)
	InkBrush.glow(self, center, radius * 3.2, Color(InkPalette.SPIRIT, 0.22 * alpha))
	# The tail: a ribbon of ink trailing behind (local -x is behind the way it faces), waving.
	var tail: PackedVector2Array = PackedVector2Array()
	for i: int in 9:
		var u: float = float(i) / 8.0
		tail.append(center + Vector2(-u * radius * 3.2, sin(_clock * 5.0 - u * 4.0) * radius * 0.35 * u + u * radius * 0.4))
	InkBrush.stroke(self, tail, radius * 1.3, 1.0, Color(InkPalette.INK, 0.8 * alpha))
	InkBrush.stroke(self, tail, radius * 0.5, 0.5, Color(InkPalette.SPIRIT_DEEP, 0.5 * alpha))
	draw_circle(center, radius * 1.05, Color(InkPalette.SPIRIT, 0.45 * alpha))
	draw_circle(center, radius, Color(InkPalette.INK, 0.92 * alpha))
	# A flickering crown of ink flame on top.
	var crown: PackedVector2Array = PackedVector2Array()
	for i: int in 7:
		var u: float = float(i) / 6.0
		var angle: float = PI + u * PI
		var lick: float = 1.0 + (0.5 + 0.3 * sin(_clock * 9.0 + u * 7.0)) * (1.0 - absf(u - 0.5) * 1.4)
		crown.append(center + Vector2.from_angle(angle) * radius * lick)
	draw_colored_polygon(crown, Color(InkPalette.INK, 0.92 * alpha))
	for eye: float in [-1.0, 1.0]:
		draw_circle(center + Vector2(radius * 0.25 + eye * radius * 0.28, -radius * 0.1), radius * 0.12, Color(InkPalette.SPIRIT, alpha))
		draw_circle(center + Vector2(radius * 0.25 + eye * radius * 0.28, -radius * 0.1), radius * 0.06, Color(InkPalette.PAPER, alpha))


## The Burning General's fire: low flames licking up around his feet and a hot glow on his body.
func _draw_fire_aura() -> void:
	var rage: int = _figure.rage if _figure != null else 1
	var strength: float = 0.6 + 0.2 * float(rage - 1)
	InkBrush.glow(self, Vector2(0.0, -_height * 0.45), _height * 0.7, Color(InkPalette.HATAMOTO_ORANGE, 0.16 * strength))
	var tongues: int = 5 + 2 * rage
	for k: int in tongues:
		var u: float = (float(k) + 0.5) / float(tongues)
		var x: float = lerpf(-_height * 0.32, _height * 0.32, u)
		var flicker: float = 0.6 + 0.4 * sin(_clock * (8.0 + float(k)) + float(k) * 2.3)
		var tall: float = _height * (0.12 + 0.14 * (1.0 - absf(u - 0.5) * 2.0)) * flicker * strength
		var w: float = _height * 0.05
		var lean: float = sin(_clock * 3.0 + float(k)) * w
		draw_colored_polygon(PackedVector2Array([Vector2(x - w, 0.0), Vector2(x + lean, -tall), Vector2(x + w, 0.0)]),
				Color(InkPalette.HATAMOTO_ORANGE, 0.75))
		draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.45, 0.0), Vector2(x + lean * 0.6, -tall * 0.6), Vector2(x + w * 0.45, 0.0)]),
				Color(InkPalette.PAPER, 0.6))
