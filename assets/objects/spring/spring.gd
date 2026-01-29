extends Area2D

@export var force : float = 700.0;

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player;
	if (player == null): return;
	
	player.set_momentum(Vector2.UP.rotated(rotation) * force, true);
	$Sprite.play("Bounced");
	$Sprite.frame = 0;
	$Sprite.frame_progress = 0;


func _on_sprite_animation_finished() -> void:
	$Sprite.play("Idle")
