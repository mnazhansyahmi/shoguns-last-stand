class_name FigurePainter
extends RefCounted
## Per-kind costume drawing for InkFigure: body shapes, headgear, weapons and the one accent.
## Each body part is built ONCE per kind into an InkBatch in the part's own space (torso, head,
## weapon, limb segment...). InkFigure keeps one child node per part (layout) that draws its
## batch once; a frame only moves those nodes. Only cloth tails are redrawn each frame; the
## bow and the Hollow Soldier's fluttering hem swap between cached shapes.
## Coordinates are figure units (see FigureKinds).

const KATANA_LENGTH: float = 70.0
const BOW_UPPER: float = 64.0
const BOW_LOWER: float = 34.0
## The bow's shape is cached at this many draw positions.
const BOW_STEPS: int = 12
## The Hollow Soldier's hem flutter is cached at this many phases (and three wind levels).
const HEM_STEPS: int = 12
const HEM_FLUTTER_SPEED: float = 7.0

## Kind -> { part name -> InkBatch }.
static var _parts: Dictionary = {}
## Bow draw step -> InkBatch.
static var _bows: Dictionary = {}
## Hem key (hem_key) -> InkBatch.
static var _hems: Dictionary = {}


## Body part slots: where a part sits each frame (InkFigure computes one transform per slot).
enum Slot { SHADOW, MARKER, LOCAL, THIGH_F, SHIN_F, FOOT_F, THIGH_B, SHIN_B, FOOT_B, UPPER_F, FORE_F,
		HAND_F, UPPER_B, FORE_B, HAND_B, TORSO, HEAD, WEAPON, PAULDRON_FRONT, HAKAMA_F, HAKAMA_B, SKIRT,
		PAULDRON_BACK }

## Part name -> slot. Every part in a layout must be listed.
const SLOTS: Dictionary = {
	&"marker": Slot.MARKER, &"shadow": Slot.SHADOW, &"tails": Slot.LOCAL,
	&"thigh_f": Slot.THIGH_F, &"shin_f": Slot.SHIN_F, &"foot_f": Slot.FOOT_F,
	&"thigh_b": Slot.THIGH_B, &"shin_b": Slot.SHIN_B, &"foot_b": Slot.FOOT_B,
	&"upper_f": Slot.UPPER_F, &"fore_f": Slot.FORE_F, &"hand_f": Slot.HAND_F,
	&"upper_b": Slot.UPPER_B, &"fore_b": Slot.FORE_B, &"hand_b": Slot.HAND_B,
	&"torso": Slot.TORSO, &"pauldron_back": Slot.PAULDRON_BACK, &"neck_wrap": Slot.TORSO, &"quiver": Slot.TORSO, &"hem": Slot.TORSO,
	&"skirt": Slot.SKIRT, &"sleeve_f": Slot.LOCAL, &"sleeve_b": Slot.LOCAL,
	&"shield": Slot.HAND_B, &"banner": Slot.TORSO,
	&"head": Slot.HEAD, &"mane": Slot.HEAD,
	&"weapon": Slot.WEAPON, &"bow": Slot.WEAPON, &"blade_glow": Slot.WEAPON,
	&"pauldron_front": Slot.PAULDRON_FRONT, &"saya": Slot.TORSO,
	&"hakama_f": Slot.HAKAMA_F, &"hakama_b": Slot.HAKAMA_B,
}
## Parts whose shape changes every frame (redrawn through paint_dynamic).
const DYNAMIC_PARTS: Array[StringName] = [&"tails", &"sleeve_f", &"sleeve_b"]

# Feet are part of the shin and hands part of the forearm (fewer canvas items per figure).
const _BACK_LIMBS: Array[StringName] = [&"thigh_b", &"shin_b"]
const _BACK_ARM: Array[StringName] = [&"upper_b", &"fore_b"]
const _FRONT_LEG: Array[StringName] = [&"thigh_f", &"shin_f"]
const _FRONT_ARM: Array[StringName] = [&"upper_f", &"fore_f"]


## Draw order of a kind's parts, back to front.
static func layout(kind: InkFigure.Kind) -> Array[StringName]:
	# The ground shadow is drawn by the InkFigure node itself (one canvas item fewer per figure).
	var order: Array[StringName] = []
	match kind:
		InkFigure.Kind.SAMURAI:
			# The hakama hem reaches the ground, so the samurai has no separate feet. The skirt part
			# is the hakama's front panel, the tassets, the sash and the scabbard (they swing together);
			# the scarf (drawn over the neck guard so its red shows) and sleeve flaps are cloth chains.
			order.append_array([&"sleeve_b", &"hakama_b", &"pauldron_back"])
			order.append_array(_BACK_ARM)
			order.append_array([&"hakama_f", &"skirt", &"torso", &"head", &"tails"])
			order.append_array(_FRONT_ARM)
			order.append_array([&"sleeve_f", &"pauldron_front", &"weapon", &"blade_glow"])
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
		InkFigure.Kind.SHRINE_HEALER, InkFigure.Kind.ONMYOJI:
			# Long sleeves hang from the arms as cloth flaps; the healer's ponytail is the mane.
			if kind == InkFigure.Kind.SHRINE_HEALER:
				order.append(&"mane")
			order.append_array(_BACK_LIMBS + _BACK_ARM)
			order.append_array([&"sleeve_b"] + _FRONT_LEG)
			order.append_array([&"torso", &"head", &"weapon"])
			order.append_array(_FRONT_ARM)
			order.append(&"sleeve_f")
		InkFigure.Kind.SPEAR_GUARDIAN:
			order.append_array(_BACK_LIMBS + [&"pauldron_back"] + _BACK_ARM + _FRONT_LEG)
			order.append_array([&"torso", &"head", &"shield"])
			order.append_array(_FRONT_ARM)
			order.append_array([&"pauldron_front", &"weapon"])
		InkFigure.Kind.HATAMOTO:
			# The banner is on his back, behind everything; he wears the samurai's hakama and skirt.
			order.append_array([&"banner", &"hakama_b", &"pauldron_back"])
			order.append_array(_BACK_ARM)
			order.append_array([&"hakama_f", &"skirt", &"torso", &"head"])
			order.append_array(_FRONT_ARM)
			order.append_array([&"pauldron_front", &"weapon"])
	return order


## The cached shapes of one part of a kind (built on first use). Null for dynamic parts.
static func part(kind: InkFigure.Kind, part_name: StringName) -> InkBatch:
	if not _parts.has(kind):
		_parts[kind] = _build(kind)
	return (_parts[kind] as Dictionary).get(part_name, null) as InkBatch


## Glowing spots of a kind, one entry per part they sit on (one additive canvas item each):
## { part, points (part space), radii (units), colors, follows }. follows = &"fall" (fades as the
## body falls) or &"pose_glow" (the spirit blade's glow).
static func glows(kind: InkFigure.Kind) -> Array[Dictionary]:
	var merged: Dictionary = {}
	match kind:
		InkFigure.Kind.SAMURAI:
			var along: float = 6.0
			while along <= 72.0:
				_add_glow(merged, &"weapon", Vector2(along, -1.5), 13.0, Color(InkPalette.SPIRIT, 0.32), &"pose_glow")
				along += 6.0
		InkFigure.Kind.HOLLOW_SOLDIER:
			_add_glow(merged, &"head", Vector2(5.5, -9.0), 6.0, Color(InkPalette.HOLLOW_PURPLE, 0.95), &"fall")
			_add_glow(merged, &"head", Vector2(2.0, -9.5), 5.0, Color(InkPalette.HOLLOW_PURPLE, 0.85), &"fall")
		InkFigure.Kind.ONI_BRUTE:
			_add_glow(merged, &"torso", Vector2(0.0, -26.0), 46.0, Color(InkPalette.ONI_EMBER, 0.16), &"fall")
			for point: Vector2 in [Vector2(6.0, -37.0), Vector2(8.0, -31.0), Vector2(8.5, -24.0), Vector2(-4.0, -28.0), Vector2(-3.5, -21.0)]:
				_add_glow(merged, &"torso", point, 7.0, Color(InkPalette.ONI_EMBER, 0.3), &"fall")
			_add_glow(merged, &"head", Vector2(7.0, -8.0), 5.0, Color(InkPalette.ONI_EMBER, 0.95), &"fall")
			_add_glow(merged, &"head", Vector2(3.0, -8.5), 4.5, Color(InkPalette.ONI_EMBER, 0.85), &"fall")
			_add_glow(merged, &"head", Vector2(6.0, -1.5), 4.5, Color(InkPalette.ONI_EMBER, 0.7), &"fall")
	var result: Array[Dictionary] = []
	for key: String in merged:
		result.append(merged[key])
	return result


static func _add_glow(merged: Dictionary, part_name: StringName, point: Vector2, radius: float, color: Color, follows: StringName) -> void:
	var key: String = "%s/%s" % [part_name, follows]
	if not merged.has(key):
		merged[key] = {"part": part_name, "points": PackedVector2Array(), "radii": PackedFloat32Array(),
				"colors": PackedColorArray(), "follows": follows}
	# Packed arrays are values: append to copies and store them back.
	var entry: Dictionary = merged[key]
	var points: PackedVector2Array = entry["points"]
	var radii: PackedFloat32Array = entry["radii"]
	var colors: PackedColorArray = entry["colors"]
	points.append(point)
	radii.append(radius)
	colors.append(color)
	entry["points"] = points
	entry["radii"] = radii
	entry["colors"] = colors


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
				_paint_cloth_tails(fig, ci, InkPalette.SAMURAI_RED, 5.2, 4.6)
			else:
				_paint_cloth_tails(fig, ci, InkPalette.ARCHER_TEAL, 4.0, 3.4)
		&"sleeve_f":
			if fig.secondary != null and fig.secondary.sleeve_front != null:
				_paint_sleeve(fig, ci, fig.secondary.sleeve_front, InkPalette.INK)
		&"sleeve_b":
			if fig.secondary != null and fig.secondary.sleeve_back != null:
				_paint_sleeve(fig, ci, fig.secondary.sleeve_back, InkPalette.INK_BACK)


## Which cached hem shape a figure shows now: flutter phase step x wind level (from trail).
## Rebuilding the hem every frame for 30 Hollow Soldiers cost ~0.5 ms; swapping cached shapes
## ~13 times a second costs almost nothing and looks the same.
static func hem_key(fig: InkFigure) -> int:
	var step: int = int(fposmod(fig.clock * HEM_FLUTTER_SPEED, TAU) / TAU * float(HEM_STEPS)) % HEM_STEPS
	var level: int = clampi(roundi(fig.trail * 2.0), 0, 2)
	return step * 3 + level


## The Hollow Soldier's tattered skirt with its ragged hem (torso space) for a hem_key().
static func hem(key: int) -> InkBatch:
	if _hems.has(key):
		return _hems[key]
	var clock: float = float(key / 3) / float(HEM_STEPS) * TAU / HEM_FLUTTER_SPEED
	var trail: float = float(key % 3) * 0.5
	var outline: PackedVector2Array = PackedVector2Array([Vector2(-10.0, -3.0), Vector2(10.0, -3.0)])
	var hem_points: Array[Vector2] = [Vector2(12.0, 8.0), Vector2(8.0, 14.0), Vector2(5.0, 9.0),
			Vector2(1.0, 15.0), Vector2(-3.0, 10.0), Vector2(-7.0, 14.5), Vector2(-11.0, 9.0)]
	for i: int in hem_points.size():
		var flutter: float = sin(clock * HEM_FLUTTER_SPEED + float(i) * 1.7) * 1.5 * (0.4 + trail)
		outline.append(hem_points[i] + Vector2(-trail * 2.0 * float(i % 2), flutter))
	var batch: InkBatch = InkBatch.new()
	batch.fill_fan(Vector2(0.0, 4.0), outline, InkPalette.INK)
	_hems[key] = batch
	return batch


## The cloth tails (scarf, headband) streaming from the body, from the figure's cloth chains.
static func _paint_cloth_tails(fig: InkFigure, ci: CanvasItem, color: Color, width: float, segment: float) -> void:
	if fig.secondary == null:
		return
	var s: float = fig.get_unit_scale()
	var to_local: Transform2D = fig.global_transform.affine_inverse()
	var batch: InkBatch = InkBatch.new()
	for tail: int in 2:
		var world: PackedVector2Array
		if tail < fig.secondary.scarf.size():
			world = fig.secondary.scarf[tail].points
		else:
			world = fig.secondary.tail_rest(fig, tail)
		batch.stroke(to_local * world, width * s, 1.4 * s, color)
	batch.draw(ci)


## A sleeve flap hanging from the arm: a tapered strip following its cloth chain.
static func _paint_sleeve(fig: InkFigure, ci: CanvasItem, chain: ClothChain, color: Color) -> void:
	var s: float = fig.get_unit_scale()
	var batch: InkBatch = InkBatch.new()
	batch.stroke(fig.global_transform.affine_inverse() * chain.points, fig.spec.sleeve_width.x * s, fig.spec.sleeve_width.y * s, color)
	batch.draw(ci)


# --- Part geometry (built once per kind) -----------------------------------

static func _build(kind: InkFigure.Kind) -> Dictionary:
	var spec: FigureKinds.Spec = FigureKinds.spec(kind)
	var parts: Dictionary = {}
	for front: bool in [true, false]:
		var color: Color = InkPalette.INK if front else InkPalette.INK_BACK
		var suffix: String = "_f" if front else "_b"
		parts[StringName("thigh" + suffix)] = _segment(spec.thigh, spec.thigh_w, color)
		# Shin with the foot at its end. The foot is authored in root orientation (x forward,
		# y down) relative to the ankle; in shin space (x along the shin, pointing down at rest)
		# a root offset (dx, dy) is (dy, -dx).
		var shin: InkBatch = _segment(spec.shin, spec.shin_w, color)
		var foot: PackedVector2Array = PackedVector2Array()
		for point: Vector2 in [Vector2(-3.5, -1.0), Vector2(3.0, -1.5), Vector2(spec.foot, 2.5), Vector2(-3.5, 2.5)]:
			foot.append(Vector2(spec.shin + point.y, -point.x))
		shin.fill_convex(foot, color)
		parts[StringName("shin" + suffix)] = shin
		parts[StringName("upper" + suffix)] = _segment(spec.upper_arm, spec.arm_w, color)
		# Forearm with the hand (fist) at its end.
		var fore: InkBatch = _segment(spec.fore_arm, spec.fore_w, color)
		fore.circle(Vector2(spec.fore_arm, 0.0), spec.hand_r, color)
		parts[StringName("fore" + suffix)] = fore
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
		_:
			AllyFigurePainter.build(kind, parts)
	return parts


## A limb segment from (0,0) to (length,0); drawn stretched between two joints.
static func _segment(length: float, widths: Vector2, color: Color) -> InkBatch:
	var batch: InkBatch = InkBatch.new()
	batch.limb(Vector2.ZERO, Vector2(length, 0.0), widths.x, widths.y, color)
	return batch


## Back and front edge of the do (chest armour) at a height y (torso space, y up is negative).
const _DO_Y: Array[float] = [-3.0, -12.0, -22.0, -31.0]
const _DO_BACK: Array[float] = [-8.5, -11.5, -13.5, -11.5]
const _DO_FRONT: Array[float] = [9.0, 12.5, 14.5, 12.0]


static func _table(ys: Array[float], values: Array[float], y: float) -> float:
	for i: int in range(1, ys.size()):
		if y >= ys[i]:
			return lerpf(values[i], values[i - 1], (y - ys[i]) / (ys[i - 1] - ys[i]))
	return values[ys.size() - 1]


static func _build_samurai(parts: Dictionary) -> void:
	var ink: Color = InkPalette.INK
	var detail: Color = InkPalette.INK_DETAIL
	var back_ink: Color = InkPalette.INK_BACK
	var red: Color = InkPalette.SAMURAI_RED
	var spec: FigureKinds.Spec = FigureKinds.spec(InkFigure.Kind.SAMURAI)
	var leg: float = spec.thigh + spec.shin

	# Hakama: each leg is a wide wedge from the hip flaring to a softly rounded hem on the ground.
	# The two together plus the front panel (skirt part) make the A-line from waist to feet.
	for front: bool in [true, false]:
		var hakama: InkBatch = InkBatch.new()
		var color: Color = ink if front else back_ink
		hakama.fill(PackedVector2Array([Vector2(-3.0, -6.0), Vector2(leg * 0.5, -9.0), Vector2(leg + 0.5, -14.0),
				Vector2(leg + 3.2, -12.5), Vector2(leg + 4.6, 0.0), Vector2(leg + 3.2, 12.5), Vector2(leg + 0.5, 14.0),
				Vector2(leg * 0.5, 9.0), Vector2(-3.0, 6.0)]), color)
		if front:
			# Pleats fanning from the hip, and a hem band.
			hakama.limb(Vector2(leg * 0.3, 2.0), Vector2(leg + 1.0, 5.5), 1.5, 1.8, detail)
			hakama.limb(Vector2(leg * 0.3, -2.0), Vector2(leg + 1.0, -5.5), 1.5, 1.8, detail)
			hakama.stroke(PackedVector2Array([Vector2(leg - 1.4, -12.0), Vector2(leg + 0.2, 0.0), Vector2(leg - 1.4, 12.0)]), 1.6, 1.6, detail)
		parts[&"hakama_f" if front else &"hakama_b"] = hakama

	# Sode: layered shoulder lames, swinging from the shoulder.
	parts[&"pauldron_front"] = _sode(ink, detail)
	parts[&"pauldron_back"] = _sode(back_ink, back_ink)

	parts[&"skirt"] = _samurai_skirt(ink, detail, red)
	parts[&"torso"] = _samurai_do(ink, detail, red)

	# Kote: armoured sleeves on the forearms (a plate with lacing lines before the wrist).
	for front: bool in [true, false]:
		var color: Color = ink if front else back_ink
		var kote: InkBatch = InkBatch.new()
		kote.limb(Vector2.ZERO, Vector2(spec.fore_arm, 0.0), 6.4, 4.6, color)
		kote.circle(Vector2(spec.fore_arm, 0.0), spec.hand_r, color)
		if front:
			kote.limb(Vector2(4.0, -3.0), Vector2(4.0, 3.0), 1.3, 1.3, detail)
			kote.limb(Vector2(spec.fore_arm - 4.0, -2.4), Vector2(spec.fore_arm - 4.0, 2.4), 1.3, 1.3, detail)
		parts[&"fore_f" if front else &"fore_b"] = kote

	parts[&"head"] = _samurai_head(ink, detail)

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


## The do (chest armour): overlapping lamellar bands, each tilted a little toward the viewer (the
## front edge sits lower than the back), with lacing ticks, and a curved breast plate on top.
static func _samurai_do(ink: Color, detail: Color, red: Color) -> InkBatch:
	var batch: InkBatch = InkBatch.new()
	# Bands from the waist up: x = top y, y = bottom y.
	var bands: Array[Vector2] = [Vector2(-9.8, -3.0), Vector2(-16.4, -9.4), Vector2(-23.0, -16.0)]
	for index: int in bands.size():
		var y_top: float = bands[index].x
		var y_bottom: float = bands[index].y
		var back_top: float = _table(_DO_Y, _DO_BACK, y_top)
		var front_top: float = _table(_DO_Y, _DO_FRONT, y_top)
		var back_bottom: float = _table(_DO_Y, _DO_BACK, y_bottom)
		var front_bottom: float = _table(_DO_Y, _DO_FRONT, y_bottom)
		var tilt: float = 1.1
		batch.fill(PackedVector2Array([
				Vector2(back_top, y_top - tilt), Vector2(front_top, y_top + tilt),
				Vector2(front_bottom, y_bottom + tilt), Vector2((back_bottom + front_bottom) * 0.5, y_bottom + tilt * 1.8),
				Vector2(back_bottom, y_bottom - tilt)]), ink)
		# Lower edge of the plate (the overlap shows as a pale seam).
		batch.stroke(PackedVector2Array([Vector2(back_bottom + 0.5, y_bottom - tilt - 0.8),
				Vector2((back_bottom + front_bottom) * 0.5, y_bottom + tilt * 1.8 - 0.9),
				Vector2(front_bottom - 0.5, y_bottom + tilt - 0.8)]), 1.6, 1.6, detail)
		# Lacing: short vertical ticks, offset every other band like brickwork.
		var ticks: int = 5
		for t: int in ticks:
			var u: float = (float(t) + 0.5 + (0.5 if index % 2 == 1 else 0.0)) / float(ticks + 1)
			if u > 0.93:
				continue
			var x: float = lerpf(lerpf(back_top, back_bottom, 0.5), lerpf(front_top, front_bottom, 0.5), u)
			var slope: float = lerpf(-tilt, tilt, u)
			batch.limb(Vector2(x, y_top + 1.8 + slope), Vector2(x, y_bottom - 2.2 + slope), 1.2, 1.2, detail)
	# Breast plate (munaita) with the neck opening.
	batch.fill(PackedVector2Array([Vector2(-11.7, -22.4), Vector2(12.6, -22.4), Vector2(14.0, -27.0),
			Vector2(12.0, -31.0), Vector2(8.5, -33.8), Vector2(5.0, -34.6), Vector2(-5.0, -34.6),
			Vector2(-9.0, -33.6), Vector2(-12.0, -30.5), Vector2(-13.2, -26.0)]), ink)
	batch.stroke(PackedVector2Array([Vector2(-12.0, -23.6), Vector2(0.0, -21.6), Vector2(13.4, -23.4)]), 1.6, 1.6, detail)
	# Shoulder cords crossing the plate toward the neck.
	batch.stroke(PackedVector2Array([Vector2(10.5, -31.0), Vector2(5.5, -27.0), Vector2(1.0, -24.5)]), 1.4, 1.4, detail)
	batch.stroke(PackedVector2Array([Vector2(-9.0, -31.0), Vector2(-5.5, -27.0), Vector2(-1.0, -24.5)]), 1.4, 1.4, detail)
	# Scarf wrapped around the collar (accent).
	batch.stroke(PackedVector2Array([Vector2(-6.0, -33.4), Vector2(-1.5, -35.6), Vector2(4.5, -35.4), Vector2(9.0, -32.6)]), 3.8, 2.4, red)
	return batch


## The hakama front panel, the kusazuri (five hanging tassets), the sash with its knot and the
## scabbard. They hang from the waist and swing together (the part pivots about the waist).
static func _samurai_skirt(ink: Color, detail: Color, red: Color) -> InkBatch:
	var batch: InkBatch = InkBatch.new()
	# Hakama front panel: waist to just above the ankles, with three pleats and a hem line.
	batch.fill(PackedVector2Array([Vector2(-9.0, -4.0), Vector2(9.0, -4.0), Vector2(13.0, 10.0), Vector2(16.5, 30.0),
			Vector2(9.0, 34.0), Vector2(0.0, 35.0), Vector2(-9.5, 34.0), Vector2(-16.0, 30.0), Vector2(-12.5, 10.0)]), ink)
	for x: float in [-4.5, 0.0, 4.5]:
		batch.limb(Vector2(x * 0.8, 6.0), Vector2(x * 1.9, 30.5), 1.5, 1.7, detail)
	batch.stroke(PackedVector2Array([Vector2(-14.5, 29.8), Vector2(0.0, 33.0), Vector2(15.0, 29.8)]), 1.6, 1.6, detail)
	# Scabbard (saya) angled back and down from the left hip, with the wakizashi hilt beside it.
	batch.stroke(PackedVector2Array([Vector2(5.0, -5.0), Vector2(-10.0, 2.0), Vector2(-24.0, 9.5), Vector2(-33.0, 15.0)]), 4.8, 4.0, ink)
	batch.limb(Vector2(-6.0, -1.2), Vector2(-5.0, 2.8), 1.5, 1.5, detail)
	batch.limb(Vector2(3.5, -6.5), Vector2(1.5, -2.5), 1.8, 1.8, detail)
	batch.limb(Vector2(4.0, -6.0), Vector2(12.0, -10.0), 3.6, 3.4, ink)
	batch.ellipse(Vector2(4.5, -6.2), Vector2(1.4, 3.2), ink, 10)
	# Tassets: five hanging plates, fanned a little, with a lacing line each.
	var bottoms: Array[float] = [10.5, 12.5, 13.5, 13.0, 11.0]
	for i: int in 5:
		var left: float = -13.5 + float(i) * 5.8
		var splay: float = float(i - 2) * 0.05
		var pivot: Vector2 = Vector2(left + 2.5, -3.0)
		var bottom: float = bottoms[i]
		var xf: Transform2D = Transform2D(splay, Vector2.ZERO)
		var corners: PackedVector2Array = PackedVector2Array([Vector2(left, -4.0), Vector2(left + 5.0, -4.0),
				Vector2(left + 5.9, bottom - 1.0), Vector2(left + 2.5, bottom + 1.0), Vector2(left - 0.9, bottom - 1.0)])
		var lace: PackedVector2Array = PackedVector2Array([Vector2(left + 0.2, 3.2), Vector2(left + 2.5, 3.9), Vector2(left + 4.8, 3.2)])
		batch.fill_convex(_about(xf, pivot, corners), ink)
		batch.stroke(_about(xf, pivot, lace), 1.3, 1.3, detail)
	# Sash (obi) and the knot with two tails (accent).
	batch.fill(PackedVector2Array([Vector2(-9.6, -6.0), Vector2(9.8, -5.6), Vector2(10.4, -1.0), Vector2(-10.0, -1.4)]), detail)
	batch.fill_convex(PackedVector2Array([Vector2(7.0, -3.5), Vector2(13.5, -6.5), Vector2(12.5, -0.5)]), red)
	batch.fill_convex(PackedVector2Array([Vector2(7.0, -3.5), Vector2(12.0, 3.5), Vector2(8.0, 4.5)]), red)
	batch.circle(Vector2(8.0, -3.0), 2.4, red)
	return batch


## Points rotated by `xf` (a rotation) about `pivot`.
static func _about(xf: Transform2D, pivot: Vector2, points: PackedVector2Array) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		result.append(pivot + xf.basis_xform(point - pivot))
	return result


## The kabuto (helmet) with its crescent crest, the layered neck guard, the visor with its turned-back
## wings and the face mask. Head space: origin at the neck.
static func _samurai_head(ink: Color, detail: Color) -> InkBatch:
	var head: InkBatch = InkBatch.new()
	head.limb(Vector2(0.0, 0.0), Vector2(0.5, -4.0), 6.0, 6.0, ink)
	head.ellipse(Vector2(2.0, -8.5), Vector2(6.5, 7.0), ink)
	# Menpo: chin guard.
	head.fill_convex(PackedVector2Array([Vector2(4.0, -6.5), Vector2(10.5, -5.5), Vector2(9.0, -0.5), Vector2(3.0, 0.5)]), ink)
	# Shikoro: three lames fanning down and back from the helmet rim, the lowest the longest.
	for k: int in [2, 1, 0]:
		var top: Vector2 = Vector2(-4.0 - float(k) * 1.4, -11.5 + float(k) * 2.3)
		_lame(head, top, 10.5 + float(k) * 2.2, 7.5 + float(k) * 2.0, 1.0 + float(k) * 0.13, 1.2, ink, detail)
	# Kabuto bowl, visor and fukigaeshi turn-backs.
	var bowl: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var angle: float = PI + PI * float(i) / 12.0
		bowl.append(Vector2(1.0, -11.0) + Vector2(cos(angle) * 9.5, sin(angle) * 9.0))
	head.fill_convex(bowl, ink)
	head.fill_convex(PackedVector2Array([Vector2(6.0, -12.5), Vector2(15.0, -10.5), Vector2(14.0, -8.5), Vector2(6.0, -10.0)]), ink)
	head.fill_convex(PackedVector2Array([Vector2(4.0, -13.0), Vector2(8.5, -19.5), Vector2(11.5, -13.0)]), ink)
	# Bowl ribs.
	head.stroke(PackedVector2Array([Vector2(-6.5, -13.5), Vector2(-3.0, -18.0), Vector2(2.0, -19.5)]), 1.4, 1.4, detail)
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
	return head


## One armour plate (lame): a band of `width` x `height` hanging from `top`, turned by `tilt`
## radians, with a curved lower edge (`sag`) and a pale seam along it.
static func _lame(batch: InkBatch, top: Vector2, width: float, height: float, tilt: float, sag: float,
		color: Color, seam: Color) -> void:
	var half: float = width * 0.5
	var outline: PackedVector2Array = PackedVector2Array([Vector2(-half, 0.0), Vector2(half, 0.0),
			Vector2(half * 1.05, height), Vector2(0.0, height + sag), Vector2(-half * 1.05, height)])
	var xf: Transform2D = Transform2D(tilt, top)
	batch.fill_convex(xf * outline, color)
	batch.stroke(xf * PackedVector2Array([Vector2(-half, height - 1.0), Vector2(0.0, height + sag - 1.0),
			Vector2(half, height - 1.0)]), 1.5, 1.5, seam)


## Sode: four lames hanging from the shoulder, each wider than the one above and turned a little
## more (a fan), with a curved cap on top. Space: origin at the shoulder.
static func _sode(color: Color, seam: Color) -> InkBatch:
	var sode: InkBatch = InkBatch.new()
	for i: int in [3, 2, 1, 0]:
		var top: Vector2 = Vector2(1.2, -4.5 + float(i) * 5.6)
		_lame(sode, top, 13.0 + float(i) * 2.0, 7.0, float(i) * 0.05 - 0.04, 1.0, color, seam)
	# Cap over the shoulder.
	sode.fill_convex(PackedVector2Array([Vector2(-6.2, -3.0), Vector2(-3.0, -6.0), Vector2(3.0, -6.8),
			Vector2(8.0, -5.0), Vector2(9.0, -1.5), Vector2(-6.8, -1.5)]), color)
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
