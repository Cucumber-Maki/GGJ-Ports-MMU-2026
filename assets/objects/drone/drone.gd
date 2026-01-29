extends Entity

@export var force : float = 500.0;
@export_range(0.0, 2.0) var horizontal : float = 1.0;
@export var push_force := Vector2(150.0, 100.0);

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player;
	if (player == null): return;
	
	if (player.position.y >= position.y + 10.0):
		player.set_momentum(push_force, true);
		player.take_damage();
	else:
		player.set_momentum(Vector2.UP.rotated(rotation) * force, true, Vector2(horizontal, 0.0));
		player.set_color(spectrum_color);
		explode();
