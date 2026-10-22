class_name RegionBackdrop
extends Node2D
## Root of a region backdrop scene (a stack of BackdropLayers plus the falling leaves). Menus reuse
## the battle backdrop behind their UI with `front_fog` off, because the front fog, front reeds and
## front leaves are drawn on top of everything in their canvas (they pass in front of the fighters
## in battle).
## It also drives the atmosphere: it sets the stage's AtmosphereTheme (apply_theme), advances the wind
## clock every frame and makes the light rays breathe with the gusts.

@export var front_fog: bool = true
## The theme to start with (null = the default sunset); a battle applies its stage's theme.
@export var theme: AtmosphereTheme

var _rays: CanvasItem
## The burning village's flame glow (empty in the bamboo scenery); it flickers.
var _fires: CanvasItem
var _painted_fires: Array[PaintedFlame] = []


func _ready() -> void:
	_rays = get_node_or_null("Rays") as CanvasItem
	_fires = get_node_or_null("Fires") as CanvasItem
	if _fires != null:
		for i: int in 6:
			var flame: PaintedFlame = PaintedFlame.new()
			flame.cell = i % 3
			flame.flame_size = Vector2(140 + i % 2 * 60, 190 + i % 3 * 35)
			flame.phase = float(i) * 2.7
			flame.position = Vector2(-420 + i * 590, 780)
			_fires.add_child(flame)
			_painted_fires.append(flame)
	apply_theme(theme)
	if front_fog:
		return
	for child: Node in get_children():
		var item: CanvasItem = child as CanvasItem
		if item != null and (child is BackdropLayer or child is AtmosphereLeaves) and item.z_index > 0:
			item.visible = false
			item.set_process(false)


## Keeps the falling leaves out of these screen rectangles (the HUD and the touch controls).
func set_keep_out(rects: Array[Rect2]) -> void:
	for child: Node in get_children():
		var leaves: AtmosphereLeaves = child as AtmosphereLeaves
		if leaves != null:
			leaves.keep_out = rects


## Paints every layer and recolours the leaves and the characters' rim light with `new_theme`.
func apply_theme(new_theme: AtmosphereTheme) -> void:
	theme = new_theme
	Atmosphere.set_theme(new_theme)
	for flame: PaintedFlame in _painted_fires:
		flame.visible = PaintedWorld.burning(Atmosphere.current())
	for child: Node in get_children():
		var layer: BackdropLayer = child as BackdropLayer
		if layer != null:
			layer.apply_theme(Atmosphere.current())
		var leaves: AtmosphereLeaves = child as AtmosphereLeaves
		if leaves != null:
			leaves.apply_theme()


func _process(delta: float) -> void:
	Atmosphere.advance(delta)
	if _rays != null:
		# The beams brighten and fade slowly, and a little more in a gust.
		_rays.modulate.a = clampf(0.72 + 0.28 * sin(Atmosphere.time * 0.42) + (Atmosphere.wind_strength() - 0.4) * 0.4, 0.3, 1.0)
	if _fires != null:
		# Uneven flicker: a few out-of-step waves, a little wilder in a gust.
		var t: float = Atmosphere.time
		_fires.modulate.a = clampf(0.78 + 0.12 * sin(t * 7.3) + 0.08 * sin(t * 12.9 + 1.1) + 0.06 * sin(t * 3.1 + 0.4)
				+ (Atmosphere.wind_strength() - 0.4) * 0.2, 0.4, 1.0)
