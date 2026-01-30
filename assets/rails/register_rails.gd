extends TileMap

func _ready() -> void:
	for sourceMask : WorldRailsInternal.SourceMask in Player._spectrum_source_masks:
		WorldRails.register_tilemap(self, sourceMask);
	Player.bind_on_spectrum_color_change(func (color): 
		var activeColor := Vector3.ZERO;
		match color:
			Player.Spectrum.Red: activeColor.x = 1.0;
			Player.Spectrum.Green: activeColor.y = 1.0;
			Player.Spectrum.Blue: activeColor.z = 1.0;
		(material as ShaderMaterial).set_shader_parameter("u_activeColor", activeColor);
	)
	
