class_name TouchInput
extends RefCounted
## Touch widgets drive the same Input Map actions as the keyboard (Input.action_press/release),
## so gameplay code reads one input state regardless of device.


static func press(action: StringName, strength: float = 1.0) -> void:
	if InputMap.has_action(action):
		Input.action_press(action, clampf(strength, 0.0, 1.0))
	else:
		push_warning("TouchInput: unknown action '%s'." % action)


static func release(action: StringName) -> void:
	if InputMap.has_action(action):
		Input.action_release(action)


static func is_touch_event(event: InputEvent) -> bool:
	return event is InputEventScreenTouch or event is InputEventScreenDrag
