extends Control
## Upgrade shop. Four tabs (Samurai, Skills, Allies, Army & Spirit), each showing only its upgrades as cards: a
## picture (a portrait of the real in-game figure, or a skill icon), the name, the level as pips, what the upgrade
## does now and next, and the cost button. Every purchase is saved immediately.

const UPGRADE_CATALOG: UpgradeCatalog = preload("res://data/upgrades/upgrade_catalog.tres")
const ALLY_ROSTER: AllyRoster = preload("res://data/allies/roster.tres")
const NAME_FONT_SIZE: int = 38
const TEXT_FONT_SIZE: int = 30
const BUTTON_FONT_SIZE: int = 34

## Overridable so automated runs never touch the player's real save.
@export var save_path: String = SaveManager.DEFAULT_PATH

@onready var _gold_label: Label = %GoldLabel
@onready var _level_label: Label = %LevelLabel
@onready var _tabs_row: HBoxContainer = %TabsRow
@onready var _scroll: ScrollContainer = %Scroll
@onready var _upgrade_list: VBoxContainer = %UpgradeList
@onready var _message_label: Label = %MessageLabel
@onready var _battle_button: Button = %BattleButton
@onready var _back_button: Button = %BackButton

var _save_manager: SaveManager
var _progress: PlayerProgress
## upgrade id -> { "card", "tab", "pips", "level", "effect", "button", "picture" }
var _rows: Dictionary = {}
var _tab_buttons: Array[Button] = []
var _tab: int = UpgradeTabs.Tab.SAMURAI
## The portraits made for this visit (character kind + silhouette flag -> its viewport): each figure is rendered once.
var _portraits: Dictionary = {}


func _ready() -> void:
	AudioManager.play_music(&"menu")
	_save_manager = SaveManager.new(save_path)
	_progress = _save_manager.load_progress()
	_build_tabs()
	_build_rows()
	_battle_button.pressed.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.STAGE_SELECT))
	_back_button.pressed.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.MAIN_MENU))
	_message_label.text = _save_manager.last_warning
	_refresh()
	select_tab(UpgradeTabs.Tab.SAMURAI)
	_back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		SceneRoutes.go_to(get_tree(), SceneRoutes.MAIN_MENU)
	elif event.is_action_pressed("ui_page_down"):
		get_viewport().set_input_as_handled()
		select_tab((_tab + 1) % UpgradeTabs.NAMES.size())
	elif event.is_action_pressed("ui_page_up"):
		get_viewport().set_input_as_handled()
		select_tab((_tab + UpgradeTabs.NAMES.size() - 1) % UpgradeTabs.NAMES.size())


## Test/automation helper: same path as clicking the row's buy button.
func buy(upgrade_id: String) -> UpgradeShop.Result:
	return _on_buy_pressed(UPGRADE_CATALOG.find(upgrade_id))


func get_progress() -> PlayerProgress:
	return _progress


func get_tab() -> int:
	return _tab


## The ids of the upgrades the current tab shows.
func get_visible_upgrade_ids() -> Array[String]:
	var ids: Array[String] = []
	for upgrade: UpgradeData in UPGRADE_CATALOG.upgrades:
		if upgrade != null and _rows.has(upgrade.id) and (_rows[upgrade.id]["card"] as Control).visible:
			ids.append(upgrade.id)
	return ids


## The parts of an upgrade's card (card, tab, pips, level, effect, button, picture), empty for an unknown id.
func get_card(upgrade_id: String) -> Dictionary:
	return _rows.get(upgrade_id, {})


## Shows `tab` (0..3) and only its upgrades.
func select_tab(tab: int) -> void:
	_tab = clampi(tab, 0, UpgradeTabs.NAMES.size() - 1)
	for i: int in _tab_buttons.size():
		_tab_buttons[i].set_pressed_no_signal(i == _tab)
	for upgrade_id: String in _rows:
		var row: Dictionary = _rows[upgrade_id]
		(row["card"] as Control).visible = int(row["tab"]) == _tab
	_scroll.scroll_vertical = 0


func _build_tabs() -> void:
	var group: ButtonGroup = ButtonGroup.new()
	for index: int in UpgradeTabs.NAMES.size():
		var button: Button = Button.new()
		button.name = "Tab%d" % index
		button.text = UpgradeTabs.NAMES[index]
		button.toggle_mode = true
		button.button_group = group
		button.theme_type_variation = &"ToggleButton"
		button.custom_minimum_size = Vector2(220.0, 124.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
		# Pressing a tab, or moving the keyboard or gamepad focus onto it, shows it.
		button.pressed.connect(select_tab.bind(index))
		button.focus_entered.connect(select_tab.bind(index))
		_tabs_row.add_child(button)
		_tab_buttons.append(button)


func _build_rows() -> void:
	for upgrade: UpgradeData in UPGRADE_CATALOG.upgrades:
		if upgrade == null or upgrade.id.is_empty():
			push_error("UpgradeMenu: catalog contains an upgrade without an id; skipped.")
			continue
		var locked: bool = is_locked(upgrade)
		var card: PanelContainer = PanelContainer.new()
		card.name = "Card_%s" % upgrade.id
		card.theme_type_variation = &"CardPanelLocked" if locked else &"CardPanel"
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 28)
		card.add_child(row)
		var picture: Control = _make_picture(upgrade, locked)
		row.add_child(picture)
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		info.add_theme_constant_override("separation", 6)
		row.add_child(info)
		var name_label: Label = _make_label(upgrade.display_name, NAME_FONT_SIZE, &"HeaderLabel")
		info.add_child(name_label)
		var pips_row: HBoxContainer = HBoxContainer.new()
		pips_row.add_theme_constant_override("separation", 18)
		var pips: LevelPips = LevelPips.new()
		pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pips.set_levels(0, upgrade.max_level)
		var level_label: Label = _make_label("", TEXT_FONT_SIZE, &"")
		pips_row.add_child(pips)
		pips_row.add_child(level_label)
		info.add_child(pips_row)
		var effect_label: Label = _make_label("", TEXT_FONT_SIZE, &"DimLabel")
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(effect_label)
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(260.0, 124.0)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
		button.pressed.connect(_on_buy_pressed.bind(upgrade))
		row.add_child(button)
		card.visible = false
		_upgrade_list.add_child(card)
		_rows[upgrade.id] = {"card": card, "tab": UpgradeTabs.tab_for(upgrade), "pips": pips, "level": level_label,
				"effect": effect_label, "button": button, "picture": picture}


func _make_label(text: String, font_size: int, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	if variation != &"":
		label.theme_type_variation = variation
	return label


## The picture on the left of a card: a skill icon, or a portrait of the character the upgrade is for (a black
## silhouette with "Clear stage N" while that ally is still locked).
func _make_picture(upgrade: UpgradeData, locked: bool) -> Control:
	var size: float = FigurePortrait.SIZE
	var icon_kind: int = UpgradeTabs.icon_for(upgrade)
	if icon_kind >= 0:
		var icon: UpgradeIcon = UpgradeIcon.new()
		icon.setup(icon_kind as UpgradeIcon.Kind, size)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return icon
	var kind: InkFigure.Kind = InkFigure.Kind.SAMURAI
	var data: AllyData = ALLY_ROSTER.find(upgrade.ally_id) if upgrade.target == UpgradeData.Target.ALLY else null
	if data != null:
		kind = data.figure
	var frame: Control = Control.new()
	frame.custom_minimum_size = Vector2(size, size)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var key: String = "%d/%s" % [int(kind), locked]
	if not _portraits.has(key):
		var viewport: SubViewport = FigurePortrait.make_viewport(kind, locked)
		add_child(viewport)
		_portraits[key] = viewport
	var rect: TextureRect = TextureRect.new()
	rect.texture = (_portraits[key] as SubViewport).get_texture()
	rect.custom_minimum_size = Vector2(size, size)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(rect)
	if locked and data != null:
		var label: Label = _make_label(SkillHints.locked_text(data.unlock_stage_id).replace("Clear ", "Clear\n"), 24, &"HudLabel")
		label.name = "LockedLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.size = Vector2(size, size - 8.0)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(label)
	return frame


func _refresh() -> void:
	_gold_label.text = "Gold: %d" % _progress.gold
	var level: int = _progress.get_level()
	_level_label.text = "Level %d   (%d / %d XP)" % [level, _progress.xp, PlayerProgress.xp_for_level(level + 1)]
	for upgrade: UpgradeData in UPGRADE_CATALOG.upgrades:
		if upgrade == null or not _rows.has(upgrade.id):
			continue
		var row: Dictionary = _rows[upgrade.id]
		var current: int = _progress.get_upgrade_level(upgrade.id)
		var level_label: Label = row["level"]
		var effect_label: Label = row["effect"]
		var button: Button = row["button"]
		(row["pips"] as LevelPips).set_levels(current, upgrade.max_level)
		level_label.text = "%d/%d" % [mini(current, upgrade.max_level), upgrade.max_level]
		if is_locked(upgrade):
			effect_label.text = (upgrade.describe_bonus(current) + "\n" if current > 0 else "") + _unlock_text(upgrade)
			button.text = "Locked"
			button.disabled = true
			button.theme_type_variation = &""
			continue
		if upgrade.is_maxed(current):
			effect_label.text = "%s (max)" % upgrade.describe_bonus(current)
			button.text = "MAX"
			button.disabled = true
			button.theme_type_variation = &""
			continue
		var now_text: String = upgrade.describe_bonus(current) if current > 0 else "none"
		effect_label.text = "%s  ->  %s" % [now_text, upgrade.describe_bonus(current + 1)]
		var cost: int = upgrade.get_cost(current)
		button.text = "%d g" % cost
		button.disabled = false
		# Left enabled when unaffordable (red) so the purchase is visibly rejected with a reason.
		button.theme_type_variation = &"CostButton" if _progress.gold >= cost else &"CostButtonShort"


## An upgrade for an ally the player has not unlocked yet can be seen but not bought.
func is_locked(upgrade: UpgradeData) -> bool:
	if upgrade == null:
		return false
	if not upgrade.is_available(_progress):
		return true
	if upgrade.target != UpgradeData.Target.ALLY:
		return false
	var data: AllyData = ALLY_ROSTER.find(upgrade.ally_id)
	return data != null and not ALLY_ROSTER.is_unlocked(data, _progress)


func _unlock_text(upgrade: UpgradeData) -> String:
	if not upgrade.is_available(_progress):
		return SkillHints.locked_text(upgrade.required_stage(_progress.get_upgrade_level(upgrade.id))) + " to unlock"
	var data: AllyData = ALLY_ROSTER.find(upgrade.ally_id)
	return SkillHints.locked_text(data.unlock_stage_id) if data != null else "Locked"


func _on_buy_pressed(upgrade: UpgradeData) -> UpgradeShop.Result:
	if is_locked(upgrade):
		_message_label.text = "%s is not unlocked yet (%s)." % [upgrade.display_name, _unlock_text(upgrade)]
		return UpgradeShop.Result.LOCKED if not upgrade.is_available(_progress) else UpgradeShop.Result.INVALID_UPGRADE
	var before: PlayerProgress = _progress.duplicate_progress()
	var level: int = _progress.get_upgrade_level(upgrade.id) if upgrade != null else 0
	var result: UpgradeShop.Result = UpgradeShop.purchase(_progress, upgrade)
	match result:
		UpgradeShop.Result.OK:
			var save_error: Error = _save_manager.save_progress(_progress)
			if save_error == OK:
				_message_label.text = "Bought %s level %d." % [upgrade.display_name, level + 1]
			else:
				# Keep memory and disk consistent: undo a purchase that could not be saved.
				_progress = before
				_message_label.text = "Could not save (error %d). Purchase cancelled." % save_error
		UpgradeShop.Result.NOT_ENOUGH_GOLD:
			_message_label.text = "Not enough gold: %s costs %d, you have %d." % [
				upgrade.display_name, upgrade.get_cost(level), _progress.gold]
		UpgradeShop.Result.MAX_LEVEL:
			_message_label.text = "%s is already at max level." % upgrade.display_name
		_:
			_message_label.text = "That upgrade is not available."
	_refresh()
	return result

