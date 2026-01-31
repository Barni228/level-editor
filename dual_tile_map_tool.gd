# @tool
class_name DualTileMapTool extends TileMapLayer


## TODO: use tile_map_data to check if the tilemap has changed, and only then update


const EMPTY := -1

## how often this should update when in the editor
## it has no affect on the actual running game, just the editor
@export var update_interval := 0.1

## if true, this will hide the dual grid tilemap, revealing the real tilemap data that is stored
@export var show_raw_tilemap := false:
	set(value):
		show_raw_tilemap = value
		# if offset tilemap does not exist yet, wait for _ready to run
		if not is_instance_valid(_offset_tilemap):
			await ready

		_offset_tilemap.visible = not show_raw_tilemap


## map that maps encoded 4 int to atlas tile position (Vector2i)
## encoded key: [0] = top left, [1] = top right, [2] = bottom left, [3] = bottom right
## the numbers in the key are tile IDs (-1 = empty)
## value: tile atlas position
var _terrain_to_tile: Dictionary[int, Vector2i] = {}

# currently only 1 atlas is supported
var source_id := 0

# currently only 1 terrain set is supported
var terrain_set := 0

var _offset_tilemap: TileMapLayer


var _update_timer := 0.0


func _ready() -> void:
	_generate_terrain_to_tile()

	# create the offset tilemap
	_offset_tilemap = TileMapLayer.new()
	_offset_tilemap.tile_set = tile_set
	_offset_tilemap.position = tile_set.tile_size / 2.0
	_offset_tilemap.name = "OffsetTileMapLayer"
	add_child(_offset_tilemap, true)

	update_every_tile()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_update_timer += delta
		if _update_timer > update_interval:
			_update_timer = 0.0
			update_every_tile()


func update_every_tile() -> void:
	_offset_tilemap.clear()

	for pos in get_used_cells():
		var tile_data := get_cell_tile_data(pos)
		add_tile(pos, tile_data.terrain)
		# I could create a set that holds which cells should be updated, and then update them from there
		# to avoid updating the same tile here multiple times, but i feel like updating tiles is cheap enough to not bother
		# if pos is close to another pos, then they probably share some of the dual tiles, so I update that same dual pos multiple times


## add a tile at [param pos]
## [param tile] is the tile ID to add
func add_tile(pos: Vector2i, tile: int) -> void:
	# add a "full" tile to the tile map
	set_cell(pos, source_id, tile_from_terrain(tile, tile, tile, tile))

	for dual_pos in pos_to_dual(pos):
		format_tile(dual_pos)


## remove the tile at [param pos]
func remove_tile(pos: Vector2i) -> void:
	erase_cell(pos)

	# update the 4 corresponding dual tile map cells
	for dual_pos in pos_to_dual(pos):
		var formatted_tile: Vector2i = get_formatted_tile(dual_pos)
		# if no one is around this tile, remove it
		if formatted_tile == tile_from_terrain(EMPTY, EMPTY, EMPTY, EMPTY):
			_offset_tilemap.erase_cell(dual_pos)
		# if there is someone near this tile (who is not current tile, since we removed it), just update it
		else:
			_offset_tilemap.set_cell(dual_pos, source_id, get_formatted_tile(dual_pos))


## update the tile at [param dual_pos] to look correctly with the terrain
func format_tile(dual_pos: Vector2i) -> void:
	_offset_tilemap.set_cell(dual_pos, source_id, get_formatted_tile(dual_pos))


## takes a dual tile map position and returns the formatted atlas tile position
func get_formatted_tile(dual_pos: Vector2i) -> Vector2i:
	var key: Array[int] = []

	# pos is in dual tile map, i format it based on 4 REAL tiles around it (so not dual grid tiles)
	# so i kind of format it based on the tiles around it in different dimension
	for pos in dual_to_pos(dual_pos):
		var cell_data: TileData = get_cell_tile_data(pos)
		# if this tile does not exist
		if cell_data == null:
			key.append(EMPTY)
		else:
			key.append(cell_data.terrain)
	
	# if this key does not exist in the terrain data, then find the most common tile (the one that appears the most around us)
	# and say that everyone is either that tile, or EMPTY, nothing else (so only 2 choices)
	# THAT should be in _terrain_to_tile, because dual grid TileSet should have every possible combination for empty or not empty tile
	if encode_key(key) not in _terrain_to_tile:
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

	return tile_from_terrain(key[0], key[1], key[2], key[3])


## takes a real tile map position and returns 4 corresponding dual tile map positions
func pos_to_dual(pos: Vector2i) -> Array[Vector2i]:
	# Note: pos is bottom right tile in the dual tile map
	return [
		pos - Vector2i(1, 1), # top left
		pos - Vector2i(0, 1), # top right
		pos - Vector2i(1, 0), # bottom left
		pos - Vector2i(0, 0), # bottom right
	]


## takes a dual tile map position and returns 4 corresponding real tile map positions
func dual_to_pos(dual_pos: Vector2i) -> Array[Vector2i]:
	# Note: dual_pos is top left in the real tile map
	return [
		dual_pos + Vector2i(0, 0), # top left
		dual_pos + Vector2i(1, 0), # top right
		dual_pos + Vector2i(0, 1), # bottom left
		dual_pos + Vector2i(1, 1), # bottom right
	]


## takes 4 terrain IDs and returns the formatted atlas tile position
## prefer this function over _terrain_to_tile dictionary
func tile_from_terrain(top_left: int, top_right: int, bottom_left: int, bottom_right: int) -> Vector2i:
	return _terrain_to_tile[encode_key([top_left, top_right, bottom_left, bottom_right])]


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
func tile_data_to_terrain_key(tile_data: TileData) -> Array[int]:
	var key: Array[int] = [
		tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER),
		tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER),
		tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER),
		tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER),
	]
	return key


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
