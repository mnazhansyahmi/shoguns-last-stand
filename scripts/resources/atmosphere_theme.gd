class_name AtmosphereTheme
extends Resource
## The colours and mood of one stage's backdrop: the sky (indigo to crimson to gold), the sun or moon,
## the clouds, the layered hills and mist, the ground, the reeds, the falling leaves and petals, the
## light rays and the sun's rim light on the characters. Each stage names its own theme (StageData),
## so every battle has its own sunset. The values here are checked against the art bible's
## contrast rules by a test (see action_band_colors()).

## What stands in the land layers: the bamboo groves of Region 1 or the burning village of Region 2 (houses on fire,
## smoke columns and charred posts instead of bamboo). The sky, mist, ground and reeds are the same for both.
enum Scenery { BAMBOO_OUTSKIRTS, BURNING_VILLAGE }

@export var theme_id: String = "golden_sunset"
@export var display_name: String = "Golden Sunset"
@export var scenery: Scenery = Scenery.BAMBOO_OUTSKIRTS

@export_group("Sky")
## Top of the sky (indigo), the middle band (crimson) and the glow that meets the horizon (gold).
@export var sky_top: Color = Color("#2a2c5c")
@export var sky_mid: Color = Color("#a63a44")
@export var sky_low: Color = Color("#e9944f")
@export var sky_horizon: Color = Color("#f2c17a")
@export_group("Sun")
@export var sun_core: Color = Color("#ffe3a0")
@export var sun_halo: Color = Color("#ffb45a")
@export var sun_radius: float = 92.0
## A dark disc with a glowing ring instead of a bright one (an eclipse).
@export var eclipse: bool = false
@export_group("Clouds")
## Lit underside and shaded body of the layered clouds.
@export var cloud_lit: Color = Color("#ffb86a")
@export var cloud_shadow: Color = Color("#6e3a5e")
@export_range(0.0, 1.0) var cloud_alpha: float = 0.85
@export_group("Land")
@export var mountain_far: Color = Color("#c98f93")
@export var mountain_mid: Color = Color("#b07a8c")
@export var mist: Color = Color("#eab894")
@export var ground_top: Color = Color("#c9a08a")
@export var ground_bottom: Color = Color("#2b2030")
@export var bamboo_far: Color = Color("#a8808f")
@export var bamboo_near: Color = Color("#3a3050")
@export_group("Light")
## Colour of the light rays through the fog and of the thin rim light on characters.
@export var ray_color: Color = Color("#ffc878")
@export var rim_color: Color = Color("#ffcf80")
@export_group("Plants and leaves")
@export var reed_stalk: Color = Color("#d9a36b")
@export var reed_plume: Color = Color("#f7dcae")
@export var leaf_colors: PackedColorArray = PackedColorArray([Color("#c8321f"), Color("#e2552a"), Color("#a8231c")])
@export var petal_color: Color = Color("#f4b6b0")
@export_group("Wind")
## Average wind strength (0..1) and how far gusts push it above that.
@export_range(0.0, 1.0) var wind_base: float = 0.4
@export_range(0.0, 1.0) var wind_gust: float = 0.45
## Share of the falling things that are petals rather than maple leaves.
@export_range(0.0, 1.0) var petal_share: float = 0.3
@export_group("Fire (burning village)")
## The hot heart of the flames, their outer tongues, and the smoke rising from them.
@export var fire_core: Color = Color("#ffd27a")
@export var fire_glow: Color = Color("#ff6a24")
@export var smoke: Color = Color("#5a4048")
## 0..1: how many of the houses burn and how tall the flames are.
@export_range(0.0, 1.0) var fire_intensity: float = 0.0
## Share of the drifting things that are embers rising from the fires instead of leaves falling.
@export_range(0.0, 1.0) var ember_share: float = 0.0


## The colours that can appear behind a fighter, with the contrast each must reach against INK
## (docs/ART_BIBLE.md): the sky glow, mountains, mist, reed stalks and the ground's edge.
func action_band_colors() -> Array[Dictionary]:
	return [
		{"name": "sky_low", "color": sky_low, "ratio": 3.0},
		{"name": "sky_horizon", "color": sky_horizon, "ratio": 3.0},
		{"name": "mountain_far", "color": mountain_far, "ratio": 3.0},
		{"name": "mountain_mid", "color": mountain_mid, "ratio": 3.0},
		{"name": "bamboo_far", "color": bamboo_far, "ratio": 3.0},
		{"name": "reed_stalk", "color": reed_stalk, "ratio": 3.0},
		{"name": "mist", "color": mist, "ratio": 4.5},
		{"name": "ground_top", "color": ground_top, "ratio": 4.5},
	]
