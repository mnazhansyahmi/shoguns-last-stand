class_name InkThemeBuilder
extends RefCounted
## Builds the game's one UI theme from InkPalette: dark charcoal panels, parchment text, gold
## accents (docs/ART_BIBLE.md, UI). tools/make_ui_theme.gd saves it to THEME_PATH, which
## project.godot sets as the custom theme, so every Control uses it. Scenes pick named
## variations (theme_type_variation) instead of overriding colours.

const THEME_PATH: String = "res://assets/ui/ink_theme.tres"
## Serif / mincho faces for titles, first one installed wins (falls back to the default font).
const SERIF_FONTS: PackedStringArray = ["Yu Mincho", "Hiragino Mincho ProN", "Noto Serif CJK JP",
		"Noto Serif JP", "Noto Serif", "Georgia", "Times New Roman", "serif"]
const LABEL_VARIATIONS: Array[StringName] = [&"TitleLabel", &"HeaderLabel", &"GoldLabel", &"DimLabel",
		&"WarningLabel", &"SuccessLabel", &"SpiritLabel", &"HudLabel", &"HudDimLabel", &"HudTitleLabel",
		&"HudBannerLabel", &"HudMessageLabel"]
const BUTTON_VARIATIONS: Array[StringName] = [&"ToggleButton", &"PrimaryButton", &"DangerButton", &"CostButton", &"CostButtonShort",
		&"MenuButtonPanel", &"MenuButtonPanelSub"]
## The upgrade shop's cards: an upgrade you can see, and one for an ally not yet unlocked.
const PANEL_VARIATIONS: Array[StringName] = [&"CardPanel", &"CardPanelLocked"]


static func build() -> Theme:
	var theme: Theme = Theme.new()
	var serif: SystemFont = SystemFont.new()
	serif.font_names = SERIF_FONTS
	serif.font_weight = 600
	_labels(theme, serif)
	_buttons(theme, serif)
	_panels(theme)
	_sliders(theme)
	_scrollbars(theme)
	return theme


static func box(background: Color, border: Color, border_width: int, corner: int = 4) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner)
	style.corner_detail = 4
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


static func _labels(theme: Theme, serif: Font) -> void:
	theme.set_color(&"font_color", &"Label", InkPalette.PARCHMENT)
	theme.set_color(&"font_outline_color", &"Label", InkPalette.INK)
	theme.set_constant(&"outline_size", &"Label", 0)
	_label(theme, &"TitleLabel", InkPalette.GOLD_BRIGHT, 14, serif)
	_label(theme, &"HeaderLabel", InkPalette.GOLD_BRIGHT, 0, serif)
	_label(theme, &"GoldLabel", InkPalette.GOLD_BRIGHT, 0, null)
	_label(theme, &"DimLabel", InkPalette.PARCHMENT_DIM, 0, null)
	_label(theme, &"WarningLabel", InkPalette.EMBER_TEXT, 0, null)
	_label(theme, &"SuccessLabel", InkPalette.JADE, 0, null)
	_label(theme, &"SpiritLabel", InkPalette.SPIRIT, 0, null)
	# On the battlefield text always gets an ink outline (it sits on the backdrop).
	_label(theme, &"HudLabel", InkPalette.PARCHMENT, 8, null)
	_label(theme, &"HudDimLabel", Color(InkPalette.PARCHMENT_DIM, 0.9), 6, null)
	_label(theme, &"HudTitleLabel", InkPalette.GOLD_BRIGHT, 8, serif)
	_label(theme, &"HudBannerLabel", InkPalette.GOLD_BRIGHT, 14, serif)
	_label(theme, &"HudMessageLabel", InkPalette.GOLD_BRIGHT, 6, null)


static func _label(theme: Theme, variation: StringName, color: Color, outline: int, font: Font) -> void:
	theme.set_type_variation(variation, &"Label")
	theme.set_color(&"font_color", variation, color)
	theme.set_color(&"font_outline_color", variation, InkPalette.INK)
	theme.set_constant(&"outline_size", variation, outline)
	if font != null:
		theme.set_font(&"font", variation, font)


static func _buttons(theme: Theme, serif: Font) -> void:
	var normal: StyleBoxFlat = box(InkPalette.UI_BUTTON, Color(InkPalette.GOLD, 0.45), 2)
	var hover: StyleBoxFlat = box(InkPalette.UI_BUTTON_HOVER, InkPalette.GOLD_BRIGHT, 3)
	var pressed: StyleBoxFlat = box(InkPalette.UI_BUTTON_PRESSED, InkPalette.GOLD, 3)
	var disabled: StyleBoxFlat = box(Color(InkPalette.UI_CHARCOAL, 0.9), Color(InkPalette.UI_DISABLED, 0.45), 2)
	var focus: StyleBoxFlat = box(Color(0.0, 0.0, 0.0, 0.0), InkPalette.GOLD_BRIGHT, 3)
	focus.draw_center = false
	focus.set_expand_margin_all(4.0)
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
		var style: StyleBoxFlat = normal
		match state:
			&"hover":
				style = hover
			&"pressed", &"hover_pressed":
				style = pressed
			&"disabled":
				style = disabled
			&"focus":
				style = focus
		theme.set_stylebox(state, &"Button", style)
	theme.set_color(&"font_color", &"Button", InkPalette.PARCHMENT)
	theme.set_color(&"font_hover_color", &"Button", InkPalette.GOLD_BRIGHT)
	theme.set_color(&"font_pressed_color", &"Button", InkPalette.GOLD_BRIGHT)
	theme.set_color(&"font_hover_pressed_color", &"Button", InkPalette.GOLD_BRIGHT)
	theme.set_color(&"font_focus_color", &"Button", InkPalette.PARCHMENT)
	theme.set_color(&"font_disabled_color", &"Button", InkPalette.UI_DISABLED)
	theme.set_color(&"font_outline_color", &"Button", InkPalette.INK)

	# A toggle that is on: lit gold.
	theme.set_type_variation(&"ToggleButton", &"Button")
	var on: StyleBoxFlat = box(InkPalette.UI_BUTTON.lerp(InkPalette.GOLD, 0.22), InkPalette.GOLD_BRIGHT, 4)
	theme.set_stylebox(&"pressed", &"ToggleButton", on)
	theme.set_stylebox(&"hover_pressed", &"ToggleButton", on)
	theme.set_color(&"font_pressed_color", &"ToggleButton", InkPalette.PARCHMENT)
	theme.set_color(&"font_hover_pressed_color", &"ToggleButton", InkPalette.PARCHMENT)

	# The main call to action on a screen (Next Stage).
	theme.set_type_variation(&"PrimaryButton", &"Button")
	theme.set_stylebox(&"normal", &"PrimaryButton", box(InkPalette.UI_BUTTON.lerp(InkPalette.GOLD, 0.12), InkPalette.GOLD_BRIGHT, 3))
	theme.set_color(&"font_color", &"PrimaryButton", InkPalette.GOLD_BRIGHT)

	# Destructive actions (reset progress).
	theme.set_type_variation(&"DangerButton", &"Button")
	theme.set_stylebox(&"normal", &"DangerButton", box(InkPalette.UI_BUTTON, InkPalette.CRIMSON, 2))
	theme.set_stylebox(&"hover", &"DangerButton", box(InkPalette.UI_BUTTON.lerp(InkPalette.CRIMSON, 0.3), InkPalette.EMBER_TEXT, 3))
	theme.set_stylebox(&"pressed", &"DangerButton", box(InkPalette.UI_BUTTON_PRESSED, InkPalette.CRIMSON, 3))
	theme.set_color(&"font_color", &"DangerButton", InkPalette.EMBER_TEXT)
	theme.set_color(&"font_hover_color", &"DangerButton", InkPalette.PARCHMENT)

	# The cost button of an upgrade card: gold when the upgrade can be bought, red when the gold is short.
	theme.set_type_variation(&"CostButton", &"Button")
	theme.set_stylebox(&"normal", &"CostButton", box(InkPalette.UI_BUTTON.lerp(InkPalette.GOLD, 0.14), InkPalette.GOLD_BRIGHT, 3))
	theme.set_color(&"font_color", &"CostButton", InkPalette.GOLD_BRIGHT)
	theme.set_color(&"font_focus_color", &"CostButton", InkPalette.GOLD_BRIGHT)
	theme.set_type_variation(&"CostButtonShort", &"Button")
	theme.set_stylebox(&"normal", &"CostButtonShort", box(InkPalette.UI_BUTTON, Color(InkPalette.CRIMSON, 0.9), 2))
	theme.set_color(&"font_color", &"CostButtonShort", InkPalette.EMBER_TEXT)
	theme.set_color(&"font_focus_color", &"CostButtonShort", InkPalette.EMBER_TEXT)
	theme.set_color(&"font_hover_color", &"CostButtonShort", InkPalette.EMBER_TEXT)
	_menu_buttons(theme, serif)


## The main menu's buttons (InkMenuButton): no box from the theme, because the button draws its own panel (so it can
## fade its glow in); gold serif text set in from the left (the margins say where InkMenuButton draws it).
## MenuButtonPanelSub leaves room under the label, inside the panel, for the small line (Continue's stage).
static func _menu_buttons(theme: Theme, serif: Font) -> void:
	for variation: StringName in [&"MenuButtonPanel", &"MenuButtonPanelSub"]:
		theme.set_type_variation(variation, &"Button")
		var bare: StyleBoxEmpty = StyleBoxEmpty.new()
		bare.content_margin_left = 40.0
		bare.content_margin_right = 24.0
		bare.content_margin_top = 8.0
		bare.content_margin_bottom = 8.0 if variation == &"MenuButtonPanel" else 48.0
		for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
			theme.set_stylebox(state, variation, bare)
		theme.set_font(&"font", variation, serif)
		# The button's own text would be drawn before (so under) the panel: it is made invisible here and the button draws
		# the gold label itself on top of the panel (InkMenuButton._draw_label).
		var clear: Color = Color(0.0, 0.0, 0.0, 0.0)
		for color_name: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color",
				&"font_hover_pressed_color", &"font_disabled_color", &"font_outline_color"]:
			theme.set_color(color_name, variation, clear)
		theme.set_constant(&"outline_size", variation, 0)


static func _panels(theme: Theme) -> void:
	var panel: StyleBoxFlat = box(Color(InkPalette.UI_CHARCOAL, 0.94), InkPalette.GOLD, 2, 6)
	panel.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	panel.shadow_size = 16
	panel.set_content_margin_all(24.0)
	theme.set_stylebox(&"panel", &"PanelContainer", panel)
	theme.set_stylebox(&"panel", &"Panel", panel)
	# Upgrade cards: a charcoal card with a thin gold edge; a locked one is dimmer.
	theme.set_type_variation(&"CardPanel", &"PanelContainer")
	var card: StyleBoxFlat = box(Color(InkPalette.UI_CHARCOAL, 0.92), Color(InkPalette.GOLD, 0.75), 2, 8)
	card.set_content_margin_all(14.0)
	theme.set_stylebox(&"panel", &"CardPanel", card)
	theme.set_type_variation(&"CardPanelLocked", &"PanelContainer")
	var locked: StyleBoxFlat = box(Color(InkPalette.INK, 0.85), Color(InkPalette.UI_DISABLED, 0.5), 2, 8)
	locked.set_content_margin_all(14.0)
	theme.set_stylebox(&"panel", &"CardPanelLocked", locked)
	# Dialogs (reset confirmation): framed window, transparent inner panel.
	var window: StyleBoxFlat = box(Color(InkPalette.UI_CHARCOAL, 0.97), InkPalette.GOLD, 2, 6)
	window.set_expand_margin_all(8.0)
	window.expand_margin_top = 44.0
	theme.set_stylebox(&"embedded_border", &"Window", window)
	theme.set_stylebox(&"embedded_unfocused_border", &"Window", window)
	theme.set_color(&"title_color", &"Window", InkPalette.GOLD_BRIGHT)
	theme.set_stylebox(&"panel", &"AcceptDialog", box(Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0), 0))


static func _sliders(theme: Theme) -> void:
	var track: StyleBoxFlat = box(InkPalette.UI_BUTTON, Color(InkPalette.GOLD, 0.4), 2, 8)
	track.content_margin_top = 10.0
	track.content_margin_bottom = 10.0
	var fill: StyleBoxFlat = box(InkPalette.GOLD, InkPalette.GOLD, 0, 8)
	fill.content_margin_top = 10.0
	fill.content_margin_bottom = 10.0
	theme.set_stylebox(&"slider", &"HSlider", track)
	theme.set_stylebox(&"grabber_area", &"HSlider", fill)
	theme.set_stylebox(&"grabber_area_highlight", &"HSlider", fill)
	theme.set_icon(&"grabber", &"HSlider", _knob(InkPalette.PARCHMENT))
	theme.set_icon(&"grabber_highlight", &"HSlider", _knob(InkPalette.GOLD_BRIGHT))


## Round slider knob: solid disc with a gold rim, drawn as a radial gradient (no image file).
static func _knob(center: Color) -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.62, 0.7, 0.86, 0.92])
	gradient.colors = PackedColorArray([center, center, InkPalette.GOLD, InkPalette.GOLD, Color(InkPalette.GOLD, 0.0)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 52
	texture.height = 52
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture


static func _scrollbars(theme: Theme) -> void:
	var track: StyleBoxFlat = box(Color(InkPalette.UI_BUTTON, 0.8), Color(0.0, 0.0, 0.0, 0.0), 0, 6)
	track.set_content_margin_all(6.0)
	var grabber: StyleBoxFlat = box(Color(InkPalette.GOLD, 0.7), Color(0.0, 0.0, 0.0, 0.0), 0, 6)
	var grabber_lit: StyleBoxFlat = box(InkPalette.GOLD_BRIGHT, Color(0.0, 0.0, 0.0, 0.0), 0, 6)
	for type_name: StringName in [&"VScrollBar", &"HScrollBar"]:
		theme.set_stylebox(&"scroll", type_name, track)
		theme.set_stylebox(&"grabber", type_name, grabber)
		theme.set_stylebox(&"grabber_highlight", type_name, grabber_lit)
		theme.set_stylebox(&"grabber_pressed", type_name, grabber_lit)
