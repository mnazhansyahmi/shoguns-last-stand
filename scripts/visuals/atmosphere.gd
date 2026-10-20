class_name Atmosphere
extends RefCounted
## The scene's shared atmosphere state (static, no autoload): the current AtmosphereTheme, the wind,
## and the shader material that gives every character the sun's thin rim light. A RegionBackdrop
## drives it: it sets the theme for the stage and advances the clock each frame; reeds, leaves and
## rays read the wind from here so they all move with the same gusts. Visual only.

const DEFAULT_THEME_PATH: String = "res://data/atmosphere/golden_sunset.tres"
const RIM_SHADER_PATH: String = "res://scripts/visuals/shaders/rim_light.gdshader"
## Screen direction toward the sun (up and to the right), and how far the rim sliver reaches in
## world pixels (about 2 px on screen with the battle zoom).
const SUN_DIRECTION: Vector2 = Vector2(0.62, -0.78)
const RIM_THICKNESS: float = 2.3

static var theme: AtmosphereTheme
## Seconds the wind has been blowing (advanced by the backdrop).
static var time: float = 0.0

static var _rim_material: ShaderMaterial


## The theme in force (the default sunset until a stage sets its own).
static func current() -> AtmosphereTheme:
	if theme == null:
		theme = load(DEFAULT_THEME_PATH) as AtmosphereTheme
	return theme


static func set_theme(new_theme: AtmosphereTheme) -> void:
	theme = new_theme if new_theme != null else load(DEFAULT_THEME_PATH) as AtmosphereTheme
	_update_rim()


static func advance(delta: float) -> void:
	time += delta


## Wind strength now, 0..1: the theme's base level plus slow, uneven gusts.
static func wind_strength(at_time: float = -1.0) -> float:
	var t: float = time if at_time < 0.0 else at_time
	var gust: float = clampf(0.5 + 0.34 * sin(t * 0.31) + 0.24 * sin(t * 0.83 + 1.7) + 0.12 * sin(t * 2.1 + 0.4), 0.0, 1.0)
	var theme_now: AtmosphereTheme = current()
	return clampf(theme_now.wind_base + theme_now.wind_gust * (gust - 0.35), 0.0, 1.0)


## Wind strength at world x: gusts travel along the field as waves.
static func wind_at(x: float, at_time: float = -1.0) -> float:
	var t: float = time if at_time < 0.0 else at_time
	return wind_strength(t) * (0.7 + 0.3 * sin(x * 0.0042 - t * 1.3))


## The shared material that lights every character part's sun side. One instance for all figures,
## so they batch together; its uniforms follow the theme.
static func rim_material() -> ShaderMaterial:
	if _rim_material == null:
		_rim_material = ShaderMaterial.new()
		_rim_material.shader = load(RIM_SHADER_PATH) as Shader
		_update_rim()
	return _rim_material


## The rim light's colour for a theme: the sun's warm light, pushed whichever way makes it stand out
## most against the theme's bright sky: toward white on a dark or saturated sky, toward a deep vivid
## sun-fire on a pale one (a test checks the contrast for every theme).
static func rim_color_for(theme_now: AtmosphereTheme) -> Color:
	var base: Color = theme_now.rim_color
	var candidates: Array[Color] = [Color(base.lerp(Color(1.0, 0.97, 0.9), 0.6), 1.0)]
	for hue_shift: float in [-0.14, -0.07, 0.0, 0.07, 0.14]:
		for value: float in [0.7, 0.85, 1.0]:
			candidates.append(Color.from_hsv(fposmod(base.h + hue_shift, 1.0), 1.0, value))
	var best: Color = candidates[0]
	var best_ratio: float = -1.0
	for candidate: Color in candidates:
		# It must also read against the dark body it outlines.
		if InkPalette.contrast(candidate, InkPalette.INK) < 5.5:
			continue
		var ratio: float = INF
		for backdrop: Color in [theme_now.sky_horizon, theme_now.mist, theme_now.ground_top]:
			ratio = minf(ratio, InkPalette.contrast(candidate, backdrop))
		if ratio > best_ratio:
			best_ratio = ratio
			best = candidate
	return best


static func _update_rim() -> void:
	if _rim_material == null:
		return
	_rim_material.set_shader_parameter("rim_color", rim_color_for(current()))
	_rim_material.set_shader_parameter("rim_offset", SUN_DIRECTION.normalized() * RIM_THICKNESS)
