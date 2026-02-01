@tool
class_name DualTileMapTool extends TileMapLayer


# TODO: use tile_map_data to check if the tilemap has changed, and only then update
# TODO: use a resource instead of Dictionary
# TODO: use TileMap.changed signal to update


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
			# if _ready decided that we should be deleted, don't do anything (because _dual_tile_map_layer doesn't exist)
			if is_queued_for_deletion():
				return

		_dual_tile_map_layer.visible = not show_raw_tilemap


## The tile map data of this dual tile map
## This stores where all the tiles are
## see [member DualTileMapLayer.data]
@export var data: DualTileMapData:
	set(value):
		data = value
		if not is_node_ready():
			await ready
			if is_queued_for_deletion():
				return

		_dual_tile_map_layer.data = data


# @export_tool_button("show") var s = func():
# 	print("show")
# 	print(_dual_tile_map_layer.visible)
# 	print(_dual_tile_map_layer.get_used_cells())
# 	print(_dual_tile_map_layer._terrain_to_tile)

# @export_tool_button("Generate DualTileMapLayer", "TileMapLayer") var generate_tile_map = func():
# 	# var generated: DualTileMapLayer = _dual_tile_map_layer.duplicate()
# 	var generated := DualTileMapLayer.new()
# 	generated.tile_set = _dual_tile_map_layer.tile_set.duplicate(true)
# 	generated.position = _dual_tile_map_layer.position
# 	generated.data = _dual_tile_map_layer.data.duplicate(true)
# 	generated.name = "DualTileMapLayer"
# 	add_child(generated, true)
# 	generated.owner = get_tree().edited_scene_root

var _dual_tile_map_layer: DualTileMapLayer

var _update_timer := 0.0

var _prev_tile_set: TileSet

func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()
		return

	# changed.connect(print.bind(["changed", self ]))

	_dual_tile_map_layer = DualTileMapLayer.new()
	_dual_tile_map_layer.tile_set = tile_set
	_dual_tile_map_layer.position = tile_set.tile_size / 2.0
	_dual_tile_map_layer.data = data
	# _dual_tile_map_layer.name = "DualTileMapLayer"
	add_child(_dual_tile_map_layer)
	_prev_tile_set = tile_set


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_update_timer += delta
		if _update_timer > update_interval:
			_update_timer = 0.0
			update()


func update() -> void:
	if data == null:
		return

	if tile_set != _prev_tile_set:
		_on_tile_set_changed()
		_prev_tile_set = tile_set

	_dual_tile_map_layer.clear_all()

	for pos in get_used_cells():
		var tile_data := get_cell_tile_data(pos)
		_dual_tile_map_layer.add_tile(pos, tile_data.terrain)
		# I could create a set that holds which cells should be updated, and then update them from there
		# to avoid updating the same tile here multiple times, but i feel like updating tiles is cheap enough to not bother
		# if pos is close to another pos, then they probably share some of the dual tiles, so I update that same dual pos multiple times


func _on_tile_set_changed() -> void:
	_dual_tile_map_layer.tile_set = tile_set
	_dual_tile_map_layer._on_tile_set_changed()
