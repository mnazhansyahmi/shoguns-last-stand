class_name FigurePainter
extends RefCounted
## Per-kind costume drawing for InkFigure: body shapes, headgear, weapons and the one accent.
## Called from InkFigure._draw() with the skeleton already solved. Coordinates are figure units
## in the space named by each `fig.use(...)` call (see FigureKinds for the spaces).

const KATANA_LENGTH: float = 70.0
const BOW_UPPER: float = 64.0
const BOW_LOWER: float = 34.0


static func paint(fig: InkFigure) -> void:
	match fig.kind:
		InkFigure.Kind.SAMURAI:
			_paint_samurai(fig)
		InkFigure.Kind.ASHIGARU:
			_paint_ashigaru(fig)
		InkFigure.Kind.YUMI_ARCHER:
			_paint_archer(fig)
		InkFigure.Kind.HOLLOW_SOLDIER:
			_paint_hollow(fig)
		InkFigure.Kind.ONI_BRUTE:
			_paint_oni(fig)


static func collect_glows(fig: InkFigure) -> void:
	var strength: float = 1.0 - fig.fall * 0.7
	match fig.kind:
		InkFigure.Kind.SAMURAI:
			if fig.pose.glow > 0.02:
				var along: float = 6.0
				while along <= 72.0:
					fig.add_glow(fig.weapon_xf, Vector2(along, -1.5), 13.0 * fig.pose.glow,
							Color(InkPalette.SPIRIT, 0.32 * fig.pose.glow))
					along += 6.0
		InkFigure.Kind.HOLLOW_SOLDIER:
			fig.add_glow(fig.head_xf, Vector2(5.5, -9.0), 6.0, Color(InkPalette.HOLLOW_PURPLE, 0.95 * strength))
			fig.add_glow(fig.head_xf, Vector2(2.0, -9.5), 5.0, Color(InkPalette.HOLLOW_PURPLE, 0.85 * strength))
		InkFigure.Kind.ONI_BRUTE:
			fig.add_glow(fig.torso_xf, Vector2(0.0, -26.0), 46.0, Color(InkPalette.ONI_EMBER, 0.16 * strength))
			fig.add_glow(fig.head_xf, Vector2(7.0, -8.0), 5.0, Color(InkPalette.ONI_EMBER, 0.95 * strength))
			fig.add_glow(fig.head_xf, Vector2(3.0, -8.5), 4.5, Color(InkPalette.ONI_EMBER, 0.85 * strength))
			fig.add_glow(fig.head_xf, Vector2(6.0, -1.5), 4.5, Color(InkPalette.ONI_EMBER, 0.7 * strength))
			for point: Vector2 in [Vector2(6.0, -37.0), Vector2(8.0, -31.0), Vector2(8.5, -24.0),
					Vector2(-4.0, -28.0), Vector2(-3.5, -21.0)]:
				fig.add_glow(fig.torso_xf, point, 7.0, Color(InkPalette.ONI_EMBER, 0.3 * strength))


## x of the bow string's nock point in bow space for a draw amount (0 = rest).
static func bow_nock_x(draw_amount: float) -> float:
	return lerpf(_bow_bend(1.0, draw_amount), -30.0, clampf(draw_amount, 0.0, 1.0))


# --- Samurai ----------------------------------------------------------------

static func _paint_samurai(fig: InkFigure) -> void:
	_paint_cloth_tails(fig, fig.torso_xf * Vector2(-3.0, -33.0), InkPalette.SAMURAI_RED, [6, 5], 5.2, 4.6)
	fig.paint_leg(false)
	# Back pauldron.
	fig.use(fig.torso_xf)
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(-12.0, -35.0), Vector2(-3.0, -35.0),
			Vector2(-2.0, -23.0), Vector2(-13.5, -24.0)]), fig.ink(InkPalette.INK_BACK))
	fig.paint_arm(false)
	fig.paint_leg(true)

	fig.use(fig.torso_xf)
	var ink: Color = fig.ink(InkPalette.INK)
	var detail: Color = fig.ink(InkPalette.INK_DETAIL)
	# Kusazuri (armour skirt) over the hakama.
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(-12.0, -4.0), Vector2(12.0, -4.0),
			Vector2(14.5, 12.0), Vector2(-13.5, 12.0)]), ink)
	for x: float in [-4.5, 4.5]:
		InkBrush.limb(fig, Vector2(x, 0.0), Vector2(x * 1.15, 10.0), 2.0, 2.0, detail)
	# Do (chest armour).
	InkBrush.fill(fig, PackedVector2Array([Vector2(-10.0, -2.0), Vector2(10.0, -2.0), Vector2(12.5, -20.0),
			Vector2(12.0, -31.0), Vector2(4.0, -34.5), Vector2(-8.0, -34.5), Vector2(-11.5, -24.0)]), ink)
	for y: float in [-10.0, -17.0]:
		InkBrush.limb(fig, Vector2(-8.5, y), Vector2(10.5, y), 2.0, 2.0, detail)
	# Sash knot (accent).
	var red: Color = fig.ink(InkPalette.SAMURAI_RED)
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(7.0, -3.5), Vector2(13.5, -6.5), Vector2(12.5, -0.5)]), red)
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(7.0, -3.5), Vector2(12.0, 3.5), Vector2(8.0, 4.5)]), red)
	fig.draw_circle(Vector2(8.0, -3.0), 2.4, red)

	_paint_samurai_head(fig)
	# Scarf wrap at the neck (accent).
	fig.use(fig.torso_xf)
	InkBrush.ellipse(fig, Vector2(1.5, -34.5), Vector2(7.0, 3.4), red)

	fig.paint_arm(true)
	_paint_front_pauldron(fig)
	_paint_katana(fig)
	fig.paint_hand(false)
	fig.paint_hand(true)


static func _paint_samurai_head(fig: InkFigure) -> void:
	var ink: Color = fig.ink(InkPalette.INK)
	fig.use(fig.head_xf)
	InkBrush.limb(fig, Vector2(0.0, 0.0), Vector2(0.5, -5.0), 6.0, 6.0, ink)
	InkBrush.ellipse(fig, Vector2(1.5, -9.5), Vector2(7.0, 8.0), ink)
	fig.draw_circle(Vector2(-5.0, -12.0), 3.6, ink)
	# Topknot (chonmage), folded forward over the crown.
	InkBrush.stroke(fig, PackedVector2Array([Vector2(-5.0, -14.0), Vector2(-1.0, -18.0),
			Vector2(3.5, -19.0), Vector2(7.0, -17.5)]), 4.6, 3.0, ink)


static func _paint_front_pauldron(fig: InkFigure) -> void:
	var to_elbow: Vector2 = fig.front_elbow - fig.spec.shoulder_front
	var angle: float = clampf(to_elbow.angle() - PI * 0.5, -0.9, 0.7) * 0.5
	fig.use(fig.torso_xf * Transform2D(angle, fig.spec.shoulder_front))
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(-5.0, -3.0), Vector2(6.0, -3.0),
			Vector2(8.0, 10.0), Vector2(-4.0, 11.0)]), fig.ink(InkPalette.INK))
	InkBrush.limb(fig, Vector2(-3.5, 4.0), Vector2(6.5, 4.0), 2.0, 2.0, fig.ink(InkPalette.INK_DETAIL))


static func _paint_katana(fig: InkFigure) -> void:
	var ink: Color = fig.ink(InkPalette.INK)
	fig.use(fig.weapon_xf)
	InkBrush.limb(fig, Vector2(-11.0, 0.0), Vector2(1.0, 0.0), 3.8, 3.8, ink)
	InkBrush.ellipse(fig, Vector2(1.8, 0.0), Vector2(1.7, 4.2), ink, 10)
	var tip: float = 3.0 + KATANA_LENGTH
	InkBrush.fill(fig, PackedVector2Array([Vector2(3.0, -1.9), Vector2(30.0, -2.7), Vector2(55.0, -3.4),
			Vector2(tip, -4.2), Vector2(56.0, -0.9), Vector2(30.0, 0.5), Vector2(3.0, 1.7)]), ink)
	InkBrush.stroke(fig, PackedVector2Array([Vector2(5.0, 1.1), Vector2(30.0, 0.0), Vector2(55.0, -1.3),
			Vector2(tip - 3.0, -3.3)]), 1.9, 1.2, fig.ink(InkPalette.STEEL))
	if fig.pose.glow > 0.02:
		InkBrush.stroke(fig, PackedVector2Array([Vector2(4.0, -0.4), Vector2(30.0, -1.2), Vector2(55.0, -2.3),
				Vector2(tip - 1.0, -3.8)]), 2.6, 1.6, Color(InkPalette.SPIRIT, fig.pose.glow))


# --- Ashigaru -------------------------------------------------------------

static func _paint_ashigaru(fig: InkFigure) -> void:
	fig.paint_leg(false)
	fig.paint_arm(false)
	fig.paint_leg(true)
	var ink: Color = fig.ink(InkPalette.INK)
	var gold: Color = fig.ink(InkPalette.ASHIGARU_GOLD)
	fig.use(fig.torso_xf)
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(-11.0, -3.0), Vector2(11.0, -3.0),
			Vector2(13.0, 9.0), Vector2(-12.0, 9.0)]), ink)
	InkBrush.fill(fig, PackedVector2Array([Vector2(-9.0, -1.0), Vector2(9.5, -1.0), Vector2(11.0, -18.0),
			Vector2(10.0, -29.0), Vector2(3.0, -31.5), Vector2(-7.0, -31.0), Vector2(-10.5, -18.0)]), ink)
	InkBrush.limb(fig, Vector2(-8.0, -14.0), Vector2(10.0, -14.0), 2.0, 2.0, fig.ink(InkPalette.INK_DETAIL))
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(-10.5, -1.0), Vector2(10.5, -1.0),
			Vector2(10.8, -5.0), Vector2(-10.8, -5.0)]), gold)

	fig.use(fig.head_xf)
	InkBrush.limb(fig, Vector2(0.0, 0.0), Vector2(0.5, -4.0), 5.5, 5.5, ink)
	InkBrush.ellipse(fig, Vector2(1.0, -8.5), Vector2(6.5, 7.5), ink)
	# Jingasa: wide shallow cone with a gold rim.
	InkBrush.fill(fig, PackedVector2Array([Vector2(-22.0, -6.0), Vector2(-9.0, -12.5), Vector2(0.5, -17.5),
			Vector2(10.0, -12.5), Vector2(23.0, -6.0), Vector2(21.5, -4.0), Vector2(-20.5, -4.0)]), ink)
	InkBrush.stroke(fig, PackedVector2Array([Vector2(-21.0, -4.6), Vector2(0.0, -5.4), Vector2(22.0, -4.6)]),
			2.6, 2.6, gold)

	_paint_yari(fig)
	fig.paint_arm(true)
	fig.paint_hand(false)
	fig.paint_hand(true)


static func _paint_yari(fig: InkFigure) -> void:
	var ink: Color = fig.ink(InkPalette.INK)
	fig.use(fig.weapon_xf)
	InkBrush.limb(fig, Vector2(-44.0, 0.0), Vector2(64.0, 0.0), 3.4, 3.2, ink)
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(63.0, -2.2), Vector2(72.0, -3.2),
			Vector2(84.0, 0.0), Vector2(72.0, 3.2), Vector2(63.0, 2.2)]), ink)
	InkBrush.limb(fig, Vector2(66.0, 0.0), Vector2(81.0, 0.0), 1.6, 1.0, fig.ink(InkPalette.STEEL))
	# Tassel hangs toward the ground whatever the spear angle (accent).
	var down: Vector2 = Vector2(0.0, 1.0).rotated(-fig.pose.blade - fig.pose.lean)
	var sway: float = sin(fig.clock * 6.0) * 1.5 * (0.4 + fig.trail)
	var base: Vector2 = Vector2(60.0, 0.0)
	var gold: Color = fig.ink(InkPalette.ASHIGARU_GOLD)
	InkBrush.stroke(fig, PackedVector2Array([base, base + down * 4.0 + Vector2(-1.0 - sway, 0.0),
			base + down * 8.0 + Vector2(-2.5 - sway * 1.6, 0.0)]), 4.5, 1.8, gold)


# --- Yumi Archer ------------------------------------------------------------

static func _paint_archer(fig: InkFigure) -> void:
	var teal: Color = fig.ink(InkPalette.ARCHER_TEAL)
	_paint_cloth_tails(fig, fig.head_xf * Vector2(-6.0, -9.5), InkPalette.ARCHER_TEAL, [4, 3], 4.0, 3.4)
	# Quiver over the back shoulder, fletching above it (accent).
	fig.use(fig.torso_xf)
	InkBrush.limb(fig, Vector2(-10.0, -32.0), Vector2(-5.0, -5.0), 6.5, 5.5, fig.ink(InkPalette.INK_BACK))
	for tip: Vector2 in [Vector2(-14.5, -42.0), Vector2(-11.5, -43.5), Vector2(-8.5, -42.5)]:
		InkBrush.limb(fig, Vector2(-10.0, -32.0), tip, 2.0, 2.0, fig.ink(InkPalette.INK_BACK))
		InkBrush.limb(fig, tip, tip + (tip - Vector2(-10.0, -32.0)).normalized() * 3.5, 3.4, 2.2, teal)
	fig.paint_leg(false)
	fig.paint_arm(false)
	fig.paint_leg(true)

	var ink: Color = fig.ink(InkPalette.INK)
	fig.use(fig.torso_xf)
	InkBrush.fill(fig, PackedVector2Array([Vector2(-9.0, -2.0), Vector2(9.0, -2.0), Vector2(10.5, -18.0),
			Vector2(9.0, -29.0), Vector2(2.0, -31.5), Vector2(-7.0, -30.0), Vector2(-10.0, -18.0)]), ink)
	InkBrush.limb(fig, Vector2(-5.0, -29.0), Vector2(6.0, -12.0), 2.0, 2.0, fig.ink(InkPalette.INK_DETAIL))
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(-10.0, -1.0), Vector2(10.0, -1.0),
			Vector2(10.3, -4.2), Vector2(-10.3, -4.2)]), teal)

	fig.use(fig.head_xf)
	InkBrush.limb(fig, Vector2(0.0, 0.0), Vector2(0.5, -4.0), 5.5, 5.5, ink)
	InkBrush.ellipse(fig, Vector2(1.0, -8.5), Vector2(6.5, 7.5), ink)
	InkBrush.stroke(fig, PackedVector2Array([Vector2(-4.0, -13.0), Vector2(-0.5, -16.5), Vector2(4.0, -16.0)]),
			4.0, 2.8, ink)
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(-6.5, -11.5), Vector2(7.5, -11.5),
			Vector2(7.5, -8.5), Vector2(-6.5, -8.5)]), teal)

	_paint_bow(fig)
	fig.paint_arm(true)
	fig.paint_hand(false)
	fig.paint_hand(true)


static func _bow_bend(t: float, draw_amount: float) -> float:
	return -(3.0 + 7.0 * clampf(draw_amount, 0.0, 1.0)) * t * t + (2.0 * t * t * t * t if t > 0.8 else 0.0)


static func _paint_bow(fig: InkFigure) -> void:
	var ink: Color = fig.ink(InkPalette.INK)
	var draw_amount: float = fig.pose.bow_draw
	fig.use(fig.weapon_xf)
	var upper: PackedVector2Array = PackedVector2Array()
	var lower: PackedVector2Array = PackedVector2Array()
	for i: int in 9:
		var t: float = float(i) / 8.0
		upper.append(Vector2(_bow_bend(t, draw_amount), -t * BOW_UPPER))
		lower.append(Vector2(_bow_bend(t, draw_amount), t * BOW_LOWER))
	var nock: Vector2 = Vector2(bow_nock_x(draw_amount), 0.0)
	# String first so the limbs cover its ends.
	InkBrush.stroke(fig, PackedVector2Array([upper[8], nock, lower[8]]), 1.4, 1.4, ink)
	InkBrush.stroke(fig, upper, 5.0, 3.2, ink)
	InkBrush.stroke(fig, lower, 5.0, 3.2, ink)
	if draw_amount > 0.25:
		var alpha: float = clampf((draw_amount - 0.25) * 2.5, 0.0, 1.0)
		var head: float = nock.x + 44.0
		InkBrush.limb(fig, nock, Vector2(head, 0.0), 2.2, 2.2, Color(ink, alpha))
		InkBrush.fill_convex(fig, PackedVector2Array([Vector2(head - 1.0, -2.6), Vector2(head + 5.0, 0.0),
				Vector2(head - 1.0, 2.6)]), Color(ink, alpha))
		var teal: Color = Color(fig.ink(InkPalette.ARCHER_TEAL), alpha)
		InkBrush.fill_convex(fig, PackedVector2Array([nock + Vector2(1.0, 0.0), nock + Vector2(8.0, 0.0),
				nock + Vector2(4.0, -3.4)]), teal)
		InkBrush.fill_convex(fig, PackedVector2Array([nock + Vector2(1.0, 0.0), nock + Vector2(8.0, 0.0),
				nock + Vector2(4.0, 3.4)]), teal)


# --- Hollow Soldier -------------------------------------------------------

static func _paint_hollow(fig: InkFigure) -> void:
	fig.paint_leg(false)
	fig.paint_arm(false)
	fig.paint_leg(true)
	var ink: Color = fig.ink(InkPalette.INK)
	var detail: Color = fig.ink(InkPalette.INK_DETAIL)
	fig.use(fig.torso_xf)
	# Tattered skirt with a fluttering ragged hem.
	var hem: PackedVector2Array = PackedVector2Array([Vector2(-10.0, -3.0), Vector2(10.0, -3.0)])
	var hem_points: Array[Vector2] = [Vector2(12.0, 8.0), Vector2(8.0, 14.0), Vector2(5.0, 9.0),
			Vector2(1.0, 15.0), Vector2(-3.0, 10.0), Vector2(-7.0, 14.5), Vector2(-11.0, 9.0)]
	for i: int in hem_points.size():
		var flutter: float = sin(fig.clock * 7.0 + float(i) * 1.7) * 1.5 * (0.4 + fig.trail)
		hem.append(hem_points[i] + Vector2(-fig.trail * 2.0 * float(i % 2), flutter))
	InkBrush.fill(fig, hem, ink)
	# Broken cuirass with a chunk torn out of the chest.
	fig.use(fig.torso_xf)
	InkBrush.fill(fig, PackedVector2Array([Vector2(-8.0, -2.0), Vector2(8.0, -2.0), Vector2(9.5, -12.0),
			Vector2(6.5, -16.0), Vector2(11.0, -19.0), Vector2(12.0, -26.0), Vector2(8.0, -31.0),
			Vector2(-3.0, -32.5), Vector2(-9.0, -25.0), Vector2(-10.0, -12.0)]), ink)
	InkBrush.limb(fig, Vector2(-6.0, -22.0), Vector2(3.0, -24.0), 2.0, 2.0, detail)
	InkBrush.limb(fig, Vector2(-6.5, -16.0), Vector2(2.0, -17.0), 2.0, 2.0, detail)

	fig.use(fig.head_xf)
	InkBrush.limb(fig, Vector2(0.0, 0.0), Vector2(1.0, -4.0), 4.5, 4.5, ink)
	InkBrush.ellipse(fig, Vector2(2.0, -8.5), Vector2(6.0, 7.5), ink)
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(3.0, -5.0), Vector2(8.5, -4.0),
			Vector2(7.5, 0.5), Vector2(2.0, 0.0)]), ink)
	# Helmet: dome, ragged neck guard, one tall crest prong and one snapped stub.
	InkBrush.fill(fig, PackedVector2Array([Vector2(-7.5, -9.0), Vector2(-6.5, -14.5), Vector2(0.0, -18.0),
			Vector2(6.5, -15.5), Vector2(8.5, -10.5)]), ink)
	InkBrush.fill(fig, PackedVector2Array([Vector2(-7.0, -11.0), Vector2(-12.0, -6.0), Vector2(-9.5, -5.0),
			Vector2(-10.5, -2.0), Vector2(-5.0, -6.0)]), ink)
	InkBrush.stroke(fig, PackedVector2Array([Vector2(1.5, -16.5), Vector2(4.5, -25.0), Vector2(9.0, -30.0)]),
			3.4, 1.8, ink)
	InkBrush.stroke(fig, PackedVector2Array([Vector2(-1.0, -16.5), Vector2(-3.5, -21.5)]), 3.4, 2.8, ink)
	# Eye cores; the halo is on the glow layer (accent).
	var eye: Color = InkPalette.HOLLOW_PURPLE.lerp(InkPalette.PAPER, 0.45)
	fig.draw_circle(Vector2(5.5, -9.0), 1.5, eye)
	fig.draw_circle(Vector2(2.0, -9.5), 1.3, eye)

	_paint_notched_sword(fig)
	fig.paint_arm(true)
	fig.paint_hand(false)
	fig.paint_hand(true)


static func _paint_notched_sword(fig: InkFigure) -> void:
	var ink: Color = fig.ink(InkPalette.INK)
	fig.use(fig.weapon_xf)
	InkBrush.limb(fig, Vector2(-7.0, 0.0), Vector2(1.0, 0.0), 3.4, 3.4, ink)
	InkBrush.ellipse(fig, Vector2(1.5, 0.0), Vector2(1.4, 3.2), ink, 10)
	InkBrush.fill(fig, PackedVector2Array([Vector2(2.0, -1.9), Vector2(20.0, -2.3), Vector2(23.5, -1.0),
			Vector2(27.0, -2.5), Vector2(44.0, -2.7), Vector2(51.0, -0.4), Vector2(44.0, 1.1),
			Vector2(32.0, 1.5), Vector2(29.0, 0.3), Vector2(26.0, 1.7), Vector2(2.0, 1.9)]), ink)
	InkBrush.limb(fig, Vector2(8.0, 0.0), Vector2(18.0, -0.3), 1.6, 1.4, fig.ink(InkPalette.INK_DETAIL))


# --- Oni Brute --------------------------------------------------------------

static func _paint_oni(fig: InkFigure) -> void:
	var ink: Color = fig.ink(InkPalette.INK)
	var back: Color = fig.ink(InkPalette.INK_BACK)
	var detail: Color = fig.ink(InkPalette.INK_DETAIL)
	var ember: Color = InkPalette.ONI_EMBER.lerp(InkPalette.PAPER, 0.25)
	# Wild mane and the far horn, behind everything.
	fig.use(fig.head_xf)
	InkBrush.fill(fig, PackedVector2Array([Vector2(-2.0, -14.0), Vector2(-11.0, -16.0), Vector2(-8.0, -11.0),
			Vector2(-16.0, -9.0), Vector2(-10.0, -6.0), Vector2(-15.0, -1.0), Vector2(-6.0, -1.0),
			Vector2(-4.0, 4.0), Vector2(2.0, -6.0)]), back)
	InkBrush.stroke(fig, PackedVector2Array([Vector2(-1.0, -11.0), Vector2(-4.5, -18.0), Vector2(-4.5, -25.0),
			Vector2(-7.5, -29.5)]), 5.0, 1.8, back)
	fig.paint_leg(false)
	fig.paint_arm(false)
	fig.paint_leg(true)

	fig.use(fig.torso_xf)
	# Tiger-hide loincloth.
	InkBrush.fill(fig, PackedVector2Array([Vector2(-15.0, -4.0), Vector2(15.0, -4.0), Vector2(17.0, 6.0),
			Vector2(11.0, 13.0), Vector2(3.0, 9.0), Vector2(-5.0, 14.0), Vector2(-13.0, 8.0)]), ink)
	for x: float in [-8.0, 0.0, 8.0]:
		InkBrush.limb(fig, Vector2(x - 2.0, -1.0), Vector2(x + 2.0, 7.0), 2.2, 1.4, detail)
	# Barrel torso.
	InkBrush.fill(fig, PackedVector2Array([Vector2(-14.0, -2.0), Vector2(14.0, -2.0), Vector2(20.0, -14.0),
			Vector2(25.0, -30.0), Vector2(21.0, -43.0), Vector2(10.0, -48.0), Vector2(-6.0, -49.0),
			Vector2(-19.0, -44.0), Vector2(-23.0, -28.0), Vector2(-19.0, -12.0)]), ink)
	InkBrush.limb(fig, Vector2(-4.0, -14.0), Vector2(10.0, -14.0), 2.2, 2.2, detail)
	# Ember cracks across the chest (accent; glow halo on the glow layer).
	InkBrush.stroke(fig, PackedVector2Array([Vector2(4.0, -39.0), Vector2(9.0, -33.0), Vector2(6.5, -28.0),
			Vector2(11.0, -21.0)]), 2.4, 1.2, ember)
	InkBrush.stroke(fig, PackedVector2Array([Vector2(-6.0, -31.0), Vector2(-2.0, -25.5), Vector2(-5.0, -19.0)]),
			2.2, 1.0, ember)

	fig.use(fig.head_xf)
	InkBrush.ellipse(fig, Vector2(3.0, -6.5), Vector2(7.5, 7.5), ink)
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(0.0, -4.0), Vector2(11.5, -4.0),
			Vector2(10.5, 2.5), Vector2(1.0, 2.5)]), ink)
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(8.0, -3.0), Vector2(10.0, -3.0), Vector2(9.0, -7.0)]), ink)
	InkBrush.stroke(fig, PackedVector2Array([Vector2(5.0, -11.0), Vector2(9.0, -17.0), Vector2(10.0, -25.0),
			Vector2(7.0, -30.5)]), 5.5, 1.8, ink)
	fig.draw_circle(Vector2(7.0, -8.0), 1.6, ember)
	fig.draw_circle(Vector2(3.0, -8.5), 1.4, ember)
	InkBrush.limb(fig, Vector2(3.5, -1.5), Vector2(9.5, -1.5), 1.4, 1.2, ember)

	_paint_kanabo(fig)
	fig.paint_arm(true)
	fig.paint_hand(false)
	fig.paint_hand(true)


static func _paint_kanabo(fig: InkFigure) -> void:
	var ink: Color = fig.ink(InkPalette.INK)
	fig.use(fig.weapon_xf)
	InkBrush.limb(fig, Vector2(-13.0, 0.0), Vector2(5.0, 0.0), 4.6, 4.6, ink)
	fig.draw_circle(Vector2(-14.5, 0.0), 3.2, ink)
	InkBrush.fill_convex(fig, PackedVector2Array([Vector2(4.0, -3.6), Vector2(60.0, -6.4), Vector2(66.0, -5.0),
			Vector2(66.0, 5.0), Vector2(60.0, 6.4), Vector2(4.0, 3.6)]), ink)
	# Iron studs break the club's outline.
	var x: float = 16.0
	while x <= 58.0:
		var half: float = lerpf(3.6, 6.4, (x - 4.0) / 56.0)
		fig.draw_circle(Vector2(x, -half), 1.9, ink)
		fig.draw_circle(Vector2(x + 4.0, half), 1.9, ink)
		x += 9.0


# --- Shared -----------------------------------------------------------------

## Two or more cloth tails (scarf, headband) streaming backward from `base` (local pixels).
static func _paint_cloth_tails(fig: InkFigure, base: Vector2, color: Color, segment_counts: Array,
		width: float, segment: float) -> void:
	var s: float = fig.get_unit_scale()
	var tint: Color = fig.ink(color)
	fig.use(Transform2D.IDENTITY)
	for tail: int in segment_counts.size():
		var count: int = segment_counts[tail]
		var points: PackedVector2Array = PackedVector2Array([base])
		var phase: float = float(tail) * 1.9
		for i: int in range(1, count + 1):
			var k: float = float(i)
			var stream: Vector2 = Vector2(-k * (0.55 + 0.55 * fig.trail), k * (0.85 - 0.6 * fig.trail) + float(tail) * k * 0.25)
			var wave: float = sin(fig.clock * (7.0 + fig.trail * 6.0) - k * 0.9 + phase) * k * 0.45 * (0.35 + fig.trail)
			points.append(base + (stream * segment + Vector2(0.0, wave)) * s)
		InkBrush.stroke(fig, points, width * s, 1.4 * s, tint)
