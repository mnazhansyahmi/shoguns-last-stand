class_name PortraitMotion
extends Node2D
## One coherent title painting. Only free hair, sash and hem pixels move; face,
## hands, torso, legs and soles stay fixed. No InkFigure or limb rig is used.

const ART: Texture2D = preload("res://assets/art/samurai/title_key_art.png")
const FOOT_ANCHOR: Vector2 = Vector2(535.0, 1498.0)
const ART_HEIGHT: float = 1464.0
const COLUMNS: int = 64
const ROWS: int = 96
var reduced_motion: bool = false
var _motion_material: ShaderMaterial
static var _vertices: PackedVector2Array
static var _uvs: PackedVector2Array
static var _weights: PackedColorArray
static var _indices: PackedInt32Array


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_build_mesh()
	_motion_material = ShaderMaterial.new()
	_motion_material.shader = preload("res://scripts/visuals/shaders/title_key_art.gdshader")
	material = _motion_material
	set_time(0.0)
	queue_redraw()


func set_time(seconds: float) -> void:
	if _motion_material == null: return
	_motion_material.set_shader_parameter("motion_time", seconds)
	_motion_material.set_shader_parameter("motion_amount", 0.15 if reduced_motion else 1.0)


## Masks deliberately stop outside the face, both hands and the standing body.
static func motion_weights(uv: Vector2) -> Color:
	var hair: float = smoothstep(0.64, 0.78, uv.x) * smoothstep(0.04, 0.10, uv.y) * (1.0 - smoothstep(0.24, 0.31, uv.y))
	var sash: float = smoothstep(0.72, 0.85, uv.x) * smoothstep(0.40, 0.47, uv.y) * (1.0 - smoothstep(0.62, 0.70, uv.y))
	var hem: float = smoothstep(0.67, 0.85, uv.x) * smoothstep(0.65, 0.72, uv.y) * (1.0 - smoothstep(0.80, 0.86, uv.y))
	return Color(hair, sash, hem, 1.0)


static func _build_mesh() -> void:
	if not _vertices.is_empty(): return
	for row: int in ROWS + 1:
		for col: int in COLUMNS + 1:
			var uv: Vector2 = Vector2(float(col) / COLUMNS, float(row) / ROWS)
			_vertices.append(uv * ART.get_size() - FOOT_ANCHOR)
			_uvs.append(uv)
			_weights.append(motion_weights(uv))
	for row: int in ROWS:
		for col: int in COLUMNS:
			var a: int = row * (COLUMNS + 1) + col
			var b: int = a + COLUMNS + 1
			_indices.append_array(PackedInt32Array([a, a + 1, b, a + 1, b + 1, b]))


func _draw() -> void:
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _indices, _vertices,
			_weights, _uvs, PackedInt32Array(), PackedFloat32Array(), ART.get_rid())
