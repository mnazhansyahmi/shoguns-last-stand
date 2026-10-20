extends "res://tests/test_case.gd"
## Playtest feedback, part 2: ink-style blood on hits and kills (more on heavy hits and the Spirit Slash), fading
## stains on the ground, a Blood On/Off setting (default On), and meatier layered hit sounds.

const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/settings_panel.tscn")
const SPIRIT_SLASH_SCENE: PackedScene = preload("res://scenes/player/spirit_slash.tscn")
const SFX: SfxLibrary = preload("res://data/audio/sfx_library.tres")
const TEST_PATH: String = "user://test_saves/gore_settings_test.cfg"


func cleanup() -> void:
	for path: String in [TEST_PATH, TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	super.cleanup()


func _hit(damage: float, heavy: bool, killed: bool, spirit: bool = false) -> HitData:
	var hit: HitData = HitData.new(damage, Vector2(120.0, 0.0), null)
	hit.heavy = heavy
	hit.killed = killed
	hit.spirit = spirit
	return hit


func _feedback(blood: bool = true) -> BattleFeedback:
	var feedback: BattleFeedback = BattleFeedback.new()
	feedback.numbers_parent = add_to_tree(Node2D.new())
	feedback.effects_parent = add_to_tree(Node2D.new())
	feedback.stains_parent = add_to_tree(Node2D.new())
	var settings: GameSettings = GameSettings.new()
	settings.blood = blood
	add_to_tree(feedback)
	feedback.configure(settings)
	return feedback


func _victim() -> Node2D:
	var victim: Node2D = add_to_tree(Node2D.new()) as Node2D
	victim.global_position = Vector2(600.0, 880.0)
	return victim


# --- The setting ---------------------------------------------------------------------------

func test_blood_is_on_by_default_and_saved() -> void:
	assert_true(GameSettings.new().blood, "Blood is On by default")
	var store: SettingsStore = SettingsStore.new(TEST_PATH)
	var settings: GameSettings = GameSettings.new()
	settings.blood = false
	assert_eq(store.save_settings(settings), OK, "saves")
	assert_true(not store.load_settings().blood, "Blood Off survives a save and load")
	assert_true(not settings.duplicate_settings().blood, "and a copy")
	var old_file: ConfigFile = ConfigFile.new()
	old_file.set_value("meta", "version", 1)
	old_file.set_value("settings", "sfx_volume", 0.5)
	old_file.save(TEST_PATH)
	assert_true(store.load_settings().blood, "a settings file from before the toggle keeps Blood On")
	var broken: ConfigFile = ConfigFile.new()
	broken.set_value("meta", "version", 1)
	broken.set_value("settings", "blood", "maybe")
	broken.save(TEST_PATH)
	assert_true(store.load_settings().blood, "an invalid value falls back to On")


func test_the_settings_panel_has_a_blood_toggle() -> void:
	var panel: SettingsPanel = add_to_tree(SETTINGS_SCENE.instantiate()) as SettingsPanel
	var settings: GameSettings = GameSettings.new()
	var changes: Array[bool] = []
	panel.changed.connect(func(updated: GameSettings) -> void: changes.append(updated.blood))
	panel.open(settings)
	var toggle: Button = panel.get_node("%BloodToggle") as Button
	assert_eq(toggle.text, "Blood: On", "the toggle says Blood: On")
	assert_true(toggle.custom_minimum_size.y >= 124.0, "and is finger-sized")
	toggle.button_pressed = false
	assert_eq(toggle.text, "Blood: Off", "pressing it turns it Off")
	assert_true(not settings.blood and changes.size() == 1 and not changes[0], "which changes the setting")
	toggle.button_pressed = true
	assert_eq(toggle.text, "Blood: On", "and back On")


# --- The blood ---------------------------------------------------------------------------

func test_hits_throw_ink_blood_and_leave_a_stain() -> void:
	var feedback: BattleFeedback = _feedback()
	var victim: Node2D = _victim()
	var burst: InkBlood = feedback.spawn_blood(victim, Vector2(600.0, 760.0), _hit(10.0, false, false))
	assert_true(burst != null, "a hit throws blood")
	assert_eq(feedback.effects_parent.get_child_count(), 1, "into the effects layer")
	assert_eq(feedback.stains_parent.get_child_count(), 1, "and leaves a stain on the ground layer")
	var stain: BloodStain = feedback.stains_parent.get_child(0) as BloodStain
	assert_true(absf(stain.global_position.y - 880.0) < 12.0, "on the ground at the victim's feet")
	assert_true(burst.live_drops() > 0, "drops in the air")


func test_the_blood_setting_off_means_no_blood_and_no_stains() -> void:
	var feedback: BattleFeedback = _feedback(false)
	var victim: Node2D = _victim()
	for i: int in 5:
		assert_true(feedback.spawn_blood(victim, Vector2(600.0, 760.0), _hit(40.0, true, true, true)) == null, "no blood with Blood Off")
	assert_eq(feedback.effects_parent.get_child_count(), 0, "nothing in the air")
	assert_eq(feedback.stains_parent.get_child_count(), 0, "nothing on the ground")


func test_heavy_hits_kills_and_the_spirit_slash_bleed_more() -> void:
	var light: int = InkBlood.amount(false, false, false)
	var heavy: int = InkBlood.amount(true, false, false)
	var spirit: int = InkBlood.amount(false, true, false)
	var kill: int = InkBlood.amount(false, false, true)
	assert_true(heavy > light and spirit > light, "heavy hits and the Spirit Slash throw more drops than a light cut (%d, %d, %d)" % [light, heavy, spirit])
	assert_true(kill > light, "and so does a kill (%d)" % kill)
	assert_true(InkBlood.amount(true, true, true) > heavy, "a heavy, spirit kill the most")
	var feedback: BattleFeedback = _feedback()
	var victim: Node2D = _victim()
	feedback.spawn_blood(victim, Vector2(600.0, 760.0), _hit(10.0, false, false))
	feedback.spawn_blood(victim, Vector2(600.0, 760.0), _hit(50.0, true, true))
	var small: BloodStain = feedback.stains_parent.get_child(0) as BloodStain
	var big: BloodStain = feedback.stains_parent.get_child(1) as BloodStain
	assert_true(big._spots.size() > small._spots.size(), "a kill leaves a bigger stain")


func test_stains_fade_away_and_are_capped() -> void:
	var stain: BloodStain = BloodStain.new()
	stain.setup(1.0, 1.0)
	track(stain)
	assert_almost_eq(stain.opacity(), 0.0, "a new stain waits for the drops to fall")
	stain.age = 1.0
	assert_true(stain.opacity() > 0.9, "then it shows")
	stain.age = BloodStain.LIFETIME * 0.7
	assert_true(stain.opacity() < 0.8 and stain.opacity() > 0.0, "and fades")
	stain.age = BloodStain.LIFETIME * 0.999
	assert_true(stain.opacity() < 0.02, "until it is gone")
	assert_true(BloodStain.LIFETIME >= 6.0, "after several seconds")
	var feedback: BattleFeedback = _feedback()
	var victim: Node2D = _victim()
	for i: int in BattleFeedback.MAX_STAINS + 15:
		feedback.spawn_blood(victim, Vector2(600.0, 760.0), _hit(10.0, false, false))
		for child: Node in feedback.effects_parent.get_children():
			child.free()
		feedback.set("_live_blood", 0)
	assert_true(feedback.stains_parent.get_child_count() <= BattleFeedback.MAX_STAINS, "old stains are cleaned away past the cap")


func test_drops_fall_to_the_ground_and_vanish() -> void:
	var burst: InkBlood = InkBlood.new()
	burst.setup(1.0, 90.0, false, false, false)
	track(burst)
	var start: int = burst.live_drops()
	for i: int in 60:
		burst._advance(1.0 / 60.0)
	assert_true(burst.live_drops() < start, "drops that reach the ground are gone (%d of %d left)" % [burst.live_drops(), start])


func test_the_spirit_slash_marks_its_hits() -> void:
	var slash: Node = add_to_tree(SPIRIT_SLASH_SCENE.instantiate())
	assert_true((slash.get_node("Hitbox") as HitboxComponent).spirit, "the Spirit Slash's hitbox is marked")
	var plain: HitboxComponent = HitboxComponent.new()
	track(plain)
	assert_true(not plain.spirit, "ordinary hitboxes are not")
	assert_true(not HitData.new().spirit, "and a hit is not a spirit hit by default")


# --- The sounds ---------------------------------------------------------------------------

func test_hits_get_a_layered_flesh_sound() -> void:
	for id: StringName in [&"flesh_hit", &"flesh_heavy", &"spirit_flesh"]:
		var entry: SfxEntry = SFX.find(id)
		assert_true(entry != null and entry.stream != null, "%s has a sound" % id)
		assert_true(FileAccess.file_exists("res://assets/audio/sfx/%s.wav" % id), "%s.wav exists" % id)
	assert_eq(BattleFeedback.flesh_sound(_hit(5.0, false, false)), &"flesh_hit", "a light cut")
	assert_eq(BattleFeedback.flesh_sound(_hit(5.0, true, false)), &"flesh_heavy", "a heavy blow")
	assert_eq(BattleFeedback.flesh_sound(_hit(5.0, false, true)), &"flesh_heavy", "a kill")
	assert_eq(BattleFeedback.flesh_sound(_hit(5.0, false, false, true)), &"spirit_flesh", "the Spirit Slash")
	var light: AudioStreamWAV = SFX.find(&"flesh_hit").stream as AudioStreamWAV
	var heavy: AudioStreamWAV = SFX.find(&"flesh_heavy").stream as AudioStreamWAV
	assert_true(heavy.data.size() > light.data.size(), "the heavy one is longer, with more thump")
