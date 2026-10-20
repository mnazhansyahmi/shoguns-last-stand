class_name LegIK
extends RefCounted
## Planar legs face +x before the visual is mirrored. Bend is always toward +x.
## Reach is handled at the pelvis/target, never by scaling a bone.
const MAX_BEND: float = 115.0
const SOLE: float = 2.5


static func minimum_reach(thigh: float, shin: float) -> float:
	return sqrt(thigh * thigh + shin * shin + 2.0 * thigh * shin * cos(deg_to_rad(MAX_BEND)))


static func fit_hip(hip: Vector2, front: Vector2, back: Vector2, thigh: float, shin: float) -> Vector2:
	var reach: float = thigh + shin - 0.001
	var minimum: float = minimum_reach(thigh, shin)
	var highest: float = -INF
	var lowest: float = INF
	for side: int in 2:
		var ankle: Vector2 = front if side == 0 else back
		var dx: float = ankle.x - hip.x - (2.0 if side == 0 else -2.0)
		highest = maxf(highest, ankle.y - sqrt(maxf(0.0, reach * reach - dx * dx)))
		lowest = minf(lowest, ankle.y - sqrt(maxf(0.0, minimum * minimum - dx * dx)))
	# A close target lifts the hips; a distant target lowers them until the leg is straight.
	hip.y = clampf(hip.y, highest, maxf(highest, lowest))
	return hip


static func knee(hip: Vector2, ankle: Vector2, thigh: float, shin: float) -> Vector2:
	var offset: Vector2 = ankle - hip
	var distance: float = maxf(offset.length(), 0.001)
	var along: float = (thigh * thigh - shin * shin + distance * distance) / (2.0 * distance)
	var forward: Vector2 = Vector2(offset.y, -offset.x).normalized()
	return hip + offset / distance * along + forward * sqrt(maxf(0.0, thigh * thigh - along * along))
