class_name UpgradeIcon
extends Control
## A small skill icon drawn by code on a dusk panel, the picture of an upgrade that has no character to show: the
## dash, the Spirit Slash, the Bow, the War Cry, the Ultimate, Spirit Capacity, Command and Spirit Regeneration.
## The symbols are also drawn by the battle HUD's round skill icons (draw_symbol), at any size; the Heavy strike and the
## two ally stances (a sword for CHARGE, a shield for HOLD) exist for them.

enum Kind { DASH, SPIRIT_SLASH, BOW, WAR_CRY, ULTIMATE, SPIRIT_CAPACITY, COMMAND, REGEN, HEAVY, STANCE_CHARGE, STANCE_HOLD }

## The symbol radius of the 144 px upgrade panel: pixel widths below are authored for it and scale with `radius`.
const REFERENCE_RADIUS: float = 49.0

var kind: Kind = Kind.DASH


func setup(p_kind: Kind, size_px: float) -> void:
	kind = p_kind
	custom_minimum_size = Vector2(size_px, size_px)
	size = Vector2(size_px, size_px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	FigurePortrait.draw_backdrop(self, size)
	draw_symbol(self, kind, size * 0.5, minf(size.x, size.y) * 0.34)


## Draws the symbol of `kind` centred on `c` into any CanvasItem (inside its _draw). The symbol reaches about
## 1.5 * `radius` from the centre; line widths scale with the radius.
static func draw_symbol(ci: CanvasItem, kind: Kind, c: Vector2, radius: float) -> void:
	var r: float = radius
	var s: float = radius / REFERENCE_RADIUS
	match kind:
		Kind.DASH:
			for i: int in 3:
				var y: float = c.y + (float(i) - 1.0) * r * 0.55
				ci.draw_line(Vector2(c.x - r * 1.0, y), Vector2(c.x + r * (0.3 - 0.15 * absf(float(i) - 1.0)), y), Color(InkPalette.SPIRIT, 0.9), (8.0 - float(i % 2) * 2.0) * s, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.35, -r * 0.7), c + Vector2(r * 1.05, 0.0), c + Vector2(r * 0.35, r * 0.7)]), InkPalette.GOLD_BRIGHT)
		Kind.SPIRIT_SLASH:
			ci.draw_arc(c + Vector2(-r * 0.75, 0.0), r * 1.2, -1.0, 1.0, 24, Color(InkPalette.SPIRIT_DEEP, 0.9), 22.0 * s, true)
			ci.draw_arc(c + Vector2(-r * 0.75, 0.0), r * 1.2, -0.95, 0.95, 24, InkPalette.SPIRIT, 12.0 * s, true)
			ci.draw_arc(c + Vector2(-r * 0.75, 0.0), r * 1.2, -0.8, 0.8, 24, InkPalette.PAPER, 4.0 * s, true)
		Kind.BOW:
			ci.draw_arc(c + Vector2(r * 0.5, 0.0), r * 1.15, PI * 0.62, PI * 1.38, 24, InkPalette.INK, 10.0 * s, true)
			var top: Vector2 = c + Vector2(r * 0.5, 0.0) + Vector2.from_angle(PI * 1.38) * r * 1.15
			var bottom: Vector2 = c + Vector2(r * 0.5, 0.0) + Vector2.from_angle(PI * 0.62) * r * 1.15
			ci.draw_line(top, bottom, Color(InkPalette.PARCHMENT_DIM, 0.9), 2.0 * s, true)
			ci.draw_line(c + Vector2(-r * 0.5, 0.0), c + Vector2(r * 1.15, 0.0), InkPalette.PARCHMENT, 5.0 * s, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 1.1, -9.0 * s), c + Vector2(r * 1.5, 0.0), c + Vector2(r * 1.1, 9.0 * s)]), InkPalette.STEEL)
		Kind.WAR_CRY:
			for i: int in 3:
				ci.draw_arc(c + Vector2(-r * 0.7, 0.0), r * (0.55 + 0.42 * float(i)), -0.75, 0.75, 20, Color(InkPalette.GOLD_BRIGHT, 1.0 - 0.22 * float(i)), (11.0 - 2.0 * float(i)) * s, true)
			ci.draw_circle(c + Vector2(-r * 0.7, 0.0), r * 0.22, InkPalette.PARCHMENT)
		Kind.ULTIMATE:
			for i: int in 8:
				var angle: float = TAU * float(i) / 8.0
				var tip: Vector2 = c + Vector2.from_angle(angle) * r * (1.25 if i % 2 == 0 else 0.9)
				var side: Vector2 = Vector2.from_angle(angle + PI * 0.5) * r * 0.18
				ci.draw_colored_polygon(PackedVector2Array([c + side, tip, c - side]), InkPalette.GOLD_BRIGHT if i % 2 == 0 else InkPalette.GOLD)
			ci.draw_circle(c, r * 0.5, InkPalette.SAMURAI_RED)
			ci.draw_circle(c, r * 0.28, InkPalette.PAPER)
		Kind.SPIRIT_CAPACITY:
			ci.draw_circle(c, r * 1.0, Color(InkPalette.SPIRIT_DEEP, 0.55))
			ci.draw_arc(c, r * 1.0, 0.0, TAU, 40, InkPalette.SPIRIT, 7.0 * s, true)
			ci.draw_circle(c, r * 0.62, InkPalette.SPIRIT)
			ci.draw_line(c + Vector2(-r * 0.3, 0.0), c + Vector2(r * 0.3, 0.0), InkPalette.INK, 8.0 * s, true)
			ci.draw_line(c + Vector2(0.0, -r * 0.3), c + Vector2(0.0, r * 0.3), InkPalette.INK, 8.0 * s, true)
		Kind.COMMAND:
			ci.draw_line(c + Vector2(-r * 0.5, r * 1.1), c + Vector2(-r * 0.5, -r * 1.15), InkPalette.PARCHMENT_DIM, 7.0 * s, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.5, -r * 1.1), c + Vector2(r * 1.0, -r * 0.7), c + Vector2(r * 0.55, -r * 0.3), c + Vector2(r * 1.0, r * 0.1), c + Vector2(-r * 0.5, -r * 0.15)]), InkPalette.SAMURAI_RED)
			ci.draw_circle(c + Vector2(r * 0.2, -r * 0.5), r * 0.16, InkPalette.PAPER)
		Kind.REGEN:
			ci.draw_arc(c, r * 0.95, -0.4, PI - 0.9, 24, InkPalette.JADE, 11.0 * s, true)
			ci.draw_arc(c, r * 0.95, PI - 0.4, TAU - 0.9, 24, InkPalette.JADE, 11.0 * s, true)
			for angle: float in [PI - 0.9, TAU - 0.9]:
				var tip: Vector2 = c + Vector2.from_angle(angle) * r * 0.95
				var tangent: Vector2 = Vector2.from_angle(angle + PI * 0.5)
				var out: Vector2 = Vector2.from_angle(angle)
				ci.draw_colored_polygon(PackedVector2Array([tip + tangent * r * 0.38, tip + out * r * 0.28, tip - out * r * 0.28]), InkPalette.JADE)
			ci.draw_circle(c, r * 0.22, InkPalette.SPIRIT)
		Kind.HEAVY:
			# One big downward cut, with an impact star where it lands.
			var from: Vector2 = c + Vector2(-r * 0.95, -r * 1.0)
			var to: Vector2 = c + Vector2(r * 0.8, r * 0.85)
			ci.draw_line(from, to, Color(InkPalette.SAMURAI_RED, 0.95), 18.0 * s, true)
			ci.draw_line(from.lerp(to, 0.08), to, InkPalette.PAPER, 5.0 * s, true)
			for angle: float in [-0.2, 0.7, 1.6]:
				ci.draw_line(to + Vector2.from_angle(angle) * r * 0.25, to + Vector2.from_angle(angle) * r * 0.62, InkPalette.GOLD_BRIGHT, 5.0 * s, true)
		Kind.STANCE_CHARGE:
			# A katana pointing up and to the right: advance.
			var hilt: Vector2 = c + Vector2(-r * 0.75, r * 0.75)
			var tip: Vector2 = c + Vector2(r * 1.0, -r * 1.0)
			var along: Vector2 = (tip - hilt).normalized()
			var across: Vector2 = along.orthogonal()
			ci.draw_line(hilt - along * r * 0.35, hilt + along * r * 0.35, InkPalette.SAMURAI_RED, 8.0 * s, true)
			ci.draw_line(hilt + along * r * 0.4 - across * r * 0.42, hilt + along * r * 0.4 + across * r * 0.42, InkPalette.GOLD_BRIGHT, 7.0 * s, true)
			ci.draw_line(hilt + along * r * 0.5, tip, InkPalette.STEEL, 9.0 * s, true)
			ci.draw_line(hilt + along * r * 0.5, tip, InkPalette.PAPER, 3.0 * s, true)
		Kind.STANCE_HOLD:
			# A shield: stand and defend.
			var outline: PackedVector2Array = PackedVector2Array([c + Vector2(-r * 0.85, -r * 0.95), c + Vector2(r * 0.85, -r * 0.95),
					c + Vector2(r * 0.85, r * 0.1), c + Vector2(0.0, r * 1.1), c + Vector2(-r * 0.85, r * 0.1)])
			ci.draw_colored_polygon(outline, InkPalette.STEEL)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.6, -r * 0.7), c + Vector2(r * 0.6, -r * 0.7), c + Vector2(r * 0.6, 0.0), c + Vector2(0.0, r * 0.8), c + Vector2(-r * 0.6, 0.0)]), InkPalette.SPIRIT_DEEP.darkened(0.55))
			ci.draw_line(c + Vector2(0.0, -r * 0.7), c + Vector2(0.0, r * 0.75), InkPalette.GOLD_BRIGHT, 4.0 * s, true)
			ci.draw_line(c + Vector2(-r * 0.6, -r * 0.2), c + Vector2(r * 0.6, -r * 0.2), InkPalette.GOLD_BRIGHT, 4.0 * s, true)
			outline.append(outline[0])
			ci.draw_polyline(outline, InkPalette.GOLD_BRIGHT, 3.0 * s, true)
