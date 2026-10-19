class_name FigurePart
extends Node2D
## One body part of an InkFigure. A static part draws its cached InkBatch once and is then only
## moved; a dynamic part (cloth, hem) is repainted by FigurePainter when the figure asks; a glow
## part draws soft additive lights at fixed points in its parent part's space.

var figure: InkFigure
var part_name: StringName = &""
var batch: InkBatch
var dynamic: bool = false
var glow_points: PackedVector2Array = PackedVector2Array()
var glow_radii: PackedFloat32Array = PackedFloat32Array()
var glow_colors: PackedColorArray = PackedColorArray()


func _draw() -> void:
	if dynamic:
		FigurePainter.paint_dynamic(figure, part_name, self)
	elif batch != null:
		batch.draw(self)
	for i: int in glow_points.size():
		InkBrush.glow(self, glow_points[i], glow_radii[i], glow_colors[i])
