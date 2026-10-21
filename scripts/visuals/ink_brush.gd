class_name InkBrush
extends RefCounted
## One-off brush drawing for dynamic art (effects, cloth): each call builds a small InkBatch and
## draws it at once into `ci` (from its _draw() or `draw` signal; the current draw transform
## applies). Static art should build an InkBatch once and replay it instead.
## Also holds the shared glow texture, the additive material and two-bone IK.

static var _glow_texture: GradientTexture2D
## Every one-off helper below builds into this one batch and draws it at once (draw copies the arrays), so a call
## allocates nothing. Drawing is never nested, so one batch is enough.
static var _scratch: InkBatch = InkBatch.new()


static func fill(ci: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	_scratch.fill(points, color)
	_scratch.flush(ci)


static func fill_convex(ci: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	_scratch.fill_convex(points, color)
	_scratch.flush(ci)


static func limb(ci: CanvasItem, a: Vector2, b: Vector2, w0: float, w1: float, color: Color) -> void:
	_scratch.limb(a, b, w0, w1, color)
	_scratch.flush(ci)


static func stroke(ci: CanvasItem, points: PackedVector2Array, w0: float, w1: float, color: Color) -> void:
	_scratch.stroke(points, w0, w1, color)
	_scratch.flush(ci)


static func ridge_fill(ci: CanvasItem, tops: PackedVector2Array, bottom_y: float, top_color: Color,
		bottom_color: Color) -> void:
	_scratch.ridge_fill(tops, bottom_y, top_color, bottom_color)
	_scratch.flush(ci)


static func gradient_rect(ci: CanvasItem, rect: Rect2, top_color: Color, bottom_color: Color) -> void:
	_scratch.gradient_rect(rect, top_color, bottom_color)
	_scratch.flush(ci)


static func ribbon(ci: CanvasItem, outer: PackedVector2Array, inner: PackedVector2Array,
		outer_colors: PackedColorArray, inner_colors: PackedColorArray) -> void:
	_scratch.ribbon(outer, inner, outer_colors, inner_colors)
	_scratch.flush(ci)


static func ellipse(ci: CanvasItem, center: Vector2, radii: Vector2, color: Color, segments: int = 18) -> void:
	_scratch.ellipse(center, radii, color, segments)
	_scratch.flush(ci)


static func ellipse_points(center: Vector2, radii: Vector2, segments: int = 18) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	points.resize(segments)
	for i: int in segments:
		var angle: float = TAU * float(i) / float(segments)
		points[i] = center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y)
	return points


## Soft radial glow (white centre fading to clear), tinted by `color`. Use on a CanvasItem with
## an additive material for light; on a normal one it reads as a soft blot.
static func glow(ci: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	if radius <= 0.0:
		return
	ci.draw_texture_rect(glow_texture(), Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, color)


static func glow_texture() -> GradientTexture2D:
	if _glow_texture == null:
		var gradient: Gradient = Gradient.new()
		gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
		gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		gradient.add_point(0.35, Color(1.0, 1.0, 1.0, 0.45))
		_glow_texture = GradientTexture2D.new()
		_glow_texture.gradient = gradient
		_glow_texture.width = 64
		_glow_texture.height = 64
		_glow_texture.fill = GradientTexture2D.FILL_RADIAL
		_glow_texture.fill_from = Vector2(0.5, 0.5)
		_glow_texture.fill_to = Vector2(0.5, 0.0)
	return _glow_texture


## Additive blend material shared by every glow layer.
static func additive_material() -> CanvasItemMaterial:
	var material: CanvasItemMaterial = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


## Two-bone IK: the joint (knee/elbow) between `from` and `to` with segment lengths l1, l2.
## bend = +1 or -1 picks which side the joint bends to.
static func solve_joint(from: Vector2, to: Vector2, l1: float, l2: float, bend: float) -> Vector2:
	var offset: Vector2 = to - from
	var distance: float = clampf(offset.length(), 0.001, l1 + l2 - 0.001)
	var direction: Vector2 = offset.normalized() if offset.length_squared() > 0.000001 else Vector2.DOWN
	var cos_angle: float = clampf((l1 * l1 + distance * distance - l2 * l2) / (2.0 * l1 * distance), -1.0, 1.0)
	return from + direction.rotated(acos(cos_angle) * bend) * l1
