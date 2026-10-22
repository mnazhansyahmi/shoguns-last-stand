class_name LivingMenuPainting
extends Node2D
## Static inpainted scene and clean alpha character. Only Character has a shader.
const ART: Texture2D = preload("res://assets/art/world/menu_background.png")
const CHARACTER: Texture2D = preload("res://assets/art/world/menu_character.png")
const CHARACTER_SCALE: Vector2 = Vector2(0.895, 0.895)
const CHARACTER_OFFSET: Vector2 = Vector2(145.0, 0.0)
const COLUMNS: int = 160
const ROWS: int = 96
var reduced_motion: bool = false
var _paint: ShaderMaterial
var _character: MeshInstance2D
static var _mesh: ArrayMesh


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_character = MeshInstance2D.new()
	_character.name = "Character"
	_character.mesh = _character_mesh()
	_character.texture = CHARACTER
	_character.position = CHARACTER_OFFSET
	_character.scale = CHARACTER_SCALE
	_paint = ShaderMaterial.new()
	_paint.shader = preload("res://scripts/visuals/shaders/living_menu.gdshader")
	_character.material = _paint
	add_child(_character)
	set_time(0.0)


func set_time(seconds: float) -> void:
	if _paint == null: return
	_paint.set_shader_parameter("motion_time", seconds)
	_paint.set_shader_parameter("motion_amount", 0.15 if reduced_motion else 1.0)


static func motion_weights(uv: Vector2) -> Color:
	var hair: float = smoothstep(0.83, 0.89, uv.x) * (1.0 - smoothstep(0.16, 0.21, uv.y))
	var sash: float = smoothstep(0.89, 0.95, uv.x) * smoothstep(0.42, 0.47, uv.y) * (1.0 - smoothstep(0.59, 0.65, uv.y))
	var hem: float = smoothstep(0.87, 0.93, uv.x) * smoothstep(0.65, 0.70, uv.y) * (1.0 - smoothstep(0.79, 0.84, uv.y))
	return Color(hair, sash, hem, 1)


static func _character_mesh() -> ArrayMesh:
	if _mesh != null: return _mesh
	var vertices: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var weights: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	for y: int in ROWS + 1:
		for x: int in COLUMNS + 1:
			var uv: Vector2 = Vector2(float(x) / COLUMNS, float(y) / ROWS)
			vertices.append(uv * CHARACTER.get_size())
			uvs.append(uv)
			weights.append(motion_weights(uv))
	for y: int in ROWS:
		for x: int in COLUMNS:
			var a: int = y * (COLUMNS + 1) + x
			var b: int = a + COLUMNS + 1
			indices.append_array(PackedInt32Array([a, a + 1, b, a + 1, b + 1, b]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = weights
	arrays[Mesh.ARRAY_INDEX] = indices
	_mesh = ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _mesh


func _draw() -> void:
	draw_texture(ART, Vector2.ZERO)
