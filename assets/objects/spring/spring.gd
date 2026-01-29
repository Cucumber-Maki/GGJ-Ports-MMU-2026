extends Area2D

@export var force : float = 700.0;
@export_range(0.0, 2.0) var horizontal : float = 0.0;
@export var center_player : bool = false;

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player;
	if (player == null): return;
	
	player.set_momentum(Vector2.UP.rotated(rotation) * force, true, Vector2(horizontal, 0.0));
	if (center_player):
		player.position = position + (Vector2.UP.rotated(rotation) * 36);
	
	$Sprite.play("Bounce");
	$Sprite.set_frame_and_progress(0, 0);

func _on_sprite_animation_finished() -> void:
	$Sprite.play("Idle")
