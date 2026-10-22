class_name EnemyBriefing
extends CanvasLayer
## Modal pre-wave intelligence, also reachable while paused. No live combat underneath.
signal dismissed
const TIPS: Dictionary = {
	InkFigure.Kind.HOLLOW_SOLDIER: "Cut through their ranks.",
	InkFigure.Kind.ONI_BRUTE: "Heavy attacks break its armor.",
	InkFigure.Kind.FALLEN_DAIMYO: "Dodge the warning, then counter.",
	InkFigure.Kind.SPECTRAL_ARCHER: "Dash close; punish the draw.",
	InkFigure.Kind.SHIELD_BEARER: "Break its shield with Heavy.",
	InkFigure.Kind.FLYING_SPIRIT: "Use Bow or ranged allies.",
	InkFigure.Kind.BURNING_GENERAL: "Evade fire; strike in recovery.",
}
var _root: Control
var _cards: GridContainer
var _title: Label
var _confirm: Button
var card_count: int = 0
var new_count: int = 0


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.025, 0.02, 0.03, 0.91)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	center.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for edge: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 28)
	panel.add_child(margin)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 24)
	margin.add_child(stack)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 48)
	stack.add_child(_title)
	_cards = GridContainer.new()
	_cards.add_theme_constant_override("h_separation", 16)
	_cards.add_theme_constant_override("v_separation", 16)
	stack.add_child(_cards)
	_confirm = Button.new()
	_confirm.text = "Ready — press any key or tap"
	_confirm.custom_minimum_size.y = 124
	_confirm.add_theme_font_size_override("font_size", 32)
	_confirm.pressed.connect(dismiss)
	stack.add_child(_confirm)
	hide()


static func enemy_id(enemy: EnemyData) -> String:
	return enemy.resource_path.get_file().get_basename()


static func first_encounter(enemy: EnemyData, progress: PlayerProgress) -> bool:
	if progress.seen_enemy_ids.has(enemy_id(enemy)): return false
	# Older saves already know enemies from stages they completed.
	for stage: StageData in StageProgression.all_stages():
		if progress.is_stage_cleared(stage.stage_id) and stage.enemy_types().has(enemy): return false
	return true


func open(stage: StageData, progress: PlayerProgress, record_seen: bool = true) -> void:
	for child: Node in _cards.get_children(): child.free()
	card_count = 0
	new_count = 0
	_title.text = stage.display_name + " — Enemy briefing"
	var enemies: Array[EnemyData] = stage.enemy_types()
	var width: float = get_viewport().get_visible_rect().size.x
	_cards.columns = mini(enemies.size(), maxi(1, int((width - 120) / 250.0)))
	for enemy: EnemyData in enemies:
		var is_new: bool = first_encounter(enemy, progress)
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(230, 340)
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.105, 0.12)
		style.border_color = Color(0.65, 0.45, 0.20) if is_new else Color(0.30, 0.28, 0.29)
		style.set_border_width_all(2)
		style.set_content_margin_all(14)
		card.add_theme_stylebox_override("panel", style)
		_cards.add_child(card)
		var stack: VBoxContainer = VBoxContainer.new()
		stack.add_theme_constant_override("separation", 8)
		card.add_child(stack)
		var tag: Label = _label("NEW" if is_new else "ENEMY", 24)
		tag.modulate = Color("deb85b") if is_new else Color(0.6, 0.58, 0.56)
		stack.add_child(tag)
		var portrait: TextureRect = TextureRect.new()
		portrait.texture = RosterSpriteArt.texture(enemy.figure, &"head")
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(200, 160)
		stack.add_child(portrait)
		var name_label: Label = _label(enemy.display_name, 29)
		name_label.custom_minimum_size.y = 70
		stack.add_child(name_label)
		stack.add_child(_label(TIPS.get(enemy.figure, "Watch its attacks, then counter."), 24))
		card_count += 1
		if is_new: new_count += 1
		var id: String = enemy_id(enemy)
		if record_seen and not progress.seen_enemy_ids.has(id): progress.seen_enemy_ids.append(id)
	show()
	_confirm.grab_focus()


func _label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	return label


func dismiss() -> void:
	if not visible: return
	hide()
	dismissed.emit()


func _input(event: InputEvent) -> void:
	if not visible: return
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventJoypadButton and event.pressed)
	if pressed:
		get_viewport().set_input_as_handled()
		dismiss()
