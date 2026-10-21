class_name SkillIcon
extends Control
## One round skill icon of the keyboard HUD: the skill's cached InkFigure picture in a dark disc with a
## ring, a small key badge at its lower right, and its state:
##   - cooling down: a dark radial sweep over the icon, shrinking as the time runs out, with the seconds left on it;
##   - ready: a soft glow behind it, and no text;
##   - locked: dimmed, with a small padlock only. How to unlock it is the tooltip (hover) and a message when tapped.
## The ally stance uses the same icon: set_kind() swaps charging allies (CHARGE) for the guardian (HOLD).

## The player tapped a locked icon: `text` ("Clear stage 2") says what unlocks it.
signal locked_pressed(text: String)

const DIAMETER: float = 66.0
const BADGE_SIZE: float = 24.0
const SWEEP_STEPS: int = 28

var _figure_art: Texture2D


func _ready() -> void:
	_refresh_art()


func _refresh_art() -> void:
	if is_inside_tree():
		_figure_art = FigureSkillArt.texture(self, kind)
	queue_redraw()


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
	if _figure_art != null:
		FigureSkillArt.draw_round(self, _figure_art, center, radius - 1.0)
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
		var font_size: int = 22
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
	var letter_size: int = 17
	draw_string(font, Vector2(badge.position.x, badge.position.y + BADGE_SIZE * 0.5 + float(letter_size) * 0.35), key_hint,
			HORIZONTAL_ALIGNMENT_CENTER, BADGE_SIZE, letter_size, InkPalette.PARCHMENT)
