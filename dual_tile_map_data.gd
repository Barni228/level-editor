@tool
class_name DualTileMapData extends Resource


## when @export_storage sets the tile_map_data, i want to run [method update_from_bytes]
## but unfortunately, _init runs BEFORE export sets up the tile_map_data
## so i just assume that the first thing that sets tile_map_data is the export, and only update that one time
var _storage_set: bool = true

# for some reason, godot cannot store Dictionary in resource, so i need to store it as bytes instead
## The tile map data
## This is binary data of the tile map, you can convert it to tile map with [method bytes_to_tile_map]
## or generate this kind of data with [method to_bytes]
## Note: it is recommended to use [method update_from_bytes] instead of setting this directly
@export_storage var tile_map_data: PackedByteArray = PackedByteArray():
	set(value):
		tile_map_data = value
		if _storage_set:
			# from now on, this is a normal variable without custom setter
			_storage_set = false
			update_from_bytes(tile_map_data)
			emit_changed()


## The tile map
## key: Vector2i tile position
## value: tile ID
var tile_map: Dictionary[Vector2i, int] = {}


## set a tile at [param pos] to [param tile]
func set_tile(pos: Vector2i, tile: int) -> void:
	tile_map[pos] = tile
	tile_map_data = to_bytes()


func get_tile(pos: Vector2i, default: Variant = null) -> int:
	return tile_map.get(pos, default)


## clear the tile map (remove all tiles)
func clear() -> void:
	tile_map.clear()
	tile_map_data = to_bytes()


## remove the tile at [param pos]
func erase(pos: Vector2i) -> void:
	tile_map.erase(pos)
	tile_map_data = to_bytes()


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


## update [member tile_map] to match [param bytes]
func update_from_bytes(bytes: PackedByteArray) -> void:
	tile_map = bytes_to_tile_map(bytes)
	tile_map_data = bytes


## convert a [code]PackedByteArray[/code] to a tile map
static func bytes_to_tile_map(bytes: PackedByteArray) -> Dictionary[Vector2i, int]:
	var _tile_map: Dictionary[Vector2i, int] = {}
	var i = 0
	while i < bytes.size():
		var x = bytes.decode_s16(i)
		i += 2
		var y = bytes.decode_s16(i)
		i += 2
		var tile = bytes.decode_u8(i) - 1  # convert tile ID back to -1..=254
		i += 1
		_tile_map[Vector2i(x, y)] = tile
	
	return _tile_map
