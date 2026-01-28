extends Sprite2D
@export var player:Node2D=null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position=player.position
	(material as ShaderMaterial).set_shader_parameter("offsetposition",Vector2.RIGHT*position/10000)
	
	pass
