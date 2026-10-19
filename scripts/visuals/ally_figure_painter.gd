class_name AllyFigurePainter
extends RefCounted
## Costumes of the four later allies (FigurePainter calls build() for their kinds): Shrine Healer,
## Spear Guardian, Onmyoji and Hatamoto. Same rules as every figure (docs/ART_BIBLE.md): solid ink
## shapes, depth from INK / INK_BACK, rare INK_DETAIL lines, and exactly one accent colour as flat cloth.
##   Shrine Healer  jade     hair ribbon, obi, the paper streamers of the gohei wand
##   Spear Guardian azure    helmet cord, shield rim, spear tassel
##   Onmyoji        magenta  hat ribbons, belt, the seal on the paper talisman
##   Hatamoto       orange   the banner on his back, sash, naginata tassel, helmet cord
## Coordinates are figure units: torso space has the origin at the hips (+x forward, -y up); head
## space has it at the neck.


static func build(kind: InkFigure.Kind, parts: Dictionary) -> void:
	match kind:
		InkFigure.Kind.SHRINE_HEALER:
			_build_healer(parts)
		InkFigure.Kind.SPEAR_GUARDIAN:
			_build_guardian(parts)
		InkFigure.Kind.ONMYOJI:
			_build_onmyoji(parts)
		InkFigure.Kind.HATAMOTO:
			_build_hatamoto(parts)


# --- Shrine Healer ----------------------------------------------------------

static func _build_healer(parts: Dictionary) -> void:
	var ink: Color = InkPalette.INK
	var detail: Color = InkPalette.INK_DETAIL
	var jade: Color = InkPalette.HEALER_JADE

	# Long ponytail swept back, tied with a jade ribbon (head space, behind the head).
	var mane: InkBatch = InkBatch.new()
	mane.stroke(PackedVector2Array([Vector2(-3.0, -13.0), Vector2(-11.0, -11.0), Vector2(-19.0, -4.0), Vector2(-23.0, 7.0),
			Vector2(-21.0, 17.0)]), 7.5, 1.6, InkPalette.INK_BACK)
	mane.circle(Vector2(-5.5, -12.5), 2.6, jade)
	mane.stroke(PackedVector2Array([Vector2(-6.0, -12.0), Vector2(-12.0, -7.0), Vector2(-15.0, -1.0)]), 3.2, 1.2, jade)
	mane.stroke(PackedVector2Array([Vector2(-6.0, -13.0), Vector2(-11.0, -16.5), Vector2(-16.0, -16.0)]), 3.0, 1.2, jade)
	parts[&"mane"] = mane

	var head: InkBatch = InkBatch.new()
	head.limb(Vector2.ZERO, Vector2(0.5, -4.0), 5.0, 5.0, ink)
	head.ellipse(Vector2(1.0, -8.5), Vector2(6.2, 7.0), ink)
	# Hair cap with a straight fringe and a hairpin.
	head.fill(PackedVector2Array([Vector2(-6.5, -8.0), Vector2(-6.0, -14.0), Vector2(0.0, -17.5), Vector2(6.5, -14.5),
			Vector2(7.5, -10.5), Vector2(3.0, -12.0), Vector2(-1.0, -11.0), Vector2(-3.5, -7.0)]), ink)
	head.limb(Vector2(-3.0, -16.0), Vector2(-8.0, -22.0), 1.6, 1.6, detail)
	head.circle(Vector2(-8.5, -22.5), 1.8, jade)
	parts[&"head"] = head

	var torso: InkBatch = InkBatch.new()
	# Hakama: wide flared trousers (a miko's), pleated, hem above the ankles.
	torso.fill(PackedVector2Array([Vector2(-9.0, -3.0), Vector2(9.0, -3.0), Vector2(14.0, 14.0), Vector2(18.0, 30.0),
			Vector2(0.0, 33.0), Vector2(-17.0, 30.0), Vector2(-13.0, 14.0)]), ink)
	for x: float in [-5.0, 0.0, 5.0]:
		torso.limb(Vector2(x * 0.8, 6.0), Vector2(x * 2.4, 29.5), 1.4, 1.6, detail)
	# Kosode top, collar crossing at the chest.
	torso.fill(PackedVector2Array([Vector2(-8.0, -2.0), Vector2(8.0, -2.0), Vector2(10.0, -16.0), Vector2(9.5, -27.0),
			Vector2(3.0, -30.5), Vector2(-6.0, -29.5), Vector2(-9.5, -17.0)]), ink)
	torso.limb(Vector2(3.0, -30.0), Vector2(-3.0, -12.0), 1.5, 1.5, detail)
	torso.limb(Vector2(-4.0, -29.0), Vector2(5.0, -13.0), 1.5, 1.5, detail)
	# Obi (accent) with a bow behind.
	torso.fill_convex(PackedVector2Array([Vector2(-9.0, -3.5), Vector2(9.2, -3.5), Vector2(9.0, -9.5), Vector2(-9.3, -9.5)]), jade)
	torso.fill_convex(PackedVector2Array([Vector2(-8.0, -6.0), Vector2(-17.0, -12.0), Vector2(-16.0, -2.0)]), jade)
	parts[&"torso"] = torso

	# Gohei: a wooden wand topped by two zigzag paper streamers (accent), held up like a blessing.
	var gohei: InkBatch = InkBatch.new()
	gohei.limb(Vector2(-10.0, 0.0), Vector2(52.0, 0.0), 3.4, 2.8, ink)
	for side: float in [1.0, -1.0]:
		gohei.fill(PackedVector2Array([Vector2(44.0, side * 1.0), Vector2(49.0, side * 1.0), Vector2(51.0, side * 6.0),
				Vector2(47.0, side * 9.5), Vector2(51.0, side * 13.0), Vector2(47.0, side * 17.0), Vector2(44.0, side * 12.0),
				Vector2(46.0, side * 8.0), Vector2(43.0, side * 5.0)]), jade)
	parts[&"weapon"] = gohei


# --- Spear Guardian ---------------------------------------------------------

static func _build_guardian(parts: Dictionary) -> void:
	var ink: Color = InkPalette.INK
	var detail: Color = InkPalette.INK_DETAIL
	var azure: Color = InkPalette.GUARDIAN_AZURE

	parts[&"pauldron_front"] = FigurePainter._sode(ink, detail)
	parts[&"pauldron_back"] = FigurePainter._sode(InkPalette.INK_BACK, InkPalette.INK_BACK)

	var torso: InkBatch = InkBatch.new()
	# Kusazuri: four heavy tassets over the thighs.
	for i: int in 4:
		var left: float = -13.0 + float(i) * 6.6
		torso.fill_convex(PackedVector2Array([Vector2(left, -4.0), Vector2(left + 6.2, -4.0), Vector2(left + 7.0, 16.0 + float(i % 2) * 1.6),
				Vector2(left - 0.6, 16.0 + float(i % 2) * 1.6)]), ink)
		torso.limb(Vector2(left + 1.0, 6.0), Vector2(left + 5.5, 6.0), 1.4, 1.4, detail)
	# Broad do: four overlapping bands and a plate over the shoulders.
	torso.fill(PackedVector2Array([Vector2(-10.0, -2.0), Vector2(10.5, -2.0), Vector2(15.5, -14.0), Vector2(17.0, -26.0),
			Vector2(12.0, -33.0), Vector2(3.0, -35.0), Vector2(-7.0, -34.0), Vector2(-15.0, -28.0), Vector2(-15.5, -14.0)]), ink)
	for y: float in [-9.0, -16.0, -23.0]:
		torso.stroke(PackedVector2Array([Vector2(-13.0, y - 0.8), Vector2(1.0, y + 1.4), Vector2(15.0, y + 0.8)]), 1.6, 1.6, detail)
	torso.limb(Vector2(-12.0, -30.0), Vector2(14.0, -29.0), 1.6, 1.6, detail)
	# Sash with a flat knot (accent).
	torso.fill_convex(PackedVector2Array([Vector2(-10.0, -3.0), Vector2(10.5, -3.0), Vector2(10.8, -7.0), Vector2(-10.2, -7.0)]), azure)
	parts[&"torso"] = torso

	var head: InkBatch = InkBatch.new()
	head.limb(Vector2.ZERO, Vector2(0.5, -4.0), 7.0, 7.0, ink)
	head.ellipse(Vector2(2.0, -8.5), Vector2(6.8, 7.0), ink)
	head.fill_convex(PackedVector2Array([Vector2(4.0, -6.5), Vector2(10.5, -5.5), Vector2(9.0, -0.5), Vector2(3.0, 0.5)]), ink)
	# Neck guard, bowl and a broad flat visor.
	head.fill(PackedVector2Array([Vector2(-6.0, -12.0), Vector2(-14.0, -3.0), Vector2(-9.0, 0.0), Vector2(-3.0, -7.0)]), ink)
	var bowl: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var angle: float = PI + PI * float(i) / 12.0
		bowl.append(Vector2(1.5, -11.0) + Vector2(cos(angle) * 9.5, sin(angle) * 8.5))
	head.fill_convex(bowl, ink)
	head.fill_convex(PackedVector2Array([Vector2(5.0, -12.5), Vector2(17.0, -11.0), Vector2(16.0, -8.0), Vector2(5.0, -9.5)]), ink)
	head.limb(Vector2(-7.0, -11.5), Vector2(10.0, -11.5), 1.8, 1.8, detail)
	# A tall flat crest standing up from the front, like a blade: the Guardian's mark.
	head.fill_convex(PackedVector2Array([Vector2(1.0, -18.5), Vector2(3.0, -31.0), Vector2(6.0, -18.5)]), ink)
	# Helmet cord and tassel (accent).
	head.stroke(PackedVector2Array([Vector2(7.0, -2.0), Vector2(8.0, 4.0), Vector2(7.0, 10.0)]), 3.2, 1.6, azure)
	parts[&"head"] = head

	# Tate: a tall shield carried on the back arm, rim and slats (it is drawn in the hand's space).
	var shield: InkBatch = InkBatch.new()
	shield.fill(PackedVector2Array([Vector2(0.0, -44.0), Vector2(15.0, -42.0), Vector2(17.0, 12.0), Vector2(1.0, 16.0)]), ink)
	shield.fill(PackedVector2Array([Vector2(15.0, -42.0), Vector2(18.0, -41.0), Vector2(20.0, 11.0), Vector2(17.0, 12.0)]), azure)
	for y: float in [-28.0, -12.0, 4.0]:
		shield.limb(Vector2(2.0, y), Vector2(15.0, y + 0.8), 1.6, 1.6, detail)
	parts[&"shield"] = shield

	# Long yari with an azure tassel under the head.
	var yari: InkBatch = InkBatch.new()
	yari.limb(Vector2(-34.0, 0.0), Vector2(96.0, 0.0), 3.8, 3.4, ink)
	yari.fill_convex(PackedVector2Array([Vector2(95.0, -2.6), Vector2(104.0, -3.8), Vector2(120.0, 0.0), Vector2(104.0, 3.8), Vector2(95.0, 2.6)]), ink)
	yari.limb(Vector2(98.0, 0.0), Vector2(117.0, 0.0), 1.6, 1.0, InkPalette.STEEL)
	yari.stroke(PackedVector2Array([Vector2(90.0, 0.0), Vector2(89.0, 5.0), Vector2(87.0, 10.0)]), 5.0, 2.0, azure)
	parts[&"weapon"] = yari


# --- Onmyoji ----------------------------------------------------------------

static func _build_onmyoji(parts: Dictionary) -> void:
	var ink: Color = InkPalette.INK
	var detail: Color = InkPalette.INK_DETAIL
	var magenta: Color = InkPalette.ONMYOJI_MAGENTA

	var head: InkBatch = InkBatch.new()
	head.limb(Vector2.ZERO, Vector2(0.5, -4.0), 5.0, 5.0, ink)
	head.ellipse(Vector2(1.0, -8.5), Vector2(6.2, 7.0), ink)
	# Eboshi: a tall lacquered court cap leaning forward, with two ribbons trailing (accent).
	head.fill(PackedVector2Array([Vector2(-6.5, -11.0), Vector2(-5.0, -24.0), Vector2(-1.0, -34.0), Vector2(6.0, -37.0),
			Vector2(9.5, -30.0), Vector2(8.0, -14.0), Vector2(0.0, -12.0)]), ink)
	head.limb(Vector2(-5.0, -13.0), Vector2(8.5, -13.0), 1.6, 1.6, detail)
	head.stroke(PackedVector2Array([Vector2(-5.5, -13.5), Vector2(-12.0, -9.0), Vector2(-17.0, -3.0)]), 3.4, 1.2, magenta)
	head.stroke(PackedVector2Array([Vector2(-5.5, -15.0), Vector2(-13.0, -14.5), Vector2(-19.0, -10.0)]), 3.0, 1.2, magenta)
	parts[&"head"] = head

	var torso: InkBatch = InkBatch.new()
	# Hakama with a few pleats.
	torso.fill(PackedVector2Array([Vector2(-9.0, -3.0), Vector2(9.0, -3.0), Vector2(13.0, 14.0), Vector2(16.0, 31.0),
			Vector2(0.0, 33.5), Vector2(-15.0, 31.0), Vector2(-12.0, 14.0)]), ink)
	for x: float in [-4.0, 4.0]:
		torso.limb(Vector2(x * 0.8, 6.0), Vector2(x * 2.4, 29.5), 1.4, 1.6, detail)
	# Kariginu: a robe with broad shoulders and a crossed collar.
	torso.fill(PackedVector2Array([Vector2(-8.0, -2.0), Vector2(8.5, -2.0), Vector2(11.0, -16.0), Vector2(13.0, -27.0),
			Vector2(5.0, -31.0), Vector2(-6.0, -30.0), Vector2(-13.0, -26.0), Vector2(-10.5, -15.0)]), ink)
	torso.limb(Vector2(4.0, -30.0), Vector2(-4.0, -11.0), 1.5, 1.5, detail)
	torso.limb(Vector2(-5.0, -29.0), Vector2(6.0, -12.0), 1.5, 1.5, detail)
	# Belt with a knot (accent).
	torso.fill_convex(PackedVector2Array([Vector2(-9.0, -3.5), Vector2(9.2, -3.5), Vector2(9.0, -8.0), Vector2(-9.3, -8.0)]), magenta)
	parts[&"torso"] = torso

	# Ofuda: a paper talisman held by its end; the seal on it is the accent.
	var ofuda: InkBatch = InkBatch.new()
	ofuda.limb(Vector2(-6.0, 0.0), Vector2(3.0, 0.0), 3.0, 3.0, ink)
	ofuda.fill_convex(PackedVector2Array([Vector2(3.0, -6.0), Vector2(34.0, -6.4), Vector2(34.0, 6.4), Vector2(3.0, 6.0)]), InkPalette.PAPER)
	ofuda.stroke(PackedVector2Array([Vector2(8.0, -2.2), Vector2(15.0, 2.4), Vector2(22.0, -2.2), Vector2(29.0, 2.4)]), 2.6, 2.6, magenta)
	ofuda.limb(Vector2(11.0, -4.5), Vector2(27.0, -4.5), 1.4, 1.4, magenta)
	ofuda.limb(Vector2(11.0, 4.5), Vector2(27.0, 4.5), 1.4, 1.4, magenta)
	parts[&"weapon"] = ofuda


# --- Hatamoto ---------------------------------------------------------------

static func _build_hatamoto(parts: Dictionary) -> void:
	var ink: Color = InkPalette.INK
	var detail: Color = InkPalette.INK_DETAIL
	var back_ink: Color = InkPalette.INK_BACK
	var orange: Color = InkPalette.HATAMOTO_ORANGE
	var spec: FigureKinds.Spec = FigureKinds.spec(InkFigure.Kind.HATAMOTO)
	var leg: float = spec.thigh + spec.shin

	for front: bool in [true, false]:
		var hakama: InkBatch = InkBatch.new()
		hakama.fill(PackedVector2Array([Vector2(-3.0, -6.0), Vector2(leg * 0.5, -8.5), Vector2(leg + 0.5, -12.5),
				Vector2(leg + 3.0, -11.5), Vector2(leg + 4.0, 0.0), Vector2(leg + 3.0, 11.5), Vector2(leg + 0.5, 12.5),
				Vector2(leg * 0.5, 8.5), Vector2(-3.0, 6.0)]), ink if front else back_ink)
		if front:
			hakama.limb(Vector2(leg * 0.3, 2.0), Vector2(leg + 1.0, 4.5), 1.5, 1.7, detail)
		parts[&"hakama_f" if front else &"hakama_b"] = hakama
	parts[&"pauldron_front"] = FigurePainter._sode(ink, detail)
	parts[&"pauldron_back"] = FigurePainter._sode(back_ink, back_ink)
	parts[&"skirt"] = FigurePainter._samurai_skirt(ink, detail, orange)
	parts[&"torso"] = FigurePainter._samurai_do(ink, detail, orange)
	for front: bool in [true, false]:
		var kote: InkBatch = InkBatch.new()
		var color: Color = ink if front else back_ink
		kote.limb(Vector2.ZERO, Vector2(spec.fore_arm, 0.0), 6.8, 5.0, color)
		kote.circle(Vector2(spec.fore_arm, 0.0), spec.hand_r, color)
		if front:
			kote.limb(Vector2(4.0, -3.0), Vector2(4.0, 3.0), 1.3, 1.3, detail)
		parts[&"fore_f" if front else &"fore_b"] = kote

	var head: InkBatch = InkBatch.new()
	head.limb(Vector2.ZERO, Vector2(0.5, -4.0), 6.5, 6.5, ink)
	head.ellipse(Vector2(2.0, -8.5), Vector2(6.8, 7.0), ink)
	head.fill_convex(PackedVector2Array([Vector2(4.0, -6.5), Vector2(10.5, -5.5), Vector2(9.0, -0.5), Vector2(3.0, 0.5)]), ink)
	for k: int in [2, 1, 0]:
		FigurePainter._lame(head, Vector2(-4.0 - float(k) * 1.4, -11.5 + float(k) * 2.3), 10.5 + float(k) * 2.2,
				7.5 + float(k) * 2.0, 1.0 + float(k) * 0.13, 1.2, ink, detail)
	var bowl: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var angle: float = PI + PI * float(i) / 12.0
		bowl.append(Vector2(1.0, -11.0) + Vector2(cos(angle) * 9.5, sin(angle) * 9.0))
	head.fill_convex(bowl, ink)
	head.fill_convex(PackedVector2Array([Vector2(6.0, -12.5), Vector2(15.0, -10.5), Vector2(14.0, -8.5), Vector2(6.0, -10.0)]), ink)
	head.limb(Vector2(-7.0, -11.5), Vector2(9.5, -11.5), 1.8, 1.8, detail)
	# Kuwagata: two swept-up horns in a V (not a crescent, so he never reads as the samurai).
	head.stroke(PackedVector2Array([Vector2(4.5, -17.0), Vector2(9.0, -24.0), Vector2(15.0, -33.0)]), 4.2, 1.2, ink)
	head.stroke(PackedVector2Array([Vector2(-1.0, -17.5), Vector2(-3.5, -25.0), Vector2(-9.0, -33.0)]), 4.2, 1.2, ink)
	head.stroke(PackedVector2Array([Vector2(7.0, -2.0), Vector2(8.0, 4.0), Vector2(7.5, 9.0)]), 3.2, 1.6, orange)
	parts[&"head"] = head

	# Sashimono: the banner on his back, a pole above his head and a flag with a mon (accent).
	var banner: InkBatch = InkBatch.new()
	banner.limb(Vector2(-7.0, -6.0), Vector2(-12.0, -100.0), 2.8, 2.4, back_ink)
	banner.fill(PackedVector2Array([Vector2(-11.7, -99.0), Vector2(-26.0, -96.0), Vector2(-34.0, -92.0), Vector2(-34.0, -62.0),
			Vector2(-26.0, -65.5), Vector2(-11.0, -63.0)]), orange)
	banner.circle(Vector2(-23.0, -79.0), 5.4, ink)
	banner.limb(Vector2(-12.0, -64.0), Vector2(-33.0, -64.0), 1.6, 1.6, ink)
	parts[&"banner"] = banner

	# Naginata: a long shaft with a sweeping curved blade (not a straight spear head).
	var naginata: InkBatch = InkBatch.new()
	naginata.limb(Vector2(-26.0, 0.0), Vector2(70.0, 0.0), 3.8, 3.4, ink)
	naginata.fill(PackedVector2Array([Vector2(68.0, 3.0), Vector2(69.0, -3.0), Vector2(82.0, -9.0), Vector2(98.0, -19.0),
			Vector2(112.0, -22.0), Vector2(101.0, -12.0), Vector2(88.0, -2.0), Vector2(75.0, 4.0)]), ink)
	naginata.stroke(PackedVector2Array([Vector2(75.0, -3.0), Vector2(90.0, -10.0), Vector2(105.0, -19.0)]), 1.6, 1.0, InkPalette.STEEL)
	naginata.stroke(PackedVector2Array([Vector2(64.0, 0.0), Vector2(63.0, 6.0), Vector2(61.0, 12.0)]), 5.0, 2.0, orange)
	parts[&"weapon"] = naginata
