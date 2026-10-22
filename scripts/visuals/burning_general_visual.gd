class_name BurningGeneralVisual
extends Node2D
## Shoulder and blade fire, bounded embers and a small local heat pass.
var visual: UnitVisual
var body_height: float = 310.0
var _flames: Array[PaintedFlame] = []
var _embers: CPUParticles2D
var _haze: Sprite2D


func _ready() -> void:
	for i: int in 4:
		var flame: PaintedFlame = PaintedFlame.new()
		flame.cell = 2 if i < 2 else 0
		flame.flame_size = Vector2(58, 88) if i < 2 else Vector2(34, 100)
		flame.phase = i * 2.1
		add_child(flame)
		_flames.append(flame)
	_embers = CPUParticles2D.new()
	_embers.name = "Embers"
	_embers.amount = 16
	_embers.lifetime = 1.3
	_embers.direction = Vector2.UP
	_embers.spread = 35.0
	_embers.gravity = Vector2(0, -18)
	_embers.initial_velocity_min = 25.0
	_embers.initial_velocity_max = 75.0
	_embers.scale_amount_min = 1.0
	_embers.scale_amount_max = 2.5
	_embers.color = Color(1.0, 0.43, 0.10, 0.7)
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_embers.emission_rect_extents = Vector2(40, 30)
	_embers.position.y = -body_height * 0.6
	add_child(_embers)
	_haze = Sprite2D.new()
	_haze.name = "HeatHaze"
	var quad: GradientTexture2D = GradientTexture2D.new()
	quad.width = 8
	quad.height = 8
	_haze.texture = quad
	_haze.scale = Vector2(190, body_height + 70) / 8.0
	_haze.position.y = -body_height * 0.55
	_haze.z_index = -1
	var heat: ShaderMaterial = ShaderMaterial.new()
	heat.shader = preload("res://scripts/visuals/shaders/heat_haze.gdshader")
	_haze.material = heat
	add_child(_haze)


func _process(_delta: float) -> void:
	if not is_instance_valid(visual): return
	var shown: bool = visual.is_on_screen() and visual.get_state() != &"dead"
	visible = shown
	_embers.emitting = shown and not GameSettings.reduced_decorative_motion
	_haze.visible = shown and not GameSettings.reduced_decorative_motion
	if not shown: return
	var fig: InkFigure = visual.get_figure()
	for i: int in 2:
		_flames[i].position = fig.transform * (fig.torso_xf * (fig.spec.shoulder_front if i == 0 else fig.spec.shoulder_back))
	for i: int in range(2, 4):
		_flames[i].position = fig.transform * (fig.weapon_xf * Vector2(32 + (i - 2) * 46, 0))
		_flames[i].rotation = fig.weapon_xf.get_rotation() + PI * 0.5
