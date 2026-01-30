extends Area2D


var cameras : Array[Camera2D] = [];
func _physics_process(delta: float) -> void:
	var targetPos := Vector2(0, -156);
	
	for camera : Camera2D in cameras:
		camera.position = camera.position.move_toward(targetPos, min(20.0 * delta, camera.position.distance_to(targetPos) * delta));

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player;
	if (player == null): return;

	$Spray.visible = true;
	player.game_win();
	for camera : Camera2D in player.find_children("*", "Camera2D"):
		if (camera == null): continue;
		camera.reparent(self);
		cameras.append(camera);
