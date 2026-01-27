extends RigidBody2D
@export var movementspeed := 500
var momentum :Vector2 = Vector2.ZERO
var attatchedrail :WorldRailsInternal.RailPath=null
var attatchedposition :float=0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var movementinput := Input.get_axis("PlayerLeft","PlayerRight")
	if attatchedrail!=null:
		attatchedposition+=movementinput*delta*movementspeed
		position=attatchedrail.get_point_along_path(attatchedposition)
	else:
		position+=Vector2.RIGHT*movementinput*delta*movementspeed
		momentum+=Vector2.DOWN*ProjectSettings.get_setting("physics/2d/default_gravity")*delta
		position+=momentum*delta
		var closestrailinfo := WorldRails.get_closest_rail(position)
		ImmediateGizmos2D.line_circle(closestrailinfo.closest_position,30)
		if closestrailinfo.closest_distance < 2:
			attatchedrail=closestrailinfo.rail_path
			attatchedposition=closestrailinfo.rail_path_distance
	pass
