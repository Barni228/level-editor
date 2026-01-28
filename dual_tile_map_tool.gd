@tool
class_name DualTileMapTool extends TileMapLayer


## how often this should update when in the editor
## it has no affect on the actual running game, just the editor
@export var update_interval := 0.1

## if true, this will hide the dual grid tilemap, revealing the real tilemap data that is stored
@export var show_raw_tilemap := false:
	set(value):
		show_raw_tilemap = value
		# if offset tilemap does not exist yet, wait for _ready to run
		if not is_instance_valid(offset_tilemap):
			await ready

		offset_tilemap.visible = not show_raw_tilemap

## if true, the offset tilemap will not be shows in the editor
## Note: when you change this, you need to restart the scene for it to take effect
var hide_offset_tilemap := true


# currently this only supports 1 terrain set (0)
## map that maps Array of 4 [int] to atlas tile position (Vector2i)
## key: [0] = top left, [1] = top right, [2] = bottom left, [3] = bottom right
## the int values are: -1 = empty, 0 = not empty
## value: tile atlas position
var terrain_to_tile: Dictionary[Array, Vector2i] = {}

## which tile set atlas to use
var source_id := 0
var tile_set_index := 0
var terrain_set := 0

var offset_tilemap: TileMapLayer


var _update_timer := 0.0


func _ready() -> void:
	_generate_terrain_to_tile()

	# create the offset tilemap
	offset_tilemap = TileMapLayer.new()
	offset_tilemap.tile_set = tile_set
	offset_tilemap.position = tile_set.tile_size / 2.0
	offset_tilemap.name = "OffsetTileMapLayer"

	add_child(offset_tilemap, true)
	# if not hide_offset_tilemap:
	# 	offset_tilemap.owner = get_tree().edited_scene_root

	update_every_tile()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_update_timer += delta
		if _update_timer > update_interval:
			_update_timer = 0.0
			update_every_tile()


func update_every_tile() -> void:
	offset_tilemap.clear()

	for pos in get_used_cells():
		var tile_data := get_cell_tile_data(pos)
		if tile_data_to_terrain_key(tile_data) == [-1, -1, -1, -1]:
			add_empty_tile(pos)
		else:
			add_tile(pos)

# func add_tile(pos: Vector2i, terrain_set: int = 0, terrain: int = 0, ignore_empty_terrains: bool = true) -> void:
## add a tile at [param pos]
func add_tile(pos: Vector2i) -> void:
	# add a "full" tile to the tile map
	set_cell(pos, source_id, terrain_to_tile[[0, 0, 0, 0]])

	for dual_pos in pos_to_dual(pos):
		offset_tilemap.set_cell(dual_pos, source_id, format_tile(dual_pos))


func add_empty_tile(pos: Vector2i) -> void:
	# add a "empty" tile to the tile map
	set_cell(pos, source_id, terrain_to_tile[[-1, -1, -1, -1]])

	# update the 4 corresponding dual tile map cells
	for dual_pos in pos_to_dual(pos):
		offset_tilemap.set_cell(dual_pos, source_id, format_tile(dual_pos))

## remove the tile at [param pos]
## if [param keep_empty] is true, this will NOT remove empty tiles (so it never removes anything from the dual grid, just updates it)
func remove_tile(pos: Vector2i) -> void:
	erase_cell(pos)

	# update the 4 corresponding dual tile map cells
	for dual_pos in pos_to_dual(pos):
		var formatted_tile: Vector2i = format_tile(dual_pos)
		# if no one is around this tile, remove it
		if formatted_tile == terrain_to_tile[[-1, -1, -1, -1]]:
			offset_tilemap.erase_cell(dual_pos)
		# if there is someone near this tile (who is not current tile, since we removed it), just update it
		else:
			offset_tilemap.set_cell(dual_pos, source_id, format_tile(dual_pos))


## takes a dual tile map position and returns the formatted atlas tile position
func format_tile(dual_pos: Vector2i) -> Vector2i:
	var key: Array[int] = []

	# pos is in dual tile map, i format it based on 4 REAL tiles around it (so not dual grid tiles)
	# so i kind of format it based on the tiles around it in different dimension
	for pos in dual_to_pos(dual_pos):
		var cell_data: TileData = get_cell_tile_data(pos)
		# if this tile does not exist, or it is empty, say it is empty
		if cell_data == null or tile_data_to_terrain_key(cell_data) == [-1, -1, -1, -1]:
			key.append(-1)
		else:
			# cell_data.terrain is 0, usually (it probably represents the middle square when painting terrains in tile set editor)
			key.append(cell_data.terrain)

	return terrain_to_tile[key]


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


## will generate terrain_to_tile based on the tile set terrains
func _generate_terrain_to_tile() -> void:
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
			var key: Array[int] = tile_data_to_terrain_key(tile_data)
			terrain_to_tile[key] = Vector2i(x, y)

func tile_data_to_terrain_key(tile_data: TileData) -> Array[int]:
	# you can also check if the cell neighbor is valid using tile_data.is_valid_terrain_peering_bit(...)
	var key: Array[int] = [
		tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER),
		tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER),
		tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER),
		tile_data.get_terrain_peering_bit(TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER),
	]
	return key
