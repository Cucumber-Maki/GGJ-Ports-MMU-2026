extends Sprite2D
@export var player:Node2D=null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position=player.position
	var backgroundPos : Vector2 = position;
	backgroundPos.x /= 10000;
	backgroundPos.y /= 10000;
	(material as ShaderMaterial).set_shader_parameter("offsetposition",backgroundPos);
