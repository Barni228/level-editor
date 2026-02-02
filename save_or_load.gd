extends VBoxContainer


# TODO: use json, or something like that


@export var dual_tile_map: DualTileMapLayer
@export_file("*.tres") var save_path: String

func save_data() -> void:
	print("Saving")
	var data := dual_tile_map.data.duplicate(true)
	# data.resource_path = save_path
	ResourceSaver.save(data, save_path)

func load_data() -> void:
	print("Loading")
	# dual_tile_map.data = load(save_path)
	dual_tile_map.data = ResourceLoader.load(save_path, &"DualTileMapData", ResourceLoader.CACHE_MODE_IGNORE)
	dual_tile_map.update_every_tile()
