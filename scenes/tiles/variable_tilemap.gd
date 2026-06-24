extends TileMapLayer


@export var custom_textures: Dictionary[int, Texture2D]


func _ready() -> void:
	tile_set = tile_set.duplicate()

	for src_id: int in custom_textures.keys():
		var texture := custom_textures[src_id]
		print("%s: swapping source %s texture to %s" % [name, src_id, texture.resource_name])
		var src := tile_set.get_source(src_id) as TileSetAtlasSource
		src.texture = texture
