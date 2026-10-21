class_name FigurePainter
extends RefCounted
## Per-kind costume drawing for InkFigure: body shapes, headgear, weapons and the one accent.
## Each body part is built ONCE per kind into an InkBatch in the part's own space (torso, head,
## weapon, limb segment...). InkFigure keeps one child node per part (layout) that draws its
## batch once; a frame only moves those nodes. Only cloth tails are redrawn each frame; the
## bow and the Hollow Soldier's fluttering hem swap between cached shapes.
## Coordinates are figure units (see FigureKinds).

const KATANA_LENGTH: float = 70.0
## The Onmyoji's staff: its top (where the fireball is lit) along the weapon.
const ONMYOJI_STAFF_TIP: float = 58.0
const BOW_UPPER: float = 64.0
const BOW_LOWER: float = 34.0
## A bow limb's ink width at the grip and at the tip (painted wood is drawn just inside it, see PaintedEquipment).
const BOW_LIMB_WIDTH: Vector2 = Vector2(3.8, 2.4)
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


## Where a kind's legs touch the ground, for InkFigure planting its feet: the lower vertices of the leg part that
## reaches the floor (the shin with its foot, or the samurai's hakama wedge down to its hem), in that part's space.
class GroundContacts extends RefCounted:
	var points: PackedVector2Array = PackedVector2Array()
	## True when the part hangs from the hip (a hakama wedge); false when it hangs from the knee (a shin).
	var from_hip: bool = false
	## The part's rest length (its space's x axis ends there).
	var length: float = 1.0
	## How far below the ground line the part may rest (a hakama hem lies a little on the ground).
	var allow: float = 0.0
	## A foot part that stays flat on the ground whatever the shin does (its points are around the ankle, unrotated).
	var flat: bool = false


static var _contacts: Dictionary = {}
## Kind -> the original vertices of its weapon (before the rim-light copy), weapon space.
static var _weapon_points: Dictionary = {}
static var _weapon_bounds: Dictionary = {}


static func ground_contacts(kind: InkFigure.Kind) -> GroundContacts:
	if _contacts.has(kind):
		return _contacts[kind]
	var contacts: GroundContacts = GroundContacts.new()
	var spec: FigureKinds.Spec = FigureKinds.spec(kind)
	var hem: bool = layout(kind).has(&"hakama_f")
	var flat: bool = layout(kind).has(&"foot_f")
	var batch: InkBatch = part(kind, &"foot_f" if flat else (&"hakama_f" if hem else &"shin_f"))
	if batch != null and flat:
		contacts.flat = true
		contacts.points = _original_vertices(batch)
	elif batch != null:
		contacts.from_hip = hem
		contacts.length = spec.thigh + spec.shin if hem else spec.shin
		contacts.allow = 1.0 if hem else 0.0
		for vertex: Vector2 in _original_vertices(batch):
			# A hakama wedge reaches the ground with its whole lower half; a leg with a foot, with the foot only
			# (the foot polygon is the part beyond the ankle).
			if vertex.x > (contacts.length * 0.5 if hem else contacts.length + 0.5):
				contacts.points.append(vertex)
	_contacts[kind] = contacts
	return contacts


## The vertices of a kind's weapon in weapon space (empty if it carries none).
static func weapon_points(kind: InkFigure.Kind) -> PackedVector2Array:
	if not _weapon_points.has(kind):
		var batch: InkBatch = part(kind, &"weapon")
		# Only hull vertices can be lowest after a rigid rotation. Interior armour/weapon detail
		# must not turn every figure refresh into hundreds of redundant ground queries.
		_weapon_points[kind] = Geometry2D.convex_hull(_original_vertices(batch)) if batch != null else PackedVector2Array()
	return _weapon_points[kind]


## A bounding circle of the held weapon in figure units (x, y of its centre and the radius, z), or a negative radius
## if the kind holds none: a weapon whose circle is above the ground cannot touch it.
static func weapon_bound(kind: InkFigure.Kind) -> Vector3:
	if not _weapon_bounds.has(kind):
		var points: PackedVector2Array = weapon_points(kind)
		var bound: Vector3 = Vector3(0.0, 0.0, -1.0)
		if not points.is_empty():
			var low: Vector2 = points[0]
			var high: Vector2 = points[0]
			for point: Vector2 in points:
				low = Vector2(minf(low.x, point.x), minf(low.y, point.y))
				high = Vector2(maxf(high.x, point.x), maxf(high.y, point.y))
			var center: Vector2 = (low + high) * 0.5
			var radius: float = 0.0
			for point: Vector2 in points:
				radius = maxf(radius, point.distance_to(center))
			bound = Vector3(center.x, center.y, radius + 0.01)
		_weapon_bounds[kind] = bound
	return _weapon_bounds[kind]


## A part's own vertices: with the rim-light copy the batch holds them twice.
static func _original_vertices(batch: InkBatch) -> PackedVector2Array:
	if batch.uvs.size() == batch.vertices.size() and not batch.uvs.is_empty():
		return batch.vertices.slice(0, batch.vertices.size() / 2)
	return batch.vertices


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
	&"hakama_f": Slot.HAKAMA_F, &"hakama_b": Slot.HAKAMA_B, &"yumi_back": Slot.TORSO,
	&"shoulder_f": Slot.TORSO,
}
## Parts whose shape changes every frame (redrawn through paint_dynamic).
const DYNAMIC_PARTS: Array[StringName] = [&"tails", &"sleeve_f", &"sleeve_b"]

# Feet have independent ground frames; hands are part of the forearm.
const _BACK_LIMBS: Array[StringName] = [&"thigh_b", &"shin_b", &"foot_b"]
const _BACK_ARM: Array[StringName] = [&"upper_b", &"fore_b"]
const _FRONT_LEG: Array[StringName] = [&"thigh_f", &"shin_f", &"foot_f"]
const _FRONT_ARM: Array[StringName] = [&"upper_f", &"fore_f"]


## Draw order of a kind's parts, back to front.
static func layout(kind: InkFigure.Kind) -> Array[StringName]:
	# The ground shadow is drawn by the InkFigure node itself (one canvas item fewer per figure).
	var order: Array[StringName] = []
	match kind:
		InkFigure.Kind.SAMURAI:
			# Slim painted hakama and independent sandals keep the articulated legs visible.
			# The yumi is slung on his back, behind everything; the Bow skill takes it into his hand.
			# He has legs (hakama trousers over bent knees), the back leg behind the body. Both hands hold the hilt in
			# front of him, so the back arm is drawn over the torso, under the front arm.
			order.append_array([&"yumi_back", &"mane", &"hem", &"sleeve_b", &"thigh_b", &"shin_b", &"foot_b"])
			order.append_array([&"thigh_f", &"shin_f", &"foot_f", &"skirt", &"torso", &"head", &"tails"])
			# The hilt lies under the front hand, which closes over it.
			order.append_array(_BACK_ARM)
			order.append(&"weapon")
			order.append_array(_FRONT_ARM)
			order.append_array([&"sleeve_f", &"bow", &"blade_glow"])
		InkFigure.Kind.ASHIGARU:
			order.append_array(_BACK_LIMBS + _BACK_ARM + _FRONT_LEG)
			order.append_array([&"hem", &"torso", &"head", &"tails", &"weapon"])
			order.append_array(_FRONT_ARM)
		InkFigure.Kind.YUMI_ARCHER:
			order.append_array([&"hem", &"tails", &"quiver"])
			order.append_array(_BACK_LIMBS + _BACK_ARM + _FRONT_LEG)
			order.append_array([&"torso", &"head", &"bow"])
			order.append_array(_FRONT_ARM)
		InkFigure.Kind.HOLLOW_SOLDIER:
			order.append_array(_BACK_LIMBS + _BACK_ARM + _FRONT_LEG)
			order.append_array([&"hem", &"torso", &"head", &"weapon"])
			order.append_array(_FRONT_ARM)
		InkFigure.Kind.ONI_BRUTE:
			# His painted head ends in a cut neck: it sits behind the shoulder line, joined by the torso's neck.
			order.append(&"mane")
			order.append_array(_BACK_LIMBS + _BACK_ARM + _FRONT_LEG)
			order.append_array([&"head", &"hem", &"torso", &"weapon"])
			order.append_array(_FRONT_ARM)
		InkFigure.Kind.SHRINE_HEALER, InkFigure.Kind.ONMYOJI:
			# Long sleeves hang from the arms as cloth flaps; the healer's ponytail is the mane.
			if kind == InkFigure.Kind.SHRINE_HEALER:
				order.append(&"mane")
			order.append_array(_BACK_LIMBS + _BACK_ARM)
			order.append_array([&"sleeve_b"] + _FRONT_LEG)
			order.append_array([&"hem", &"torso", &"head", &"tails", &"weapon"])
			order.append_array(_FRONT_ARM)
			order.append(&"sleeve_f")
		InkFigure.Kind.SPEAR_GUARDIAN:
			order.append_array(_BACK_LIMBS + [&"pauldron_back"] + _BACK_ARM + _FRONT_LEG)
			order.append_array([&"hem", &"torso", &"head", &"tails", &"shield"])
			order.append_array(_FRONT_ARM)
			order.append_array([&"pauldron_front", &"weapon"])
		InkFigure.Kind.HATAMOTO:
			# The banner is on his back, behind everything; he wears the samurai's hakama and skirt.
			order.append_array([&"hem", &"banner", &"thigh_b", &"shin_b", &"foot_b", &"pauldron_back"])
			order.append_array(_BACK_ARM)
			order.append_array([&"thigh_f", &"shin_f", &"foot_f", &"skirt", &"torso", &"head", &"tails"])
			order.append_array(_FRONT_ARM)
			order.append_array([&"pauldron_front", &"weapon"])
		InkFigure.Kind.FALLEN_DAIMYO:
			# The torn cloak ("hem") hangs behind everything; he holds the odachi in both hands.
			order.append_array([&"hem", &"pauldron_back"] + _BACK_LIMBS + _BACK_ARM + _FRONT_LEG)
			order.append_array([&"torso", &"head", &"weapon"])
			order.append_array(_FRONT_ARM + [&"pauldron_front"])
	if RosterSpriteArt.ARMHOLES.has(kind):
		# The painted front arm's open sleeve end is covered by a cap of the torso's own shoulder, under the forearm.
		order.insert(order.find(&"upper_f") + 1, &"shoulder_f")
	return order


## True for the six allies, who wear the lighter blue-slate ink (InkPalette.ALLY_INK).
static func is_ally_tone(kind: InkFigure.Kind) -> bool:
	return kind != InkFigure.Kind.SAMURAI and kind != InkFigure.Kind.HOLLOW_SOLDIER and kind != InkFigure.Kind.ONI_BRUTE \
			and kind != InkFigure.Kind.FALLEN_DAIMYO


## The ink colour `color` becomes on a kind: the allies' lighter tones, everyone else's unchanged.
static func tone(kind: InkFigure.Kind, color: Color) -> Color:
	if not is_ally_tone(kind):
		return color
	if color == InkPalette.INK:
		return InkPalette.ALLY_INK
	if color == InkPalette.INK_BACK:
		return InkPalette.ALLY_INK_BACK
	if color == InkPalette.INK_DETAIL:
		return InkPalette.ALLY_INK_DETAIL
	return color


## Swaps the three inks of a freshly built batch for the kind's tones (a no-op for non-allies).
static func tone_batch(kind: InkFigure.Kind, batch: InkBatch) -> void:
	if not is_ally_tone(kind):
		return
	batch.remap(InkPalette.INK, InkPalette.ALLY_INK)
	batch.remap(InkPalette.INK_BACK, InkPalette.ALLY_INK_BACK)
	batch.remap(InkPalette.INK_DETAIL, InkPalette.ALLY_INK_DETAIL)


## The cached shapes of one part of a kind (built on first use). Null for dynamic parts.
static func part(kind: InkFigure.Kind, part_name: StringName) -> InkBatch:
	if not _parts.has(kind):
		_parts[kind] = _build(kind)
	return (_parts[kind] as Dictionary).get(part_name, null) as InkBatch


## Glowing spots of a kind, one entry per part they sit on (one additive canvas item each):
## { part, points (part space), radii (units), colors, follows, flicker, rage_min }. rage_min is the
## first rage level (a boss's phase, InkFigure.rage) at which that light shows. follows = &"fall" (fades
## as the body falls) or &"pose_glow" (the spirit blade's glow). flicker (0..1) is how deeply the
## light pulses, each figure on its own random phase (InkFigure.flicker_phase).
static func glows(kind: InkFigure.Kind) -> Array[Dictionary]:
	var merged: Dictionary = {}
	match kind:
		InkFigure.Kind.SAMURAI:
			var along: float = 6.0
			while along <= 72.0:
				_add_glow(merged, &"weapon", Vector2(along, -1.5), 13.0, Color(InkPalette.SPIRIT, 0.32), &"pose_glow")
				along += 6.0
			# A faint, steady spirit light on the point of the blade: calm.
			_add_glow(merged, &"weapon", Vector2(66.0, -1.5), 7.0, Color(InkPalette.SPIRIT, 0.34), &"fall", 0.2)
		InkFigure.Kind.ASHIGARU:
			# The gold tassel under the spearhead smoulders like a lantern.
			_add_glow(merged, &"weapon", Vector2(58.5, 5.0), 6.5, Color(InkPalette.ASHIGARU_GOLD, 0.5), &"fall", 0.45)
		InkFigure.Kind.YUMI_ARCHER:
			# The fletching of the arrows in the quiver.
			for tip: Vector2 in [Vector2(-14.5, -42.0), Vector2(-11.5, -43.5), Vector2(-8.5, -42.5)]:
				_add_glow(merged, &"quiver", tip + Vector2(0.0, -1.0), 4.0, Color(InkPalette.ARCHER_TEAL, 0.5), &"fall", 0.3)
		InkFigure.Kind.SHRINE_HEALER:
			# The paper streamers of the gohei glow softly, like a held blessing.
			for side: float in [1.0, -1.0]:
				_add_glow(merged, &"weapon", Vector2(48.0, side * 10.0), 7.0, Color(InkPalette.HEALER_JADE, 0.42), &"fall", 0.25)
		InkFigure.Kind.SPEAR_GUARDIAN:
			# The azure rim of the shield.
			for y: float in [-34.0, -16.0, 2.0]:
				_add_glow(merged, &"shield", Vector2(19.0, y), 6.0, Color(InkPalette.GUARDIAN_AZURE, 0.38), &"fall", 0.15)
		InkFigure.Kind.FALLEN_DAIMYO:
			# The cursed edge of the odachi, his eyes and the cracks in his armour. Phase 2 and 3 add a
			# burning aura around the whole body.
			var reach: float = 14.0
			while reach <= 112.0:
				_add_glow(merged, &"weapon", Vector2(reach, 0.5), 15.0, Color(InkPalette.DAIMYO_CURSE, 0.26), &"fall", 0.3)
				reach += 9.0
			_add_glow(merged, &"head", Vector2(6.5, -8.5), 6.0, Color(InkPalette.DAIMYO_CURSE, 0.95), &"fall", 0.25)
			_add_glow(merged, &"head", Vector2(2.5, -9.0), 5.0, Color(InkPalette.DAIMYO_CURSE, 0.85), &"fall", 0.25)
			for crack: Vector2 in [Vector2(3.0, -28.0), Vector2(6.0, -19.0), Vector2(-6.0, -24.0)]:
				_add_glow(merged, &"torso", crack, 11.0, Color(InkPalette.DAIMYO_CURSE, 0.32), &"fall", 0.5)
			_add_glow(merged, &"torso", Vector2(0.0, -22.0), 62.0, Color(InkPalette.DAIMYO_CURSE, 0.10), &"fall", 0.2, 2)
			_add_glow(merged, &"torso", Vector2(0.0, -20.0), 100.0, Color(InkPalette.DAIMYO_CURSE, 0.11), &"fall", 0.3, 3)
		InkFigure.Kind.ONMYOJI:
			# The seal on the talisman burns, flickering like a candle.
			_add_glow(merged, &"weapon", Vector2(ONMYOJI_STAFF_TIP, 0.0), 13.0, Color(InkPalette.HATAMOTO_ORANGE, 0.55), &"fall", 0.6)
		InkFigure.Kind.HATAMOTO:
			# The mon on the banner.
			_add_glow(merged, &"banner", Vector2(-23.0, -79.0), 12.0, Color(InkPalette.HATAMOTO_ORANGE, 0.32), &"fall", 0.35)
		InkFigure.Kind.HOLLOW_SOLDIER:
			_add_glow(merged, &"head", Vector2(5.5, -9.0), 6.0, Color(InkPalette.HOLLOW_PURPLE, 0.95), &"fall", 0.25)
			_add_glow(merged, &"head", Vector2(2.0, -9.5), 5.0, Color(InkPalette.HOLLOW_PURPLE, 0.85), &"fall", 0.25)
		InkFigure.Kind.ONI_BRUTE:
			_add_glow(merged, &"torso", Vector2(0.0, -26.0), 46.0, Color(InkPalette.ONI_EMBER, 0.16), &"fall")
			for point: Vector2 in [Vector2(6.0, -37.0), Vector2(8.0, -31.0), Vector2(8.5, -24.0), Vector2(-4.0, -28.0), Vector2(-3.5, -21.0)]:
				_add_glow(merged, &"torso", point, 7.0, Color(InkPalette.ONI_EMBER, 0.3), &"fall", 0.45)
			_add_glow(merged, &"head", Vector2(7.0, -8.0), 5.0, Color(InkPalette.ONI_EMBER, 0.95), &"fall")
			_add_glow(merged, &"head", Vector2(3.0, -8.5), 4.5, Color(InkPalette.ONI_EMBER, 0.85), &"fall")
			_add_glow(merged, &"head", Vector2(6.0, -1.5), 4.5, Color(InkPalette.ONI_EMBER, 0.7), &"fall")
	var result: Array[Dictionary] = []
	for key: String in merged:
		result.append(merged[key])
	return result


static func _add_glow(merged: Dictionary, part_name: StringName, point: Vector2, radius: float, color: Color, follows: StringName, flicker: float = 0.0, rage_min: int = 1) -> void:
	var key: String = "%s/%s/%.2f/%d" % [part_name, follows, flicker, rage_min]
	if not merged.has(key):
		merged[key] = {"part": part_name, "points": PackedVector2Array(), "radii": PackedFloat32Array(),
				"colors": PackedColorArray(), "follows": follows, "flicker": flicker, "rage_min": rage_min}
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


## The bow (limbs, string, nocked arrow) at a draw amount, cached per draw step. The samurai's yumi has a
## red grip wrap and red fletching; the archer's fletching is teal.
static func bow(draw_amount: float, kind: InkFigure.Kind = InkFigure.Kind.YUMI_ARCHER) -> InkBatch:
	return _bow(draw_amount, kind == InkFigure.Kind.SAMURAI)


static func bow_step(draw_amount: float) -> int:
	return clampi(roundi(draw_amount * BOW_STEPS), 0, BOW_STEPS)


## Draws a part whose shape changes every frame (one of DYNAMIC_PARTS) into ci, in the part's
## slot space.
static func paint_dynamic(fig: InkFigure, part_name: StringName, ci: CanvasItem) -> void:
	match part_name:
		&"mane":
			if fig.secondary != null and fig.secondary.hair != null:
				var local_hair: PackedVector2Array = ci.global_transform.affine_inverse() * fig.secondary.hair.points
				SamuraiSpriteArt.paint_cloth(ci, SamuraiSpriteArt.hair_spine(local_hair), 18.0, true, SamuraiSpriteArt.SOURCES[&"mane"])
		&"tails":
			if fig.kind == InkFigure.Kind.SAMURAI:
				if fig.secondary != null:
					for chain: ClothChain in fig.secondary.scarf:
						SamuraiSpriteArt.paint_cloth(ci, ci.global_transform.affine_inverse() * chain.points,
								7.0 * fig.get_unit_scale(), true)
			else:
				_paint_cloth_tails(fig, ci, fig.spec.accent, 3.2, 3.4)
		&"sleeve_f":
			if fig.secondary != null and fig.secondary.sleeve_front != null:
				_paint_sleeve(fig, ci, fig.secondary.sleeve_front, tone(fig.kind, InkPalette.INK))
		&"sleeve_b":
			if fig.secondary != null and fig.secondary.sleeve_back != null:
				_paint_sleeve(fig, ci, fig.secondary.sleeve_back, tone(fig.kind, InkPalette.INK_BACK))


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
	var lit: InkBatch = batch.with_rim()
	_hems[key] = lit
	return lit


## The cloth tails (scarf, headband) streaming from the body, from the figure's cloth chains.
static func _paint_cloth_tails(fig: InkFigure, ci: CanvasItem, color: Color, width: float, segment: float) -> void:
	if fig.secondary == null:
		return
	var s: float = fig.get_unit_scale()
	var to_local: Transform2D = ci.global_transform.affine_inverse()
	if RosterSpriteArt.NAMES.has(fig.kind):
		for chain: ClothChain in fig.secondary.scarf:
			RosterSpriteArt.paint_tail(fig.kind, ci, to_local * chain.points, width * s * 1.4)
		return
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
	if fig.kind == InkFigure.Kind.SAMURAI:
		SamuraiSpriteArt.paint_cloth(ci, ci.global_transform.affine_inverse() * chain.points, 8.0 * s, false)
		return
	if RosterSpriteArt.NAMES.has(fig.kind):
		SamuraiSpriteArt.paint_cloth(ci, SamuraiSpriteArt.smooth_ribbon(ci.global_transform.affine_inverse() * chain.points),
				fig.spec.sleeve_width.x * s, false, RosterSpriteArt.region(fig.kind, 4), RosterSpriteArt.atlas(fig.kind))
		return
	var batch: InkBatch = InkBatch.new()
	batch.stroke(ci.global_transform.affine_inverse() * chain.points, fig.spec.sleeve_width.x * s, fig.spec.sleeve_width.y * s, color)
	batch.draw(ci)


# --- Part geometry (built once per kind) -----------------------------------

static func _build(kind: InkFigure.Kind) -> Dictionary:
	var spec: FigureKinds.Spec = FigureKinds.spec(kind)
	var parts: Dictionary = {}
	for front: bool in [true, false]:
		var color: Color = InkPalette.INK if front else InkPalette.INK_BACK
		var suffix: String = "_f" if front else "_b"
		parts[StringName("thigh" + suffix)] = _segment(spec.thigh, spec.thigh_w, color)
		parts[StringName("shin" + suffix)] = _segment(spec.shin, Vector2(spec.shin_w.x, minf(spec.shin_w.y, 4.0)), color)
		# Independent tabi/sole: rotation of the shin cannot tip the foot into the floor.
		var foot: InkBatch = InkBatch.new()
		foot.fill_convex(PackedVector2Array([Vector2(-3.5, -1.0), Vector2(3.0, -1.5),
				Vector2(spec.foot, 2.5), Vector2(-3.5, 2.5)]), color)
		parts[StringName("foot" + suffix)] = foot
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
		InkFigure.Kind.FALLEN_DAIMYO:
			DaimyoFigurePainter.build(parts)
		_:
			AllyFigurePainter.build(kind, parts)
	if RosterSpriteArt.NAMES.has(kind):
		RosterSpriteArt.build_body(kind, parts)
	# Every body part gets the sun's rim light (drawn once per part with the shared rim material).
	for part_name: StringName in parts:
		if part_name != &"shadow" and part_name != &"blade_glow":
			tone_batch(kind, parts[part_name] as InkBatch)
			parts[part_name] = (parts[part_name] as InkBatch).with_rim()
	return parts


## A limb segment from (0,0) to (length,0); drawn stretched between two joints.
static func _segment(length: float, widths: Vector2, color: Color) -> InkBatch:
	var batch: InkBatch = InkBatch.new()
	batch.limb(Vector2.ZERO, Vector2(length, 0.0), widths.x, widths.y, color)
	return batch


static func _table(ys: Array[float], values: Array[float], y: float) -> float:
	for i: int in range(1, ys.size()):
		if y >= ys[i]:
			return lerpf(values[i], values[i - 1], (y - ys[i]) / (ys[i - 1] - ys[i]))
	return values[ys.size() - 1]


static func _build_samurai(parts: Dictionary) -> void:
	var ink: Color = InkPalette.INK
	var detail: Color = InkPalette.INK_DETAIL
	var red: Color = InkPalette.SAMURAI_RED

	SamuraiSpriteArt.build_body(parts)
	parts[&"yumi_back"] = _samurai_yumi_back(ink, detail, red)

	var katana: InkBatch = InkBatch.new()
	# A long hilt for two hands: the front hand at the guard, the back hand at the pommel end, with the wrapped
	# diamonds of the hilt cord and a pommel.
	katana.limb(Vector2(-17.0, 0.0), Vector2(1.0, 0.0), 3.6, 3.8, ink)
	for x: float in [-14.5, -11.5, -8.5, -5.5, -2.5]:
		katana.limb(Vector2(x, -1.9), Vector2(x + 1.5, 1.9), 1.0, 1.0, detail)
	katana.ellipse(Vector2(-17.5, 0.0), Vector2(1.7, 2.5), detail, 8)
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


## The yumi slung on the samurai's back (torso space): the long, bowed curve leaning back from the hips to well
## above the shoulder, its string straight on the body side and the red grip wrap a third of the way up (his
## back hand reaches it at FigureKinds.BACK_BOW_GRIP). The torso hides its lower end.
static func _samurai_yumi_back(ink: Color, detail: Color, red: Color) -> InkBatch:
	var batch: InkBatch = InkBatch.new()
	var lower: Vector2 = Vector2(-10.0, -2.0)
	var upper: Vector2 = Vector2(-20.0, -64.0)
	var control: Vector2 = Vector2(-25.5, -32.0)
	batch.stroke(PackedVector2Array([lower, upper]), 1.1, 1.1, detail)
	var curve: PackedVector2Array = PackedVector2Array()
	for i: int in 15:
		curve.append(_quadratic(lower, control, upper, float(i) / 14.0))
	batch.stroke(curve, 2.2, 1.3, detail)
	batch.stroke(PackedVector2Array([_quadratic(lower, control, upper, 0.3), _quadratic(lower, control, upper, 0.4)]), 2.6, 2.6, red.darkened(0.2))
	return batch


static func _quadratic(a: Vector2, control: Vector2, b: Vector2, u: float) -> Vector2:
	return a.lerp(control, u).lerp(control.lerp(b, u), u)


## The samurai's hakama: a short flare hanging from the hip to the knee over the plain tapered leg (the same clean
## construction as the Spear Guardian's), ending in a hem band at the knee so he still reads as a samurai in
## silhouette. Thigh space: x along the thigh from the hip to the knee.
static func _samurai_hakama_flare(parts: Dictionary, spec: FigureKinds.Spec, ink: Color, back_ink: Color, detail: Color) -> void:
	for front: bool in [true, false]:
		var color: Color = ink if front else back_ink
		var thigh: InkBatch = parts[&"thigh_f" if front else &"thigh_b"]
		var length: float = spec.thigh
		thigh.fill(PackedVector2Array([Vector2(-1.0, -7.5), Vector2(length * 0.5, -10.0), Vector2(length + 1.5, -14.0),
				Vector2(length + 4.0, -11.0), Vector2(length + 4.5, 0.0), Vector2(length + 4.0, 11.0), Vector2(length + 1.5, 14.0),
				Vector2(length * 0.5, 10.0), Vector2(-1.0, 7.5)]), color)
		if front:
			thigh.limb(Vector2(length * 0.3, 0.0), Vector2(length - 1.0, 0.0), 1.3, 1.3, detail)
			thigh.stroke(PackedVector2Array([Vector2(length + 3.4, -10.5), Vector2(length + 4.0, 0.0), Vector2(length + 3.4, 10.5)]), 1.6, 1.6, detail)


## The samurai's body (torso space): shoulders and a short neck, a chest that narrows to the waist, plates that curve
## with the body (each bulging a little at the front, their lower edges sagging) and not boxes.
const _BODY_Y: Array[float] = [-1.0, -10.0, -19.0, -26.0, -30.0]
const _BODY_BACK: Array[float] = [-9.0, -8.2, -10.5, -12.0, -9.0]
const _BODY_FRONT: Array[float] = [9.5, 8.8, 11.8, 13.8, 10.0]


static func _samurai_body(ink: Color, detail: Color, red: Color) -> InkBatch:
	var batch: InkBatch = InkBatch.new()
	# The neck, running up into the helmet.
	batch.limb(Vector2(-0.5, -28.0), Vector2(1.5, -34.5), 5.4, 4.8, ink)
	var edges: Array[float] = [-1.0, -10.0, -18.0, -25.0, -30.0]
	for index: int in 4:
		var y_bottom: float = edges[index]
		var y_top: float = edges[index + 1]
		var y_mid: float = (y_bottom + y_top) * 0.5
		var back_bottom: float = _table(_BODY_Y, _BODY_BACK, y_bottom)
		var front_bottom: float = _table(_BODY_Y, _BODY_FRONT, y_bottom)
		var back_top: float = _table(_BODY_Y, _BODY_BACK, y_top)
		var front_top: float = _table(_BODY_Y, _BODY_FRONT, y_top)
		var back_mid: float = _table(_BODY_Y, _BODY_BACK, y_mid) - 0.3
		var front_mid: float = _table(_BODY_Y, _BODY_FRONT, y_mid) + 0.9
		var sag: float = 1.3
		batch.fill(PackedVector2Array([Vector2(back_top, y_top), Vector2(front_top, y_top + 0.6), Vector2(front_mid, y_mid),
				Vector2(front_bottom, y_bottom + 0.8), Vector2((back_bottom + front_bottom) * 0.5, y_bottom + sag),
				Vector2(back_bottom, y_bottom), Vector2(back_mid, y_mid)]), ink)
		# The pale seam along the lower edge, and the lacing ticks between the plate edges.
		batch.stroke(PackedVector2Array([Vector2(back_bottom + 0.6, y_bottom - 0.6), Vector2((back_bottom + front_bottom) * 0.5, y_bottom + sag - 0.8),
				Vector2(front_bottom - 0.6, y_bottom + 0.2)]), 1.4, 1.4, detail)
		if index < 3:
			for tick: int in 4:
				var u: float = (float(tick) + 0.5 + (0.5 if index % 2 == 1 else 0.0)) / 5.0
				var x: float = lerpf(lerpf(back_top, back_bottom, 0.5), lerpf(front_top, front_bottom, 0.5), u)
				batch.limb(Vector2(x, y_top + 1.8), Vector2(x, y_bottom - 2.0), 1.1, 1.1, detail)
	# The breast plate's curve and the cords crossing it toward the neck.
	batch.stroke(PackedVector2Array([Vector2(-8.0, -24.0), Vector2(1.0, -22.6), Vector2(11.5, -24.5)]), 1.5, 1.5, detail)
	batch.stroke(PackedVector2Array([Vector2(8.5, -29.0), Vector2(5.0, -26.0), Vector2(1.5, -24.0)]), 1.3, 1.3, detail)
	batch.stroke(PackedVector2Array([Vector2(-7.0, -29.0), Vector2(-4.0, -26.0), Vector2(-1.0, -24.0)]), 1.3, 1.3, detail)
	# Scarf wrapped around the neck (accent).
	batch.stroke(PackedVector2Array([Vector2(-5.5, -30.5), Vector2(-1.0, -32.2), Vector2(4.0, -32.0), Vector2(8.0, -29.8)]), 3.6, 2.4, red)
	return batch


## The hips: five hanging tassets fanned over the thighs, the sash with its knot and the scabbard angled back from
## the left hip. They hang from the waist and swing together (the part pivots about the waist). The hakama itself is
## the legs.
static func _samurai_kusazuri(ink: Color, detail: Color, red: Color) -> InkBatch:
	var batch: InkBatch = InkBatch.new()
	# Scabbard (saya), the sword drawn: angled back and down from the left hip, with the wakizashi hilt beside it.
	batch.stroke(PackedVector2Array([Vector2(5.0, -5.0), Vector2(-10.0, 2.0), Vector2(-24.0, 9.5), Vector2(-33.0, 15.0)]), 4.8, 4.0, ink)
	batch.limb(Vector2(-6.0, -1.2), Vector2(-5.0, 2.8), 1.5, 1.5, detail)
	batch.limb(Vector2(3.5, -6.5), Vector2(1.5, -2.5), 1.8, 1.8, detail)
	batch.limb(Vector2(4.0, -6.0), Vector2(12.0, -10.0), 3.6, 3.4, ink)
	batch.ellipse(Vector2(4.5, -6.2), Vector2(1.4, 3.2), ink, 10)
	# Tassets: five hanging plates, fanned a little, with a lacing line each.
	var bottoms: Array[float] = [11.0, 13.5, 15.0, 14.0, 11.5]
	for i: int in 5:
		var left: float = -12.5 + float(i) * 5.4
		var splay: float = float(i - 2) * 0.07
		var pivot: Vector2 = Vector2(left + 2.5, -3.0)
		var bottom: float = bottoms[i]
		var xf: Transform2D = Transform2D(splay, Vector2.ZERO)
		var corners: PackedVector2Array = PackedVector2Array([Vector2(left, -4.0), Vector2(left + 5.2, -4.0),
				Vector2(left + 6.0, bottom - 1.0), Vector2(left + 2.6, bottom + 1.2), Vector2(left - 0.9, bottom - 1.0)])
		var lace: PackedVector2Array = PackedVector2Array([Vector2(left + 0.2, 3.6), Vector2(left + 2.6, 4.3), Vector2(left + 5.0, 3.6)])
		batch.fill_convex(_about(xf, pivot, corners), ink)
		batch.stroke(_about(xf, pivot, lace), 1.3, 1.3, detail)
	# Sash (obi) and the knot with two tails (accent).
	batch.fill(PackedVector2Array([Vector2(-9.4, -6.0), Vector2(9.6, -5.6), Vector2(10.2, -1.0), Vector2(-9.8, -1.4)]), detail)
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
	head.limb(Vector2(0.0, 3.0), Vector2(0.5, -4.0), 5.0, 6.0, ink)
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
static func _bow(draw_amount: float, samurai: bool = false) -> InkBatch:
	var step: int = bow_step(draw_amount)
	var key: int = step + (BOW_STEPS + 1 if samurai else 0)
	if _bows.has(key):
		return _bows[key]
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
	# String first so the limbs cover its ends: a slim hemp cord, not an ink line.
	batch.stroke(PackedVector2Array([upper[8], nock, lower[8]]), 1.1, 1.1, InkPalette.PARCHMENT_DIM.darkened(0.25))
	batch.stroke(upper, BOW_LIMB_WIDTH.x, BOW_LIMB_WIDTH.y, ink)
	batch.stroke(lower, BOW_LIMB_WIDTH.x, BOW_LIMB_WIDTH.y, ink)
	var fletching: Color = InkPalette.SAMURAI_RED if samurai else InkPalette.ARCHER_TEAL
	if samurai:
		# The wrapped grip, a third of the way up from the lower tip (where the front hand holds it).
		batch.limb(Vector2(0.4, -6.0), Vector2(0.4, 6.0), 4.6, 4.6, InkPalette.SAMURAI_RED)
	if drawn > 0.25:
		var alpha: float = clampf((drawn - 0.25) * 2.5, 0.0, 1.0)
		var head: float = nock.x + 44.0
		batch.limb(nock, Vector2(head, 0.0), 2.2, 2.2, Color(ink, alpha))
		batch.fill_convex(PackedVector2Array([Vector2(head - 1.0, -2.6), Vector2(head + 5.0, 0.0),
				Vector2(head - 1.0, 2.6)]), Color(ink, alpha))
		var teal: Color = Color(fletching, alpha)
		batch.fill_convex(PackedVector2Array([nock + Vector2(1.0, 0.0), nock + Vector2(8.0, 0.0),
				nock + Vector2(4.0, -3.4)]), teal)
		batch.fill_convex(PackedVector2Array([nock + Vector2(1.0, 0.0), nock + Vector2(8.0, 0.0),
				nock + Vector2(4.0, 3.4)]), teal)
	_bows[key] = batch
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
