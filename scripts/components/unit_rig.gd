class_name UnitRig
extends RefCounted
## Builds collision shapes and the placeholder Polygon2D rig for data-driven units
## (enemies and allies). Expected rig children: Body, Head, Eye, Headgear, Weapon/Blade.

enum Headgear { NONE, HORNS, JINGASA }

const HEADGEAR_COLORS: Dictionary = {
	Headgear.HORNS: Color(0.92, 0.88, 0.75),
	Headgear.JINGASA: Color(0.3, 0.22, 0.14),
}


## Gives each instance its own shapes sized from data.
static func build_collision(body_shape: CollisionShape2D, hurtbox_shape: CollisionShape2D,
		hitbox_shape: CollisionShape2D, size: Vector2, hitbox_size: Vector2) -> void:
	var body_rect: RectangleShape2D = RectangleShape2D.new()
	body_rect.size = size
	body_shape.shape = body_rect
	body_shape.position = Vector2(0.0, -size.y * 0.5)

	var hurt_rect: RectangleShape2D = RectangleShape2D.new()
	hurt_rect.size = size
	hurtbox_shape.shape = hurt_rect
	hurtbox_shape.position = body_shape.position

	var hit_rect: RectangleShape2D = RectangleShape2D.new()
	hit_rect.size = hitbox_size
	hitbox_shape.shape = hit_rect


## Shapes the rig polygons. Returns the y of the top of the head (for health bars).
static func build_visual(rig: Node2D, size: Vector2, body_color: Color, head_color: Color,
		weapon_length: float, headgear: Headgear) -> float:
	var half: float = size.x * 0.5
	var torso_top: float = -size.y * 0.78
	var head_size: float = size.x * 0.55
	var head_top: float = torso_top - head_size

	var body: Polygon2D = rig.get_node("Body")
	body.color = body_color
	body.polygon = PackedVector2Array([
		Vector2(-half, 0.0), Vector2(half, 0.0),
		Vector2(half * 0.85, torso_top), Vector2(-half * 0.85, torso_top)])

	var head: Polygon2D = rig.get_node("Head")
	head.color = head_color
	head.polygon = rect(-head_size * 0.5, head_top, head_size * 0.5, torso_top)

	var eye: Polygon2D = rig.get_node("Eye")
	eye.polygon = rect(head_size * 0.1, torso_top - head_size * 0.7, head_size * 0.35, torso_top - head_size * 0.5)

	var gear: Polygon2D = rig.get_node("Headgear")
	gear.visible = headgear != Headgear.NONE
	gear.color = HEADGEAR_COLORS.get(headgear, Color.WHITE)
	match headgear:
		Headgear.HORNS:
			gear.polygon = PackedVector2Array([
				Vector2(-head_size * 0.5, head_top), Vector2(-head_size * 0.25, head_top),
				Vector2(-head_size * 0.55, head_top - head_size * 0.6),
				Vector2(head_size * 0.25, head_top), Vector2(head_size * 0.5, head_top),
				Vector2(head_size * 0.55, head_top - head_size * 0.6)])
		Headgear.JINGASA:
			gear.polygon = PackedVector2Array([
				Vector2(-head_size * 1.0, head_top + head_size * 0.25),
				Vector2(head_size * 1.0, head_top + head_size * 0.25),
				Vector2(0.0, head_top - head_size * 0.4)])

	var weapon: Node2D = rig.get_node("Weapon")
	weapon.position = Vector2(half * 0.6, torso_top * 0.75)
	var blade: Polygon2D = rig.get_node("Weapon/Blade")
	var thickness: float = maxf(3.0, size.x * 0.06)
	blade.polygon = rect(-8.0, -thickness, weapon_length, thickness)
	return head_top


static func rect(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])
