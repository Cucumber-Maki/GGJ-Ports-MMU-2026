extends MarginContainer
class_name EndTimeMessage;

static var s_instance : EndTimeMessage = null;

var game_time : int = 0;

func _ready() -> void:
	visible = false;
	s_instance = self;

func present(time : int) -> void:
	visible = true;
	game_time = time;
	
	setRank($VBoxContainer/Score, get_rank_index(time));
	$VBoxContainer/CenterContainer/TextureButton.grab_focus();

func _process(delta: float) -> void:
	if (!visible): return;
	

func get_rank_index(time : int) -> int:
	# S A B C	
	const ranks : Array[int] = [ 70, 90, 120, 150 ];	
	for i : int in ranks.size():
		if (time <= ranks[i]):
			return i;
	
	return ranks.size(); # D

func setRank(rect : TextureRect, digit : int):
	(rect.texture as AtlasTexture).region.position.x = digit * 16;


func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn");
