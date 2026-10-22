class_name PaintedWorld
extends RefCounted
## Authored atlas slices retain the existing layer depths and camera framing.
const BAMBOO: Texture2D = preload("res://assets/art/world/bamboo_parallax.png")
const VILLAGE: Texture2D = preload("res://assets/art/world/village_parallax.png")
const GATES: Texture2D = preload("res://assets/art/world/gates.png")
const PORTALS: Texture2D = preload("res://assets/art/world/portals.png")
const FIRE: Texture2D = preload("res://assets/art/world/fire.png")
const FIRE_CELLS: Array[Rect2] = [Rect2(0, 0, 0.4, 0.52), Rect2(0.4, 0, 0.6, 0.52),
	Rect2(0, 0.52, 0.4, 0.48), Rect2(0.4, 0.52, 0.6, 0.48)]


static func burning(theme: AtmosphereTheme = null) -> bool:
	return (theme if theme != null else Atmosphere.current()).scenery == AtmosphereTheme.Scenery.BURNING_VILLAGE


static func source(texture: Texture2D, region: Rect2) -> Rect2:
	return Rect2(region.position * texture.get_size(), region.size * texture.get_size())


## Returns false only for the retained atmosphere overlays (mist, rays, clouds).
static func paint(ci: CanvasItem, layer: BambooOutskirtsPainter.Layer, theme: AtmosphereTheme) -> bool:
	var village: bool = burning(theme)
	var atlas: Texture2D = VILLAGE if village else BAMBOO
	var cuts: PackedFloat32Array = PackedFloat32Array([0.0, 0.195, 0.445, 0.683, 0.821, 1.0] if village else [0.0, 0.199, 0.398, 0.627, 0.799, 1.0])
	var row: int = -1
	var rect: Rect2
	var tint: Color = Color.WHITE
	match layer:
		BambooOutskirtsPainter.Layer.SKY:
			row = 0
			rect = Rect2(-1400, -900, 4700, 1780)
		BambooOutskirtsPainter.Layer.MOUNTAINS:
			row = 1
			rect = Rect2(-900, 60, 3700, 820)
			tint = Color(1.08, 1.08, 1.08)
		BambooOutskirtsPainter.Layer.BAMBOO_FAR:
			row = 2
			rect = Rect2(-900, 100, 3700, 780)
			tint = Color(1.1, 1.1, 1.1)
		BambooOutskirtsPainter.Layer.GROUND:
			# Ground rows include empty sky. Crop to the painted contact contour;
			# the collision line stays y=880 in both regions.
			var top: float = 0.734 if village else 0.701
			ci.draw_texture_rect_region(atlas, Rect2(-900, 870, 3700, 830),
				source(atlas, Rect2(0, top, 1, cuts[4] - top)), Color(1.12, 1.12, 1.12))
			return true
		BambooOutskirtsPainter.Layer.REEDS_FRONT:
			row = 4
			rect = Rect2(-900, 930, 3700, 650)
			tint = Color(0.8, 0.8, 0.8, 0.85)
		BambooOutskirtsPainter.Layer.REEDS_BACK:
			row = 4
			rect = Rect2(-900, 770, 3700, 250)
			tint = Color(1, 1, 1, 0.7)
		BambooOutskirtsPainter.Layer.FIRES:
			return true # Separate painted shader sprites retain their draw commands.
		BambooOutskirtsPainter.Layer.MOON, BambooOutskirtsPainter.Layer.DISTANT_MOUNTAINS, \
		BambooOutskirtsPainter.Layer.HILLS, BambooOutskirtsPainter.Layer.BAMBOO_NEAR, \
		BambooOutskirtsPainter.Layer.CLOUDS_HIGH, BambooOutskirtsPainter.Layer.CLOUDS_LOW:
			return true # These forms are already in the authored scenery slices.
		_:
			return false
	ci.draw_texture_rect_region(atlas, rect, source(atlas, Rect2(0, cuts[row], 1, cuts[row + 1] - cuts[row])), tint)
	return true
