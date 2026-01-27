extends Sprite2D


@export var tilemap: TileMapLayer

func _ready() -> void:
	var tile_set_index: int = 0
	var tile_set_source: TileSetSource = tilemap.tile_set.get_source(tile_set_index)
	if tile_set_source is not TileSetAtlasSource:
		return
	
	var tile_source: TileSetAtlasSource = tile_set_source
	var tile_pos: Vector2i = Vector2i(0, 0)
	var tile_data: TileData = tile_source.get_tile_data(tile_pos, 0)
	var space_or_char: Callable = func(neighbor: TileSet.CellNeighbor, chr: String) -> String:
		if tile_data.is_valid_terrain_peering_bit(neighbor) and tile_data.get_terrain_peering_bit(neighbor) != -1:
			return chr
		else:
			return "."
	
	# var drawing: String = """\
	# %s%s\
	# %s%s\
	# """ % [
	var drawing: String = "%s%s\n%s%s\n" % [
		space_or_char.call(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER, "┌"),
		space_or_char.call(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER, "┐"),
		space_or_char.call(TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, "└"),
		space_or_char.call(TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, "┘"),
	]
	print(drawing)
	# for i in 16:
	# 	printt(i, tile_data.is_valid_terrain_peering_bit(i))


func _process(_delta: float) -> void:
	# var mouse_pos = get_global_mouse_position() - Vector2(8, 8)
	var mouse_pos = get_global_mouse_position()
	var grid_pos: Vector2i = (mouse_pos / 16).round()
	position = grid_pos * 16
	# position += Vector2(8, 8)
	if Input.is_action_pressed(&"add_tile"):
	# if Input.is_action_just_pressed(&"add_tile"):
		# tilemap.set_cell(grid_pos, 0, Vector2(0, 0))
		# tilemap.set_cells_terrain_connect(real_surrounding_cells(grid_pos), 0, 0)
		tilemap.set_cells_terrain_connect([
			grid_pos,
			grid_pos - Vector2i(1, 0),
			grid_pos - Vector2i(0, 1),
			grid_pos - Vector2i(1, 1),
		], 0, 0)
		# tilemap.set_cells_terrain_connect([grid_pos], 0, 0)
	elif Input.is_action_pressed("remove_tile"):
		# tilemap.set_cell(grid_pos)
		tilemap.set_cells_terrain_connect([
			grid_pos,
			grid_pos - Vector2i(1, 0),
			grid_pos - Vector2i(0, 1),
			grid_pos - Vector2i(1, 1),
		], 0, 0)


func real_surrounding_cells(pos: Vector2i) -> Array[Vector2i]:
	var cells = _surrounding_cells(pos)
	var all_cells = tilemap.get_used_cells()
	var result: Array[Vector2i] = [pos]

	for cell in cells:
		if cell in all_cells:
			result.append(cell)

	print(result)
	return result


func _surrounding_cells(pos: Vector2i) -> Array[Vector2i]:
	return [
		pos + Vector2i(-1, -1),
		pos + Vector2i(0, -1),
		pos + Vector2i(1, -1),
		pos + Vector2i(-1, 0),
		pos + Vector2i(1, 0),
		pos + Vector2i(-1, 1),
		pos + Vector2i(0, 1),
		pos + Vector2i(1, 1),
	]
