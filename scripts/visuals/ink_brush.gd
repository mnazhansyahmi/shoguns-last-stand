class_name InkBrush
extends RefCounted
## Brush-style drawing helpers for code-drawn art. Call them from a CanvasItem's _draw()
## (or its `draw` signal) with that CanvasItem as `ci`; the current draw transform applies.
## Shapes go straight to the RenderingServer as triangles, so a degenerate polygon (zero size,
## mid-animation) is skipped quietly instead of logging a triangulation error.

static var _glow_texture: GradientTexture2D


## Fills any simple polygon. Skips it if it can't be triangulated.
static func fill(ci: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	if points.size() < 3:
		return
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(points)
	if indices.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), indices, points, PackedColorArray([color]))


## Fills a convex polygon (fan triangulation, no failure case).
static func fill_convex(ci: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	var count: int = points.size()
	if count < 3:
		return
	var indices: PackedInt32Array = PackedInt32Array()
	indices.resize((count - 2) * 3)
	for i: int in range(1, count - 1):
		indices[(i - 1) * 3] = 0
		indices[(i - 1) * 3 + 1] = i
		indices[(i - 1) * 3 + 2] = i + 1
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), indices, points, PackedColorArray([color]))


## A tapered segment from a (width w0) to b (width w1) with rounded ends, like a brush limb.
static func limb(ci: CanvasItem, a: Vector2, b: Vector2, w0: float, w1: float, color: Color) -> void:
	var direction: Vector2 = b - a
	if direction.length_squared() > 0.0001:
		var normal: Vector2 = direction.normalized().orthogonal()
		fill_convex(ci, PackedVector2Array([a + normal * w0 * 0.5, b + normal * w1 * 0.5,
				b - normal * w1 * 0.5, a - normal * w0 * 0.5]), color)
	ci.draw_circle(a, w0 * 0.5, color)
	ci.draw_circle(b, w1 * 0.5, color)


## A tapered polyline (width w0 at the first point to w1 at the last), built as a triangle
## strip so sharp bends overlap instead of failing.
static func stroke(ci: CanvasItem, points: PackedVector2Array, w0: float, w1: float, color: Color) -> void:
	var count: int = points.size()
	if count < 2:
		return
	var vertices: PackedVector2Array = PackedVector2Array()
	vertices.resize(count * 2)
	for i: int in count:
		var direction: Vector2
		if i == 0:
			direction = points[1] - points[0]
		elif i == count - 1:
			direction = points[count - 1] - points[count - 2]
		else:
			direction = points[i + 1] - points[i - 1]
		if direction.length_squared() < 0.000001:
			direction = Vector2.RIGHT
		var normal: Vector2 = direction.normalized().orthogonal()
		var half: float = lerpf(w0, w1, float(i) / float(count - 1)) * 0.5
		vertices[i * 2] = points[i] + normal * half
		vertices[i * 2 + 1] = points[i] - normal * half
	var indices: PackedInt32Array = PackedInt32Array()
	indices.resize((count - 1) * 6)
	for i: int in count - 1:
		var k: int = i * 2
		var j: int = i * 6
		indices[j] = k
		indices[j + 1] = k + 1
		indices[j + 2] = k + 2
		indices[j + 3] = k + 1
		indices[j + 4] = k + 3
		indices[j + 5] = k + 2
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), indices, vertices, PackedColorArray([color]))


static func ellipse(ci: CanvasItem, center: Vector2, radii: Vector2, color: Color, segments: int = 18) -> void:
	fill_convex(ci, ellipse_points(center, radii, segments), color)


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
