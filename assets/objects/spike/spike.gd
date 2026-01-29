extends Area2D

@export var push_force := Vector2(150.0, 200.0);

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player;
	if (player == null): return;
	
	var right := Vector2.RIGHT.rotated(rotation);
	var playerFactor := Vector2(signf(right.dot(player.position - position)), -1.0);
	player.set_momentum(push_force.rotated(rotation) * playerFactor, true);
	player.take_damage();
