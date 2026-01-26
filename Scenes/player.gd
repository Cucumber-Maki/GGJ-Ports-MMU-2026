extends RigidBody2D

@export var schmovementspeed=100
var currentfloornormal:=Vector2.UP
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("ligma")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var previousfloornormal=currentfloornormal
	currentfloornormal=$ShapeCast2D.currentfloornormal
	var previousvelocity=linear_velocity
	if $ShapeCast2D.isonfloor:
		linear_velocity=previousvelocity.rotated(previousfloornormal.angle_to(currentfloornormal))
	apply_central_force(ProjectSettings.get_setting("physics/2d/default_gravity")*-currentfloornormal)
	var schmovement=0
	if(Input.is_action_pressed("PlayerRight")):
		schmovement=schmovementspeed
	if(Input.is_action_pressed("PlayerLeft")):
		schmovement=-schmovementspeed
	apply_central_force(currentfloornormal.rotated(deg_to_rad(90))*schmovement)
	if(Input.is_action_just_pressed("PlayerJump")):
		apply_central_impulse(currentfloornormal*600)

#Makes the floor normal for momentum reasons
func _floor_normality() -> Vector2:
	var space_state:= get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	query.from=position
	query.to=position+(-currentfloornormal*30)
	query.collision_mask=collision_mask
	var hitobject=space_state.intersect_ray(query)
	if(hitobject.is_empty()):
		return Vector2.UP
	return hitobject.normal
	
