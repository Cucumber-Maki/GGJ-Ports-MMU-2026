extends Sprite2D

func _process(_delta: float) -> void:
	position= get_viewport().get_camera_2d().get_screen_center_position();
	
	var backgroundPos : Vector2 = position;
	backgroundPos.x /= 10000;
	backgroundPos.y /= 10000;
	(material as ShaderMaterial).set_shader_parameter("offsetposition",backgroundPos);
