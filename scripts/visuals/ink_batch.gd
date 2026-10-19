class_name InkBatch
extends RefCounted
## Accumulates brush shapes as coloured triangles and draws them with ONE RenderingServer call.
## Static art (backdrop layers, each character part) is built once into a batch and replayed
## every frame, so nothing is re-triangulated or rebuilt per frame. A shape that can't be
## triangulated (degenerate) is skipped quietly instead of logging an error.

var vertices: PackedVector2Array = PackedVector2Array()
var colors: PackedColorArray = PackedColorArray()
var indices: PackedInt32Array = PackedInt32Array()


func is_empty() -> bool:
	return indices.is_empty()


func clear() -> void:
	vertices.resize(0)
	colors.resize(0)
	indices.resize(0)


## Issues the whole batch as one draw command on `ci` (call from its _draw / draw signal).
func draw(ci: CanvasItem) -> void:
	if not indices.is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), indices, vertices, colors)


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
