class_name DualTileMapLayer extends TileMapLayer


# TODO: make used_cells a dictionary, where values are cell info (like what terrain it uses)
# godot does not have sets yet, so pretend that this is a set (dictionary without values)
## A set of all used cells (not dual cells that are displayed, there are real tile positions)
var used_cells: Dictionary[Vector2i, Variant] = {}


## add a tile at [param pos]
func add_tile(pos: Vector2i, terrain_set: int = 0, terrain: int = 0, ignore_empty_terrains: bool = true) -> void:
	# add the cell to the used cells set
	used_cells[pos] = null

	# for p in pos_to_dual(pos):
	# 	erase_cell(p)

	# this only works with path mode, not connect mode
	set_cells_terrain_path(pos_to_dual(pos), terrain_set, terrain, ignore_empty_terrains)


func remove_tile(pos: Vector2i) -> void:
	# remove the cell from the used cells set
	used_cells.erase(pos)

	# remove 4 corresponding cells from the dual tile map
	for cell in pos_to_dual(pos):
		erase_cell(cell)

	# update the 8 cells around the removed cell
	for cell in existing_surrounding_cells(pos, used_cells):
		add_tile(cell)


func pos_to_dual(pos: Vector2i) -> Array[Vector2i]:
	# Note: pos is bottom right tile in the dual tile map
	return [
		pos - Vector2i(0, 0), # bottom right
		pos - Vector2i(1, 0), # bottom left
		pos - Vector2i(0, 1), # top right
		pos - Vector2i(1, 1), # top left
	]


## get every surrounding cell around [param pos], but only if they exist in [param all_cells] [br]
## [param pos] is not returned
func existing_surrounding_cells(pos: Vector2i, all_cells: Dictionary[Vector2i, Variant]) -> Array[Vector2i]:
	var cells = surrounding_cells(pos)
	var result: Array[Vector2i] = []

	for cell in cells:
		if cell in all_cells:
			result.append(cell)

	return result


## get every surrounding cell around [param pos] (8 in total)
## [param pos] is not returned
func surrounding_cells(pos: Vector2i) -> Array[Vector2i]:
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
