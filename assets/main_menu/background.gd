extends Sprite2D

@export var scroll_speed : float = 100.0;
var time : float = 0;

@export var startbutton : TextureButton = null;
@export var player : AnimatedSprite2D = null;
@export var tilemap : TileMap = null;

var player_last : float = 0;

func _ready() -> void:
	startbutton.grab_focus();

func _process(delta: float) -> void:
	time += delta;
	
	var scrollPos := scroll_speed * time;
	
	#player.position
	tilemap.position.x = fposmod(-scrollPos, 32.0);
	
	player.position.x = (sin(time * 0.5) * 0.3453) + (cos(time * 0.151263) * 0.2138) + (sin(time * 0.28263) * 0.4138)
	player.position.x *= 100.0;
	if (player.position.x > player_last):
		player.play("default");
	else:
		player.play("rolling");
	player_last = player.position.x;
	
	position= get_viewport().get_camera_2d().get_screen_center_position();
	var backgroundPos : Vector2 = Vector2(scrollPos, 0);
	backgroundPos.x /= 10000;
	backgroundPos.y /= 10000;
	(material as ShaderMaterial).set_shader_parameter("offsetposition",backgroundPos);


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/gay_me.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit();
