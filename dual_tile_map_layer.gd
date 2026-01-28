class_name DualTileMapLayer extends TileMapLayer

# currently this only supports 1 terrain set (0)
## map that maps Array of 4 [int] to atlas tile position (Vector2i)
## key: [0] = top left, [1] = top right, [2] = bottom left, [3] = bottom right
## value: -1 = empty, 0 = grass
var terrain_to_tile: Dictionary[Array, Vector2i] = {}

## which tile set atlas to use
var source_id := 0
var tile_set_index := 0

## A dictionary that maps tile position (Vector2i) to tile type (int)
var used_cells: Dictionary[Vector2i, int] = {}


func _ready() -> void:
	var tile_set_source: TileSetSource = tile_set.get_source(tile_set_index)
	if tile_set_source is not TileSetAtlasSource:
		push_error("Only TileSetAtlasSource is supported")
	
	var tile_source: TileSetAtlasSource = tile_set_source
	var grid_size = tile_source.get_atlas_grid_size()
	for x in grid_size.x:
		for y in grid_size.y:
			if tile_source.get_tile_at_coords(Vector2i(x, y)) == Vector2i(-1, -1):
				continue

			var tile_data: TileData = tile_source.get_tile_data(Vector2i(x, y), 0)
			# you can also check if the cell neighbor is valid using tile_data.is_valid_terrain_peering_bit(...)
			var key: Array[int] = [
				tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER),
				tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER),
				tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER),
				tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER),
			]
			terrain_to_tile[key] = Vector2i(x, y)
	

# func add_tile(pos: Vector2i, terrain_set: int = 0, terrain: int = 0, ignore_empty_terrains: bool = true) -> void:
## add a tile at [param pos]
func add_tile(pos: Vector2i) -> void:
	# add the cell to the used cells
	used_cells[pos] = 0

	for dual_pos in pos_to_dual(pos):
		set_cell(dual_pos, source_id, format_tile(dual_pos))


## remove the tile at [param pos]
## if [param keep_empty] is true, this will NOT remove empty tiles (so it never removes anything from the dual grid, just updates it)
func remove_tile(pos: Vector2i, keep_empty: bool = false) -> void:
	used_cells.erase(pos)

	# update the 4 corresponding dual tile map cells
	for dual_pos in pos_to_dual(pos):
		var formatted_tile: Vector2i = format_tile(dual_pos)
		# if no one is around this tile, remove it
		if not keep_empty and formatted_tile == terrain_to_tile[[-1, -1, -1, -1]]:
			erase_cell(dual_pos)
		# if there is someone near this tile (who is not current tile, since we removed it), just update it
		else:
			set_cell(dual_pos, source_id, format_tile(dual_pos))


## takes a dual tile map position and returns the formatted atlas tile position
func format_tile(dual_pos: Vector2i) -> Vector2i:
	var key: Array[int] = []

	# pos is in dual tile map, i format it based on 4 REAL tiles around it (so not dual grid tiles)
	# so i kind of format it based on the tiles around it in different dimension
	for pos in dual_to_pos(dual_pos):
		key.append(used_cells.get(pos, -1))

	return terrain_to_tile[key]


## takes a tile position, returns 4 corner positions
func pos_to_dual(pos: Vector2i) -> Array[Vector2i]:
	# Note: pos is bottom right tile in the dual tile map
	return [
		pos - Vector2i(1, 1), # top left
		pos - Vector2i(0, 1), # top right
		pos - Vector2i(1, 0), # bottom left
		pos - Vector2i(0, 0), # bottom right
	]

func dual_to_pos(dual_pos: Vector2i) -> Array[Vector2i]:
	# Note: dual_pos is top left in the real tile map
	return [
		dual_pos + Vector2i(0, 0), # top left
		dual_pos + Vector2i(1, 0), # top right
		dual_pos + Vector2i(0, 1), # bottom left
		dual_pos + Vector2i(1, 1), # bottom right
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
