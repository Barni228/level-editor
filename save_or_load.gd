extends VBoxContainer


@export var dual_tile_map: DualTileMapLayer
@export_file("*.tres") var save_path: String

func save_data() -> void:
	print("Saving")
	var data := dual_tile_map.data.duplicate(true)
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_buffer(data.to_bytes())

func load_data() -> void:
	print("Loading")
	var bytes := FileAccess.get_file_as_bytes(save_path)
	dual_tile_map.data.from_bytes(bytes)
	dual_tile_map.update_every_tile()
