extends MarginContainer
class_name GameTimer;
static var s_instance : GameTimer;

var game_time : float = 0.0;
var finished : bool = false;

@onready var digit1 := $HBoxContainer/Digit4 as TextureRect
@onready var digit10 := $HBoxContainer/Digit3 as TextureRect
@onready var digit60 := $HBoxContainer/Digit2 as TextureRect
@onready var digit600 := $HBoxContainer/Digit as TextureRect

func _ready() -> void:
	s_instance = self;
	digit1.texture = digit1.texture.duplicate();
	digit10.texture = digit10.texture.duplicate();
	digit60.texture = digit60.texture.duplicate();
	digit600.texture = digit600.texture.duplicate();

func _process(delta: float) -> void:
	if (!finished):
		game_time += delta;
	
	var itime := get_time();
	var d1 := posmod(itime, 10);
	var d2 := posmod(itime / 10, 6);
	var d3 := posmod(itime / 60, 10);
	var d4 := posmod(itime / 600, 10);
	
	setDigit(digit1, d1);
	setDigit(digit10, d2);
	setDigit(digit60, d3);
	setDigit(digit600, d4);
	
func get_time() -> int:
	return roundi(game_time);
	
func setDigit(rect : TextureRect, digit : int):
	(rect.texture as AtlasTexture).region.position.x = posmod(digit - 1, 10) * 11;
