extends Control
## Upgrade shop. Rows are built from the UpgradeCatalog; every purchase is saved immediately.
## Also hosts the "Reset Progress" option behind a confirmation dialog.

const UPGRADE_CATALOG: UpgradeCatalog = preload("res://data/upgrades/upgrade_catalog.tres")
const AFFORDABLE_COLOR: Color = Color(1.0, 0.9, 0.55)
const UNAFFORDABLE_COLOR: Color = Color(1.0, 0.45, 0.4)
const ROW_FONT_SIZE: int = 32

## Overridable so automated runs never touch the player's real save.
@export var save_path: String = SaveManager.DEFAULT_PATH

@onready var _gold_label: Label = %GoldLabel
@onready var _level_label: Label = %LevelLabel
@onready var _upgrade_list: VBoxContainer = %UpgradeList
@onready var _message_label: Label = %MessageLabel
@onready var _battle_button: Button = %BattleButton
@onready var _back_button: Button = %BackButton
@onready var _reset_button: Button = %ResetButton
@onready var _reset_dialog: ConfirmationDialog = %ResetDialog

var _save_manager: SaveManager
var _progress: PlayerProgress
## upgrade id -> { "level": Label, "effect": Label, "button": Button }
var _rows: Dictionary = {}


func _ready() -> void:
	_save_manager = SaveManager.new(save_path)
	_progress = _save_manager.load_progress()
	_build_rows()
	_style_reset_dialog()
	_battle_button.pressed.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.STAGE_SELECT))
	_back_button.pressed.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.MAIN_MENU))
	_reset_button.pressed.connect(_reset_dialog.popup_centered)
	_reset_dialog.confirmed.connect(_on_reset_confirmed)
	_message_label.text = _save_manager.last_warning
	_refresh()
	_back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not _reset_dialog.visible:
		get_viewport().set_input_as_handled()
		SceneRoutes.go_to(get_tree(), SceneRoutes.MAIN_MENU)


## Test/automation helper: same path as clicking the row's buy button.
func buy(upgrade_id: String) -> UpgradeShop.Result:
	return _on_buy_pressed(UPGRADE_CATALOG.find(upgrade_id))


func get_progress() -> PlayerProgress:
	return _progress


func _build_rows() -> void:
	for upgrade: UpgradeData in UPGRADE_CATALOG.upgrades:
		if upgrade == null or upgrade.id.is_empty():
			push_error("UpgradeMenu: catalog contains an upgrade without an id; skipped.")
			continue
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		var name_label: Label = _make_label(upgrade.display_name, 420.0)
		var level_label: Label = _make_label("", 170.0)
		var effect_label: Label = _make_label("", 0.0)
		effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(300.0, 124.0)
		button.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
		button.pressed.connect(_on_buy_pressed.bind(upgrade))
		row.add_child(name_label)
		row.add_child(level_label)
		row.add_child(effect_label)
		row.add_child(button)
		_upgrade_list.add_child(row)
		_rows[upgrade.id] = {"level": level_label, "effect": effect_label, "button": button}


func _make_label(text: String, min_width: float) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(min_width, 0.0)
	label.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	return label


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
		level_label.text = "Lv %d / %d" % [mini(current, upgrade.max_level), upgrade.max_level]
		if upgrade.is_maxed(current):
			effect_label.text = "%s (max)" % upgrade.describe_bonus(current)
			button.text = "MAX"
			button.disabled = true
			continue
		var now_text: String = upgrade.describe_bonus(current) if current > 0 else "none"
		effect_label.text = "%s  ->  %s" % [now_text, upgrade.describe_bonus(current + 1)]
		var cost: int = upgrade.get_cost(current)
		button.text = "Buy  %d g" % cost
		button.disabled = false
		# Left enabled when unaffordable so the purchase is visibly rejected with a reason.
		button.add_theme_color_override("font_color", AFFORDABLE_COLOR if _progress.gold >= cost else UNAFFORDABLE_COLOR)


func _on_buy_pressed(upgrade: UpgradeData) -> UpgradeShop.Result:
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


func _on_reset_confirmed() -> void:
	var error: Error = _save_manager.reset_progress()
	_progress = _save_manager.load_progress()
	_message_label.text = "Progress reset." if error == OK else "Reset failed (error %d)." % error
	_refresh()


func _style_reset_dialog() -> void:
	_reset_dialog.get_label().add_theme_font_size_override("font_size", 32)
	for button: Button in [_reset_dialog.get_ok_button(), _reset_dialog.get_cancel_button()]:
		button.custom_minimum_size = Vector2(240.0, 124.0)
		button.add_theme_font_size_override("font_size", 32)
