extends Node2D
class_name Respawner;

signal onRespawn;
var remainingTime : float = 10.0;

func _process(delta: float) -> void:
	if (remainingTime > 0.0):
		remainingTime -= delta;
		return;
	
	onRespawn.emit();
	queue_free();
	
