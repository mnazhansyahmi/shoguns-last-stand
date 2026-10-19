class_name FigurePainter
extends RefCounted
## Per-kind costume drawing for InkFigure: body shapes, headgear, weapons and the one accent.
## Each body part is built ONCE per kind into an InkBatch in the part's own space (torso, head,
## weapon, limb segment...). InkFigure keeps one child node per part (layout) that draws its
## batch once; a frame only moves those nodes. Only cloth tails and the Hollow Soldier's hem
## change shape and are redrawn each frame; the bow swaps between cached draw steps.
## Coordinates are figure units (see FigureKinds).

const KATANA_LENGTH: float = 70.0
const BOW_UPPER: float = 64.0
const BOW_LOWER: float = 34.0
## The bow's shape is cached at this many draw positions.
const BOW_STEPS: int = 12

## Kind -> { part name -> InkBatch }.
static var _parts: Dictionary = {}
## Bow draw step -> InkBatch.
static var _bows: Dictionary = {}


## Body part slots: where a part sits each frame (InkFigure computes one transform per slot).
enum Slot { SHADOW, MARKER, LOCAL, THIGH_F, SHIN_F, FOOT_F, THIGH_B, SHIN_B, FOOT_B, UPPER_F, FORE_F,
		HAND_F, UPPER_B, FORE_B, HAND_B, TORSO, HEAD, WEAPON, PAULDRON_FRONT, HAKAMA_F, HAKAMA_B }

## Part name -> slot. Every part in a layout must be listed.
const SLOTS: Dictionary = {
	&"marker": Slot.MARKER, &"shadow": Slot.SHADOW, &"tails": Slot.LOCAL,
	&"thigh_f": Slot.THIGH_F, &"shin_f": Slot.SHIN_F, &"foot_f": Slot.FOOT_F,
	&"thigh_b": Slot.THIGH_B, &"shin_b": Slot.SHIN_B, &"foot_b": Slot.FOOT_B,
	&"upper_f": Slot.UPPER_F, &"fore_f": Slot.FORE_F, &"hand_f": Slot.HAND_F,
	&"upper_b": Slot.UPPER_B, &"fore_b": Slot.FORE_B, &"hand_b": Slot.HAND_B,
	&"torso": Slot.TORSO, &"pauldron_back": Slot.TORSO, &"neck_wrap": Slot.TORSO, &"quiver": Slot.TORSO, &"hem": Slot.TORSO,
	&"head": Slot.HEAD, &"mane": Slot.HEAD,
	&"weapon": Slot.WEAPON, &"bow": Slot.WEAPON, &"blade_glow": Slot.WEAPON,
	&"pauldron_front": Slot.PAULDRON_FRONT, &"saya": Slot.TORSO,
	&"hakama_f": Slot.HAKAMA_F, &"hakama_b": Slot.HAKAMA_B,
}
## Parts whose shape changes every frame (redrawn through paint_dynamic).
const DYNAMIC_PARTS: Array[StringName] = [&"tails", &"hem"]

const _BACK_LIMBS: Array[StringName] = [&"thigh_b", &"shin_b", &"foot_b"]
const _BACK_ARM: Array[StringName] = [&"upper_b", &"fore_b"]
const _FRONT_LEG: Array[StringName] = [&"thigh_f", &"shin_f", &"foot_f"]
const _FRONT_ARM: Array[StringName] = [&"upper_f", &"fore_f"]
const _HANDS: Array[StringName] = [&"hand_b", &"hand_f"]


## Draw order of a kind's parts, back to front.
static func layout(kind: InkFigure.Kind) -> Array[StringName]:
	var order: Array[StringName] = [&"shadow"]
	match kind:
		InkFigure.Kind.SAMURAI:
			order.append_array([&"tails", &"foot_b", &"hakama_b", &"pauldron_back"])
			order.append_array(_BACK_ARM)
			order.append_array([&"foot_f", &"hakama_f", &"torso", &"saya", &"neck_wrap", &"head"])
			order.append_array(_FRONT_ARM)
			order.append_array([&"pauldron_front", &"weapon", &"blade_glow"])
		InkFigure.Kind.ASHIGARU:
			order.append_array(_BACK_LIMBS + _BACK_ARM + _FRONT_LEG)
			order.append_array([&"torso", &"head", &"weapon"])
			order.append_array(_FRONT_ARM)
		InkFigure.Kind.YUMI_ARCHER:
			order.append_array([&"tails", &"quiver"])
			order.append_array(_BACK_LIMBS + _BACK_ARM + _FRONT_LEG)
			order.append_array([&"torso", &"head", &"bow"])
			order.append_array(_FRONT_ARM)
		InkFigure.Kind.HOLLOW_SOLDIER:
			order.append_array(_BACK_LIMBS + _BACK_ARM + _FRONT_LEG)
			order.append_array([&"hem", &"torso", &"head", &"weapon"])
			order.append_array(_FRONT_ARM)
		InkFigure.Kind.ONI_BRUTE:
			order.append(&"mane")
			order.append_array(_BACK_LIMBS + _BACK_ARM + _FRONT_LEG)
			order.append_array([&"torso", &"head", &"weapon"])
			order.append_array(_FRONT_ARM)
	order.append_array(_HANDS)
	return order


## The cached shapes of one part of a kind (built on first use). Null for dynamic parts.
static func part(kind: InkFigure.Kind, part_name: StringName) -> InkBatch:
	if not _parts.has(kind):
		_parts[kind] = _build(kind)
	return (_parts[kind] as Dictionary).get(part_name, null) as InkBatch


## Glowing spots of a kind: each { part, points (part space), radius (units), color, follows }.
## follows = &"fall" (fades as the body falls) or &"pose_glow" (the spirit blade's glow).
static func glows(kind: InkFigure.Kind) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match kind:
		InkFigure.Kind.SAMURAI:
			var blade: PackedVector2Array = PackedVector2Array()
			var along: float = 6.0
			while along <= 72.0:
				blade.append(Vector2(along, -1.5))
				along += 6.0
			result.append(_glow(&"weapon", blade, 13.0, Color(InkPalette.SPIRIT, 0.32), &"pose_glow"))
		InkFigure.Kind.HOLLOW_SOLDIER:
			result.append(_glow(&"head", PackedVector2Array([Vector2(5.5, -9.0)]), 6.0, Color(InkPalette.HOLLOW_PURPLE, 0.95), &"fall"))
			result.append(_glow(&"head", PackedVector2Array([Vector2(2.0, -9.5)]), 5.0, Color(InkPalette.HOLLOW_PURPLE, 0.85), &"fall"))
		InkFigure.Kind.ONI_BRUTE:
			result.append(_glow(&"torso", PackedVector2Array([Vector2(0.0, -26.0)]), 46.0, Color(InkPalette.ONI_EMBER, 0.16), &"fall"))
			result.append(_glow(&"torso", PackedVector2Array([Vector2(6.0, -37.0), Vector2(8.0, -31.0), Vector2(8.5, -24.0),
					Vector2(-4.0, -28.0), Vector2(-3.5, -21.0)]), 7.0, Color(InkPalette.ONI_EMBER, 0.3), &"fall"))
			result.append(_glow(&"head", PackedVector2Array([Vector2(7.0, -8.0)]), 5.0, Color(InkPalette.ONI_EMBER, 0.95), &"fall"))
			result.append(_glow(&"head", PackedVector2Array([Vector2(3.0, -8.5)]), 4.5, Color(InkPalette.ONI_EMBER, 0.85), &"fall"))
			result.append(_glow(&"head", PackedVector2Array([Vector2(6.0, -1.5)]), 4.5, Color(InkPalette.ONI_EMBER, 0.7), &"fall"))
	return result


static func _glow(part_name: StringName, points: PackedVector2Array, radius: float, color: Color, follows: StringName) -> Dictionary:
	return {"part": part_name, "points": points, "radius": radius, "color": color, "follows": follows}


## x of the bow string's nock point in bow space for a draw amount (0 = rest).
static func bow_nock_x(draw_amount: float) -> float:
	return lerpf(_bow_bend(1.0, draw_amount), -30.0, clampf(draw_amount, 0.0, 1.0))


## The bow (limbs, string, nocked arrow) at a draw amount, cached per draw step.
static func bow(draw_amount: float) -> InkBatch:
	return _bow(draw_amount)


static func bow_step(draw_amount: float) -> int:
	return clampi(roundi(draw_amount * BOW_STEPS), 0, BOW_STEPS)


## Draws a part whose shape changes every frame (one of DYNAMIC_PARTS) into ci, in the part's
## slot space.
static func paint_dynamic(fig: InkFigure, part_name: StringName, ci: CanvasItem) -> void:
	match part_name:
		&"tails":
			if fig.kind == InkFigure.Kind.SAMURAI:
				_paint_cloth_tails(fig, ci, fig.torso_xf * Vector2(-3.0, -33.0), InkPalette.SAMURAI_RED, [6, 5], 5.2, 4.6)
			else:
				_paint_cloth_tails(fig, ci, fig.head_xf * Vector2(-6.0, -9.5), InkPalette.ARCHER_TEAL, [4, 3], 4.0, 3.4)
		&"hem":
			_paint_hem(fig, ci)


## Tattered skirt with a fluttering ragged hem (torso space).
static func _paint_hem(fig: InkFigure, ci: CanvasItem) -> void:
	var hem: PackedVector2Array = PackedVector2Array([Vector2(-10.0, -3.0), Vector2(10.0, -3.0)])
	var hem_points: Array[Vector2] = [Vector2(12.0, 8.0), Vector2(8.0, 14.0), Vector2(5.0, 9.0),
			Vector2(1.0, 15.0), Vector2(-3.0, 10.0), Vector2(-7.0, 14.5), Vector2(-11.0, 9.0)]
	for i: int in hem_points.size():
		var flutter: float = sin(fig.clock * 7.0 + float(i) * 1.7) * 1.5 * (0.4 + fig.trail)
		hem.append(hem_points[i] + Vector2(-fig.trail * 2.0 * float(i % 2), flutter))
	var batch: InkBatch = InkBatch.new()
	batch.fill_fan(Vector2(0.0, 4.0), hem, InkPalette.INK)
	batch.draw(ci)


## Two or more cloth tails (scarf, headband) streaming backward from base (local pixels).
static func _paint_cloth_tails(fig: InkFigure, ci: CanvasItem, base: Vector2, color: Color, segment_counts: Array,
		width: float, segment: float) -> void:
	var s: float = fig.get_unit_scale()
	var batch: InkBatch = InkBatch.new()
	for tail: int in segment_counts.size():
		var count: int = segment_counts[tail]
		var points: PackedVector2Array = PackedVector2Array([base])
		var phase: float = float(tail) * 1.9
		for i: int in range(1, count + 1):
			var k: float = float(i)
			var stream: Vector2 = Vector2(-k * (0.55 + 0.55 * fig.trail), k * (0.85 - 0.6 * fig.trail) + float(tail) * k * 0.25)
			var wave: float = sin(fig.clock * (7.0 + fig.trail * 6.0) - k * 0.9 + phase) * k * 0.45 * (0.35 + fig.trail)
			points.append(base + (stream * segment + Vector2(0.0, wave)) * s)
		batch.stroke(points, width * s, 1.4 * s, color)
	batch.draw(ci)


# --- Part geometry (built once per kind) -----------------------------------

static func _build(kind: InkFigure.Kind) -> Dictionary:
	var spec: FigureKinds.Spec = FigureKinds.spec(kind)
	var parts: Dictionary = {}
	for front: bool in [true, false]:
		var color: Color = InkPalette.INK if front else InkPalette.INK_BACK
		var suffix: String = "_f" if front else "_b"
		parts[StringName("thigh" + suffix)] = _segment(spec.thigh, spec.thigh_w, color)
		parts[StringName("shin" + suffix)] = _segment(spec.shin, spec.shin_w, color)
		parts[StringName("upper" + suffix)] = _segment(spec.upper_arm, spec.arm_w, color)
		parts[StringName("fore" + suffix)] = _segment(spec.fore_arm, spec.fore_w, color)
		var foot: InkBatch = InkBatch.new()
		foot.fill_convex(PackedVector2Array([Vector2(-3.5, -1.0), Vector2(3.0, -1.5), Vector2(spec.foot, 2.5),
				Vector2(-3.5, 2.5)]), color)
		parts[StringName("foot" + suffix)] = foot
		var hand: InkBatch = InkBatch.new()
		hand.circle(Vector2.ZERO, spec.hand_r, color)
		parts[StringName("hand" + suffix)] = hand
	var shadow: InkBatch = InkBatch.new()
	shadow.ellipse(Vector2.ZERO, Vector2(spec.shadow_width, 3.2), Color(InkPalette.INK, InkFigure.SHADOW_ALPHA))
	parts[&"shadow"] = shadow
	match kind:
		InkFigure.Kind.SAMURAI:
			_build_samurai(parts)
		InkFigure.Kind.ASHIGARU:
			_build_ashigaru(parts)
		InkFigure.Kind.YUMI_ARCHER:
			_build_archer(parts)
		InkFigure.Kind.HOLLOW_SOLDIER:
			_build_hollow(parts)
		InkFigure.Kind.ONI_BRUTE:
			_build_oni(parts)
	return parts


## A limb segment from (0,0) to (length,0); drawn stretched between two joints.
static func _segment(length: float, widths: Vector2, color: Color) -> InkBatch:
	var batch: InkBatch = InkBatch.new()
	batch.limb(Vector2.ZERO, Vector2(length, 0.0), widths.x, widths.y, color)
	return batch


static func _build_samurai(parts: Dictionary) -> void:
	var ink: Color = InkPalette.INK
	var detail: Color = InkPalette.INK_DETAIL
	var red: Color = InkPalette.SAMURAI_RED
	var spec: FigureKinds.Spec = FigureKinds.spec(InkFigure.Kind.SAMURAI)
	var leg: float = spec.thigh + spec.shin

	# Hakama: each leg is a wide wedge from the hip flaring to a hem on the ground; the two
	# together (plus the front panel on the torso) make the triangle from waist to feet.
	for front: bool in [true, false]:
		var hakama: InkBatch = InkBatch.new()
		var color: Color = ink if front else InkPalette.INK_BACK
		hakama.fill(PackedVector2Array([Vector2(-3.0, -6.0), Vector2(leg * 0.5, -9.5), Vector2(leg + 1.5, -16.5),
				Vector2(leg + 3.5, -15.0), Vector2(leg + 3.5, 15.0), Vector2(leg + 1.5, 16.5), Vector2(leg * 0.5, 9.5),
				Vector2(-3.0, 6.0)]), color)
		if front:
			hakama.limb(Vector2(leg * 0.35, 2.5), Vector2(leg + 2.0, 6.0), 1.8, 2.2, detail)
			hakama.limb(Vector2(leg * 0.35, -2.5), Vector2(leg + 2.0, -6.0), 1.8, 2.2, detail)
		parts[&"hakama_f" if front else &"hakama_b"] = hakama

	# Sode: three overlapping lames hanging from the shoulder, wider toward the bottom.
	parts[&"pauldron_front"] = _sode(Vector2.ZERO, ink, detail)
	parts[&"pauldron_back"] = _sode(spec.shoulder_back + Vector2(-2.0, -1.0), InkPalette.INK_BACK, InkPalette.INK_BACK)

	var torso: InkBatch = InkBatch.new()
	# Front panel of the hakama, below the armour skirt.
	torso.fill_convex(PackedVector2Array([Vector2(-11.0, -3.0), Vector2(11.0, -3.0), Vector2(19.0, 30.0),
			Vector2(-19.0, 30.0)]), ink)
	# Kusazuri (armour skirt).
	torso.fill_convex(PackedVector2Array([Vector2(-12.0, -5.0), Vector2(12.0, -5.0), Vector2(16.5, 13.0),
			Vector2(-15.5, 13.0)]), ink)
	for x: float in [-6.0, 0.0, 6.0]:
		torso.limb(Vector2(x, -1.0), Vector2(x * 1.25, 11.0), 2.0, 2.0, detail)
	torso.limb(Vector2(-13.0, 5.0), Vector2(14.0, 5.0), 2.0, 2.0, detail)
	# Do: tapered chest armour, broad at the shoulders, narrow at the waist.
	torso.fill(PackedVector2Array([Vector2(-9.0, -3.0), Vector2(9.0, -3.0), Vector2(14.0, -21.0),
			Vector2(14.0, -30.0), Vector2(6.0, -34.5), Vector2(-7.0, -34.5), Vector2(-13.5, -30.0), Vector2(-13.0, -20.0)]), ink)
	for y: float in [-11.0, -18.0, -25.0]:
		torso.limb(Vector2(-10.0 - (y + 11.0) * 0.12, y), Vector2(11.0 - (y + 11.0) * 0.2, y), 2.0, 2.0, detail)
	# Sash knot (accent).
	torso.fill_convex(PackedVector2Array([Vector2(7.0, -3.5), Vector2(13.5, -6.5), Vector2(12.5, -0.5)]), red)
	torso.fill_convex(PackedVector2Array([Vector2(7.0, -3.5), Vector2(12.0, 3.5), Vector2(8.0, 4.5)]), red)
	torso.circle(Vector2(8.0, -3.0), 2.4, red)
	parts[&"torso"] = torso

	# Saya (scabbard) at the left hip, angled back and down, with the wakizashi hilt beside it.
	var saya: InkBatch = InkBatch.new()
	saya.stroke(PackedVector2Array([Vector2(5.0, -5.0), Vector2(-10.0, 2.0), Vector2(-24.0, 9.5),
			Vector2(-33.0, 15.0)]), 4.8, 4.0, ink)
	saya.limb(Vector2(3.5, -6.5), Vector2(1.5, -2.5), 1.8, 1.8, detail)
	saya.limb(Vector2(4.0, -6.0), Vector2(12.0, -10.0), 3.6, 3.4, ink)
	saya.ellipse(Vector2(4.5, -6.2), Vector2(1.4, 3.2), ink, 10)
	parts[&"saya"] = saya

	var head: InkBatch = InkBatch.new()
	head.limb(Vector2(0.0, 0.0), Vector2(0.5, -4.0), 6.0, 6.0, ink)
	head.ellipse(Vector2(2.0, -8.5), Vector2(6.5, 7.0), ink)
	# Menpo: chin guard.
	head.fill_convex(PackedVector2Array([Vector2(4.0, -6.5), Vector2(10.5, -5.5), Vector2(9.0, -0.5), Vector2(3.0, 0.5)]), ink)
	# Shikoro: lamed neck guard sweeping back and down over the shoulders.
	head.fill(PackedVector2Array([Vector2(6.0, -12.0), Vector2(7.5, -9.0), Vector2(-1.0, -7.5), Vector2(-9.0, -3.5),
			Vector2(-17.5, 1.5), Vector2(-19.0, -2.5), Vector2(-13.0, -9.5), Vector2(-6.0, -13.0)]), ink)
	head.limb(Vector2(-3.0, -9.5), Vector2(-15.0, -1.5), 1.8, 1.8, detail)
	head.limb(Vector2(-5.0, -12.0), Vector2(-16.0, -5.0), 1.8, 1.8, detail)
	# Kabuto bowl, visor and fukigaeshi turn-backs.
	var bowl: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var angle: float = PI + PI * float(i) / 12.0
		bowl.append(Vector2(1.0, -11.0) + Vector2(cos(angle) * 9.5, sin(angle) * 9.0))
	head.fill_convex(bowl, ink)
	head.fill_convex(PackedVector2Array([Vector2(6.0, -12.5), Vector2(15.0, -10.5), Vector2(14.0, -8.5), Vector2(6.0, -10.0)]), ink)
	head.fill_convex(PackedVector2Array([Vector2(4.0, -13.0), Vector2(8.5, -19.5), Vector2(11.5, -13.0)]), ink)
	head.limb(Vector2(-7.0, -11.5), Vector2(9.5, -11.5), 1.8, 1.8, detail)
	# Maedate: a large crescent crest rising from the front of the helmet.
	var crest_center: Vector2 = Vector2(6.0, -28.0)
	var left: PackedVector2Array = PackedVector2Array()
	var right: PackedVector2Array = PackedVector2Array()
	for i: int in 9:
		var t: float = float(i) / 8.0
		left.append(crest_center + Vector2.from_angle(lerpf(PI + 0.4, PI * 0.5, t)) * 11.0)
		right.append(crest_center + Vector2.from_angle(lerpf(PI * 0.5, -0.4, t)) * 11.0)
	head.stroke(left, 1.2, 4.8, ink)
	head.stroke(right, 4.8, 1.2, ink)
	head.limb(Vector2(5.5, -19.0), crest_center + Vector2(0.0, 10.5), 3.0, 3.0, ink)
	parts[&"head"] = head

	var wrap: InkBatch = InkBatch.new()
	wrap.ellipse(Vector2(1.5, -34.5), Vector2(7.0, 3.4), red)
	parts[&"neck_wrap"] = wrap

	var katana: InkBatch = InkBatch.new()
	katana.limb(Vector2(-11.0, 0.0), Vector2(1.0, 0.0), 3.8, 3.8, ink)
	katana.ellipse(Vector2(1.8, 0.0), Vector2(1.7, 4.2), ink, 10)
	var tip: float = 3.0 + KATANA_LENGTH
	katana.fill(PackedVector2Array([Vector2(3.0, -1.9), Vector2(30.0, -2.7), Vector2(55.0, -3.4),
			Vector2(tip, -4.2), Vector2(56.0, -0.9), Vector2(30.0, 0.5), Vector2(3.0, 1.7)]), ink)
	katana.stroke(PackedVector2Array([Vector2(5.0, 1.1), Vector2(30.0, 0.0), Vector2(55.0, -1.3),
			Vector2(tip - 3.0, -3.3)]), 1.9, 1.2, InkPalette.STEEL)
	parts[&"weapon"] = katana

	var glow: InkBatch = InkBatch.new()
	glow.stroke(PackedVector2Array([Vector2(4.0, -0.4), Vector2(30.0, -1.2), Vector2(55.0, -2.3),
			Vector2(tip - 1.0, -3.8)]), 2.6, 1.6, InkPalette.SPIRIT)
	parts[&"blade_glow"] = glow


## Sode: three overlapping lames from `origin` (the shoulder), each wider than the one above.
static func _sode(origin: Vector2, color: Color, line_color: Color) -> InkBatch:
	var sode: InkBatch = InkBatch.new()
	for i: int in 3:
		var y0: float = -4.0 + float(i) * 7.5
		var y1: float = y0 + 8.5
		var left: float = -7.0 - float(i) * 1.2
		var right: float = 8.0 + float(i) * 1.8
		sode.fill_convex(PackedVector2Array([origin + Vector2(left, y0), origin + Vector2(right, y0),
				origin + Vector2(right + 1.2, y1), origin + Vector2(left - 0.6, y1)]), color)
		if i < 2:
			sode.limb(origin + Vector2(left, y1 - 0.4), origin + Vector2(right + 1.0, y1 - 0.4), 1.8, 1.8, line_color)
	return sode


static func _build_ashigaru(parts: Dictionary) -> void:
	var ink: Color = InkPalette.INK
	var gold: Color = InkPalette.ASHIGARU_GOLD
	var torso: InkBatch = InkBatch.new()
	torso.fill_convex(PackedVector2Array([Vector2(-11.0, -3.0), Vector2(11.0, -3.0), Vector2(13.0, 9.0),
			Vector2(-12.0, 9.0)]), ink)
	torso.fill(PackedVector2Array([Vector2(-9.0, -1.0), Vector2(9.5, -1.0), Vector2(11.0, -18.0),
			Vector2(10.0, -29.0), Vector2(3.0, -31.5), Vector2(-7.0, -31.0), Vector2(-10.5, -18.0)]), ink)
	torso.limb(Vector2(-8.0, -14.0), Vector2(10.0, -14.0), 2.0, 2.0, InkPalette.INK_DETAIL)
	torso.fill_convex(PackedVector2Array([Vector2(-10.5, -1.0), Vector2(10.5, -1.0), Vector2(10.8, -5.0),
			Vector2(-10.8, -5.0)]), gold)
	parts[&"torso"] = torso

	var head: InkBatch = InkBatch.new()
	head.limb(Vector2(0.0, 0.0), Vector2(0.5, -4.0), 5.5, 5.5, ink)
	head.ellipse(Vector2(1.0, -8.5), Vector2(6.5, 7.5), ink)
	# Jingasa: wide shallow cone with a gold rim.
	head.fill(PackedVector2Array([Vector2(-22.0, -6.0), Vector2(-9.0, -12.5), Vector2(0.5, -17.5),
			Vector2(10.0, -12.5), Vector2(23.0, -6.0), Vector2(21.5, -4.0), Vector2(-20.5, -4.0)]), ink)
	head.stroke(PackedVector2Array([Vector2(-21.0, -4.6), Vector2(0.0, -5.4), Vector2(22.0, -4.6)]), 2.6, 2.6, gold)
	parts[&"head"] = head

	var yari: InkBatch = InkBatch.new()
	yari.limb(Vector2(-44.0, 0.0), Vector2(64.0, 0.0), 3.4, 3.2, ink)
	yari.fill_convex(PackedVector2Array([Vector2(63.0, -2.2), Vector2(72.0, -3.2), Vector2(84.0, 0.0),
			Vector2(72.0, 3.2), Vector2(63.0, 2.2)]), ink)
	yari.limb(Vector2(66.0, 0.0), Vector2(81.0, 0.0), 1.6, 1.0, InkPalette.STEEL)
	# Tassel under the spearhead (accent).
	yari.stroke(PackedVector2Array([Vector2(60.0, 0.0), Vector2(59.0, 4.0), Vector2(57.5, 8.0)]), 4.5, 1.8, gold)
	parts[&"weapon"] = yari


static func _build_archer(parts: Dictionary) -> void:
	var ink: Color = InkPalette.INK
	var teal: Color = InkPalette.ARCHER_TEAL
	# Quiver over the back shoulder, fletching above it (accent).
	var quiver: InkBatch = InkBatch.new()
	quiver.limb(Vector2(-10.0, -32.0), Vector2(-5.0, -5.0), 6.5, 5.5, InkPalette.INK_BACK)
	for tip: Vector2 in [Vector2(-14.5, -42.0), Vector2(-11.5, -43.5), Vector2(-8.5, -42.5)]:
		quiver.limb(Vector2(-10.0, -32.0), tip, 2.0, 2.0, InkPalette.INK_BACK)
		quiver.limb(tip, tip + (tip - Vector2(-10.0, -32.0)).normalized() * 3.5, 3.4, 2.2, teal)
	parts[&"quiver"] = quiver

	var torso: InkBatch = InkBatch.new()
	torso.fill(PackedVector2Array([Vector2(-9.0, -2.0), Vector2(9.0, -2.0), Vector2(10.5, -18.0),
			Vector2(9.0, -29.0), Vector2(2.0, -31.5), Vector2(-7.0, -30.0), Vector2(-10.0, -18.0)]), ink)
	torso.limb(Vector2(-5.0, -29.0), Vector2(6.0, -12.0), 2.0, 2.0, InkPalette.INK_DETAIL)
	torso.fill_convex(PackedVector2Array([Vector2(-10.0, -1.0), Vector2(10.0, -1.0), Vector2(10.3, -4.2),
			Vector2(-10.3, -4.2)]), teal)
	parts[&"torso"] = torso

	var head: InkBatch = InkBatch.new()
	head.limb(Vector2(0.0, 0.0), Vector2(0.5, -4.0), 5.5, 5.5, ink)
	head.ellipse(Vector2(1.0, -8.5), Vector2(6.5, 7.5), ink)
	head.stroke(PackedVector2Array([Vector2(-4.0, -13.0), Vector2(-0.5, -16.5), Vector2(4.0, -16.0)]), 4.0, 2.8, ink)
	head.fill_convex(PackedVector2Array([Vector2(-6.5, -11.5), Vector2(7.5, -11.5), Vector2(7.5, -8.5),
			Vector2(-6.5, -8.5)]), teal)
	parts[&"head"] = head


static func _bow_bend(t: float, draw_amount: float) -> float:
	return -(3.0 + 7.0 * clampf(draw_amount, 0.0, 1.0)) * t * t + (2.0 * t * t * t * t if t > 0.8 else 0.0)


## The bow (limbs, string, nocked arrow) at a draw amount, cached per draw step.
static func _bow(draw_amount: float) -> InkBatch:
	var step: int = bow_step(draw_amount)
	if _bows.has(step):
		return _bows[step]
	var drawn: float = float(step) / float(BOW_STEPS)
	var ink: Color = InkPalette.INK
	var batch: InkBatch = InkBatch.new()
	var upper: PackedVector2Array = PackedVector2Array()
	var lower: PackedVector2Array = PackedVector2Array()
	for i: int in 9:
		var t: float = float(i) / 8.0
		upper.append(Vector2(_bow_bend(t, drawn), -t * BOW_UPPER))
		lower.append(Vector2(_bow_bend(t, drawn), t * BOW_LOWER))
	var nock: Vector2 = Vector2(bow_nock_x(drawn), 0.0)
	# String first so the limbs cover its ends.
	batch.stroke(PackedVector2Array([upper[8], nock, lower[8]]), 1.4, 1.4, ink)
	batch.stroke(upper, 5.0, 3.2, ink)
	batch.stroke(lower, 5.0, 3.2, ink)
	if drawn > 0.25:
		var alpha: float = clampf((drawn - 0.25) * 2.5, 0.0, 1.0)
		var head: float = nock.x + 44.0
		batch.limb(nock, Vector2(head, 0.0), 2.2, 2.2, Color(ink, alpha))
		batch.fill_convex(PackedVector2Array([Vector2(head - 1.0, -2.6), Vector2(head + 5.0, 0.0),
				Vector2(head - 1.0, 2.6)]), Color(ink, alpha))
		var teal: Color = Color(InkPalette.ARCHER_TEAL, alpha)
		batch.fill_convex(PackedVector2Array([nock + Vector2(1.0, 0.0), nock + Vector2(8.0, 0.0),
				nock + Vector2(4.0, -3.4)]), teal)
		batch.fill_convex(PackedVector2Array([nock + Vector2(1.0, 0.0), nock + Vector2(8.0, 0.0),
				nock + Vector2(4.0, 3.4)]), teal)
	_bows[step] = batch
	return batch


static func _build_hollow(parts: Dictionary) -> void:
	var ink: Color = InkPalette.INK
	var detail: Color = InkPalette.INK_DETAIL
	# Broken cuirass with a chunk torn out of the chest.
	var torso: InkBatch = InkBatch.new()
	torso.fill(PackedVector2Array([Vector2(-8.0, -2.0), Vector2(8.0, -2.0), Vector2(9.5, -12.0),
			Vector2(6.5, -16.0), Vector2(11.0, -19.0), Vector2(12.0, -26.0), Vector2(8.0, -31.0),
			Vector2(-3.0, -32.5), Vector2(-9.0, -25.0), Vector2(-10.0, -12.0)]), ink)
	torso.limb(Vector2(-6.0, -22.0), Vector2(3.0, -24.0), 2.0, 2.0, detail)
	torso.limb(Vector2(-6.5, -16.0), Vector2(2.0, -17.0), 2.0, 2.0, detail)
	parts[&"torso"] = torso

	var head: InkBatch = InkBatch.new()
	head.limb(Vector2(0.0, 0.0), Vector2(1.0, -4.0), 4.5, 4.5, ink)
	head.ellipse(Vector2(2.0, -8.5), Vector2(6.0, 7.5), ink)
	head.fill_convex(PackedVector2Array([Vector2(3.0, -5.0), Vector2(8.5, -4.0), Vector2(7.5, 0.5), Vector2(2.0, 0.0)]), ink)
	# Helmet: dome, ragged neck guard, one tall crest prong and one snapped stub.
	head.fill(PackedVector2Array([Vector2(-7.5, -9.0), Vector2(-6.5, -14.5), Vector2(0.0, -18.0),
			Vector2(6.5, -15.5), Vector2(8.5, -10.5)]), ink)
	head.fill(PackedVector2Array([Vector2(-7.0, -11.0), Vector2(-12.0, -6.0), Vector2(-9.5, -5.0),
			Vector2(-10.5, -2.0), Vector2(-5.0, -6.0)]), ink)
	head.stroke(PackedVector2Array([Vector2(1.5, -16.5), Vector2(4.5, -25.0), Vector2(9.0, -30.0)]), 3.4, 1.8, ink)
	head.stroke(PackedVector2Array([Vector2(-1.0, -16.5), Vector2(-3.5, -21.5)]), 3.4, 2.8, ink)
	# Eye cores; the halo is on the glow layer (accent).
	var eye: Color = InkPalette.HOLLOW_PURPLE.lerp(InkPalette.PAPER, 0.45)
	head.circle(Vector2(5.5, -9.0), 1.5, eye)
	head.circle(Vector2(2.0, -9.5), 1.3, eye)
	parts[&"head"] = head

	var sword: InkBatch = InkBatch.new()
	sword.limb(Vector2(-7.0, 0.0), Vector2(1.0, 0.0), 3.4, 3.4, ink)
	sword.ellipse(Vector2(1.5, 0.0), Vector2(1.4, 3.2), ink, 10)
	sword.fill(PackedVector2Array([Vector2(2.0, -1.9), Vector2(20.0, -2.3), Vector2(23.5, -1.0),
			Vector2(27.0, -2.5), Vector2(44.0, -2.7), Vector2(51.0, -0.4), Vector2(44.0, 1.1),
			Vector2(32.0, 1.5), Vector2(29.0, 0.3), Vector2(26.0, 1.7), Vector2(2.0, 1.9)]), ink)
	sword.limb(Vector2(8.0, 0.0), Vector2(18.0, -0.3), 1.6, 1.4, detail)
	parts[&"weapon"] = sword


static func _build_oni(parts: Dictionary) -> void:
	var ink: Color = InkPalette.INK
	var back: Color = InkPalette.INK_BACK
	var detail: Color = InkPalette.INK_DETAIL
	var ember: Color = InkPalette.ONI_EMBER.lerp(InkPalette.PAPER, 0.25)
	# Wild mane and the far horn, behind everything (head space).
	var mane: InkBatch = InkBatch.new()
	mane.fill(PackedVector2Array([Vector2(-2.0, -14.0), Vector2(-11.0, -16.0), Vector2(-8.0, -11.0),
			Vector2(-16.0, -9.0), Vector2(-10.0, -6.0), Vector2(-15.0, -1.0), Vector2(-6.0, -1.0),
			Vector2(-4.0, 4.0), Vector2(2.0, -6.0)]), back)
	mane.stroke(PackedVector2Array([Vector2(-1.0, -11.0), Vector2(-4.5, -18.0), Vector2(-4.5, -25.0),
			Vector2(-7.5, -29.5)]), 5.0, 1.8, back)
	parts[&"mane"] = mane

	var torso: InkBatch = InkBatch.new()
	# Tiger-hide loincloth.
	torso.fill(PackedVector2Array([Vector2(-15.0, -4.0), Vector2(15.0, -4.0), Vector2(17.0, 6.0),
			Vector2(11.0, 13.0), Vector2(3.0, 9.0), Vector2(-5.0, 14.0), Vector2(-13.0, 8.0)]), ink)
	for x: float in [-8.0, 0.0, 8.0]:
		torso.limb(Vector2(x - 2.0, -1.0), Vector2(x + 2.0, 7.0), 2.2, 1.4, detail)
	# Barrel torso.
	torso.fill(PackedVector2Array([Vector2(-14.0, -2.0), Vector2(14.0, -2.0), Vector2(20.0, -14.0),
			Vector2(25.0, -30.0), Vector2(21.0, -43.0), Vector2(10.0, -48.0), Vector2(-6.0, -49.0),
			Vector2(-19.0, -44.0), Vector2(-23.0, -28.0), Vector2(-19.0, -12.0)]), ink)
	torso.limb(Vector2(-4.0, -14.0), Vector2(10.0, -14.0), 2.2, 2.2, detail)
	# Ember cracks across the chest (accent; glow halo on the glow layer).
	torso.stroke(PackedVector2Array([Vector2(4.0, -39.0), Vector2(9.0, -33.0), Vector2(6.5, -28.0),
			Vector2(11.0, -21.0)]), 2.4, 1.2, ember)
	torso.stroke(PackedVector2Array([Vector2(-6.0, -31.0), Vector2(-2.0, -25.5), Vector2(-5.0, -19.0)]), 2.2, 1.0, ember)
	parts[&"torso"] = torso

	var head: InkBatch = InkBatch.new()
	head.ellipse(Vector2(3.0, -6.5), Vector2(7.5, 7.5), ink)
	head.fill_convex(PackedVector2Array([Vector2(0.0, -4.0), Vector2(11.5, -4.0), Vector2(10.5, 2.5), Vector2(1.0, 2.5)]), ink)
	head.fill_convex(PackedVector2Array([Vector2(8.0, -3.0), Vector2(10.0, -3.0), Vector2(9.0, -7.0)]), ink)
	head.stroke(PackedVector2Array([Vector2(5.0, -11.0), Vector2(9.0, -17.0), Vector2(10.0, -25.0),
			Vector2(7.0, -30.5)]), 5.5, 1.8, ink)
	head.circle(Vector2(7.0, -8.0), 1.6, ember)
	head.circle(Vector2(3.0, -8.5), 1.4, ember)
	head.limb(Vector2(3.5, -1.5), Vector2(9.5, -1.5), 1.4, 1.2, ember)
	parts[&"head"] = head

	var club: InkBatch = InkBatch.new()
	club.limb(Vector2(-13.0, 0.0), Vector2(5.0, 0.0), 4.6, 4.6, ink)
	club.circle(Vector2(-14.5, 0.0), 3.2, ink)
	club.fill_convex(PackedVector2Array([Vector2(4.0, -3.6), Vector2(60.0, -6.4), Vector2(66.0, -5.0),
			Vector2(66.0, 5.0), Vector2(60.0, 6.4), Vector2(4.0, 3.6)]), ink)
	# Iron studs break the club's outline.
	var x: float = 16.0
	while x <= 58.0:
		var half: float = lerpf(3.6, 6.4, (x - 4.0) / 56.0)
		club.circle(Vector2(x, -half), 1.9, ink)
		club.circle(Vector2(x + 4.0, half), 1.9, ink)
		x += 9.0
	parts[&"weapon"] = club
