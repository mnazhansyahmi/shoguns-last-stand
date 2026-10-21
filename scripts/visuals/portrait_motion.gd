class_name PortraitMotion
extends Node2D
## A tessellated painted portrait: pinned feet, breathing chest, independent hair
## and robe weights. The immutable UV mesh is shared; only the clock reaches the GPU.

const COLUMNS: int = 40
const ROWS: int = 56
const REGION: Rect2 = SamuraiSpriteArt.PORTRAIT_REGION
var texture: Texture2D = SamuraiSpriteArt.PORTRAIT
var reduced_motion: bool = false
var _motion_material: ShaderMaterial
static var _vertices: PackedVector2Array
static var _uvs: PackedVector2Array
static var _weights: PackedColorArray
static var _indices: PackedInt32Array


func _ready() -> void:
	_build_mesh()
	_motion_material = ShaderMaterial.new()
	_motion_material.shader = preload("res://scripts/visuals/shaders/portrait_motion.gdshader")
	material = _motion_material
	set_time(0.0)
	queue_redraw()


func set_time(seconds: float) -> void:
	if _motion_material != null:
		_motion_material.set_shader_parameter("motion_time", seconds)
		_motion_material.set_shader_parameter("motion_amount", 0.15 if reduced_motion else 1.0)


## All weights go to zero at the soles; body movement cannot lift the portrait.
static func motion_weights(uv: Vector2) -> Color:
	var pinned: float = 1.0 - smoothstep(0.84, 0.93, uv.y)
	var chest: float = pinned * (1.0 - smoothstep(0.25, 0.84, uv.y))
	var hair: float = (1.0 - smoothstep(0.23, 0.36, uv.y)) * smoothstep(0.52, 0.81, uv.x)
	var robe: float = smoothstep(0.28, 0.46, uv.y) * pinned * smoothstep(0.49, 0.76, uv.x)
	return Color(chest, hair, robe, 1.0)


static func _build_mesh() -> void:
	if not _vertices.is_empty():
		return
	for row: int in ROWS + 1:
		for column: int in COLUMNS + 1:
			var uv: Vector2 = Vector2(float(column) / COLUMNS, float(row) / ROWS)
			_vertices.append((uv - Vector2(0.5, 1.0)) * REGION.size)
			_uvs.append((REGION.position + uv * REGION.size) / SamuraiSpriteArt.PORTRAIT.get_size())
			_weights.append(motion_weights(uv))
	for row: int in ROWS:
		for column: int in COLUMNS:
			var a: int = row * (COLUMNS + 1) + column
			var b: int = a + COLUMNS + 1
			_indices.append_array(PackedInt32Array([a, a + 1, b, a + 1, b + 1, b]))


func _draw() -> void:
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _indices,
			_vertices, _weights, _uvs, PackedInt32Array(), PackedFloat32Array(), texture.get_rid())
