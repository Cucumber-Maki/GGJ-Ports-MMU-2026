extends RigidBody2D
class_name Player;
static var s_instance : Player = null;

@export_group("Movement Properties", "movement_")
@export var movement_speed : float = 600.0;
@export_range(0.0, 1.0, 0.001) var movement_momentum_retention : float = 0.985
@export_range(0.0, 2.0) var movement_air_factor : float = 0.7;

var movement_momentum : Vector2 = Vector2.ZERO;

@export_group("Rail Properties", "rail_")
@export_range(0.0, 180.0, 0.1, "radians_as_degrees") var rail_detatch_angle_threshold : float = deg_to_rad(70.0);
@export var rail_detatch_force : float = 56.0;
@export var rail_detatch_speed_threshold : float = 240.0;
@export var rail_detatch_bounce_retention : float = 0.1;
@export_range(0.0, 2.0) var rail_wall_bounce_retention : float = 0.45;
@export_range(0.0, 2.0) var rail_wall_gravity_factor : float = 1.0;
@export var rail_wall_jump_up_momentum_scale : float = 100.0;
@export var rail_wall_jump_up_momentum_direction_factor : float = 3.0;
@export var rail_wall_jump_down_jump_scale : float = 1.25;
@export_range(0.0, 180.0, 0.1, "radians_as_degrees") var rail_ceiling_direction_swap_angle : float = TAU * 0.125;
var rail_ceiling_direction_was_on_ceiling : bool = false;
var rail_ceiling_direction_last_input_on_ceiling : bool = false;
var rail_ceiling_direction_last_input : float = false;
var rail_attatched_rail : RailGroup.RailPath = null
var rail_attatched_position : float = 0

@export_group("Jump Properties", "jump_")
@export var jump_impulse_force : float = 500.0;
@export_range(0.0, 2.0) var jump_impulse_momentum_factor : float = 0.6;
@export var jump_impulse_momentum_max : float = 500.0;
@export_range(0.0, 1.0) var jump_release_strength : float = 0.4;
var jump_release_possible : bool = false;
@export var jump_coyote_time : float = 0.1;
var jump_coyote_direction : Vector2 = Vector2.UP;
var jump_coyote_remaining_time : float = 0.0;

@export_group("Collision Properties", "collision_")
@onready var collision_collider_size : float = ($CollisionShape2D.shape as CircleShape2D).radius;

enum Spectrum {
	White, 
	Red, Green, Blue,
};
var _spectrum_color = Spectrum.White;
signal on_spectrum_color_change(color : Spectrum);

static func get_spectrum_color(color : Spectrum) -> Color:
	match (color):
		Spectrum.Red: return Color("ff3a51");
		Spectrum.Green: return Color("6ccd34");
		Spectrum.Blue: return Color("0081ff");
	return Color("b9bdbd");

func set_color(color : Spectrum, force : bool = false) -> bool:
	if (color == Spectrum.White && !force): return false;
	if (_spectrum_color == color): return false;
	_spectrum_color = color;
	($Cat.material as ShaderMaterial).set_shader_parameter("u_spectrumColor", get_spectrum_color(_spectrum_color));
	on_spectrum_color_change.emit(_spectrum_color);
	return true;
	
func get_color() -> Color:
	return get_spectrum_color(_spectrum_color);

func spectrum_can_interact(color : Spectrum) -> bool:
	return color == Spectrum.White || color == _spectrum_color;

static func bind_on_spectrum_color_change(callback : Callable) -> void:
	callback.call(s_instance._spectrum_color);
	s_instance.on_spectrum_color_change.connect(callback);
	
static var _spectrum_source_masks : Array[WorldRailsInternal.SourceMask] = [
	WorldRailsInternal.SourceMask.new([0]),
	WorldRailsInternal.SourceMask.new([0, 1]),
	WorldRailsInternal.SourceMask.new([0, 2]),
	WorldRailsInternal.SourceMask.new([0, 3]),
];
func get_source_mask() -> WorldRailsInternal.SourceMask:
	return _spectrum_source_masks[_spectrum_color as int];

#######################################################################################################
# Player inputs.

func input_movement() -> float:
	return Input.get_axis("PlayerLeft","PlayerRight");
	
func input_jump() -> bool:
	return Input.is_action_just_pressed("PlayerJump");
func input_jump_release() -> bool:
	return Input.is_action_just_released("PlayerJump");

#######################################################################################################
# Player behavour..

func _ready() -> void:
	s_instance = self;

func _physics_process(delta: float) -> void:
	if (jump_coyote_remaining_time > 0.0):
		jump_coyote_remaining_time -= delta;
	
	if (rail_attatched_rail != null):
		handle_rail(delta);	
	else:
		handle_movement(delta);

	update_visuals();
	movement_momentum *= movement_momentum_retention; # Drag.

#######################################################################################################
# Visual behaviour.
	
func update_visuals() -> void:
	var target_positon = position;
	var target_rotation = 0.0;
	
	if (rail_attatched_rail != null): 
		var attachedInfo := rail_attatched_rail.get_point_along_path(rail_attatched_position, rail_detatch_angle_threshold);
		target_positon = attachedInfo.position + (attachedInfo.smooth_normal * collision_collider_size);
		target_rotation = (PI / 2) + attachedInfo.smooth_normal.angle();
		
	position = target_positon;
	rotation = lerp_angle(rotation, target_rotation, 0.125);
	
	var positivemomentumx=absf(movement_momentum.x)

	# Rail animations
	if (rail_attatched_rail != null):
		if positivemomentumx>32:
			$Cat.play("Run",clamp(positivemomentumx/256,0,1.5))
		else: 
			$Cat.play("Idle")
	else:
		# Air animations
		if movement_momentum.y < -50.0:
			$Cat.play("Jump")
		elif movement_momentum.y > 50.0: 
			$Cat.play("Descent")
		else:
			$Cat.play("Air_Neutral")
	
	var movementInput := input_movement();
	if (rail_ceiling_direction_last_input_on_ceiling):
		movementInput *= -1;
	if movementInput!=0:
		$Cat.flip_h= movementInput==-1
	
	if (WorldRails.draw_rails):
		ImmediateGizmos2D.line_circle(position, collision_collider_size, Color.MEDIUM_VIOLET_RED);
	
#######################################################################################################
# Movement / air behaviours.
	
func handle_movement(delta : float) -> void:
	if (jump_coyote_remaining_time > 0.0 && input_jump()):
		jump(jump_coyote_direction);
	
	if (jump_release_possible && movement_momentum.y > 0.0):
		jump_release_possible = false;
	if (jump_release_possible && input_jump_release()):
		movement_momentum.y *= 1.0 - jump_release_strength;
		jump_release_possible = false;
		
		
	var movementInput := input_movement();
	if (rail_ceiling_direction_last_input != movementInput):
		rail_ceiling_direction_last_input_on_ceiling = false;
	if (rail_ceiling_direction_last_input_on_ceiling):
		movementInput *= -1;

	movement_momentum += Vector2.RIGHT * movementInput * delta * movement_speed * movement_air_factor;
	movement_momentum += Vector2.DOWN * ProjectSettings.get_setting("physics/2d/default_gravity") * delta;
	
	var closestRailInfo := WorldRails.get_closest_rail(position, get_source_mask());
	if (closestRailInfo != null):
		if (WorldRails.draw_rails):
			ImmediateGizmos2D.line_circle(closestRailInfo.closest_position, 30)
		if ((movement_momentum.normalized().dot(position.direction_to(closestRailInfo.closest_position)) > 0.0 && 
			closestRailInfo.closest_distance <= (collision_collider_size + (movement_momentum.length() * delta)))):
			attach_to_rail(closestRailInfo);
			return;
	
	position += movement_momentum * delta
	
#######################################################################################################
# Rail behaviours.
	
func handle_rail(delta : float) -> void:
	jump_release_possible = false;
	
	var lastAttachedInfo := rail_attatched_rail.get_point_along_path(rail_attatched_position, rail_detatch_angle_threshold);
	var isOnCeiling := acos(lastAttachedInfo.normal.dot(Vector2.DOWN)) < rail_ceiling_direction_swap_angle;
	var movementInput := input_movement();
	
	# Swap controls?
	if (rail_ceiling_direction_last_input != movementInput):
		rail_ceiling_direction_last_input_on_ceiling = isOnCeiling;
	rail_ceiling_direction_last_input = movementInput;
	rail_ceiling_direction_was_on_ceiling = isOnCeiling;
	if (rail_ceiling_direction_last_input_on_ceiling):
		movementInput *= -1;
		
	# Movement (Internally on a 1D plane!).
	movement_momentum.y = 0.0;
	movement_momentum.x += movementInput * delta * movement_speed;
	movement_momentum.x += Vector2.RIGHT.dot(lastAttachedInfo.smooth_normal) * ProjectSettings.get_setting("physics/2d/default_gravity") * delta * rail_wall_gravity_factor;
	
	# Seek ahead.
	var seekMovement := (movement_momentum.x * delta) + (signf(movement_momentum.x) * collision_collider_size);
	if (WorldRails.draw_rails): seekMovement += signf(movement_momentum.x) * 200.0; # Debug
	var seekInfo := rail_attatched_rail.seek_point_along_path(rail_attatched_position, seekMovement, rail_detatch_angle_threshold);
	
	# Debug:
	if (WorldRails.draw_rails): 
		for point in rail_attatched_rail.points:
			if (position.distance_squared_to(point) < 200*200):
				ImmediateGizmos2D.line_circle(point + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)), 2.5, Color.GRAY);
		if (seekInfo.detatch_index != -1):
			var detatchInfo := rail_attatched_rail.get_point_along_path(rail_attatched_position + seekInfo.detatch_distance);
			var color := Color.YELLOW if (absf(movement_momentum.x) <= rail_detatch_speed_threshold) else Color.RED;
			ImmediateGizmos2D.line(detatchInfo.position, detatchInfo.position + detatchInfo.smooth_normal * 50.0, color);
			ImmediateGizmos2D.line_circle(detatchInfo.position, 3.0, color);
		if (seekInfo.wall_index != -1):
			var wallInfo := rail_attatched_rail.get_point_along_path(rail_attatched_position + seekInfo.wall_distance);
			ImmediateGizmos2D.line(wallInfo.position, wallInfo.position + wallInfo.smooth_normal * 50.0, Color.GREEN);
			ImmediateGizmos2D.line_circle(wallInfo.position, 3.0, Color.GREEN);
	
	# Detatch!
	if (seekInfo.detatch_index != -1 && 
		absf(seekInfo.detatch_distance) <= absf(seekInfo.wall_distance) &&
		absf(seekInfo.detatch_distance) <= absf(movement_momentum.x * delta)):
		if (absf(movement_momentum.x) <= rail_detatch_speed_threshold):
			#movement_momentum.y = -100.0;
			movement_momentum.x *= -rail_detatch_bounce_retention;
		else:
			detatch_from_rail(lastAttachedInfo);
			position += movement_momentum * delta;
			jump_coyote_remaining_time = jump_coyote_time;
			return;

	# Wall bounce!
	if (seekInfo.wall_index != -1  && 
		absf(seekInfo.wall_distance) < absf(seekInfo.detatch_distance) &&
		absf(seekInfo.wall_distance) <= (absf(movement_momentum.x * delta) + collision_collider_size)):
		movement_momentum.x *= -rail_wall_bounce_retention;
		
	# Jump.
	if (input_jump()):
		jump(lastAttachedInfo.normal);
		detatch_from_rail(lastAttachedInfo);
		position += movement_momentum * delta;
		return;

	# Move!
	rail_attatched_position += movement_momentum.x * delta;

func attach_to_rail(railCloseInfo : RailGroup.RailCloseInformation) -> void:
	if (railCloseInfo == null): 
		return;
	rail_attatched_rail = railCloseInfo.rail_path;
	rail_attatched_position = railCloseInfo.rail_path_distance;
	movement_momentum = movement_momentum.rotated(railCloseInfo.rail_normal.angle_to(Vector2.UP));
	#
	var railPointInfo := rail_attatched_rail.get_point_along_path(rail_attatched_position, rail_detatch_angle_threshold);
	position = railPointInfo.position; 
	#
	var isOnCeiling := acos(railPointInfo.normal.dot(Vector2.DOWN)) < rail_ceiling_direction_swap_angle;
	if (rail_ceiling_direction_was_on_ceiling != isOnCeiling):
		rail_ceiling_direction_last_input_on_ceiling = !rail_ceiling_direction_last_input_on_ceiling;

func detatch_from_rail(railPointInfo : RailGroup.RailPointInformation) -> void:
	if (rail_attatched_rail == null): 
		return;
	jump_coyote_remaining_time = 0.0;
	if (railPointInfo != null):
		movement_momentum.y += -rail_detatch_force;
		movement_momentum = movement_momentum.rotated(-railPointInfo.smooth_normal.angle_to(Vector2.UP))
		jump_coyote_direction = railPointInfo.normal;
	rail_attatched_rail = null;

#######################################################################################################
# Jump....

func jump(normal : Vector2) -> void:
	var jumpForce := (jump_impulse_force + minf(absf(movement_momentum.x) * jump_impulse_momentum_factor, jump_impulse_momentum_max));
	var jumpDirection := Vector2.UP;
	var effectStrength := absf(normal.dot(Vector2.RIGHT));
	
	# Up wall.
	if ((normal.dot(Vector2.RIGHT) > 0.0 && movement_momentum.x < 0.0) ||
		(normal.dot(Vector2.RIGHT) < 0.0 && movement_momentum.x > 0.0)):
		var jumpDirectionality := clampf(movement_momentum.x / rail_wall_jump_up_momentum_scale, -1.0, 1.0);	
		jumpDirection = jumpDirection.slerp(
			Vector2(jumpDirectionality * rail_wall_jump_up_momentum_direction_factor, jumpDirection.y).normalized(),
			effectStrength
		);
	elif ((normal.dot(Vector2.RIGHT) > 0.0 && movement_momentum.x > 0.0) ||
		(normal.dot(Vector2.RIGHT) < 0.0 && movement_momentum.x < 0.0)):
		jumpForce = lerpf(jumpForce, jumpForce * rail_wall_jump_down_jump_scale, effectStrength);
			
	movement_momentum.y += jumpDirection.y * jumpForce;
	movement_momentum.x += jumpDirection.x * jumpForce * effectStrength * 0.5;
	jump_release_possible = true;
	jump_coyote_remaining_time = 0.0;

func get_momentum() -> Vector2:
	if (rail_attatched_rail == null): return movement_momentum;
	var attachedInfo := rail_attatched_rail.get_point_along_path(rail_attatched_position, rail_detatch_angle_threshold);
	return movement_momentum.rotated(-attachedInfo.smooth_normal.angle_to(Vector2.UP));
	
func set_momentum(momentum : Vector2, detatch : bool = false, mask : Vector2 = Vector2.ZERO):
	if (rail_attatched_rail != null):
		var attachedInfo := rail_attatched_rail.get_point_along_path(rail_attatched_position, rail_detatch_angle_threshold);
		if (detatch):
			detatch_from_rail(attachedInfo);
		else:
			momentum = momentum.rotated(attachedInfo.smooth_normal.angle_to(Vector2.UP));
	movement_momentum = momentum + (movement_momentum * mask);
	
func add_momentum(momentum : Vector2):
	set_momentum(momentum, false, Vector2.ONE);

#######################################################################################################
