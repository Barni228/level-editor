@tool
class_name DualTileMapData extends Resource


@export_storage var tile_map_data: PackedByteArray = PackedByteArray():
	set(value):
		if value != tile_map_data:
			tile_map_data = value
			tile_map = bytes_to_var_with_objects(tile_map_data)
			emit_changed()

## The tile map
## key: Vector2i tile position
## value: tile ID
var tile_map: Dictionary[Vector2i, int] = {}


## set a tile at [param pos] to [param tile]
func set_tile(pos: Vector2i, tile: int) -> void:
	tile_map[pos] = tile
	tile_map_data = var_to_bytes_with_objects(tile_map)


func get_tile(pos: Vector2i, default: Variant = null) -> int:
	return tile_map.get(pos, default)


## clear the tile map (remove all tiles)
func clear() -> void:
	tile_map.clear()
	tile_map_data = var_to_bytes_with_objects(tile_map)


## remove the tile at [param pos]
func erase(pos: Vector2i) -> void:
	tile_map.erase(pos)
	tile_map_data = var_to_bytes_with_objects(tile_map)


## check if there is a tile at [param pos]
func has(pos: Vector2i) -> bool:
	return tile_map.has(pos)


## get all tile positions
func keys() -> Array[Vector2i]:
	return tile_map.keys()


## This will return a [code]PackedByteArray[/code] of all the tiles
func to_bytes() -> PackedByteArray:
	# it stores stuff like this:
	# [u16 pos.x, u16 pos.y, u8 tile_id, ...]
	var bytes = PackedByteArray()
	var i = 0
	bytes.resize(tile_map.size() * 5)

	for pos in tile_map.keys():
		bytes.encode_s16(i, pos.x)
		i += 2
		bytes.encode_s16(i, pos.y)
		i += 2
		bytes.encode_u8(i, tile_map[pos] + 1)  # make -1 a valid u8
		i += 1

	return bytes


func from_bytes(bytes: PackedByteArray) -> void:
	tile_map = {}
	var i = 0
	while i < bytes.size():
		var x = bytes.decode_s16(i)
		i += 2
		var y = bytes.decode_s16(i)
		i += 2
		var tile = bytes.decode_u8(i) - 1  # convert tile ID back to -1..=254
		i += 1
		tile_map[Vector2i(x, y)] = tile
