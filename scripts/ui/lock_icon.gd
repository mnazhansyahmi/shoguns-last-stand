class_name LockIcon
extends RefCounted
## A padlock drawn by code (shackle arc over a body with a keyhole), for locked skills.


## Draws it centred on `center`, `size` pixels tall, onto any CanvasItem (inside its _draw).
static func draw(ci: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var body: Rect2 = Rect2(center + Vector2(-size * 0.36, -size * 0.04), Vector2(size * 0.72, size * 0.5))
	var shackle_radius: float = size * 0.24
	var shackle_center: Vector2 = Vector2(center.x, body.position.y)
	ci.draw_arc(shackle_center, shackle_radius, PI, TAU, 16, color, maxf(size * 0.11, 2.0), true)
	ci.draw_line(shackle_center + Vector2(-shackle_radius, 0.0), shackle_center + Vector2(-shackle_radius, size * 0.1), color, maxf(size * 0.11, 2.0))
	ci.draw_line(shackle_center + Vector2(shackle_radius, 0.0), shackle_center + Vector2(shackle_radius, size * 0.1), color, maxf(size * 0.11, 2.0))
	ci.draw_rect(body, color)
	var hole: Color = Color(InkPalette.INK, 0.9)
	ci.draw_circle(body.get_center() + Vector2(0.0, -size * 0.04), size * 0.07, hole)
	ci.draw_rect(Rect2(body.get_center() + Vector2(-size * 0.025, -size * 0.04), Vector2(size * 0.05, size * 0.15)), hole)
