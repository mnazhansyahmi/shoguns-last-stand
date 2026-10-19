class_name RegionBackdrop
extends Node2D
## Root of a region backdrop scene (a stack of BackdropLayers). Menus reuse the battle backdrop
## behind their UI with `front_fog` off, because the front fog layer is drawn on top of
## everything in its canvas (it passes in front of the fighters in battle).

@export var front_fog: bool = true


func _ready() -> void:
	if front_fog:
		return
	for child: Node in get_children():
		var layer: BackdropLayer = child as BackdropLayer
		if layer != null and layer.z_index > 0:
			layer.visible = false
			layer.set_process(false)
