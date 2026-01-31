@tool
extends Node2D

# ALL TILE MAP LOGIC IS IN THE dual_tile_map_layer.gd
var rect_mode := false
var rect_start: Vector2i

## if [member keep_empty] is true, this will NOT remove empty tiles (so it never removes anything from the dual grid, just updates it)
## see [method DualTileMapTool.add_empty_tile]
@export var keep_empty := false

# @export var tilemap: TileMapLayer
# @export var dual_tile_map: DualTileMapLayer
@export var dual_tile_map: DualTileMapTool


func _ready() -> void:
	# don't update in editor, this is tool just so it can draw itself
	if Engine.is_editor_hint():
		set_process(false)


# TODO: use TileMap.local_to_map instead of assuming the grid is 16x16
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"rect"):
		rect_mode = !rect_mode
		queue_redraw()
		if rect_mode:
			rect_start = mouse_grid_pos()
			# reset the position at when we are re-drawing, so you don't see a quick position change for 1 frame
			# since queue_redraw() will redraw at the next frame, so change position at the next frame (so await either 1 frame, or draw signal)
			# await get_tree().process_frame
			await draw
			position = Vector2.ZERO

	var new_pos: Vector2 = mouse_grid_pos() * 16

	if rect_mode and not new_pos.is_equal_approx(position):
		queue_redraw()

	# only move when in normal mode, because in rect mode cursor stretches
	if not rect_mode:
		position = new_pos

	if Input.is_action_pressed(&"add_tile"):
		for grid_pos in selected_tiles():
			# dual_tile_map.add_tile(grid_pos, 0)
			dual_tile_map.add_tile(grid_pos, 2)
	

	if Input.is_action_pressed(&"remove_tile"):
		for grid_pos in selected_tiles():
			if keep_empty:
				dual_tile_map.add_tile(grid_pos, -1)
			else:
				dual_tile_map.remove_tile(grid_pos)

	
func selected_tiles() -> Array[Vector2i]:
	if rect_mode:
		var end = mouse_grid_pos()

		var min_x = min(rect_start.x, end.x)
		var max_x = max(rect_start.x, end.x)
		var min_y = min(rect_start.y, end.y)
		var max_y = max(rect_start.y, end.y)

		var result: Array[Vector2i] = []
		for x in range(min_x, max_x + 1):
			for y in range(min_y, max_y + 1):
				result.append(Vector2i(x, y))
		return result

	else:
		return [mouse_grid_pos()]

func mouse_grid_pos() -> Vector2i:
	var mouse_pos = get_global_mouse_position() - Vector2(8, 8)
	var grid_pos: Vector2i = (mouse_pos / 16).round()
	return grid_pos


func _draw() -> void:
	# var sides := [Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]
	var sides := [Vector2(0, 0), Vector2(16, 0), Vector2(16, 16), Vector2(0, 16)]

	if rect_mode:
		var end = mouse_grid_pos()
		var min_x = min(rect_start.x, end.x) * 16
		var max_x = max(rect_start.x, end.x) * 16
		var min_y = min(rect_start.y, end.y) * 16
		var max_y = max(rect_start.y, end.y) * 16
		sides[0] += Vector2(min_x, min_y)
		sides[1] += Vector2(max_x, min_y)
		sides[2] += Vector2(max_x, max_y)
		sides[3] += Vector2(min_x, max_y)

	for i in range(sides.size()):
		draw_dashed_line(sides[i], sides[(i + 1) % sides.size()], Color.WHITE, 1, 6)
