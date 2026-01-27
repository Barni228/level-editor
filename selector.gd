extends Sprite2D


# @export var tilemap: TileMapLayer
@export var dual_tile_map: DualTileMapLayer


func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var grid_pos: Vector2i = (mouse_pos / 16).round()
	position = grid_pos * 16
	if Input.is_action_pressed(&"add_tile"):
		dual_tile_map.add_tile(grid_pos)
	
	if Input.is_action_pressed(&"remove_tile"):
	# if Input.is_action_just_pressed(&"remove_tile"):
		dual_tile_map.remove_tile(grid_pos)
		# dual_tile_map.set_cell(grid_pos, 0, Vector2(0, 3))
		# dual_tile_map.add_tile(grid_pos, 0, 0)
