class_name ResultCelebration
extends Control
## Native result-screen chrome: a victory crest and one restrained impact reveal.
## The battle remains visible behind it; this is not a second opaque menu panel.
var victory: bool = true
var reveal: float = 1.0:
	set(value):
		reveal = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var accent: Color = InkPalette.GOLD_BRIGHT if victory else InkPalette.EMBER_TEXT
	var ink: Color = InkPalette.INK
	# Wide ink strokes sit behind the content, with open edges into the battle.
	for side: int in 2:
		var sign_x: float = -1.0 if side == 0 else 1.0
		var x: float = center.x + sign_x * 680.0
		draw_polygon(PackedVector2Array([Vector2(x, center.y - 300.0), Vector2(center.x, center.y - 314.0),
				Vector2(center.x, center.y - 170.0), Vector2(x + sign_x * 65.0, center.y - 180.0)]),
				PackedColorArray([Color(InkPalette.SAMURAI_RED, 0.0), Color(InkPalette.SAMURAI_RED, 0.72),
						Color(InkPalette.SAMURAI_RED, 0.60), Color(InkPalette.SAMURAI_RED, 0.0)]))
		draw_polygon(PackedVector2Array([Vector2(x + sign_x * 150.0, center.y - 130.0), Vector2(center.x, center.y - 150.0),
				Vector2(center.x, center.y + 145.0), Vector2(x + sign_x * 150.0, center.y + 130.0)]),
				PackedColorArray([Color(ink, 0.0), Color(ink, 0.86), Color(ink, 0.86), Color(ink, 0.0)]))
	var crest: Vector2 = center + Vector2(0.0, -384.0)
	draw_circle(crest + Vector2(0, 6), 64.0, Color(ink, 0.72))
	draw_circle(crest, 59.0, InkPalette.SAMURAI_RED.darkened(0.5))
	draw_arc(crest, 61.0, 0.0, TAU, 64, accent, 3.0, true)
	# Crossed katana pictogram, kept within the icon budget.
	for facing: float in [-1.0, 1.0]:
		var axis: Vector2 = Vector2(facing, -1.0).normalized()
		draw_line(crest - axis * 29.0, crest + axis * 35.0, accent, 5.0, true)
		var guard: Vector2 = crest - axis * 12.0
		draw_line(guard - axis.orthogonal() * 10.0, guard + axis.orthogonal() * 10.0, accent, 4.0, true)
	# One short burst; reduced motion sets reveal straight to its resting value.
	var burst: float = sin(reveal * PI) * 0.6
	if victory and burst > 0.01:
		for i: int in 18:
			var direction: Vector2 = Vector2.from_angle(TAU * float(i) / 18.0)
			var point: Vector2 = crest + direction * (70.0 + reveal * 120.0)
			draw_line(point, point + direction * 10.0, Color(accent, burst), 2.0, true)
