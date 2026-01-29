extends Area2D
class_name Entity

@export var respawnable : bool = true;
@export var respawnTimer : float = 8.0;

const respawnerPrefab := preload("res://assets/objects/entity/respawner.tscn");
const explosionPrefab := preload("res://assets/objects/entity/explosion.tscn");

func explode() -> void:
	if (respawnable): 
		var repawner := respawnerPrefab.instantiate() as Respawner;
		var sceneFile := self.scene_file_path;
		var location := transform;
		var parent := self.get_parent();
		repawner.onRespawn.connect(func(): 
			var node := load(sceneFile).instantiate() as Node2D;
			node.transform = location;
			parent.add_child(node);
		);
		get_tree().root.add_child(repawner)
	
	var explosion := explosionPrefab.instantiate() as Node2D;
	get_tree().root.add_child(explosion)
	explosion.position = position;
	
	queue_free();
	
