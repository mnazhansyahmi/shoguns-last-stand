class_name SkillHints
extends RefCounted
## What the battle UI tells the player about a skill's key and its lock. Keys are read from the Input Map, so the
## hints stay right if a binding changes; the lock text names the stage that unlocks the skill.


## The short label of the first keyboard key bound to `action` ("J", "Q", "1"), or "" if none.
static func key_label(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event: InputEvent in InputMap.action_get_events(action):
		var key: InputEventKey = event as InputEventKey
		if key == null:
			continue
		var code: Key = key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		return OS.get_keycode_string(code)
	return ""


## "Clear stage 2" for the stage id that unlocks a skill ("stage_2").
static func locked_text(unlock_stage_id: String) -> String:
	var digits: String = ""
	for i: int in range(unlock_stage_id.length() - 1, -1, -1):
		var character: String = unlock_stage_id[i]
		if character < "0" or character > "9":
			break
		digits = character + digits
	return "Clear stage %s" % digits if not digits.is_empty() else "Locked"


## The text a locked skill shows: Bow ("bow") and War Cry ("war_cry").
static func locked_text_for(skill: StringName) -> String:
	return locked_text(Player.BOW_UNLOCK_STAGE if skill == &"bow" else Player.WAR_CRY_UNLOCK_STAGE)
