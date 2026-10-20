class_name DaimyoFigurePainter
extends RefCounted
## The Fallen Daimyo's costume (FigurePainter calls build()): a corrupted samurai lord, bigger than the
## Oni. Same rules as every figure (docs/ART_BIBLE.md): solid ink shapes, depth from INK / INK_BACK, rare
## INK_DETAIL lines, torn edges, and exactly one accent, the cursed green-yellow (DAIMYO_CURSE), on the
## cracks in his armour, his eyes and the edge of his blade. The torn cloak is the "hem" part
## (FigureTatters). Coordinates are figure units: torso space has the origin at the hips (+x forward,
## -y up); head space has it at the neck; weapon space runs along the blade.


static func build(parts: Dictionary) -> void:
	var ink: Color = InkPalette.INK
	var back: Color = InkPalette.INK_BACK
	var detail: Color = InkPalette.INK_DETAIL
	var curse: Color = InkPalette.DAIMYO_CURSE.lerp(InkPalette.PAPER, 0.2)

	parts[&"pauldron_front"] = FigurePainter._sode(ink, detail)
	parts[&"pauldron_back"] = FigurePainter._sode(back, back)

	var torso: InkBatch = InkBatch.new()
	# Kusazuri: tassets of uneven length, some broken off.
	var lengths: Array[float] = [15.0, 21.0, 12.0, 24.0, 17.0, 10.0]
	for i: int in lengths.size():
		var left: float = -15.0 + float(i) * 5.4
		var drop: float = lengths[i]
		torso.fill(PackedVector2Array([Vector2(left, -4.0), Vector2(left + 5.6, -4.0), Vector2(left + 5.9, drop - 2.0),
				Vector2(left + 3.0, drop), Vector2(left + 0.4, drop - 3.0)]), ink)
	torso.limb(Vector2(-12.0, 6.0), Vector2(11.0, 7.0), 1.4, 1.4, detail)
	# The do: broad, battered, one shoulder plate cracked away.
	torso.fill(PackedVector2Array([Vector2(-12.0, -2.0), Vector2(12.5, -2.0), Vector2(17.0, -14.0), Vector2(19.0, -27.0),
			Vector2(13.0, -35.0), Vector2(3.0, -38.0), Vector2(-9.0, -37.0), Vector2(-18.0, -31.0), Vector2(-19.0, -23.0),
			Vector2(-15.0, -13.0)]), ink)
	for y: float in [-9.0, -17.0, -25.0]:
		torso.stroke(PackedVector2Array([Vector2(-15.0, y - 0.8), Vector2(2.0, y + 1.6), Vector2(17.0, y + 0.8)]), 1.7, 1.7, detail)
	# A rope sash with a frayed end.
	torso.stroke(PackedVector2Array([Vector2(-12.0, -4.0), Vector2(2.0, -2.5), Vector2(13.0, -4.5)]), 3.0, 3.0, back)
	torso.stroke(PackedVector2Array([Vector2(10.0, -4.0), Vector2(12.5, 6.0), Vector2(11.0, 13.0)]), 3.2, 1.2, back)
	# Cursed cracks through the armour (the accent; the glow layer lights them).
	torso.stroke(PackedVector2Array([Vector2(1.0, -35.0), Vector2(6.0, -28.0), Vector2(3.0, -22.0), Vector2(9.0, -14.0)]), 2.6, 1.2, curse)
	torso.stroke(PackedVector2Array([Vector2(-9.0, -30.0), Vector2(-4.0, -24.0), Vector2(-8.0, -17.0)]), 2.2, 1.0, curse)
	parts[&"torso"] = torso

	var head: InkBatch = InkBatch.new()
	head.limb(Vector2.ZERO, Vector2(0.5, -4.0), 7.0, 7.0, ink)
	head.ellipse(Vector2(2.0, -8.5), Vector2(6.8, 7.2), ink)
	head.fill_convex(PackedVector2Array([Vector2(4.0, -6.5), Vector2(10.5, -5.5), Vector2(9.0, -0.5), Vector2(3.0, 0.5)]), ink)
	# Shikoro: three ragged neck lames.
	for k: int in 3:
		var y: float = -11.0 + float(k) * 3.4
		head.fill(PackedVector2Array([Vector2(-5.0, y), Vector2(-16.0 - float(k) * 1.5, y + 3.0), Vector2(-14.0 - float(k) * 1.5, y + 5.4),
				Vector2(-17.0 - float(k) * 1.5, y + 7.0), Vector2(-4.0, y + 4.0)]), ink if k % 2 == 0 else back)
	var bowl: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var angle: float = PI + PI * float(i) / 12.0
		bowl.append(Vector2(1.0, -11.0) + Vector2(cos(angle) * 9.8, sin(angle) * 9.2))
	head.fill_convex(bowl, ink)
	head.fill_convex(PackedVector2Array([Vector2(6.0, -12.5), Vector2(15.0, -10.5), Vector2(14.0, -8.0), Vector2(6.0, -9.5)]), ink)
	head.limb(Vector2(-8.0, -11.5), Vector2(9.5, -11.5), 1.8, 1.8, detail)
	# Kuwagata: the front horn stands tall and bent, the other is snapped to a stump.
	head.stroke(PackedVector2Array([Vector2(4.5, -18.0), Vector2(11.0, -27.0), Vector2(14.0, -38.0)]), 4.4, 1.2, ink)
	head.stroke(PackedVector2Array([Vector2(-1.0, -18.5), Vector2(-3.0, -24.0)]), 4.4, 3.2, ink)
	# Eyes (accent), burning under the brim.
	head.circle(Vector2(6.5, -8.5), 1.6, curse)
	head.circle(Vector2(2.5, -9.0), 1.4, curse)
	parts[&"head"] = head

	# Odachi: a long two-handed blade, chipped along the back; its cutting edge is the accent.
	var sword: InkBatch = InkBatch.new()
	sword.limb(Vector2(-20.0, 0.0), Vector2(4.0, 0.0), 3.8, 3.8, ink)
	for x: float in [-16.0, -10.0, -4.0]:
		sword.limb(Vector2(x, -1.8), Vector2(x + 2.0, 1.8), 1.3, 1.3, detail)
	sword.ellipse(Vector2(5.0, 0.0), Vector2(1.8, 5.4), ink, 12)
	sword.fill(PackedVector2Array([Vector2(6.0, -2.6), Vector2(30.0, -3.2), Vector2(34.0, -1.8), Vector2(40.0, -3.4),
			Vector2(74.0, -3.8), Vector2(100.0, -3.0), Vector2(116.0, 0.4), Vector2(100.0, 1.9), Vector2(66.0, 2.6),
			Vector2(38.0, 2.7), Vector2(34.0, 1.2), Vector2(30.0, 2.9), Vector2(6.0, 2.6)]), ink)
	sword.stroke(PackedVector2Array([Vector2(8.0, 2.0), Vector2(40.0, 2.3), Vector2(80.0, 1.9), Vector2(112.0, 0.5)]), 1.6, 0.8, curse)
	parts[&"weapon"] = sword
