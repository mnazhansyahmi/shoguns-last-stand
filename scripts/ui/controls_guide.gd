class_name ControlsGuide
extends VBoxContainer
## Settings' controls page. The layout picture uses the same layout math and cached art as play.

signal back_requested


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_label(self, "Controls", 44, true)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 72)
	add_child(columns)
	var keyboard: VBoxContainer = VBoxContainer.new()
	keyboard.custom_minimum_size.x = 650.0
	columns.add_child(keyboard)
	_label(keyboard, "Keyboard", 34)
	_label(keyboard, "A / D or arrows     Move\nJ     Attack · three-hit combo\nK     Heavy strike       L     Dash\nU     Spirit Slash        I     Ultimate\nE     Draw bow           Q     War Cry\nF     Allies: charge / hold\n1–6 or click portrait     Summon\nEsc     Pause / resume", 28)
	var gamepad: VBoxContainer = VBoxContainer.new()
	columns.add_child(gamepad)
	_label(gamepad, "Gamepad · Xbox / PlayStation", 34)
	_label(gamepad, "Left stick / D-pad left–right     Move\nX / Square     Attack      Y / Triangle     Heavy\nA / Cross     Dash          B / Circle     Allies\nRB / R1     Spirit Slash   LB / L1     War Cry\nRT / R2     Bow              LT / L2     Ultimate\nD-pad up–down     Select summon portrait\nRight stick click (R3)     Summon selected ally\nMenu / Options     Pause      A / Cross     Confirm", 28)
	_label(self, "Touch layout", 34)
	var touch: HBoxContainer = HBoxContainer.new()
	touch.add_theme_constant_override("separation", 40)
	add_child(touch)
	var picture: TouchPicture = TouchPicture.new()
	picture.custom_minimum_size = Vector2(720.0, 300.0)
	touch.add_child(picture)
	_label(touch, "Left thumb · slide to move\nRight thumb · tap a skill picture\nBottom portraits · summon allies\nGold ring · Ultimate charge\nTop right · pause\nMirror in Settings → Left-handed", 28)
	var back: Button = Button.new()
	back.text = "Back to Settings"
	back.custom_minimum_size = Vector2(0.0, 124.0)
	back.add_theme_font_size_override("font_size", 34)
	back.pressed.connect(back_requested.emit)
	add_child(back)


static func _label(parent: Node, text: String, font_size: int, centered: bool = false) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)


class TouchPicture extends Control:
	var _art: Dictionary = {}
	var _portraits: Array[Texture2D] = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for pair: Array in [["attack", UpgradeIcon.Kind.ATTACK], ["heavy", UpgradeIcon.Kind.HEAVY],
			["dash", UpgradeIcon.Kind.DASH], ["slash", UpgradeIcon.Kind.SPIRIT_SLASH], ["bow", UpgradeIcon.Kind.BOW],
			["war_cry", UpgradeIcon.Kind.WAR_CRY], ["stance", UpgradeIcon.Kind.STANCE_CHARGE]]:
			_art[pair[0]] = FigureSkillArt.texture(self, pair[1])
		_art["ultimate"] = FigureSkillArt.portrait(self, InkFigure.Kind.SAMURAI)
		for kind: InkFigure.Kind in [InkFigure.Kind.ASHIGARU, InkFigure.Kind.YUMI_ARCHER, InkFigure.Kind.SHRINE_HEALER,
			InkFigure.Kind.SPEAR_GUARDIAN, InkFigure.Kind.ONMYOJI, InkFigure.Kind.HATAMOTO]:
			_portraits.append(FigureSkillArt.portrait(self, kind))

	func _draw() -> void:
		var screen: Vector2 = Vector2(2341.0, 1080.0)
		var factor: float = minf(size.x / screen.x, size.y / screen.y)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * factor)
		draw_rect(Rect2(Vector2.ZERO, screen), InkPalette.SKY_HORIZON.darkened(0.6))
		draw_rect(Rect2(Vector2.ZERO, screen), InkPalette.GOLD, false, 8.0)
		draw_circle(Vector2(1280.0, 225.0), 100.0, InkPalette.MOON)
		draw_line(Vector2(0.0, 460.0), Vector2(2341.0, 460.0), InkPalette.GROUND_TOP, 15.0)
		var rects: Dictionary = TouchLayout.compute(screen, Rect2(Vector2.ZERO, screen), 1.0, false, 6)
		var joystick: Rect2 = rects["joystick"]
		draw_circle(joystick.get_center(), joystick.size.x * 0.48, InkPalette.UI_CHARCOAL)
		draw_arc(joystick.get_center(), joystick.size.x * 0.48, 0.0, TAU, 40, InkPalette.GOLD, 7.0, true)
		draw_circle(joystick.get_center(), joystick.size.x * 0.18, InkPalette.PARCHMENT_DIM)
		for key: String in TouchLayout.ACTION_BUTTONS:
			var rect: Rect2 = TouchLayout.ACTION_BUTTONS[key]
			rect.position += (rects["actions"] as Rect2).position
			_icon(rect, _art[key])
		_icon(rects["stance"], _art["stance"])
		var summons: Rect2 = rects["summons"]
		var buttons: Array[Rect2] = TouchLayout.summon_button_rects(6, summons.size, 1.0)
		for slot: int in buttons.size():
			var rect: Rect2 = buttons[slot]
			rect.position += summons.position
			_icon(rect, _portraits[slot])
		draw_rect(Rect2(2145.0, 35.0, 150.0, 125.0), InkPalette.UI_CHARCOAL)
		draw_line(Vector2(2200.0, 65.0), Vector2(2200.0, 130.0), InkPalette.PARCHMENT, 14.0)
		draw_line(Vector2(2240.0, 65.0), Vector2(2240.0, 130.0), InkPalette.PARCHMENT, 14.0)

	func _icon(rect: Rect2, art: Texture2D) -> void:
		var radius: float = minf(rect.size.x, rect.size.y) * 0.48
		draw_circle(rect.get_center(), radius, InkPalette.UI_CHARCOAL)
		FigureSkillArt.draw_round(self, art, rect.get_center(), radius)
		draw_arc(rect.get_center(), radius, 0.0, TAU, 32, InkPalette.GOLD_BRIGHT, 5.0, true)
