extends Area2D

@export var spectrum_color : Player.Spectrum = Player.Spectrum.White;

@export var force : float = 700.0;
@export_range(0.0, 2.0) var horizontal : float = 0.0;
@export var center_player : bool = false;

func _ready() -> void:
	Entity.cache_spectrum_material($Sprite, spectrum_color);
	Player.bind_on_spectrum_color_change(func (color):
		$Sprite.play("Idle" if (color == spectrum_color) else "Disabled");
	);

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player;
	if (player == null): return;
	if (!player.spectrum_can_interact(spectrum_color)): return;
	
	player.set_momentum(Vector2.UP.rotated(rotation) * force, true, Vector2(horizontal, 0.0));
	if (center_player):
		player.position = position + (Vector2.UP.rotated(rotation) * 36);
	
	$Sprite.play("Bounce");
	$Sprite.set_frame_and_progress(0, 0);

func _on_sprite_animation_finished() -> void:
	$Sprite.play("Idle")
