extends RigidBody2D

@export var movement_speed := 700

var momentum : Vector2 = Vector2.ZERO
var attatched_rail : WorldRailsInternal.RailPath = null
var attatched_position : float = 0

@export var detatchThreshold : float = 70.0

func _physics_process(delta: float) -> void:
	var movementInput := Input.get_axis("PlayerLeft","PlayerRight")
	if attatched_rail!=null:
		var lastMomentum := momentum;
		var lastAttachedInfo := attatched_rail.get_point_along_path(attatched_position);
		momentum.y = 0.0;
		momentum.x += movementInput * delta * movement_speed;
		momentum.x += Vector2.RIGHT.dot(lastAttachedInfo.normal) * ProjectSettings.get_setting("physics/2d/default_gravity") * delta;
		attatched_position += momentum.x * delta;
		
		var attachedInfo := attatched_rail.get_point_along_path(attatched_position);
		position = attachedInfo.position;
		rotation = (PI / 2) + attachedInfo.normal.angle();
		
		if (Input.is_action_just_pressed("PlayerJump")):
			momentum.y = -500.0;
			detatch();
		
		#if (attachedInfo.normal.dot(Vector2.UP) <= 0.05 && 
			#(sign(momentum.x) != sign(lastMomentum.x) || absf(momentum.x) <= 0.5)):
			#detatch();
		
		var angle := rad_to_deg(lastAttachedInfo.normal.angle_to(attachedInfo.normal));
		if ((momentum.x > 0.0 && angle >= detatchThreshold) || 
			(momentum.x < 0.0 && angle <= -detatchThreshold)):
			detatch();
		elif ((momentum.x < 0.0 && angle >= detatchThreshold) || 
			(momentum.x > 0.0 && angle <= -detatchThreshold)):
			attatched_position -= momentum.x * delta;
			momentum.x *= -0.45;
			return _physics_process(0.0);
		
		if (attatched_rail == null):
			momentum = momentum.rotated(-lastAttachedInfo.normal.angle_to(Vector2.UP))
			return _physics_process(0.0);
	else:
		rotation = 0.0;
		
		momentum += Vector2.RIGHT * movementInput * delta * movement_speed;
		momentum += Vector2.DOWN * ProjectSettings.get_setting("physics/2d/default_gravity") * delta;
		
		var closestRailInfo := WorldRails.get_closest_rail(position)
		ImmediateGizmos2D.line_circle(closestRailInfo.closest_position, 30)
		if (momentum.normalized().dot(position.direction_to(closestRailInfo.closest_position)) > 0.0 && 
			closestRailInfo.closest_distance <= momentum.length() * delta):
			attatched_rail = closestRailInfo.rail_path;
			attatched_position = closestRailInfo.rail_path_distance;
			momentum = momentum.rotated(closestRailInfo.rail_normal.angle_to(Vector2.UP));
		else:
			position += momentum * delta

	momentum *= 0.99;
	
func detatch() -> void:
	if (attatched_rail == null): return;
	
	attatched_rail = null;
