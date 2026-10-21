class_name FigureSkillArt
extends RefCounted
## Shared, one-shot renders of the game's own figures. Only the resulting textures survive;
## no animated skeletons or live render targets are kept behind the HUD.

const PIXELS: int = 256
static var _textures: Dictionary[int, ImageTexture] = {}


static func supports(kind: int) -> bool:
	return kind in [UpgradeIcon.Kind.DASH, UpgradeIcon.Kind.HEAVY, UpgradeIcon.Kind.SPIRIT_SLASH,
		UpgradeIcon.Kind.BOW, UpgradeIcon.Kind.WAR_CRY, UpgradeIcon.Kind.STANCE_CHARGE,
		UpgradeIcon.Kind.STANCE_HOLD, UpgradeIcon.Kind.ATTACK]


static func texture(owner: Node, kind: int) -> Texture2D:
	if not _textures.has(kind):
		var result: ImageTexture = ImageTexture.create_from_image(Image.create(PIXELS, PIXELS, false, Image.FORMAT_RGBA8))
		_textures[kind] = result
		if DisplayServer.get_name() != "headless":
			var baker: Baker = Baker.new()
			baker.icon_kind = kind
			baker.result = result
			owner.get_tree().root.add_child.call_deferred(baker)
	return _textures[kind]


static func draw_round(ci: CanvasItem, art: Texture2D, center: Vector2, radius: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	for i: int in 64:
		var unit: Vector2 = Vector2.from_angle(TAU * float(i) / 64.0)
		points.append(center + unit * radius)
		uvs.append(Vector2.ONE * 0.5 + unit * 0.5)
	ci.draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, art)


class Baker extends SubViewport:
	var icon_kind: int
	var result: ImageTexture

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		size = Vector2i(PIXELS, PIXELS)
		transparent_bg = true
		render_target_update_mode = SubViewport.UPDATE_ONCE
		var stage: Stage = Stage.new()
		stage.icon_kind = icon_kind
		add_child(stage)
		await RenderingServer.frame_post_draw
		var rendered: Image = get_texture().get_image()
		if rendered != null and not rendered.is_empty():
			result.update(rendered)
		queue_free()


class Stage extends Node2D:
	var icon_kind: int

	func _ready() -> void:
		match icon_kind:
			UpgradeIcon.Kind.DASH:
				for i: int in 3:
					_figure(InkFigure.Kind.SAMURAI, &"dash", Vector2(57.0 + i * 34.0, 214.0), 148.0,
						Color(1.0, 1.0, 1.0, [0.18, 0.38, 1.0][i]))
			UpgradeIcon.Kind.STANCE_CHARGE:
				_figure(InkFigure.Kind.ASHIGARU, &"run", Vector2(69.0, 207.0), 112.0, InkPalette.PARCHMENT_DIM)
				_figure(InkFigure.Kind.HATAMOTO, &"run", Vector2(126.0, 224.0), 146.0, InkPalette.PARCHMENT)
			UpgradeIcon.Kind.STANCE_HOLD:
				_figure(InkFigure.Kind.SPEAR_GUARDIAN, &"idle", Vector2(114.0, 229.0), 164.0)
			_:
				var state: StringName = &"strike"
				match icon_kind:
					UpgradeIcon.Kind.BOW: state = &"shoot"
					UpgradeIcon.Kind.SPIRIT_SLASH: state = &"cast"
					UpgradeIcon.Kind.WAR_CRY: state = &"war_cry"
				_figure(InkFigure.Kind.SAMURAI, state, Vector2(107.0, 225.0), 153.0)
		queue_redraw()


	func _figure(kind: InkFigure.Kind, state: StringName, at: Vector2, height_px: float, tint: Color = Color.WHITE) -> void:
		var figure: InkFigure = InkFigure.new()
		figure.kind = kind
		figure.height = height_px
		figure.position = at
		add_child(figure)
		figure.pose.copy_from(FigureKinds.pose(kind, state, 0, icon_kind == UpgradeIcon.Kind.HEAVY))
		figure.refresh()
		figure.modulate = tint
		if icon_kind == UpgradeIcon.Kind.STANCE_CHARGE:
			var shader: Shader = Shader.new()
			shader.code = "shader_type canvas_item; void fragment() { COLOR = vec4(vec3(0.055, 0.045, 0.07), COLOR.a); }"
			var silhouette: ShaderMaterial = ShaderMaterial.new()
			silhouette.shader = shader
			for part: FigurePart in figure.get_children():
				part.material = silhouette


	func _draw() -> void:
		# A dusk moon separates the black armour from the charcoal frame at HUD size.
		draw_circle(Vector2(128.0, 128.0), 128.0, InkPalette.SKY_HORIZON.darkened(0.5))
		draw_circle(Vector2(121.0, 113.0), 92.0, InkPalette.MOON.darkened(0.46))
		draw_circle(Vector2(133.0, 214.0), 82.0, Color(InkPalette.SAMURAI_RED.darkened(0.62), 0.65))
		match icon_kind:
			UpgradeIcon.Kind.HEAVY:
				draw_arc(Vector2(111.0, 131.0), 91.0, -1.7, 0.9, 40, Color(InkPalette.SAMURAI_RED, 0.85), 15.0, true)
				draw_arc(Vector2(111.0, 131.0), 91.0, -1.6, 0.85, 40, InkPalette.PAPER, 4.0, true)
			UpgradeIcon.Kind.SPIRIT_SLASH:
				for layer: int in 3:
					draw_arc(Vector2(144.0, 133.0), 71.0 + layer * 4.0, -1.2, 1.0, 40,
						[InkPalette.SPIRIT_DEEP, InkPalette.SPIRIT, InkPalette.PAPER][layer], 19.0 - layer * 7.0, true)
			UpgradeIcon.Kind.WAR_CRY:
				draw_arc(Vector2(127.0, 144.0), 85.0, 0.0, TAU, 64, Color(InkPalette.GOLD_BRIGHT, 0.8), 7.0, true)
