class_name FigurePart
extends Node2D
## One body part of an InkFigure. A static part draws its cached InkBatch once and is then only
## moved; a dynamic part (cloth, hem) is repainted by FigurePainter when the figure asks; a glow
## part draws soft additive lights at fixed points in its parent part's space.

var figure: InkFigure
var part_name: StringName = &""
var batch: InkBatch
## Optional original painted layer on the same bone frame as procedural parts.
var art: Texture2D
var art_frame: Transform2D = Transform2D.IDENTITY
## Optional soft-edged painted patch drawn over `art` in the same frame: [indices, vertices, colours, uvs] sampling
## `patch_texture` (RosterSpriteArt.shoulder_patch()). A part may be only a patch (no `art`).
var art_patch: Array = []
var patch_texture: Texture2D
## Optional mesh [indices, vertices, colours, uvs] that draws `art`'s atlas in place of the whole layer (the samurai's
## skirt through its own outline, SamuraiSpriteArt.outline_mesh()).
var art_mesh: Array = []
## Pixels cut off the left (proximal) end of `art` (an upper arm without its open sleeve end). Still one plain
## texture rectangle, so it batches with the figure's other painted parts.
var art_trim: float = 0.0
var dynamic: bool = false
var glow_points: PackedVector2Array = PackedVector2Array()
var glow_radii: PackedFloat32Array = PackedFloat32Array()
var glow_colors: PackedColorArray = PackedColorArray()


func _draw() -> void:
	if part_name == &"bow":
		PaintedEquipment.draw_bow(self, figure)
	elif part_name == &"yumi_back" and batch != null:
		PaintedEquipment.draw_stowed_bow(self, batch)
	elif part_name == &"banner" and RosterSpriteArt.NAMES.has(figure.kind):
		PaintedEquipment.draw_banner_pole(self)
	elif art != null or not art_patch.is_empty():
		draw_set_transform_matrix(art_frame)
		if not art_mesh.is_empty() and art is AtlasTexture:
			RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), art_mesh[0], art_mesh[1], art_mesh[2],
					art_mesh[3], PackedInt32Array(), PackedFloat32Array(), (art as AtlasTexture).atlas.get_rid())
		elif art != null and art_trim > 0.0 and art is AtlasTexture:
			var region: Rect2 = (art as AtlasTexture).region
			draw_texture_rect_region((art as AtlasTexture).atlas, Rect2(art_trim, 0.0, region.size.x - art_trim, region.size.y),
					Rect2(region.position.x + art_trim, region.position.y, region.size.x - art_trim, region.size.y))
		elif art != null:
			draw_texture(art, Vector2.ZERO)
		if not art_patch.is_empty():
			RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), art_patch[0], art_patch[1], art_patch[2],
					art_patch[3], PackedInt32Array(), PackedFloat32Array(), patch_texture.get_rid())
		draw_set_transform_matrix(Transform2D.IDENTITY)
	elif dynamic:
		FigurePainter.paint_dynamic(figure, part_name, self)
	elif batch != null:
		batch.draw(self)
	for i: int in glow_points.size():
		InkBrush.glow(self, glow_points[i], glow_radii[i], glow_colors[i])
