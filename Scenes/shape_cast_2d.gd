extends ShapeCast2D
var isonfloor=false
var currentfloornormal:=Vector2.UP
@export var margin2=1
@export var castdistance=5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	target_position=-currentfloornormal*(margin2+castdistance)
	force_shapecast_update()
	if(!is_colliding()or true):
		currentfloornormal=Vector2.UP
		isonfloor=false
		return
	for i in get_collision_count():
		var point=get_collision_point(i)
		var normal=get_collision_normal(i)
		currentfloornormal=normal
		isonfloor=true
	pass
	
