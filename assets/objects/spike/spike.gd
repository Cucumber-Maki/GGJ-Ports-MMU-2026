extends Area2D

@export var push_horizontal_force : float = 150.0;
@export var push_up_force : float = 200.0;

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player;
	if (player == null): return;
	
	var force := Vector2(push_horizontal_force, push_up_force);
	var right := Vector2.RIGHT.rotated(rotation);
	var playerFactor := Vector2(signf(right.dot(player.position - position)), -1.0);
	player.set_momentum(force.rotated(rotation) * playerFactor, true);
	player.take_damage();
