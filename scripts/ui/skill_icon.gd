class_name SkillIcon
extends Control
## One round skill icon of the keyboard HUD: a bold, simple light symbol of the skill (glyph(): dash arrows, a heavy
## cut, a crescent, a bow, a war cry, a sword or a shield) with an ink outline, in a dark disc with a ring, a small key
## badge at its lower right, and its state:
##   - cooling down: a dark radial sweep over the icon, shrinking as the time runs out, with the seconds left on it;
##   - ready: a soft glow behind it, and no text;
##   - locked: dimmed, with a small padlock only. How to unlock it is the tooltip (hover) and a message when tapped.
## The ally stance uses the same icon: set_kind() swaps the sword (CHARGE) for the shield (HOLD).

## The player tapped a locked icon: `text` ("Clear stage 2") says what unlocks it.
signal locked_pressed(text: String)

const DIAMETER: float = 86.0
const BADGE_SIZE: float = 26.0
const SWEEP_STEPS: int = 28
## The symbol reaches this fraction of the disc's radius from its centre.
const GLYPH_RADIUS: float = 0.62
## Light symbol on the dark frame, with an ink outline this much wider than each stroke.
const GLYPH_COLOR: Color = InkPalette.PARCHMENT
const GLYPH_OUTLINE: float = 6.0

## The symbol of the current kind: [strokes, fills] in units of the glyph radius (see glyph()).
var _glyph: Array = []


func _ready() -> void:
	_refresh_art()


func _refresh_art() -> void:
	_glyph = glyph(kind)
	queue_redraw()


## The bold symbol of a skill as [strokes, fills], points in units of the glyph radius around the centre: a stroke is
## [points, width] (width in radius units), a fill a polygon. Simple shapes that read at a glance, not pictures.
static func glyph(of_kind: UpgradeIcon.Kind) -> Array:
	var strokes: Array = []
	var fills: Array = []
	match of_kind:
		UpgradeIcon.Kind.DASH:
			# Two chevrons with speed lines behind them.
			for x: float in [-0.15, 0.45]:
				strokes.append([PackedVector2Array([Vector2(x - 0.4, -0.7), Vector2(x + 0.3, 0.0), Vector2(x - 0.4, 0.7)]), 0.3])
			for y: float in [-0.45, 0.0, 0.45]:
				strokes.append([PackedVector2Array([Vector2(-1.05, y), Vector2(-0.7, y)]), 0.16])
		UpgradeIcon.Kind.HEAVY:
			# A broad blade cutting down to the right, its guard, and the impact where it lands.
			strokes.append([PackedVector2Array([Vector2(-0.55, -0.55), Vector2(0.55, 0.55)]), 0.34])
			strokes.append([PackedVector2Array([Vector2(-0.95, -0.95), Vector2(-0.62, -0.62)]), 0.2])
			strokes.append([PackedVector2Array([Vector2(-0.82, -0.38), Vector2(-0.38, -0.82)]), 0.18])
			for angle: float in [-0.15, 0.78, 1.7]:
				var out: Vector2 = Vector2.from_angle(angle)
				strokes.append([PackedVector2Array([Vector2(0.62, 0.62) + out * 0.28, Vector2(0.62, 0.62) + out * 0.6]), 0.14])
		UpgradeIcon.Kind.SPIRIT_SLASH:
			# A crescent: the outer arc and a thinner inner arc meeting at two points.
			var crescent: PackedVector2Array = PackedVector2Array()
			for i: int in 17:
				crescent.append(Vector2.from_angle(lerpf(-1.25, 1.25, float(i) / 16.0)) + Vector2(-0.25, 0.0))
			for i: int in 17:
				var t: float = 1.0 - float(i) / 16.0
				crescent.append(Vector2.from_angle(lerpf(-1.05, 1.05, t)) * Vector2(0.42, 0.82) + Vector2(-0.25, 0.0))
			fills.append(crescent)
		UpgradeIcon.Kind.BOW:
			# The bow's curve, its string, and a nocked arrow.
			var limb: PackedVector2Array = PackedVector2Array()
			for i: int in 13:
				limb.append(Vector2(-0.2, 0.0) + Vector2.from_angle(lerpf(-1.15, 1.15, float(i) / 12.0)))
			strokes.append([limb, 0.24])
			strokes.append([PackedVector2Array([limb[0], Vector2(-0.45, 0.0), limb[12]]), 0.08])
			strokes.append([PackedVector2Array([Vector2(-0.45, 0.0), Vector2(0.95, 0.0)]), 0.12])
			fills.append(PackedVector2Array([Vector2(0.85, -0.22), Vector2(1.15, 0.0), Vector2(0.85, 0.22)]))
		UpgradeIcon.Kind.WAR_CRY:
			# A shout: a source and three widening sound arcs.
			fills.append(_circle(Vector2(-0.7, 0.0), 0.26))
			for i: int in 3:
				var arc: PackedVector2Array = PackedVector2Array()
				for k: int in 9:
					arc.append(Vector2(-0.7, 0.0) + Vector2.from_angle(lerpf(-0.8, 0.8, float(k) / 8.0)) * (0.65 + 0.42 * float(i)))
				strokes.append([arc, 0.2])
		UpgradeIcon.Kind.STANCE_CHARGE:
			# A sword pointing forward and up: advance.
			strokes.append([PackedVector2Array([Vector2(-0.55, 0.55), Vector2(0.95, -0.95)]), 0.24])
			strokes.append([PackedVector2Array([Vector2(-0.95, 0.95), Vector2(-0.6, 0.6)]), 0.22])
			strokes.append([PackedVector2Array([Vector2(-0.82, 0.34), Vector2(-0.34, 0.82)]), 0.18])
		UpgradeIcon.Kind.STANCE_HOLD:
			# A shield: stand and defend.
			fills.append(PackedVector2Array([Vector2(-0.8, -0.85), Vector2(0.8, -0.85), Vector2(0.8, 0.1), Vector2(0.0, 1.0),
					Vector2(-0.8, 0.1)]))
		_:
			fills.append(_circle(Vector2.ZERO, 0.5))
	return [strokes, fills]


static func _circle(center: Vector2, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 16:
		points.append(center + Vector2.from_angle(TAU * float(i) / 16.0) * radius)
	return points


## Draws `symbol` (glyph()) centred on `center`, `radius` units from it: an ink outline under every shape, then the
## light shapes themselves.
static func draw_glyph(ci: CanvasItem, symbol: Array, center: Vector2, radius: float, color: Color) -> void:
	for pass_index: int in 2:
		var outline: bool = pass_index == 0
		var paint: Color = Color(InkPalette.INK, 0.9 * color.a) if outline else color
		for stroke: Array in symbol[0]:
			var points: PackedVector2Array = PackedVector2Array()
			for point: Vector2 in (stroke[0] as PackedVector2Array):
				points.append(center + point * radius)
			var width: float = float(stroke[1]) * radius + (GLYPH_OUTLINE if outline else 0.0)
			ci.draw_polyline(points, paint, width, true)
			# Round ends, so thick strokes do not stop in hard corners.
			for end: Vector2 in [points[0], points[points.size() - 1]]:
				ci.draw_circle(end, width * 0.5, paint)
		for shape: PackedVector2Array in symbol[1]:
			var points: PackedVector2Array = PackedVector2Array()
			for point: Vector2 in shape:
				points.append(center + point * radius)
			if outline:
				var ring: PackedVector2Array = points.duplicate()
				ring.append(points[0])
				ci.draw_polyline(ring, paint, GLYPH_OUTLINE, true)
			else:
				ci.draw_colored_polygon(points, paint)


var kind: UpgradeIcon.Kind = UpgradeIcon.Kind.DASH
## The ring colour while the skill is cooling down or idle.
var accent: Color = InkPalette.GOLD
var skill_name: String = ""
## The keyboard key of the skill, on the badge ("" = no badge).
var key_hint: String = ""
## Set while the skill is locked: "Clear stage 2".
var locked_text: String = ""
var cooldown_left: float = 0.0
var cooldown_total: float = 1.0


func _init() -> void:
	custom_minimum_size = Vector2(DIAMETER, DIAMETER)
	size = Vector2(DIAMETER, DIAMETER)
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(p_kind: UpgradeIcon.Kind, p_accent: Color, p_name: String, p_key: String) -> void:
	kind = p_kind
	_refresh_art()
	accent = p_accent
	skill_name = p_name
	key_hint = p_key
	_update_tooltip()
	queue_redraw()


func set_kind(p_kind: UpgradeIcon.Kind) -> void:
	if p_kind == kind:
		return
	kind = p_kind
	_refresh_art()
	queue_redraw()


func set_key_hint(text: String) -> void:
	if text == key_hint:
		return
	key_hint = text
	queue_redraw()


func set_skill_name(text: String) -> void:
	skill_name = text
	_update_tooltip()


## `text` empty = unlocked.
func set_locked(text: String) -> void:
	if text == locked_text:
		return
	locked_text = text
	_update_tooltip()
	queue_redraw()


func is_locked() -> bool:
	return not locked_text.is_empty()


func set_cooldown(left: float, total: float) -> void:
	var new_left: float = maxf(left, 0.0)
	var new_total: float = maxf(total, 0.001)
	if is_equal_approx(new_left, cooldown_left) and is_equal_approx(new_total, cooldown_total):
		return
	cooldown_left = new_left
	cooldown_total = new_total
	queue_redraw()


## Usable now: not locked and not cooling down (it glows).
func is_ready() -> bool:
	return not is_locked() and cooldown_left <= 0.0


## The seconds shown on the sweep ("" when it is not cooling down).
func cooldown_text() -> String:
	if cooldown_left <= 0.0 or is_locked():
		return ""
	return "%.1f" % cooldown_left if cooldown_left < 10.0 else "%d" % ceili(cooldown_left)


## How much of the cooldown is still to go, 0..1.
func cooldown_fraction() -> float:
	return clampf(cooldown_left / cooldown_total, 0.0, 1.0) if cooldown_left > 0.0 else 0.0


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and is_locked():
		accept_event()
		locked_pressed.emit(locked_text)


func _update_tooltip() -> void:
	tooltip_text = locked_text if is_locked() else skill_name


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - 3.0
	var locked: bool = is_locked()
	if is_ready():
		InkBrush.glow(self, center, radius * 1.9, Color(InkPalette.GOLD_BRIGHT, 0.7))
	draw_circle(center, radius, Color(InkPalette.UI_CHARCOAL, 0.94))
	draw_glyph(self, _glyph, center, radius * GLYPH_RADIUS, Color(GLYPH_COLOR, 0.45) if locked else GLYPH_COLOR)
	if locked:
		draw_circle(center, radius, Color(InkPalette.UI_CHARCOAL, 0.66))
		LockIcon.draw(self, center + Vector2(0.0, -2.0), radius * 0.95, Color(InkPalette.PARCHMENT, 0.92))
	var fraction: float = cooldown_fraction()
	if fraction > 0.0 and not locked:
		_draw_sweep(center, radius, fraction)
	var ring: Color = InkPalette.UI_DISABLED if locked else (InkPalette.GOLD_BRIGHT if is_ready() else accent)
	draw_arc(center, radius, 0.0, TAU, 40, ring, 3.0, true)
	var font: Font = get_theme_default_font()
	var seconds: String = cooldown_text()
	if not seconds.is_empty():
		var font_size: int = 26
		var baseline: float = center.y + float(font_size) * 0.35
		draw_string_outline(font, Vector2(0.0, baseline), seconds, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, 6, Color(InkPalette.INK, 0.95))
		draw_string(font, Vector2(0.0, baseline), seconds, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, InkPalette.PARCHMENT)
	if not key_hint.is_empty():
		_draw_badge(font)


## The dark overlay of the time still to go: a pie from the "clock hand" round to 12 o'clock, so the hand sweeps
## clockwise as the cooldown runs out.
func _draw_sweep(center: Vector2, radius: float, fraction: float) -> void:
	var points: PackedVector2Array = PackedVector2Array([center])
	var start: float = -PI * 0.5 + TAU * (1.0 - fraction)
	var steps: int = maxi(int(ceilf(float(SWEEP_STEPS) * fraction)), 2)
	for i: int in steps + 1:
		points.append(center + Vector2.from_angle(start + TAU * fraction * float(i) / float(steps)) * (radius - 1.0))
	draw_colored_polygon(points, Color(InkPalette.INK, 0.66))


func _draw_badge(font: Font) -> void:
	var badge: Rect2 = Rect2(Vector2(size.x - BADGE_SIZE + 2.0, size.y - BADGE_SIZE + 2.0), Vector2(BADGE_SIZE, BADGE_SIZE))
	draw_rect(badge, Color(InkPalette.INK, 0.94))
	draw_rect(badge, Color(InkPalette.GOLD_BRIGHT, 0.95), false, 2.0)
	var letter_size: int = 19
	draw_string(font, Vector2(badge.position.x, badge.position.y + BADGE_SIZE * 0.5 + float(letter_size) * 0.35), key_hint,
			HORIZONTAL_ALIGNMENT_CENTER, BADGE_SIZE, letter_size, InkPalette.PARCHMENT)
