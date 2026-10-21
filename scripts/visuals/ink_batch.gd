class_name InkBatch
extends RefCounted
## Accumulates brush shapes as coloured triangles and draws them with ONE RenderingServer call.
## Static art (backdrop layers, each character part) is built once into a batch and replayed
## every frame, so nothing is re-triangulated or rebuilt per frame. A shape that can't be
## triangulated (degenerate) is skipped quietly instead of logging an error.

var vertices: PackedVector2Array = PackedVector2Array()
var colors: PackedColorArray = PackedColorArray()
var indices: PackedInt32Array = PackedInt32Array()
## Optional per-vertex UVs (see with_rim()); empty for ordinary batches.
var uvs: PackedVector2Array = PackedVector2Array()


func is_empty() -> bool:
	return indices.is_empty()


func clear() -> void:
	vertices.resize(0)
	colors.resize(0)
	indices.resize(0)
	uvs.resize(0)


## Issues the whole batch as one draw command on `ci` (call from its _draw / draw signal).
func draw(ci: CanvasItem) -> void:
	if indices.is_empty():
		return
	if uvs.size() == vertices.size():
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), indices, vertices, colors, uvs)
	else:
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), indices, vertices, colors)


## A copy of this batch for the rim-light shader (scripts/visuals/shaders/rim_light.gdshader): the
## shapes twice in one draw command, first a copy flagged with UV.x = 1 (which the shader pushes toward
## the sun and tints), then the shapes themselves on top. One command and one material per part.
func with_rim() -> InkBatch:
	var lit: InkBatch = InkBatch.new()
	var count: int = vertices.size()
	lit.vertices = vertices.duplicate()
	lit.vertices.append_array(vertices)
	lit.colors = colors.duplicate()
	lit.colors.append_array(colors)
	lit.indices = indices.duplicate()
	for index: int in indices:
		lit.indices.append(index + count)
	lit.uvs.resize(count * 2)
	for i: int in count:
		lit.uvs[i] = Vector2(1.0, 0.0)
	return lit


## Replaces every vertex colour equal to `from` (ignoring alpha) with `to`, keeping its alpha.
func remap(from: Color, to: Color) -> void:
	for i: int in colors.size():
		var c: Color = colors[i]
		if absf(c.r - from.r) < 0.004 and absf(c.g - from.g) < 0.004 and absf(c.b - from.b) < 0.004:
			colors[i] = Color(to, c.a)


## Draws and empties the batch (to keep draw order when other draws must come in between).
func flush(ci: CanvasItem) -> void:
	draw(ci)
	clear()


## Any simple polygon.
func fill(points: PackedVector2Array, color: Color) -> void:
	if points.size() < 3:
		return
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(points)
	if triangles.is_empty():
		return
	var base: int = vertices.size()
	_add_points(points, color)
	for index: int in triangles:
		indices.append(base + index)


## A convex polygon (fan from the first point).
func fill_convex(points: PackedVector2Array, color: Color) -> void:
	var count: int = points.size()
	if count < 3:
		return
	var base: int = vertices.size()
	_add_points(points, color)
	for i: int in range(1, count - 1):
		indices.append(base)
		indices.append(base + i)
		indices.append(base + i + 1)


## A closed ring of points that every point can "see" from `center` (star-shaped), as a fan.
func fill_fan(center: Vector2, ring: PackedVector2Array, color: Color) -> void:
	var count: int = ring.size()
	if count < 2:
		return
	var base: int = vertices.size()
	vertices.append(center)
	colors.append(color)
	_add_points(ring, color)
	for i: int in count:
		indices.append(base)
		indices.append(base + 1 + i)
		indices.append(base + 1 + (i + 1) % count)


## A polygon that was triangulated once (`triangles` from Geometry2D.triangulate_polygon), scaled about the origin:
## for an effect that redraws the same blot every frame without triangulating it again.
func fill_triangulated(points: PackedVector2Array, triangles: PackedInt32Array, color: Color, scale: float = 1.0) -> void:
	if triangles.is_empty():
		return
	var base: int = vertices.size()
	for point: Vector2 in points:
		vertices.append(point * scale)
		colors.append(color)
	for index: int in triangles:
		indices.append(base + index)


## A flat tapered segment from a (width w0) to b (width w1), square ends: the same quad as a two-point stroke(), built
## without any point array (for the many short streaks of a spray of drops or sparks).
func segment(a: Vector2, b: Vector2, w0: float, w1: float, color: Color) -> void:
	var direction: Vector2 = b - a
	if direction.length_squared() < 0.000001:
		direction = Vector2.RIGHT
	var normal: Vector2 = direction.normalized().orthogonal()
	var base: int = vertices.size()
	vertices.append(a + normal * w0 * 0.5)
	vertices.append(a - normal * w0 * 0.5)
	vertices.append(b + normal * w1 * 0.5)
	vertices.append(b - normal * w1 * 0.5)
	for i: int in 4:
		colors.append(color)
	indices.append(base)
	indices.append(base + 1)
	indices.append(base + 2)
	indices.append(base + 1)
	indices.append(base + 3)
	indices.append(base + 2)


## A filled disc as a fan of `segments` triangles (no point array: the ring is computed in place).
func disc(center: Vector2, radius: float, color: Color, segments: int = 12) -> void:
	var base: int = vertices.size()
	vertices.append(center)
	colors.append(color)
	for i: int in segments:
		var angle: float = TAU * float(i) / float(segments)
		vertices.append(center + Vector2(cos(angle), sin(angle)) * radius)
		colors.append(color)
	for i: int in segments:
		indices.append(base)
		indices.append(base + 1 + i)
		indices.append(base + 1 + (i + 1) % segments)


func circle(center: Vector2, radius: float, color: Color) -> void:
	ellipse(center, Vector2(radius, radius), color, clampi(int(radius * 1.2), 8, 24))


func ellipse(center: Vector2, radii: Vector2, color: Color, segments: int = 18) -> void:
	fill_convex(InkBrush.ellipse_points(center, radii, segments), color)


## A tapered segment from a (width w0) to b (width w1) with rounded ends.
func limb(a: Vector2, b: Vector2, w0: float, w1: float, color: Color) -> void:
	var direction: Vector2 = b - a
	if direction.length_squared() > 0.0001:
		var normal: Vector2 = direction.normalized().orthogonal()
		fill_convex(PackedVector2Array([a + normal * w0 * 0.5, b + normal * w1 * 0.5,
				b - normal * w1 * 0.5, a - normal * w0 * 0.5]), color)
	circle(a, w0 * 0.5, color)
	circle(b, w1 * 0.5, color)


## A tapered polyline (width w0 at the first point to w1 at the last) as a triangle strip.
func stroke(points: PackedVector2Array, w0: float, w1: float, color: Color) -> void:
	var count: int = points.size()
	if count < 2:
		return
	var base: int = vertices.size()
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
		vertices.append(points[i] + normal * half)
		vertices.append(points[i] - normal * half)
		colors.append(color)
		colors.append(color)
	_strip_indices(base, count)


## The area between a ridge line (left to right) and `bottom_y`, shaded top to bottom.
func ridge_fill(tops: PackedVector2Array, bottom_y: float, top_color: Color, bottom_color: Color) -> void:
	var count: int = tops.size()
	if count < 2:
		return
	var base: int = vertices.size()
	for i: int in count:
		vertices.append(tops[i])
		vertices.append(Vector2(tops[i].x, bottom_y))
		colors.append(top_color)
		colors.append(bottom_color)
	_strip_indices(base, count)


func gradient_rect(rect: Rect2, top_color: Color, bottom_color: Color) -> void:
	ridge_fill(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y)]), rect.end.y, top_color, bottom_color)


## A strip between two matching point lists with a colour per point.
func ribbon(outer: PackedVector2Array, inner: PackedVector2Array, outer_colors: PackedColorArray,
		inner_colors: PackedColorArray) -> void:
	var count: int = mini(outer.size(), inner.size())
	if count < 2:
		return
	var base: int = vertices.size()
	for i: int in count:
		vertices.append(outer[i])
		vertices.append(inner[i])
		colors.append(outer_colors[i])
		colors.append(inner_colors[i])
	_strip_indices(base, count)


func _add_points(points: PackedVector2Array, color: Color) -> void:
	vertices.append_array(points)
	for i: int in points.size():
		colors.append(color)


## Indices for a strip of `count` vertex pairs starting at `base`.
func _strip_indices(base: int, count: int) -> void:
	for i: int in count - 1:
		var k: int = base + i * 2
		indices.append(k)
		indices.append(k + 1)
		indices.append(k + 2)
		indices.append(k + 1)
		indices.append(k + 3)
		indices.append(k + 2)
