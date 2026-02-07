extends VBoxContainer


@export var dual_tile_map: DualTileMapLayer
@export_file("*.tres") var save_path: String

func save_data() -> void:
	print("Saving")
	# open the file, but compress it with ZSTD compression (best one)
	var file := FileAccess.open_compressed(save_path, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	file.store_buffer(dual_tile_map.data.to_bytes())


func load_data() -> void:
	print("Loading")
	var file := FileAccess.open_compressed(save_path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	var bytes := file.get_buffer(file.get_length())
	dual_tile_map.data.from_bytes(bytes)
	dual_tile_map.update_every_tile()
