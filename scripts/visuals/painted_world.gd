class_name PaintedWorld
extends RefCounted
## Each layer is a native-resolution painting. Repeated, mirrored tiles cover the
## scroll bounds; no texture is enlarged, even at the battle camera's 1.5x zoom.
const BAMBOO: Array[Texture2D] = [
	preload("res://assets/art/world/sharp/bamboo_sky.png"),
	preload("res://assets/art/world/sharp/bamboo_mountains.png"),
	preload("res://assets/art/world/sharp/bamboo_scenery.png"),
	preload("res://assets/art/world/sharp/bamboo_ground.png"),
	preload("res://assets/art/world/sharp/bamboo_grass.png")]
const VILLAGE: Array[Texture2D] = [
	preload("res://assets/art/world/sharp/village_sky.png"),
	preload("res://assets/art/world/sharp/village_mountains.png"),
	preload("res://assets/art/world/sharp/village_scenery.png"),
	preload("res://assets/art/world/sharp/village_ground.png"),
	preload("res://assets/art/world/sharp/village_grass.png")]
const TILE_SCALES: PackedFloat32Array = [1.0, 0.82, 0.65, 0.60, 0.45]
const DEPTHS: PackedFloat32Array = [0.0, 0.18, 0.55, 1.0, 1.05]
const LEFT: float = -1400.0
const RIGHT: float = 3600.0
const SCENERY_ORIGIN: float = -600.0
const GATES: Texture2D = preload("res://assets/art/world/gates.png")
const PORTALS: Texture2D = preload("res://assets/art/world/portals.png")
const FIRE: Texture2D = preload("res://assets/art/world/fire.png")
const FIRE_CELLS: Array[Rect2] = [Rect2(0, 0, 0.4, 0.52), Rect2(0.4, 0, 0.6, 0.52),
	Rect2(0, 0.52, 0.4, 0.48), Rect2(0.4, 0.52, 0.6, 0.48)]


static func burning(theme: AtmosphereTheme = null) -> bool:
	return (theme if theme != null else Atmosphere.current()).scenery == AtmosphereTheme.Scenery.BURNING_VILLAGE


static func source(texture: Texture2D, region: Rect2) -> Rect2:
	return Rect2(region.position * texture.get_size(), region.size * texture.get_size())


static func textures(theme: AtmosphereTheme = null) -> Array[Texture2D]:
	return VILLAGE if burning(theme) else BAMBOO


## Density in each axis is identical: all textures retain their original aspect.
static func texels_per_screen_pixel(index: int, zoom: float = 1.5) -> float:
	return 1.0 / (TILE_SCALES[index] * lerpf(1.0, zoom, DEPTHS[index]))


static func tile_rect(index: int, tile: int, theme: AtmosphereTheme = null) -> Rect2:
	var tex: Texture2D = textures(theme)[index]
	var size: Vector2 = tex.get_size() * TILE_SCALES[index]
	var bottom: float = 880.0
	var origin: float = SCENERY_ORIGIN
	match index:
		0:
			bottom = 684.0
			origin = -126.0
		3:
			bottom = 1394.4 # Top at 780; painted dirt becomes solid at the feet.
		4:
			bottom = 1090.0
	return Rect2(Vector2(origin + tile * size.x, bottom - size.y), size)


static func _tiles(ci: CanvasItem, index: int, theme: AtmosphereTheme, tint: Color = Color.WHITE, y_offset: float = 0.0) -> void:
	var tex: Texture2D = textures(theme)[index]
	var exemplar: Rect2 = tile_rect(index, 0, theme)
	var start: int = floori((LEFT - exemplar.position.x) / exemplar.size.x)
	var finish: int = ceili((RIGHT - exemplar.position.x) / exemplar.size.x)
	for tile: int in range(start, finish):
		var rect: Rect2 = tile_rect(index, tile, theme)
		if rect.end.x < LEFT or rect.position.x > RIGHT: continue
		rect.position.y += y_offset
		# Mirror adjacent edges rather than stretch or cross-fade sharp details.
		if posmod(tile, 2) == 1:
			ci.draw_set_transform(Vector2(rect.end.x, 0), 0.0, Vector2(-1, 1))
			rect.position.x = 0.0
		ci.draw_texture_rect(tex, rect, false, tint)
		ci.draw_set_transform(Vector2.ZERO)


## Returns false only for the retained atmosphere overlays (mist, rays, clouds).
static func paint(ci: CanvasItem, layer: BambooOutskirtsPainter.Layer, theme: AtmosphereTheme) -> bool:
	match layer:
		BambooOutskirtsPainter.Layer.SKY:
			ci.draw_rect(Rect2(LEFT, -1200, RIGHT - LEFT, 3000), Color("6b4741") if burning(theme) else Color("bd9d80"))
			_tiles(ci, 0, theme)
		BambooOutskirtsPainter.Layer.MOUNTAINS:
			_tiles(ci, 1, theme)
		BambooOutskirtsPainter.Layer.BAMBOO_FAR:
			_tiles(ci, 2, theme, Color(0.9, 0.9, 0.9))
		BambooOutskirtsPainter.Layer.GROUND:
			_tiles(ci, 3, theme)
		BambooOutskirtsPainter.Layer.REEDS_FRONT:
			_tiles(ci, 4, theme, Color(0.8, 0.8, 0.8, 0.85))
		BambooOutskirtsPainter.Layer.REEDS_BACK:
			_tiles(ci, 4, theme, Color(0.9, 0.9, 0.9, 0.45), -100.0)
		BambooOutskirtsPainter.Layer.FIRES:
			return true # Separate painted shader sprites retain their draw commands.
		BambooOutskirtsPainter.Layer.MOON, BambooOutskirtsPainter.Layer.DISTANT_MOUNTAINS, \
		BambooOutskirtsPainter.Layer.HILLS, BambooOutskirtsPainter.Layer.BAMBOO_NEAR, \
		BambooOutskirtsPainter.Layer.CLOUDS_HIGH, BambooOutskirtsPainter.Layer.CLOUDS_LOW:
			return true # These forms are already in the authored scenery slices.
		_:
			return false
	return true
