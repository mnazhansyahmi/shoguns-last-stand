class_name PaintedFlame
extends Sprite2D
## A retained painted flame quad. No per-frame geometry or particles are rebuilt.
var cell: int = 0
var flame_size: Vector2 = Vector2(100, 160)
var phase: float = 0.0
var _paint: ShaderMaterial


func _ready() -> void:
	var art: AtlasTexture = AtlasTexture.new()
	art.atlas = PaintedWorld.FIRE
	var uv: Rect2 = PaintedWorld.FIRE_CELLS[clampi(cell, 0, 3)]
	art.region = PaintedWorld.source(PaintedWorld.FIRE, uv)
	art.filter_clip = true
	texture = art
	centered = false
	offset = Vector2(-art.region.size.x * 0.5, -art.region.size.y)
	scale = flame_size / art.region.size
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_paint = ShaderMaterial.new()
	_paint.shader = preload("res://scripts/visuals/shaders/painted_flame.gdshader")
	_paint.set_shader_parameter("uv_rect", Vector4(uv.position.x, uv.position.y, uv.size.x, uv.size.y))
	_paint.set_shader_parameter("phase", phase)
	material = _paint


func _process(_delta: float) -> void:
	if not is_visible_in_tree(): return
	_paint.set_shader_parameter("motion", 0.15 if GameSettings.reduced_decorative_motion else 1.0)
