class_name LivingMenuPainting
extends Node2D
## One opaque scene; the samurai, stone and environment share the same paint/light.
const ART: Texture2D = preload("res://assets/art/world/menu_scene.png")
const COLUMNS: int = 128
const ROWS: int = 72
var reduced_motion: bool = false
var _paint: ShaderMaterial
static var _vertices: PackedVector2Array = PackedVector2Array()
static var _uvs: PackedVector2Array = PackedVector2Array()
static var _weights: PackedColorArray = PackedColorArray()
static var _indices: PackedInt32Array = PackedInt32Array()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_build_mesh()
	_paint = ShaderMaterial.new()
	_paint.shader = preload("res://scripts/visuals/shaders/living_menu.gdshader")
	material = _paint
	set_time(0.0)


func set_time(seconds: float) -> void:
	if _paint == null: return
	_paint.set_shader_parameter("motion_time", seconds)
	_paint.set_shader_parameter("motion_amount", 0.15 if reduced_motion else 1.0)


static func motion_weights(uv: Vector2) -> Color:
	var hair: float = smoothstep(0.84, 0.88, uv.x) * (1.0 - smoothstep(0.13, 0.18, uv.y))
	var sash: float = smoothstep(0.88, 0.94, uv.x) * smoothstep(0.38, 0.42, uv.y) * (1.0 - smoothstep(0.53, 0.58, uv.y))
	var hem: float = smoothstep(0.87, 0.92, uv.x) * smoothstep(0.58, 0.63, uv.y) * (1.0 - smoothstep(0.70, 0.74, uv.y))
	return Color(hair, sash, hem, 1)


static func _build_mesh() -> void:
	if not _vertices.is_empty(): return
	for y: int in ROWS + 1:
		for x: int in COLUMNS + 1:
			var uv: Vector2 = Vector2(float(x) / COLUMNS, float(y) / ROWS)
			_vertices.append(uv * ART.get_size())
			_uvs.append(uv)
			_weights.append(motion_weights(uv))
	for y: int in ROWS:
		for x: int in COLUMNS:
			var a: int = y * (COLUMNS + 1) + x
			var b: int = a + COLUMNS + 1
			_indices.append_array(PackedInt32Array([a, a + 1, b, a + 1, b + 1, b]))


func _draw() -> void:
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _indices, _vertices,
		_weights, _uvs, PackedInt32Array(), PackedFloat32Array(), ART.get_rid())
