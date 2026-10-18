class_name Faction
extends RefCounted
## Faction identification and the physics layers used by hitboxes/hurtboxes.

enum Type { DEFENDERS, ENEMIES }

## Physics layer 7 ("hurtbox_defenders"): player, allies, gate.
const HURTBOX_LAYER_DEFENDERS: int = 1 << 6
## Physics layer 8 ("hurtbox_enemies").
const HURTBOX_LAYER_ENEMIES: int = 1 << 7


static func hurtbox_layer(faction: Type) -> int:
	return HURTBOX_LAYER_DEFENDERS if faction == Type.DEFENDERS else HURTBOX_LAYER_ENEMIES


## Mask a hitbox of `faction` uses so it only ever sees hostile hurtboxes.
static func hostile_hurtbox_mask(faction: Type) -> int:
	return HURTBOX_LAYER_ENEMIES if faction == Type.DEFENDERS else HURTBOX_LAYER_DEFENDERS


static func are_hostile(a: Type, b: Type) -> bool:
	return a != b
