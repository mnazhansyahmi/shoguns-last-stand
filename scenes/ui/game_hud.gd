class_name GameHud
extends CanvasLayer
## Battle HUD. Top-left, two blocks: the vitals (the samurai's round portrait medallion with the Ultimate meter as a ring
## round it, his health as a katana blade coming out of it, Spirit Energy as a flowing ink bar with a spirit orb, and the
## gate's health as a small gate icon with a short bar) and, in keyboard mode, one row of round skill icons (Dash, Heavy, Slash, Bow, War Cry and the ally stance: a symbol, its key, a cooldown
## sweep, a glow when ready, a padlock when locked). Top-center: wave and enemies remaining. Top-right: pause button.
## Keyboard hints at the bottom are hidden while touch controls are shown. Respects the safe area and UI scale.

signal pause_requested

const BANNER_FADE_TIME: float = 0.4
const SCREEN_MARGIN: Vector2 = Vector2(32.0, 24.0)
## Room kept free above the touch summon buttons and the Allies button for messages.
const TOUCH_BOTTOM_SPACE: float = 380.0
## Edge indicator tabs start at least this far below the top of the safe area, and always below
## the top-left vitals (left tab) or the pause button (right tab).
const INDICATOR_TOP: float = 196.0
const INDICATOR_GAP: float = 14.0
## The skill icons in order: [id, symbol, ring colour, name, Input Map action of the key badge].
const SKILL_ICONS: Array[Array] = [
	["dash", UpgradeIcon.Kind.DASH, Color(0.29, 0.435, 0.647, 1.0), "Dash", &"dash"],
	["heavy", UpgradeIcon.Kind.HEAVY, Color(0.722, 0.196, 0.165, 1.0), "Heavy strike", &"heavy_attack"],
	["slash", UpgradeIcon.Kind.SPIRIT_SLASH, Color(0.184, 0.525, 0.722, 1.0), "Spirit Slash", &"spirit_slash"],
	["bow", UpgradeIcon.Kind.BOW, Color(0.42, 0.56, 0.3, 1.0), "Bow", &"bow"],
	["war_cry", UpgradeIcon.Kind.WAR_CRY, Color(0.78, 0.56, 0.2, 1.0), "War Cry", &"war_cry"],
	["stance", UpgradeIcon.Kind.STANCE_CHARGE, Color(0.843, 0.216, 0.169, 1.0), "Allies", &"stance"],
]

@onready var _margin: MarginContainer = $Margin
@onready var _top_left: VBoxContainer = %TopLeft
@onready var _wave_box: VBoxContainer = %WaveBox
@onready var _health_blade: HudHealthBlade = %HealthBlade
@onready var _spirit_bar: HudSpiritBar = %SpiritBar
@onready var _gate_bar: HudGateBar = %GateBar
@onready var _ultimate_ring: HudUltimateRing = %UltimateRing
@onready var _skill_row: HBoxContainer = %SkillRow
@onready var _wave_label: Label = %WaveLabel
@onready var _remaining_label: Label = %RemainingLabel
@onready var _pause_button: Button = %PauseButton
@onready var _banner_label: Label = %BannerLabel
@onready var _status_label: Label = %StatusLabel
@onready var _message_label: Label = %MessageLabel
@onready var _summon_label: Label = %SummonLabel
@onready var _hint_label: Label = %HintLabel
@onready var _debug_hint_label: Label = %DebugHintLabel
@onready var _touch_spacer: Control = %TouchSpacer

var _summon_bar: HBoxContainer
var _summon_buttons: Array[TouchActionButton] = []
var _safe_rect: Rect2 = Rect2()
## The boss's bar with his name, under the wave text at the top of the screen (hidden without a boss).
var _boss_bar: FillBar
## The round skill icons by id ("dash", "heavy", "slash", "bow", "war_cry", "stance").
var _skill_icons: Dictionary = {}
## "CHARGE" or "HOLD".
var _stance_name: String = "CHARGE"
var _gate_indicator: EdgeIndicator
var _enemy_indicator: EdgeIndicator
var _banner_tween: Tween
var _message_tween: Tween
var _touch_mode: bool = false
var _tutorial_hint_allowed: bool = false
var _ui_scale: float = 1.0


func _ready() -> void:
	var summon_margin: MarginContainer = MarginContainer.new()
	summon_margin.name = "SummonPortraits"
	summon_margin.add_theme_constant_override("margin_top", 28)
	_summon_bar = HBoxContainer.new()
	_summon_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_summon_bar.add_theme_constant_override("separation", 20)
	summon_margin.add_child(_summon_bar)
	_summon_label.get_parent().add_child(summon_margin)
	_summon_label.get_parent().move_child(summon_margin, _summon_label.get_index())
	_gate_indicator = EdgeIndicator.new()
	_gate_indicator.name = "GateIndicator"
	_gate_indicator.points_left = true
	add_child(_gate_indicator)
	_enemy_indicator = EdgeIndicator.new()
	_enemy_indicator.name = "EnemyIndicator"
	_enemy_indicator.points_left = false
	add_child(_enemy_indicator)
	_place_indicators(get_viewport().get_visible_rect())
	# Every icon shows its key (read from the Input Map); locked skills show a padlock until unlocked.
	for entry: Array in SKILL_ICONS:
		var icon: SkillIcon = SkillIcon.new()
		icon.name = "%sIcon" % String(entry[0]).capitalize().replace(" ", "")
		icon.setup(entry[1], entry[2], entry[3], SkillHints.key_label(entry[4]))
		icon.locked_pressed.connect(show_message.bind(2.0))
		_skill_row.add_child(icon)
		_skill_icons[entry[0]] = icon
	_ultimate_ring.set_key_hint(SkillHints.key_label(&"ultimate"))
	set_skills_unlocked(false, false)
	set_stance(_stance_name)
	_boss_bar = FillBar.new()
	_boss_bar.name = "BossBar"
	_boss_bar.custom_minimum_size = Vector2(780.0, 50.0)
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar.fill_color = Color(InkPalette.DAIMYO_CURSE.darkened(0.25), 1.0)
	_boss_bar.font_size = 28
	# Ticks at one third and two thirds mark where the phases change.
	_boss_bar.segments = 3
	_boss_bar.visible = false
	_wave_box.add_child(_boss_bar)
	_pause_button.pressed.connect(pause_requested.emit)
	_top_left.resized.connect(_update_pivots)
	_wave_box.resized.connect(_update_pivots)


## The Bow and War Cry icons are always there; a locked one is dimmed with a small padlock. "Clear stage N" is its
## tooltip (and what tapping it says), never text in the HUD.
func set_skills_unlocked(bow: bool, war_cry: bool) -> void:
	for pair: Array in [["bow", bow], ["war_cry", war_cry]]:
		var icon: SkillIcon = _skill_icons[pair[0]]
		icon.visible = true
		icon.set_locked("" if pair[1] else SkillHints.locked_text_for(StringName(pair[0])))


## True when the skill's icon is shown and usable (not locked).
func is_skill_icon_visible(key: String) -> bool:
	var icon: SkillIcon = _skill_icons[key]
	return icon.visible and _skill_row.visible and not icon.is_locked()


func is_skill_locked(key: String) -> bool:
	return (_skill_icons[key] as SkillIcon).is_locked()


func get_skill_icon(key: String) -> SkillIcon:
	return _skill_icons[key]


## The ally stance ("CHARGE" or "HOLD"): a sword for CHARGE, a shield for HOLD, in the icon row (its tooltip says which).
func set_stance(stance_name: String) -> void:
	_stance_name = stance_name
	var icon: SkillIcon = _skill_icons["stance"]
	icon.set_kind(UpgradeIcon.Kind.STANCE_CHARGE if stance_name == "CHARGE" else UpgradeIcon.Kind.STANCE_HOLD)
	icon.set_skill_name("Allies: %s" % stance_name)


func get_stance_name() -> String:
	return _stance_name


## Shows the boss bar with the boss's name.
func show_boss(boss_name: String) -> void:
	_boss_bar.caption = boss_name
	_boss_bar.visible = true
	_boss_bar.queue_redraw()


func set_boss_health(current: float, maximum: float) -> void:
	_boss_bar.set_ratio_text(current / maxf(maximum, 0.001), "%d%%" % ceili(current / maxf(maximum, 0.001) * 100.0))


func hide_boss() -> void:
	_boss_bar.visible = false


func is_boss_bar_visible() -> bool:
	return _boss_bar.visible


func get_boss_bar() -> FillBar:
	return _boss_bar


func set_player_health(current: float, maximum: float) -> void:
	_health_blade.set_value(current, maximum)
	_ultimate_ring.danger = _health_blade.is_low()


func set_gate_health(current: float, maximum: float) -> void:
	_gate_bar.set_value(current, maximum)


func set_energy(current: float, maximum: float) -> void:
	_spirit_bar.set_ratio_text(current / maxf(maximum, 0.001), "%d / %d" % [floori(current), roundi(maximum)])


## The Ultimate ring round the portrait: fills as he fights, glows and pulses when it can be used.
func set_ultimate(ratio: float, is_ready: bool) -> void:
	var text: String = "%d%%" % floori(ratio * 100.0)
	if is_ready:
		text = "READY"
	_ultimate_ring.set_ratio_text(ratio, text)
	_ultimate_ring.set_pulsing(is_ready)


## cooldowns: {"dash": Vector2(seconds_left, total), "heavy": ..., "slash": ...}
func set_ability_cooldowns(cooldowns: Dictionary) -> void:
	for key: String in cooldowns:
		var icon: SkillIcon = _skill_icons.get(key)
		if icon != null:
			var info: Vector2 = cooldowns[key]
			icon.set_cooldown(info.x, info.y)


func set_wave_text(text: String) -> void:
	_wave_label.text = text


func set_remaining(count: int) -> void:
	_remaining_label.text = "Enemies remaining: %d" % count


func set_summon_text(text: String) -> void:
	_summon_label.text = text


func configure_summons(roster: Array[AllyData]) -> void:
	for button: TouchActionButton in _summon_buttons:
		button.release()
		button.queue_free()
	_summon_buttons.clear()
	for slot: int in roster.size():
		var data: AllyData = roster[slot]
		var button: TouchActionButton = TouchActionButton.new()
		button.action = StringName("summon_%d" % (slot + 1))
		button.custom_minimum_size = Vector2(96.0, 96.0)
		button.mouse_enabled = true
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.font_size = 22
		button.tooltip_text = data.display_name
		_summon_bar.add_child(button)
		button.modulate.a = 1.0
		button.set_portrait(data.figure)
		button.base_color = FigureKinds.spec(data.figure).accent
		_summon_buttons.append(button)


func set_summon_state(slot: int, cost: int, left: float, total: float, affordable: bool) -> void:
	if slot < 0 or slot >= _summon_buttons.size():
		return
	var button: TouchActionButton = _summon_buttons[slot]
	if button.summon_cost != cost:
		button.summon_cost = cost
		button.set_captions(button.tooltip_text, "%d SE" % cost)
		button.unavailable_text = "need %d" % cost
	button.set_cooldown(left / maxf(total, 0.001), left)
	button.set_available(affordable, button.unavailable_text)


func get_summon_button(slot: int) -> TouchActionButton:
	return _summon_buttons[slot]


func set_tutorial_hint(stage_id: String, cleared_before: bool) -> void:
	_tutorial_hint_allowed = stage_id == "stage_1" and not cleared_before
	_refresh_bottom()


## Touch controls show cooldowns and summons themselves, so keyboard-only parts are hidden.
func set_touch_mode(enabled: bool) -> void:
	_touch_mode = enabled
	if enabled:
		release_summons()
	_refresh_bottom()


## Keeps HUD content inside the safe area and scales the corner clusters around their corners.
func apply_layout(safe_rect: Rect2, viewport_size: Vector2, ui_scale: float) -> void:
	_ui_scale = TouchLayout.clamp_scale(ui_scale)
	_margin.add_theme_constant_override("margin_left", roundi(safe_rect.position.x + SCREEN_MARGIN.x))
	_margin.add_theme_constant_override("margin_top", roundi(safe_rect.position.y + SCREEN_MARGIN.y))
	_margin.add_theme_constant_override("margin_right", roundi(viewport_size.x - safe_rect.end.x + SCREEN_MARGIN.x))
	_margin.add_theme_constant_override("margin_bottom", roundi(viewport_size.y - safe_rect.end.y + SCREEN_MARGIN.y))
	for control: Control in [_top_left, _wave_box, _pause_button]:
		control.scale = Vector2(_ui_scale, _ui_scale)
	_place_indicators(safe_rect)
	_refresh_bottom()
	_update_pivots()


## Off-screen markers: the gate (left edge) and incoming enemies (right edge).
## gate_ratio = gate health 0..1; at_gate = enemies off screen to the left (at the gate); gate_alert = the gate was
## damaged in the last few seconds or enemies are at it. The gate tab shows only then: the Gate bar already has its health.
func set_edge_indicators(gate_hidden: bool, gate_ratio: float, at_gate: int, gate_alert: bool,
		incoming: int, oni_incoming: bool) -> void:
	if gate_hidden and gate_alert:
		_gate_indicator.show_info("Gate %d%%" % roundi(gate_ratio * 100.0),
				("%d at the gate" % at_gate) if at_gate > 0 else "", gate_ratio, gate_alert)
	else:
		_gate_indicator.hide_info()
	if incoming > 0:
		_enemy_indicator.show_info("%d incoming" % incoming, "Oni Brute!" if oni_incoming else "", -1.0, oni_incoming)
	else:
		_enemy_indicator.hide_info()


func get_gate_indicator() -> EdgeIndicator:
	return _gate_indicator


func get_enemy_indicator() -> EdgeIndicator:
	return _enemy_indicator


## Screen y of the bottom edge of a top HUD block (the vitals at the top left, the pause button): its top margin plus its
## real content height times the UI scale. Computed, not read from the node, because a container is only laid out
## a frame after its content changes (and a scaled control's own rect ignores its scale).
func block_bottom(control: Control) -> float:
	var height: float = maxf(control.size.y, control.get_combined_minimum_size().y)
	return _safe_rect.position.y + SCREEN_MARGIN.y + height * _ui_scale


## Tabs sit at the screen edges just below the top HUD (the vitals, pause button), above
## the fighters' heads and well clear of the touch controls.
func _place_indicators(safe_rect: Rect2) -> void:
	_safe_rect = safe_rect
	var top: float = safe_rect.position.y + INDICATOR_TOP * _ui_scale
	for indicator: EdgeIndicator in [_gate_indicator, _enemy_indicator]:
		if indicator == null:
			continue
		indicator.scale = Vector2(_ui_scale, _ui_scale)
		var width: float = EdgeIndicator.TAB_SIZE.x * _ui_scale
		var x: float = safe_rect.position.x + 8.0 if indicator.points_left else safe_rect.end.x - 8.0 - width
		var above: Control = _top_left if indicator.points_left else _pause_button
		var below_hud: float = block_bottom(above) + INDICATOR_GAP if above.is_visible_in_tree() else top
		indicator.position = Vector2(x, maxf(top, below_hud))


## Screen rectangles the HUD covers (vitals, wave text, pause button, hints and the edge tabs), for
## keeping the falling leaves out of them.
func get_keep_out_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for control: Control in [_top_left, _wave_box, _pause_button, get_node_or_null("Margin/BottomBox") as Control,
			_gate_indicator, _enemy_indicator]:
		if control != null and control.is_visible_in_tree():
			rects.append(control.get_global_transform() * Rect2(Vector2.ZERO, control.size))
	return rects


func get_pause_button_rect() -> Rect2:
	return _pause_button.get_global_rect()


## Big centered text that fades out after `duration` seconds.
func show_banner(text: String, duration: float = 2.0) -> void:
	_banner_tween = _show_fading(_banner_label, text, duration, _banner_tween)


## Small message above the summon area (e.g. why a summon failed).
func show_message(text: String, duration: float = 1.2) -> void:
	_message_tween = _show_fading(_message_label, text, duration, _message_tween)


func show_status(text: String, color: Color = InkPalette.EMBER_TEXT) -> void:
	_banner_label.visible = false
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", color)
	_status_label.visible = true


func hide_status() -> void:
	_status_label.visible = false


static func format_cooldown(seconds: float) -> String:
	return "ready" if seconds <= 0.0 else "%.1fs" % seconds


func _refresh_bottom() -> void:
	_summon_label.visible = not _touch_mode
	_summon_bar.get_parent().visible = not _touch_mode
	_hint_label.visible = _tutorial_hint_allowed and not _touch_mode
	_debug_hint_label.visible = false
	# Touch buttons show their own cooldowns and the Allies button shows the stance, so the icon row is for the
	# keyboard only.
	_skill_row.visible = not _touch_mode
	if _safe_rect.size != Vector2.ZERO:
		_place_indicators(_safe_rect)
	_touch_spacer.custom_minimum_size.y = TOUCH_BOTTOM_SPACE * _ui_scale if _touch_mode else 0.0


func _update_pivots() -> void:
	_top_left.pivot_offset = Vector2.ZERO
	_wave_box.pivot_offset = Vector2(_wave_box.size.x * 0.5, 0.0)
	_pause_button.pivot_offset = Vector2(_pause_button.size.x, 0.0)
	# The top-left cluster grows/shrinks (ability row in keyboard mode): keep the tabs below it.
	if _safe_rect.size != Vector2.ZERO:
		_place_indicators(_safe_rect)


func _show_fading(label: Label, text: String, duration: float, previous: Tween) -> Tween:
	if previous != null and previous.is_valid():
		previous.kill()
	label.text = text
	label.modulate.a = 1.0
	label.visible = true
	var tween: Tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_property(label, "modulate:a", 0.0, BANNER_FADE_TIME)
	tween.tween_callback(label.hide)
	return tween


func release_summons() -> void:
	for button: TouchActionButton in _summon_buttons:
		button.release()
