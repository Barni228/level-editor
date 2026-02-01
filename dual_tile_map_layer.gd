class_name DualTileMapLayer extends TileMapLayer


const EMPTY := -1


## The tile map
## key: Vector2i tile position
## value: tile ID
var tile_map: Dictionary[Vector2i, int] = {}


## map that maps encoded 4 int to atlas tile position (Vector2i)
## encoded key: [0] = top left, [1] = top right, [2] = bottom left, [3] = bottom right
## the numbers in the key are tile IDs (-1 = empty)
## value: tile atlas position
var _terrain_to_tile: Dictionary[int, Vector2i] = {}

# currently only 1 atlas is supported
var source_id := 0

# currently only 1 terrain set is supported
var terrain_set := 0

func _ready() -> void:
	_generate_terrain_to_tile()

	update_every_tile()


func update_every_tile() -> void:
	clear()
	for pos in tile_map:
		add_tile(pos, tile_map[pos])


## removes every tile from the [member tile_map], and rendered tiles
func clear_all() -> void:
	tile_map.clear()
	clear()


## add a tile at [param pos]
## [param tile] is the tile ID to add
func add_tile(pos: Vector2i, tile: int) -> void:
	tile_map[pos] = tile

	for dual_pos in pos_to_dual(pos):
		format_tile(dual_pos)


## remove the tile at [param pos]
func remove_tile(pos: Vector2i) -> void:
	tile_map.erase(pos)

	# update the 4 corresponding dual tile map cells
	for dual_pos in pos_to_dual(pos):
		# if this dual tile is used by any other real tile, just update the dual tile
		if dual_to_pos(dual_pos).any(func(p): return p in tile_map):
			format_tile(dual_pos)
		# if no real tile relies on this dual tile, remove it
		else:
			erase_cell(dual_pos)


## update the tile at [param dual_pos] to look correctly with the terrain
func format_tile(dual_pos: Vector2i) -> void:
	set_cell(dual_pos, source_id, get_formatted_tile(dual_pos))


## takes a dual tile map position and returns the formatted atlas tile position
func get_formatted_tile(dual_pos: Vector2i) -> Vector2i:
	var key: Array[int] = []

	# pos is in dual tile map, i format it based on 4 REAL tiles around it (so not dual grid tiles)
	# so i kind of format it based on the tiles around it in different dimension
	for pos in dual_to_pos(dual_pos):
		key.append(tile_map.get(pos, EMPTY))
	
	return tile_from_terrain(key)


## takes 4 terrain IDs (as [param key] Array) and returns the formatted atlas tile position
## prefer this function over directly accessing [member _terrain_to_tile]
func tile_from_terrain(key: Array[int]) -> Vector2i:
	var tile = _terrain_to_tile.get(encode_key(key))
	# if this key does not exist in the terrain data, then find the most common tile (the one that appears the most around us)
	# and say that everyone is either that tile, or EMPTY, nothing else (so only 2 choices)
	# THAT should be in _terrain_to_tile, because dual grid TileSet should have every possible combination for empty or not empty tile
	if tile == null:
		# find the most common element in this array, that is not -1
		var most_common = key.reduce(func(common, new):
			if common == EMPTY:
				return new
			if new == EMPTY:
				return common
			# if both are equal, return the smaller tile ID (so it is consistent)
			if key.count(common) == key.count(new):
				return min(common, new)
			return common if key.count(common) > key.count(new) else new
		)
		# replace every non-empty tile with the most common tile
		for i in key.size():
			if key[i] != EMPTY:
				key[i] = most_common

		tile = _terrain_to_tile[encode_key(key)]

	return tile


## will generate _terrain_to_tile based on the tile set terrains
func _generate_terrain_to_tile() -> void:
	var tile_set_source: TileSetSource = tile_set.get_source(source_id)
	if tile_set_source is not TileSetAtlasSource:
		push_error("Only TileSetAtlasSource is supported")
	
	var tile_source: TileSetAtlasSource = tile_set_source
	var grid_size = tile_source.get_atlas_grid_size()
	for x in grid_size.x:
		for y in grid_size.y:
			# skip non existing tiles (the ones that are disabled)
			if tile_source.get_tile_at_coords(Vector2i(x, y)) == Vector2i(-1, -1):
				continue

			var tile_data: TileData = tile_source.get_tile_data(Vector2i(x, y), 0)
			# check if the tile data has a terrain set
			if not tile_data.is_valid_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER):
				continue

			var key: Array[int] = tile_data_to_terrain_key(tile_data)
			_terrain_to_tile[encode_key(key)] = Vector2i(x, y)


## takes a [param tile_data] and returns the 4 terrain peering bits
static func tile_data_to_terrain_key(tile_data: TileData) -> Array[int]:
	var key: Array[int] = [
		tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER),
		tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER),
		tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER),
		tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER),
	]
	return key


## takes a real tile map position and returns 4 corresponding dual tile map positions
static func pos_to_dual(pos: Vector2i) -> Array[Vector2i]:
	# Note: pos is bottom right tile in the dual tile map
	return [
		pos - Vector2i(1, 1), # top left
		pos - Vector2i(0, 1), # top right
		pos - Vector2i(1, 0), # bottom left
		pos - Vector2i(0, 0), # bottom right
	]


## takes a dual tile map position and returns 4 corresponding real tile map positions
static func dual_to_pos(dual_pos: Vector2i) -> Array[Vector2i]:
	# Note: dual_pos is top left in the real tile map
	return [
		dual_pos + Vector2i(0, 0), # top left
		dual_pos + Vector2i(1, 0), # top right
		dual_pos + Vector2i(0, 1), # bottom left
		dual_pos + Vector2i(1, 1), # bottom right
	]

## encode the [param key] into a single [code]int[/code] [br]
## every number in [param key] should be from -1 to 254
## returned value is [code]u32[/code] integer (0 to 4294967295)
static func encode_key(key: Array[int]) -> int:
	var encoded: int = 0
	for i in key.size():
		# make n a valid u8, by adding 1 (-1..=254 -> 0..=255)
		var n = key[i] + 1
		assert(0 <= n and n <= 255)
		encoded |= n << (i * 8)
	return encoded

# ## encode the 4 terrain IDs into a single [code]int[/code] [br]
# ## every terrain ID should be from -1 to 254
# ## returned value is [code]u32[/code] integer (0 to 4294967295)
# static func encode_key(top_left: int, top_right: int, bottom_left: int, bottom_right: int) -> int:
# 	return (
# 		(top_left + 1)
# 		| (top_right + 1) << 8
# 		| (bottom_left + 1) << 16
# 		| (bottom_right + 1) << 24
# 	)