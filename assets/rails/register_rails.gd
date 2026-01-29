extends TileMap

func _ready() -> void:
	for sourceMask : WorldRailsInternal.SourceMask in Player._spectrum_source_masks:
		WorldRails.register_tilemap(self, sourceMask);
