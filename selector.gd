@tool
extends Node2D

# ALL TILE MAP LOGIC IS IN THE dual_tile_map_layer.gd


signal selection_changed(new_selection: Array[Vector2i])

var rect_mode := false
var rect_start: Vector2i
var placing := false
var removing := false
var hovering_over: Vector2i

## if [member keep_empty] is true, this will NOT remove empty tiles (so it never removes anything from the dual grid, just updates it)
@export var keep_empty := false

@export var dual_tile_map: DualTileMapLayer


func _ready() -> void:
	selection_changed.connect(update)
	# don't update in editor, this is tool just so it can draw itself
	if Engine.is_editor_hint():
		set_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)


# use unhandled_input so when I click a button, it does not also place a tile
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"rect"):
		rect_mode = !rect_mode
		queue_redraw()
		if rect_mode:
			rect_start = mouse_grid_pos()
			# reset the position at when we are re-drawing, so you don't see a quick position change for 1 frame
			# since queue_redraw() will redraw at the next frame, so change position at the next frame (so await either: 1 frame, or draw signal)
			await draw
			position = Vector2.ZERO
		update(selected_tiles())

	if event.is_action_pressed(&"add_tile"):
		placing = true
		update(selected_tiles())
	if event.is_action_released(&"add_tile"):
		placing = false
	
	if event.is_action_pressed(&"remove_tile"):
		removing = true
		update(selected_tiles())
	if event.is_action_released(&"remove_tile"):
		removing = false


func _process(_delta: float) -> void:
	var new_tile: Vector2i = mouse_grid_pos()
	if new_tile != hovering_over:
		hovering_over = new_tile
		selection_changed.emit(selected_tiles())


func update(new_selection: Array[Vector2i]) -> void:
	if rect_mode:
		queue_redraw()
	# only move when in normal mode, because in rect mode cursor stretches
	else:
		position = pos_from_mouse()


	if placing:
		for grid_pos in new_selection:
			# dual_tile_map.add_tile(grid_pos, 0)
			dual_tile_map.add_tile(grid_pos, 2)
	
	elif removing:
		for grid_pos in new_selection:
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


func pos_from_mouse() -> Vector2i:
	var new_pos: Vector2 = mouse_grid_pos() * dual_tile_map.tile_set.tile_size
	new_pos += dual_tile_map.tile_set.tile_size / 2.0
	return new_pos


func mouse_grid_pos() -> Vector2i:
	var mouse_pos = dual_tile_map.get_local_mouse_position() + dual_tile_map.tile_set.tile_size / 2.0
	var grid_pos: Vector2i = dual_tile_map.local_to_map(mouse_pos)
	return grid_pos


# TODO: maybe use a shader to create the lasso-select feel for rect mode, instead of this
func _draw() -> void:
	# var sides := [Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]
	var tile_size: int = dual_tile_map.tile_set.tile_size.x
	var half_size: float = tile_size / 2.0
	var sides := [Vector2(-half_size, -half_size), Vector2(half_size, -half_size), Vector2(half_size, half_size), Vector2(-half_size, half_size)]

	if rect_mode:
		var end = mouse_grid_pos()
		var min_x = min(rect_start.x, end.x) * tile_size + half_size
		var max_x = max(rect_start.x, end.x) * tile_size + half_size
		var min_y = min(rect_start.y, end.y) * tile_size + half_size
		var max_y = max(rect_start.y, end.y) * tile_size + half_size
		sides[0] += Vector2(min_x, min_y)
		sides[1] += Vector2(max_x, min_y)
		sides[2] += Vector2(max_x, max_y)
		sides[3] += Vector2(min_x, max_y)

	for i in range(sides.size()):
		draw_dashed_line(sides[i], sides[(i + 1) % sides.size()], Color.WHITE, 1, 6)
