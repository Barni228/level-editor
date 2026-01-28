@tool
extends Node2D

## if [member keep_empty] is true, this will NOT remove empty tiles (so it never removes anything from the dual grid, just updates it)
## see [method DualTileMapLayer.remove_tile]
@export var keep_empty := false

# @export var tilemap: TileMapLayer
@export var dual_tile_map: DualTileMapLayer


func _ready() -> void:
	# only do _draw in the editor
	if Engine.is_editor_hint():
		set_process(false)


func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var grid_pos: Vector2i = (mouse_pos / 16).round()
	position = grid_pos * 16

	if Input.is_action_pressed(&"add_tile"):
		dual_tile_map.add_tile(grid_pos)
	
	if Input.is_action_pressed(&"remove_tile"):
		dual_tile_map.remove_tile(grid_pos, keep_empty)


func _draw() -> void:
	var sides = [Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]
	for i in range(sides.size()):
		draw_dashed_line(sides[i], sides[(i + 1) % sides.size()], Color.WHITE, 1, 6)
