class_name UnitRig
extends RefCounted
## Builds the per-instance collision shapes for data-driven units (enemies and allies).
## Their look is drawn by UnitVisual / InkFigure from the data's `figure` kind.


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
