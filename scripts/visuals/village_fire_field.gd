class_name VillageFireField
extends Node2D
## Retained batches: flame tongues, painted rising smoke and warm light. No
## individual particle nodes or per-frame drawing/geometry/material allocation.
const SMOKE: Texture2D = preload("res://assets/art/world/sharp/village_smoke.png")
## Measured roof/window/fence attachment points in village_scenery.png.
const ANCHORS: PackedVector2Array = [Vector2(0.075, 0.47), Vector2(0.18, 0.59),
	Vector2(0.28, 0.70), Vector2(0.44, 0.82), Vector2(0.67, 0.65),
	Vector2(0.82, 0.58), Vector2(0.93, 0.35)]
const FLAME_CELLS: Array[Rect2] = [Rect2(0.039872, 0.012759, 0.359649, 0.501595),
	Rect2(0.399522, 0.122807, 0.574960, 0.397129), Rect2(0.016746, 0.539075, 0.382775, 0.423445),
	Rect2(0.399522, 0.622807, 0.586124, 0.342903)]
var sites: Array[Dictionary] = []
var _materials: Array[ShaderMaterial] = []
var _last_reduced: int = -1
var _wind_clock: float = 0.0
static var _light: GradientTexture2D


static func layout(stage_key: String, ground: bool = false) -> Array[Dictionary]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = stage_key.hash() + (781 if ground else 19)
	var result: Array[Dictionary] = []
	if ground:
		for i: int in 2:
			result.append({"position": Vector2(350 + i * 1100 + rng.randf_range(-65, 90), rng.randf_range(885, 900)),
				"size": Vector2(rng.randf_range(20, 38), rng.randf_range(28, 55)),
				"phase": rng.randf() * TAU, "cell": rng.randi_range(0, 3), "smoke": false, "anchor": -1, "tile": 0})
		return result
	var theme: AtmosphereTheme = AtmosphereTheme.new()
	theme.scenery = AtmosphereTheme.Scenery.BURNING_VILLAGE
	for tile: int in range(-1, 3):
		var rect: Rect2 = PaintedWorld.tile_rect(2, tile, theme)
		for i: int in [0, 2, 4, 6]:
			# Select sites, never jitter the attachment off the painted architecture.
			if rng.randf() < 0.45: continue
			var uv: Vector2 = ANCHORS[i]
			if posmod(tile, 2) == 1: uv.x = 1.0 - uv.x
			var at: Vector2 = rect.position + uv * rect.size
			if at.x < -380 or at.x > 2380: continue
			var height: float = rng.randf_range(40, 85)
			result.append({"position": at, "size": Vector2(height * rng.randf_range(0.4, 0.7), height),
				"phase": rng.randf() * TAU, "cell": rng.randi_range(0, 3),
				"smoke": true, "anchor": i, "tile": tile})
	return result


func configure(stage_key: String, ground: bool = false) -> void:
	sites = layout(stage_key, ground)
	for child: Node in get_children(): child.free()
	_materials.clear()
	if _light == null:
		_light = GradientTexture2D.new()
		_light.width = 128
		_light.height = 64
		_light.fill = GradientTexture2D.FILL_RADIAL
		_light.fill_from = Vector2(0.5, 0.5)
		_light.fill_to = Vector2(1, 0.5)
		_light.gradient = Gradient.new()
		_light.gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	_batch("Glow", _light, preload("res://scripts/visuals/shaders/village_glow.gdshader"), 0, ground)
	_batch("Smoke", SMOKE, preload("res://scripts/visuals/shaders/village_smoke.gdshader"), 1, ground)
	if not ground:
		_batch("Heat", _light, preload("res://scripts/visuals/shaders/village_heat.gdshader"), 3, ground)
		_batch("Embers", _light, preload("res://scripts/visuals/shaders/village_embers.gdshader"), 4, ground)
	_batch("Flames", PaintedWorld.FIRE, preload("res://scripts/visuals/shaders/village_flames.gdshader"), 2, ground)
	_last_reduced = -1
	_process(0)


func _batch(label: String, tex: Texture2D, shader: Shader, kind: int, ground: bool) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	for site: Dictionary in sites:
		if kind == 1 and not site.smoke: continue
		var size: Vector2 = site.size
		var at: Vector2 = site.position
		var uv: Rect2 = Rect2(0, 0, 1, 1)
		if kind == 0:
			size *= Vector2(3.0, 0.42 if ground else 1.9)
			at.y += size.y * (0.5 if ground else 0.32)
		elif kind == 1:
			size *= Vector2(1.8, 2.4)
		elif kind == 2:
			uv = FLAME_CELLS[site.cell]
		else:
			size *= Vector2(1.8, 2.3)
		var rect: Rect2 = Rect2(at - Vector2(size.x * 0.5, size.y), size)
		var n: int = points.size()
		points.append_array(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))
		uvs.append_array(PackedVector2Array([uv.position, Vector2(uv.end.x, uv.position.y), uv.end, Vector2(uv.position.x, uv.end.y)]))
		for i: int in 4: colors.append(Color(float(site.phase) / TAU, float(site.cell) / 3.0, 0, 1))
		indices.append_array(PackedInt32Array([n, n + 1, n + 2, n, n + 2, n + 3]))
	if points.is_empty(): return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var draw: MeshInstance2D = MeshInstance2D.new()
	draw.name = label
	draw.mesh = mesh
	draw.texture = tex
	draw.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var paint: ShaderMaterial = ShaderMaterial.new()
	paint.shader = shader
	if kind == 2:
		var cells: PackedVector4Array = PackedVector4Array()
		for rect: Rect2 in FLAME_CELLS: cells.append(Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
		paint.set_shader_parameter("cells", cells)
	draw.material = paint
	_materials.append(paint)
	add_child(draw)


func _process(delta: float) -> void:
	var reduced: int = int(GameSettings.reduced_decorative_motion)
	_wind_clock -= delta
	if _wind_clock <= 0.0:
		_wind_clock = 0.15
		for paint: ShaderMaterial in _materials: paint.set_shader_parameter("wind", Atmosphere.wind_strength())
	if reduced == _last_reduced: return
	_last_reduced = reduced
	for paint: ShaderMaterial in _materials:
		paint.set_shader_parameter("motion", 0.15 if reduced else 1.0)
