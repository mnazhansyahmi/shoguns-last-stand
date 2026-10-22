class_name SpawnPortalVisual
extends Node2D
## Where the dead come from: a ruined, leaning torii with a violet vortex of ink mist swirling
## between its posts. Origin = ground level at the spawn point. Visual only.

const CENTER: Vector2 = Vector2(0.0, -125.0)
const ARMS: int = 4

var _clock: float = 0.0
var _glow_layer: Node2D
var _burning: bool = false
var _painting: Sprite2D
var _paint_material: ShaderMaterial


func _ready() -> void:
	_glow_layer = Node2D.new()
	_glow_layer.name = "PortalGlow"
	_glow_layer.material = InkFigure.additive_material()
	_glow_layer.show_behind_parent = true
	add_child(_glow_layer)
	_glow_layer.draw.connect(_draw_glow)
	_painting = Sprite2D.new()
	_painting.name = "PaintedPortal"
	_painting.position = Vector2(0, -155)
	add_child(_painting)
	apply_region(PaintedWorld.burning())


func apply_region(burning: bool) -> void:
	_burning = burning
	if _painting == null: return
	var art: AtlasTexture = AtlasTexture.new()
	art.atlas = PaintedWorld.PORTALS
	art.region = Rect2(Vector2(PaintedWorld.PORTALS.get_width() * (0.5 if burning else 0.0), 0),
		PaintedWorld.PORTALS.get_size() * Vector2(0.5, 1))
	art.filter_clip = true
	_painting.texture = art
	_painting.scale = Vector2(260, 410) / art.region.size
	_paint_material = ShaderMaterial.new()
	_paint_material.shader = preload("res://scripts/visuals/shaders/painted_portal.gdshader")
	_paint_material.set_shader_parameter("region_x", 0.5 if burning else 0.0)
	_painting.material = _paint_material


func _process(delta: float) -> void:
	_clock += delta
	if _paint_material != null:
		_paint_material.set_shader_parameter("motion", 0.15 if GameSettings.reduced_decorative_motion else 1.0)


func _draw() -> void:
	return # Retained painted portal supplies the torii and swirling ink.


func _draw_legacy() -> void:
	var torii: Color = InkPalette.INK_BACK.lerp(InkPalette.MIST, 0.3)
	# Left post upright, right post leaning; the top beam is snapped and hangs down on the right.
	InkBrush.fill_convex(self, PackedVector2Array([Vector2(-86.0, 0.0), Vector2(-66.0, 0.0),
			Vector2(-68.0, -262.0), Vector2(-86.0, -262.0)]), torii)
	InkBrush.fill_convex(self, PackedVector2Array([Vector2(66.0, 0.0), Vector2(86.0, 0.0),
			Vector2(96.0, -236.0), Vector2(78.0, -238.0)]), torii)
	InkBrush.fill_convex(self, PackedVector2Array([Vector2(-104.0, -222.0), Vector2(30.0, -222.0),
			Vector2(26.0, -236.0), Vector2(-104.0, -236.0)]), torii)
	InkBrush.fill(self, PackedVector2Array([Vector2(-128.0, -262.0), Vector2(-96.0, -258.0), Vector2(8.0, -258.0),
			Vector2(14.0, -270.0), Vector2(-4.0, -279.0), Vector2(-112.0, -282.0), Vector2(-136.0, -290.0)]), torii)
	InkBrush.fill_convex(self, PackedVector2Array([Vector2(26.0, -262.0), Vector2(110.0, -226.0),
			Vector2(104.0, -214.0), Vector2(22.0, -250.0)]), torii)
	# Swirling ink mist.
	var core: Color = Color(InkPalette.INK, 0.8)
	InkBrush.ellipse(self, CENTER, Vector2(30.0 + 3.0 * sin(_clock * 2.0), 92.0), core, 24)
	for arm: int in ARMS:
		var points: PackedVector2Array = PackedVector2Array()
		var start: float = _clock * 1.6 + TAU * float(arm) / float(ARMS)
		for i: int in 14:
			var t: float = float(i) / 13.0
			var angle: float = start + t * 2.6
			var radius: float = lerpf(18.0, 58.0, t)
			points.append(CENTER + Vector2(cos(angle) * radius, sin(angle) * radius * 1.9))
		InkBrush.stroke(self, points, 9.0, 2.0, Color(InkPalette.HOLLOW_PURPLE.darkened(0.25), 0.55))


func _draw_glow() -> void:
	var pulse: float = 0.85 + 0.15 * sin(_clock * 2.4)
	InkBrush.glow(_glow_layer, CENTER, 150.0 * pulse, Color(InkPalette.HOLLOW_PURPLE, 0.32 * pulse))
	InkBrush.glow(_glow_layer, CENTER + Vector2(0.0, 110.0), 90.0, Color(InkPalette.HOLLOW_PURPLE, 0.18))
