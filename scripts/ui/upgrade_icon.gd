class_name UpgradeIcon
extends Control
## A small skill icon drawn by code on a dusk panel, the picture of an upgrade that has no character to show: the
## dash, the Spirit Slash, the Bow, the War Cry, the Ultimate, Spirit Capacity, Command and Spirit Regeneration.

enum Kind { DASH, SPIRIT_SLASH, BOW, WAR_CRY, ULTIMATE, SPIRIT_CAPACITY, COMMAND, REGEN }

var kind: Kind = Kind.DASH


func setup(p_kind: Kind, size_px: float) -> void:
	kind = p_kind
	custom_minimum_size = Vector2(size_px, size_px)
	size = Vector2(size_px, size_px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	FigurePortrait.draw_backdrop(self, size)
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.34
	match kind:
		Kind.DASH:
			for i: int in 3:
				var y: float = c.y + (float(i) - 1.0) * r * 0.55
				draw_line(Vector2(c.x - r * 1.0, y), Vector2(c.x + r * (0.3 - 0.15 * absf(float(i) - 1.0)), y), Color(InkPalette.SPIRIT, 0.9), 8.0 - float(i % 2) * 2.0, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.35, -r * 0.7), c + Vector2(r * 1.05, 0.0), c + Vector2(r * 0.35, r * 0.7)]), InkPalette.GOLD_BRIGHT)
		Kind.SPIRIT_SLASH:
			draw_arc(c + Vector2(-r * 0.75, 0.0), r * 1.2, -1.0, 1.0, 24, Color(InkPalette.SPIRIT_DEEP, 0.9), 22.0, true)
			draw_arc(c + Vector2(-r * 0.75, 0.0), r * 1.2, -0.95, 0.95, 24, InkPalette.SPIRIT, 12.0, true)
			draw_arc(c + Vector2(-r * 0.75, 0.0), r * 1.2, -0.8, 0.8, 24, InkPalette.PAPER, 4.0, true)
		Kind.BOW:
			draw_arc(c + Vector2(r * 0.5, 0.0), r * 1.15, PI * 0.62, PI * 1.38, 24, InkPalette.INK, 10.0, true)
			var top: Vector2 = c + Vector2(r * 0.5, 0.0) + Vector2.from_angle(PI * 1.38) * r * 1.15
			var bottom: Vector2 = c + Vector2(r * 0.5, 0.0) + Vector2.from_angle(PI * 0.62) * r * 1.15
			draw_line(top, bottom, Color(InkPalette.PARCHMENT_DIM, 0.9), 2.0, true)
			draw_line(c + Vector2(-r * 0.5, 0.0), c + Vector2(r * 1.15, 0.0), InkPalette.PARCHMENT, 5.0, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(r * 1.1, -9.0), c + Vector2(r * 1.5, 0.0), c + Vector2(r * 1.1, 9.0)]), InkPalette.STEEL)
		Kind.WAR_CRY:
			for i: int in 3:
				draw_arc(c + Vector2(-r * 0.7, 0.0), r * (0.55 + 0.42 * float(i)), -0.75, 0.75, 20, Color(InkPalette.GOLD_BRIGHT, 1.0 - 0.22 * float(i)), 11.0 - 2.0 * float(i), true)
			draw_circle(c + Vector2(-r * 0.7, 0.0), r * 0.22, InkPalette.PARCHMENT)
		Kind.ULTIMATE:
			for i: int in 8:
				var angle: float = TAU * float(i) / 8.0
				var tip: Vector2 = c + Vector2.from_angle(angle) * r * (1.25 if i % 2 == 0 else 0.9)
				var side: Vector2 = Vector2.from_angle(angle + PI * 0.5) * r * 0.18
				draw_colored_polygon(PackedVector2Array([c + side, tip, c - side]), InkPalette.GOLD_BRIGHT if i % 2 == 0 else InkPalette.GOLD)
			draw_circle(c, r * 0.5, InkPalette.SAMURAI_RED)
			draw_circle(c, r * 0.28, InkPalette.PAPER)
		Kind.SPIRIT_CAPACITY:
			draw_circle(c, r * 1.0, Color(InkPalette.SPIRIT_DEEP, 0.55))
			draw_arc(c, r * 1.0, 0.0, TAU, 40, InkPalette.SPIRIT, 7.0, true)
			draw_circle(c, r * 0.62, InkPalette.SPIRIT)
			draw_line(c + Vector2(-r * 0.3, 0.0), c + Vector2(r * 0.3, 0.0), InkPalette.INK, 8.0, true)
			draw_line(c + Vector2(0.0, -r * 0.3), c + Vector2(0.0, r * 0.3), InkPalette.INK, 8.0, true)
		Kind.COMMAND:
			draw_line(c + Vector2(-r * 0.5, r * 1.1), c + Vector2(-r * 0.5, -r * 1.15), InkPalette.PARCHMENT_DIM, 7.0, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.5, -r * 1.1), c + Vector2(r * 1.0, -r * 0.7), c + Vector2(r * 0.55, -r * 0.3), c + Vector2(r * 1.0, r * 0.1), c + Vector2(-r * 0.5, -r * 0.15)]), InkPalette.SAMURAI_RED)
			draw_circle(c + Vector2(r * 0.2, -r * 0.5), r * 0.16, InkPalette.PAPER)
		Kind.REGEN:
			draw_arc(c, r * 0.95, -0.4, PI - 0.9, 24, InkPalette.JADE, 11.0, true)
			draw_arc(c, r * 0.95, PI - 0.4, TAU - 0.9, 24, InkPalette.JADE, 11.0, true)
			for angle: float in [PI - 0.9, TAU - 0.9]:
				var tip: Vector2 = c + Vector2.from_angle(angle) * r * 0.95
				var tangent: Vector2 = Vector2.from_angle(angle + PI * 0.5)
				var out: Vector2 = Vector2.from_angle(angle)
				draw_colored_polygon(PackedVector2Array([tip + tangent * r * 0.38, tip + out * r * 0.28, tip - out * r * 0.28]), InkPalette.JADE)
			draw_circle(c, r * 0.22, InkPalette.SPIRIT)
