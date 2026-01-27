extends TileMap

func _ready() -> void:
	WorldRails.register_tilemap(self);
