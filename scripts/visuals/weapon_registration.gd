class_name WeaponRegistration
extends RefCounted
## Measured shaft/hilt centers in the painted source, independent of cloth,
## guards and curved tips. Uniform sampling keeps the weapon's real proportions.
## Values: global source grip x/y, source shaft angle, figure units/source pixel.
const POINTS: Dictionary = {
	InkFigure.Kind.ASHIGARU: Vector4(105, 185, -0.009, 0.34),
	InkFigure.Kind.SPEAR_GUARDIAN: Vector4(459, 185, 0.0, 0.37),
	InkFigure.Kind.HATAMOTO: Vector4(840, 185, 0.0, 0.33),
	InkFigure.Kind.ONMYOJI: Vector4(1183, 185, 0.0, 0.23),
	InkFigure.Kind.SHRINE_HEALER: Vector4(103, 495, -0.165, 0.23),
	InkFigure.Kind.HOLLOW_SOLDIER: Vector4(423, 487, 0.075, 0.21),
	InkFigure.Kind.ONI_BRUTE: Vector4(802, 497, -0.075, 0.255),
	InkFigure.Kind.FALLEN_DAIMYO: Vector4(1152, 501, -0.03, 0.35),
	InkFigure.Kind.SAMURAI: Vector4(1136, 861, 0.02, 0.258),
	InkFigure.Kind.SHIELD_BEARER: Vector4(951, 1113, 0.0, 0.21),
	InkFigure.Kind.BURNING_GENERAL: Vector4(940, 1129, -0.04, 0.35),
}


static func frame(kind: InkFigure.Kind, source: Rect2) -> Transform2D:
	var point: Vector4 = POINTS[kind]
	var grip: Vector2 = Vector2(point.x, point.y) - source.position
	return Transform2D(0.0, Vector2.ONE * point.w, 0.0, Vector2.ZERO) * Transform2D(point.z, grip).affine_inverse()
