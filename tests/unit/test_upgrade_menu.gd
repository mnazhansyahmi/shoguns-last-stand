extends "res://tests/test_case.gd"
## The upgrade shop: four tabs that each show only their upgrades, the cards (level pips, now -> next, cost button,
## MAX, red cost when the gold is short, locked allies), the pictures and the keyboard / gamepad handling.

const UPGRADE_MENU_SCENE: PackedScene = preload("res://scenes/upgrade_menu/upgrade_menu.tscn")
const CATALOG: UpgradeCatalog = preload("res://data/upgrades/upgrade_catalog.tres")
const SAVE_DIR: String = "user://test_upgrade_menu/"

const PORTRAIT_IDS: Array[String] = ["samurai_max_health", "samurai_damage", "ashigaru_health", "archer_damage",
		"healer_blessing", "guardian_health", "onmyoji_damage", "hatamoto_damage"]
const ICON_IDS: Array[String] = ["samurai_dash_cooldown", "samurai_slash_cooldown", "samurai_ultimate_charge",
		"spirit_regen", "spirit_capacity", "army_command", "samurai_bow_damage", "samurai_war_cry_duration"]


func _menu(gold: int, levels: Dictionary = {}, cleared: Array[String] = []) -> Control:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var path: String = SAVE_DIR + "menu_save.json"
	var progress: PlayerProgress = PlayerProgress.new()
	progress.gold = gold
	progress.stages_cleared = cleared.duplicate()
	for id: String in levels:
		progress.set_upgrade_level(id, int(levels[id]))
	SaveManager.new(path).save_progress(progress)
	var menu: Control = UPGRADE_MENU_SCENE.instantiate()
	menu.set("save_path", path)
	add_to_tree(menu)
	return menu


func test_every_upgrade_is_on_a_tab() -> void:
	var seen: Dictionary = {}
	for upgrade: UpgradeData in CATALOG.upgrades:
		var tab: int = UpgradeTabs.tab_for(upgrade)
		assert_true(tab >= 0 and tab < UpgradeTabs.NAMES.size(), "%s has a tab" % upgrade.id)
		seen[tab] = true
	assert_eq(UpgradeTabs.NAMES.size(), 4, "four tabs")
	assert_eq(seen.size(), 4, "and every tab has upgrades")


func test_each_tab_shows_only_its_upgrades() -> void:
	var menu: Control = _menu(500)
	var expected: Dictionary = {
		UpgradeTabs.Tab.SAMURAI: ["samurai_max_health", "samurai_damage"],
		UpgradeTabs.Tab.SKILLS: ["samurai_dash_cooldown", "samurai_slash_cooldown", "samurai_ultimate_charge", "samurai_bow_damage", "samurai_war_cry_duration"],
		UpgradeTabs.Tab.ALLIES: ["ashigaru_health", "ashigaru_damage", "archer_damage", "healer_blessing", "guardian_health",
				"onmyoji_damage", "hatamoto_damage"],
		UpgradeTabs.Tab.ARMY_SPIRIT: ["spirit_regen", "spirit_capacity", "army_command", "gate_armour", "army_fire_resistance"],
	}
	assert_eq(menu.call("get_tab"), UpgradeTabs.Tab.SAMURAI, "it opens on the Samurai tab")
	for tab: int in expected:
		menu.call("select_tab", tab)
		var shown: Array[String] = menu.call("get_visible_upgrade_ids")
		shown.sort()
		var want: Array[String] = []
		want.assign(expected[tab])
		want.sort()
		assert_eq(shown, want, "tab %s shows only its own upgrades" % UpgradeTabs.NAMES[tab])


func test_cards_show_pips_levels_effects_and_costs() -> void:
	var menu: Control = _menu(500, {"samurai_max_health": 3, "samurai_damage": CATALOG.find("samurai_damage").max_level}, ["stage_5"])
	var health: UpgradeData = CATALOG.find("samurai_max_health")
	var card: Dictionary = menu.call("get_card", "samurai_max_health")
	assert_eq((card["level"] as Label).text, "3/%d" % health.max_level, "the level shows as 3/max")
	assert_eq((card["pips"] as LevelPips).level, 3, "three pips are filled")
	assert_eq((card["pips"] as LevelPips).max_level, health.max_level, "one pip per level")
	var effect: String = (card["effect"] as Label).text
	assert_true(effect.contains("->"), "the card shows current -> next")
	assert_true(effect.contains(health.describe_bonus(3)) and effect.contains(health.describe_bonus(4)), "with both bonuses")
	assert_eq((card["button"] as Button).text, "%d g" % health.get_cost(3), "the cost button shows the price")
	assert_eq((card["button"] as Button).theme_type_variation, &"CostButton", "gold when it can be bought")
	var maxed: Dictionary = menu.call("get_card", "samurai_damage")
	assert_eq((maxed["button"] as Button).text, "MAX", "a maxed upgrade shows MAX")
	assert_true((maxed["button"] as Button).disabled, "and cannot be bought")


func test_region_two_cards_show_unlock_requirements_and_new_prices() -> void:
	var locked: Control = _menu(14000, {"samurai_max_health": 5})
	for id: String in ["samurai_max_health", "gate_armour", "army_fire_resistance"]:
		var card: Dictionary = locked.call("get_card", id)
		assert_true((card["button"] as Button).disabled, "%s cannot buy before Region 2" % id)
		assert_true((card["effect"] as Label).text.contains("5"), "%s explains stage 5 requirement" % id)
	var open: Control = _menu(14000, {"samurai_max_health": 5}, ["stage_5"])
	for id: String in ["samurai_max_health", "gate_armour", "army_fire_resistance"]:
		var card: Dictionary = open.call("get_card", id)
		assert_true(not (card["button"] as Button).disabled, "%s unlocked on Region 2 entry" % id)
		assert_eq((card["button"] as Button).text, "%d g" % CATALOG.find(id).get_cost(5 if id == "samurai_max_health" else 0), "%s shows correct next-tier cost" % id)


func test_an_unaffordable_cost_is_red_and_tapping_says_why() -> void:
	var menu: Control = _menu(0)
	var card: Dictionary = menu.call("get_card", "samurai_max_health")
	assert_eq((card["button"] as Button).theme_type_variation, &"CostButtonShort", "the cost is red when gold is short")
	assert_true(not (card["button"] as Button).disabled, "it stays tappable so it can explain itself")
	var result: UpgradeShop.Result = menu.call("buy", "samurai_max_health")
	assert_eq(result, UpgradeShop.Result.NOT_ENOUGH_GOLD, "the purchase is refused")
	var message: Label = menu.get_node("%MessageLabel")
	assert_true(message.text.begins_with("Not enough gold"), "the reason is shown")
	assert_eq((menu.call("get_progress") as PlayerProgress).gold, 0, "no gold changes hands")


func test_buying_updates_the_card_and_the_gold() -> void:
	var menu: Control = _menu(1000)
	var cost: int = CATALOG.find("samurai_damage").get_cost(0)
	assert_eq(menu.call("buy", "samurai_damage"), UpgradeShop.Result.OK, "the purchase succeeds")
	var card: Dictionary = menu.call("get_card", "samurai_damage")
	assert_eq((card["pips"] as LevelPips).level, 1, "a pip fills")
	assert_eq((menu.get_node("%GoldLabel") as Label).text, "Gold: %d" % (1000 - cost), "the gold is updated")


func test_the_gold_is_shown_big() -> void:
	var menu: Control = _menu(1280)
	var gold: Label = menu.get_node("%GoldLabel")
	assert_eq(gold.text, "Gold: 1280", "the gold total")
	assert_true(gold.get_theme_font_size("font_size") >= 60, "in a big font")


func test_locked_allies_show_a_silhouette_and_the_stage_to_clear() -> void:
	var menu: Control = _menu(500, {}, ["stage_1"] as Array[String])
	var locked: Dictionary = menu.call("get_card", "onmyoji_damage")
	assert_true(menu.call("is_locked", CATALOG.find("onmyoji_damage")), "the Onmyoji is still locked")
	assert_eq((locked["card"] as Control).theme_type_variation, &"CardPanelLocked", "its card is dimmed")
	var label: Label = (locked["picture"] as Control).get_node_or_null("LockedLabel")
	assert_true(label != null and label.text.contains("Clear") and label.text.contains("3"), "its picture says Clear stage 3")
	assert_eq((locked["button"] as Button).text, "Locked", "and its button is Locked")
	var open: Dictionary = menu.call("get_card", "ashigaru_health")
	assert_true((open["picture"] as Control).get_node_or_null("LockedLabel") == null, "an unlocked ally has no lock label")


func test_pictures_are_portraits_for_the_samurai_and_allies_and_icons_for_skills() -> void:
	var menu: Control = _menu(500)
	for id: String in PORTRAIT_IDS:
		var picture: Control = (menu.call("get_card", id) as Dictionary)["picture"]
		assert_true(picture.get_child(0) is TextureRect, "%s wears a portrait" % id)
		assert_true((picture.get_child(0) as TextureRect).texture != null, "%s's portrait has a texture" % id)
	for id: String in ICON_IDS:
		var picture: Control = (menu.call("get_card", id) as Dictionary)["picture"]
		assert_true(picture is UpgradeIcon, "%s wears a skill icon" % id)


func test_each_skill_stat_has_its_own_icon() -> void:
	var kinds: Dictionary = {}
	for id: String in ICON_IDS:
		var icon: int = UpgradeTabs.icon_for(CATALOG.find(id))
		assert_true(icon >= 0, "%s has an icon" % id)
		kinds[icon] = true
	assert_eq(kinds.size(), ICON_IDS.size(), "no two share an icon")
	assert_eq(UpgradeTabs.icon_for(CATALOG.find("samurai_damage")), -1, "the samurai's own stats use his portrait")


func test_page_keys_and_focus_change_tab() -> void:
	var menu: Control = _menu(500)
	var down: InputEventAction = InputEventAction.new()
	down.action = "ui_page_down"
	down.pressed = true
	menu.call("_unhandled_input", down)
	assert_eq(menu.call("get_tab"), UpgradeTabs.Tab.SKILLS, "page down shows the next tab")
	var up: InputEventAction = InputEventAction.new()
	up.action = "ui_page_up"
	up.pressed = true
	menu.call("_unhandled_input", up)
	menu.call("_unhandled_input", up)
	assert_eq(menu.call("get_tab"), UpgradeTabs.Tab.ARMY_SPIRIT, "page up wraps round to the last tab")
	var tabs: HBoxContainer = menu.get_node("%TabsRow")
	(tabs.get_child(UpgradeTabs.Tab.ALLIES) as Button).grab_focus()
	assert_eq(menu.call("get_tab"), UpgradeTabs.Tab.ALLIES, "moving focus onto a tab shows it")


func test_tabs_and_cost_buttons_are_big_touch_targets() -> void:
	var menu: Control = _menu(500)
	var tabs: HBoxContainer = menu.get_node("%TabsRow")
	assert_eq(tabs.get_child_count(), 4, "four tab buttons")
	for tab: Node in tabs.get_children():
		assert_true((tab as Button).custom_minimum_size.y >= 121.0, "%s is a big enough target" % tab.name)
	for id: String in ["samurai_max_health", "ashigaru_health"]:
		var button: Button = (menu.call("get_card", id) as Dictionary)["button"]
		assert_true(button.custom_minimum_size.y >= 121.0, "%s's cost button is a big enough target" % id)


func test_bow_and_war_cry_upgrades_persist_and_change_only_their_stats() -> void:
	var menu: Control = _menu(1000)
	for id: String in ["samurai_bow_damage", "samurai_war_cry_duration"]:
		assert_eq(menu.call("buy", id), UpgradeShop.Result.OK, "%s can be purchased" % id)
	var saved: PlayerProgress = SaveManager.new(SAVE_DIR + "menu_save.json").load_progress()
	var base: PlayerStats = PlayerStats.new()
	var upgraded: PlayerStats = UpgradeApplier.build_player_stats(base, saved, CATALOG)
	assert_almost_eq(upgraded.bow_damage_multiplier, base.bow_damage_multiplier * 1.1, "one level adds 10% bow damage")
	assert_almost_eq(upgraded.war_cry_duration, base.war_cry_duration + 1.0, "one level adds one second of rally")
	assert_almost_eq(upgraded.base_damage, base.base_damage, "the base katana damage is unchanged")
	assert_almost_eq(PlayerStats.new().war_cry_duration, base.war_cry_duration, "shared stats stay unchanged")
	assert_true(menu.get_node_or_null("%ResetButton") == null, "reset no longer lives in the upgrade shop")


func test_settings_reset_requires_confirmation_and_uses_the_owners_save() -> void:
	var path: String = SAVE_DIR + "reset_save.json"
	var other: String = SAVE_DIR + "unrelated_save.json"
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var progress: PlayerProgress = PlayerProgress.new()
	progress.gold = 500
	progress.stages_cleared = ["stage_1"]
	progress.set_upgrade_level("samurai_bow_damage", 2)
	SaveManager.new(path).save_progress(progress)
	SaveManager.new(other).save_progress(progress)
	var panel: SettingsPanel = load("res://scenes/ui/settings_panel.tscn").instantiate() as SettingsPanel
	panel.save_path = path
	add_to_tree(panel)
	panel.open(GameSettings.new())
	var button: Button = panel.get_node("%ResetButton")
	var dialog: ConfirmationDialog = panel.get_node("%ResetDialog")
	button.pressed.emit()
	assert_true(dialog.visible, "Reset Progress opens the confirmation dialog")
	assert_eq(SaveManager.new(path).load_progress().gold, 500, "opening the dialog does not delete anything")
	dialog.get_cancel_button().pressed.emit()
	assert_eq(SaveManager.new(path).load_progress().gold, 500, "Cancel preserves progress")
	button.pressed.emit()
	dialog.confirmed.emit()
	var reset: PlayerProgress = SaveManager.new(path).load_progress()
	assert_eq(reset.gold, 0, "confirmation resets gold")
	assert_true(reset.stages_cleared.is_empty(), "confirmation resets stage clears")
	assert_eq(reset.get_upgrade_level("samurai_bow_damage"), 0, "confirmation resets upgrades")
	assert_eq(SaveManager.new(other).load_progress().gold, 500, "another save stays untouched")
