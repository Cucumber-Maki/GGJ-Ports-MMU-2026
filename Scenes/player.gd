extends RigidBody2D
@export var movementspeed := 700
var momentum : Vector2 = Vector2.ZERO
var attatchedrail : WorldRailsInternal.RailPath = null
var attatchedposition : float = 0

@export var detatchThreshold : float = 70.0

func _physics_process(delta: float) -> void:
	var movementinput := Input.get_axis("PlayerLeft","PlayerRight")
	if attatchedrail!=null:
		var lastAttachedInfo := attatchedrail.get_point_along_path(attatchedposition);
		momentum.y = 0.0;
		momentum += Vector2.RIGHT * movementinput * delta * movementspeed;
		attatchedposition += momentum.x * delta;
		
		var attachedInfo := attatchedrail.get_point_along_path(attatchedposition);
		position = attachedInfo.position;
		rotation = (PI / 2) + attachedInfo.normal.angle();
		
		if (Input.is_action_just_pressed("PlayerJump")):
			attatchedrail = null;
			momentum.y = -500.0;
		
		var angle := rad_to_deg(lastAttachedInfo.normal.angle_to(attachedInfo.normal));
		if ((momentum.x > 0.0 && angle >= detatchThreshold) || 
			(momentum.x < 0.0 && angle <= -detatchThreshold)):
			attatchedrail = null;
		elif ((momentum.x < 0.0 && angle >= detatchThreshold) || 
			(momentum.x > 0.0 && angle <= -detatchThreshold)):
			attatchedposition -= momentum.x * delta;
			momentum.x *= -0.45;
			return _physics_process(0.0);
		
		if (attatchedrail == null):
			momentum = momentum.rotated(-lastAttachedInfo.normal.angle_to(Vector2.UP))
			return _physics_process(0.0);
	else:
		rotation = 0.0;
		
		momentum += Vector2.RIGHT * movementinput * delta * movementspeed;
		momentum += Vector2.DOWN * ProjectSettings.get_setting("physics/2d/default_gravity") * delta;
		
		var closestrailinfo := WorldRails.get_closest_rail(position)
		ImmediateGizmos2D.line_circle(closestrailinfo.closest_position, 30)
		if (momentum.normalized().dot(position.direction_to(closestrailinfo.closest_position)) > 0.0 && 
			closestrailinfo.closest_distance <= momentum.length() * delta):
			attatchedrail = closestrailinfo.rail_path;
			attatchedposition = closestrailinfo.rail_path_distance;
			momentum = momentum.rotated(closestrailinfo.rail_normal.angle_to(Vector2.UP));
		else:
			position += momentum * delta

	momentum *= 0.99;
