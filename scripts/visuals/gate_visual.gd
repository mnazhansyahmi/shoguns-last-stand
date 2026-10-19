class_name GateVisual
extends Node2D
## The village gate, drawn in ink: stone-based palisade wall, a gate tower with a curved tiled
## roof and studded doors, and two paper lanterns (the warm light the village is defending).
## Cracks appear as it takes damage; it goes dark when destroyed. Origin = centre of the gate
## at ground level. Visual only: VillageGate tells it about hits, damage and destruction.

const FLASH_TIME: float = 0.15
const FLASH_STRENGTH: float = 0.45
const DESTROYED_TINT: Color = Color(0.45, 0.43, 0.45)
const LANTERNS: Array[Vector2] = [Vector2(-150.0, -282.0), Vector2(150.0, -282.0)]

var _flash: float = 0.0
var _damage: float = 0.0
var _destroyed: bool = false
var _clock: float = 0.0
var _glow_layer: Node2D


func _ready() -> void:
	_glow_layer = Node2D.new()
	_glow_layer.name = "LanternGlow"
	_glow_layer.material = InkFigure.additive_material()
	add_child(_glow_layer)
	_glow_layer.draw.connect(_draw_lantern_glow)


func _process(delta: float) -> void:
	_clock += delta
	if _flash > 0.0:
		_flash = maxf(_flash - delta / FLASH_TIME, 0.0)
		queue_redraw()
	_glow_layer.queue_redraw()


func flash_hit() -> void:
	_flash = 1.0
	queue_redraw()


## 0 = intact, 1 = about to fall. Cracks appear at one third and two thirds.
func set_damage(ratio: float) -> void:
	var clamped: float = clampf(ratio, 0.0, 1.0)
	if is_equal_approx(clamped, _damage):
		return
	_damage = clamped
	queue_redraw()


func get_damage() -> float:
	return _damage


func set_destroyed() -> void:
	_destroyed = true
	modulate = DESTROYED_TINT
	queue_redraw()


func is_lit() -> bool:
	return not _destroyed


## Kept for the visual interface; the gate only goes dark through set_destroyed().
func set_tint(color: Color) -> void:
	modulate = color


func _ink(color: Color) -> Color:
	return color.lerp(InkPalette.PAPER, _flash * FLASH_STRENGTH) if _flash > 0.0 else color


func _draw() -> void:
	var ink: Color = _ink(InkPalette.INK)
	var back: Color = _ink(InkPalette.INK_BACK)
	var detail: Color = _ink(InkPalette.INK_DETAIL)
	_draw_wall(ink, back, detail)
	_draw_tower(ink, back, detail)
	_draw_cracks()
	_draw_lanterns(ink)


func _draw_wall(ink: Color, back: Color, detail: Color) -> void:
	InkBrush.fill_convex(self, PackedVector2Array([Vector2(-820.0, 0.0), Vector2(-96.0, 0.0),
			Vector2(-100.0, -48.0), Vector2(-820.0, -52.0)]), back)
	for row: int in 3:
		var y: float = -2.0 - row * 16.0
		InkBrush.limb(self, Vector2(-818.0, y - 14.0), Vector2(-100.0, y - 14.0), 2.0, 2.0, detail)
		var x: float = -812.0 + (row % 2) * 22.0
		while x < -104.0:
			InkBrush.limb(self, Vector2(x, y - 1.0), Vector2(x, y - 13.0), 2.0, 2.0, detail)
			x += 44.0
	InkBrush.fill_convex(self, PackedVector2Array([Vector2(-820.0, -50.0), Vector2(-100.0, -46.0),
			Vector2(-100.0, -204.0), Vector2(-820.0, -204.0)]), ink)
	var plank: float = -804.0
	while plank < -104.0:
		InkBrush.limb(self, Vector2(plank, -56.0), Vector2(plank, -198.0), 2.0, 2.0, detail)
		plank += 34.0
	InkBrush.fill(self, PackedVector2Array([Vector2(-840.0, -212.0), Vector2(-826.0, -200.0), Vector2(-90.0, -200.0),
			Vector2(-80.0, -214.0), Vector2(-92.0, -232.0), Vector2(-826.0, -232.0)]), ink)
	var tile: float = -826.0
	while tile < -96.0:
		InkBrush.limb(self, Vector2(tile, -206.0), Vector2(tile, -214.0), 2.0, 2.0, detail)
		tile += 14.0


func _draw_tower(ink: Color, back: Color, detail: Color) -> void:
	# Doors.
	InkBrush.fill_convex(self, PackedVector2Array([Vector2(-74.0, 0.0), Vector2(74.0, 0.0),
			Vector2(74.0, -252.0), Vector2(-74.0, -252.0)]), back)
	var x: float = -56.0
	while x < 70.0:
		InkBrush.limb(self, Vector2(x, -6.0), Vector2(x, -246.0), 2.0, 2.0, detail)
		x += 18.0
	InkBrush.limb(self, Vector2(0.0, -4.0), Vector2(0.0, -248.0), 3.0, 3.0, ink)
	for band_y: float in [-62.0, -190.0]:
		InkBrush.limb(self, Vector2(-72.0, band_y), Vector2(72.0, band_y), 7.0, 7.0, ink)
		var stud: float = -62.0
		while stud < 70.0:
			draw_circle(Vector2(stud, band_y), 2.4, detail)
			stud += 16.0
	# Posts, lintel, upper wall with a name plaque.
	for side: float in [-1.0, 1.0]:
		InkBrush.fill_convex(self, PackedVector2Array([Vector2(side * 100.0, 0.0), Vector2(side * 72.0, 0.0),
				Vector2(side * 74.0, -320.0), Vector2(side * 98.0, -320.0)]), ink)
	InkBrush.fill_convex(self, PackedVector2Array([Vector2(-122.0, -256.0), Vector2(122.0, -256.0),
			Vector2(122.0, -276.0), Vector2(-122.0, -276.0)]), ink)
	InkBrush.fill_convex(self, PackedVector2Array([Vector2(-96.0, -276.0), Vector2(96.0, -276.0),
			Vector2(96.0, -322.0), Vector2(-96.0, -322.0)]), ink)
	InkBrush.fill_convex(self, PackedVector2Array([Vector2(-28.0, -284.0), Vector2(28.0, -284.0),
			Vector2(28.0, -312.0), Vector2(-28.0, -312.0)]), detail)
	# Curved roof with upturned eaves, ridge and curled ridge ornaments.
	InkBrush.fill(self, PackedVector2Array([Vector2(-186.0, -348.0), Vector2(-152.0, -326.0), Vector2(152.0, -326.0),
			Vector2(186.0, -348.0), Vector2(152.0, -354.0), Vector2(126.0, -374.0), Vector2(-126.0, -374.0),
			Vector2(-152.0, -354.0)]), ink)
	var eave: float = -146.0
	while eave <= 146.0:
		InkBrush.limb(self, Vector2(eave, -332.0), Vector2(eave * 0.92, -344.0), 2.0, 2.0, detail)
		eave += 12.0
	InkBrush.fill_convex(self, PackedVector2Array([Vector2(-140.0, -372.0), Vector2(140.0, -372.0),
			Vector2(135.0, -385.0), Vector2(-135.0, -385.0)]), ink)
	for side: float in [-1.0, 1.0]:
		InkBrush.stroke(self, PackedVector2Array([Vector2(side * 132.0, -382.0), Vector2(side * 144.0, -396.0),
				Vector2(side * 139.0, -408.0), Vector2(side * 130.0, -404.0)]), 7.0, 3.0, ink)


func _draw_cracks() -> void:
	if _damage < 0.33:
		return
	var crack: Color = Color(InkPalette.MIST, 0.7)
	InkBrush.stroke(self, PackedVector2Array([Vector2(-30.0, -214.0), Vector2(-12.0, -176.0), Vector2(-22.0, -142.0),
			Vector2(-4.0, -108.0)]), 3.0, 1.5, crack)
	InkBrush.stroke(self, PackedVector2Array([Vector2(-86.0, -300.0), Vector2(-80.0, -262.0), Vector2(-88.0, -232.0)]),
			2.6, 1.5, crack)
	if _damage < 0.66:
		return
	InkBrush.stroke(self, PackedVector2Array([Vector2(46.0, -96.0), Vector2(24.0, -70.0), Vector2(34.0, -36.0),
			Vector2(18.0, -12.0)]), 3.0, 1.5, crack)
	InkBrush.stroke(self, PackedVector2Array([Vector2(110.0, -340.0), Vector2(84.0, -334.0), Vector2(70.0, -342.0)]),
			2.6, 1.5, crack)
	InkBrush.stroke(self, PackedVector2Array([Vector2(-60.0, -40.0), Vector2(-40.0, -58.0), Vector2(-48.0, -84.0)]),
			2.6, 1.5, crack)


func _draw_lanterns(ink: Color) -> void:
	var paper: Color = InkPalette.MOON if not _destroyed else InkPalette.MIST.darkened(0.3)
	for lantern: Vector2 in LANTERNS:
		InkBrush.limb(self, Vector2(lantern.x, -328.0), lantern + Vector2(0.0, -18.0), 2.0, 2.0, ink)
		InkBrush.ellipse(self, lantern, Vector2(13.0, 18.0), paper)
		for rib: float in [-7.0, 0.0, 7.0]:
			InkBrush.limb(self, lantern + Vector2(-12.0, rib), lantern + Vector2(12.0, rib), 1.6, 1.6,
					Color(InkPalette.MOON_HALO.darkened(0.35), 0.6))
		InkBrush.fill_convex(self, PackedVector2Array([lantern + Vector2(-9.0, -15.0), lantern + Vector2(9.0, -15.0),
				lantern + Vector2(8.0, -21.0), lantern + Vector2(-8.0, -21.0)]), ink)
		InkBrush.fill_convex(self, PackedVector2Array([lantern + Vector2(-9.0, 15.0), lantern + Vector2(9.0, 15.0),
				lantern + Vector2(8.0, 21.0), lantern + Vector2(-8.0, 21.0)]), ink)


func _draw_lantern_glow() -> void:
	if _destroyed:
		return
	for i: int in LANTERNS.size():
		var flicker: float = 0.88 + 0.12 * sin(_clock * (7.0 + i * 2.3) + i) * sin(_clock * 3.1 + i * 1.7)
		InkBrush.glow(_glow_layer, LANTERNS[i], 70.0 * flicker, Color(InkPalette.MOON_HALO, 0.42 * flicker))
