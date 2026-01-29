extends Entity

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player;
	if (player == null): return;
	
	if (player.set_color(spectrum_color)):
		explode();
