extends Area2D
class_name Checkpoint

static var lastCheckPoint : Checkpoint = null;

func _ready() -> void:
	if (lastCheckPoint == null): # first one *in the node list* is the default
		lastCheckPoint = self;
	$Sprite2D.queue_free();
	$Sprite2D2.queue_free();

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player;
	if (player == null): return;
	
	lastCheckPoint = self;
