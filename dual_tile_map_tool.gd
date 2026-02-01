@tool
class_name DualTileMapTool extends TileMapLayer


## TODO: use tile_map_data to check if the tilemap has changed, and only then update
## TODO: generate TileSet TileMapPatterns for every tile type automatically
## TODO: use a resource instead of Dictionary


const EMPTY := -1

## how often this should update when in the editor
## it has no affect on the actual running game, just the editor
@export var update_interval := 0.1

@export var show_raw_tilemap := false:
	set(value):
		show_raw_tilemap = value
		# wait for _ready to run, so that _dual_tile_map_layer exists
		if not is_node_ready():
			await ready

		_dual_tile_map_layer.visible = not show_raw_tilemap


@export_tool_button("Generate DualTileMapLayer", "TileMapLayer") var generate_tile_map = func():
	# var generated: DualTileMapLayer = _dual_tile_map_layer.duplicate()
	var generated := DualTileMapLayer.new()
	generated.tile_set = _dual_tile_map_layer.tile_set.duplicate(true)
	generated.position = _dual_tile_map_layer.position
	generated.tile_map = _dual_tile_map_layer.tile_map.duplicate(true)
	generated.name = "DualTileMapLayer"

	add_child(generated, true)
	generated.owner = get_tree().edited_scene_root

# @export_tool_button("Generate TileMapPattern", "TileSet") var generate_tile_map_pattern = func():
# 	for i in range(tile_set.get_terrains_count(_dual_tile_map_layer.terrain_set) + 1):
# 		# include -1 (empty)
# 		i -= 1
# 		var tile = _dual_tile_map_layer._terrain_to_tile.get(DualTileMapLayer.encode_key([i, i, i, i]))
# 		if tile == null:
# 			continue
# 		print(i)
# 		var pattern := TileMapPattern.new()
# 		pattern.set_cell(Vector2i.ZERO, _dual_tile_map_layer.source_id, tile)
# 		tile_set.add_pattern(pattern)
# 		break
# 	# prints("generated", i, "patterns")


var _dual_tile_map_layer: DualTileMapLayer

var _update_timer := 0.0


func _ready() -> void:
	_dual_tile_map_layer = DualTileMapLayer.new()
	_dual_tile_map_layer.tile_set = tile_set
	_dual_tile_map_layer.position = tile_set.tile_size / 2.0
	# _dual_tile_map_layer.name = "DualTileMapLayer"
	add_child(_dual_tile_map_layer)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_update_timer += delta
		if _update_timer > update_interval:
			_update_timer = 0.0
			update()


func update() -> void:
	_dual_tile_map_layer.clear_all()

	for pos in get_used_cells():
		var tile_data := get_cell_tile_data(pos)
		_dual_tile_map_layer.add_tile(pos, tile_data.terrain)
		# I could create a set that holds which cells should be updated, and then update them from there
		# to avoid updating the same tile here multiple times, but i feel like updating tiles is cheap enough to not bother
		# if pos is close to another pos, then they probably share some of the dual tiles, so I update that same dual pos multiple times
