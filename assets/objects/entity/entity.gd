extends Area2D
class_name Entity

@export var spectrum_color : Player.Spectrum = Player.Spectrum.White;
@export var respawnable : bool = true;
@export var respawnTimer : float = 8.0;

const respawnerPrefab := preload("res://assets/objects/entity/respawner.tscn");
const explosionPrefab := preload("res://assets/objects/entity/explosion.tscn");

var _defaultProperties :Dictionary = {};

func _ready() -> void:
	update_material();
	for key in get_property_list():
		_defaultProperties.set(key.name, get(key.name));
	
	
static var material_cache : Dictionary = {};
func update_material() -> void:
	var sprites := find_children("*", "AnimatedSprite2D");
	for sprite : AnimatedSprite2D in sprites:
		cache_spectrum_material(sprite, spectrum_color);

static func cache_spectrum_material(sprite : AnimatedSprite2D, color : Player.Spectrum) -> void:
	if (sprite == null || sprite.material == null): return;
	var rid := sprite.material.get_rid();
	if (!material_cache.has(rid)):
		material_cache.set(rid, {});
	var cache := material_cache.get(rid) as Dictionary;

	if (!cache.has(color)):
		var mat := sprite.material.duplicate() as ShaderMaterial;
		mat.set_shader_parameter("u_spectrumColor", Player.get_spectrum_color(color));
		cache.set(color, mat);
	sprite.material = cache.get(color);

func explode() -> void:
	if (respawnable): 
		var repawner := respawnerPrefab.instantiate() as Respawner;
		var sceneFile := self.scene_file_path;
		var parent := self.get_parent();
		var defualtProperties := _defaultProperties;
		repawner.onRespawn.connect(func(): 
			var node := load(sceneFile).instantiate() as Node2D;
			for key in defualtProperties.keys():
				node.set(key, defualtProperties.get(key));
			parent.add_child(node);
		);
		get_tree().root.add_child(repawner)
	
	var explosion := explosionPrefab.instantiate() as AnimatedSprite2D;
	cache_spectrum_material(explosion, spectrum_color);
	get_tree().root.add_child(explosion)
	explosion.position = position;
	
	queue_free();
	
