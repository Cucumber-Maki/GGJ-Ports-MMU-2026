extends Area2D

@export var speed_set : float = 800.0;
@export_range(-1, 1) var direction : int = 0;

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player;
	if (player == null): return;
	
	if (direction == 0):
		if (absf(player.get_momentum().x) < speed_set):
			player.set_momentum(Vector2.RIGHT.rotated(rotation) * speed_set * signf(player.movement_momentum.x), false, Vector2.UP);
		return;
	
	if (player.get_momentum().x * direction >= speed_set):
		return;
	player.set_momentum(Vector2.RIGHT.rotated(rotation) * speed_set * direction, false, Vector2.UP);
	$Sprite.flip_h = direction == -1;
