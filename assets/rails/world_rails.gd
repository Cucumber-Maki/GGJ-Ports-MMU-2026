extends Node
class_name WorldRailsInternal


########################################################################################################################

var rail_groups : Dictionary = {};

class SourceMask:
	var source_mask : Array[int] = [];
	
	func _init(sourceMask : Array[int]) -> void:
		source_mask = sourceMask;
		source_mask.sort()
	
	func key() -> Array[int]:
		return source_mask;

func get_rail_group(sourceMask : SourceMask) -> RailGroup:
	if (!rail_groups.has(sourceMask.key())):
		rail_groups.set(sourceMask.key(), RailGroup.new());
	return rail_groups.get(sourceMask.key());
	
########################################################################################################################

var tile_shapes : TileShapes = TileShapes.new();

########################################################################################################################

func _physics_process(_delta: float) -> void:	
	if (Input.is_action_just_pressed("debug_drawRails")):
		draw_rails = !draw_rails;
	if (draw_rails):
		_draw_rail_paths();

var draw_rails : bool = false;
func _draw_rail_paths() -> void:
	var railGroup := get_rail_group(Player.s_instance.get_source_mask());
	for path : RailGroup.RailPath in railGroup.rail_paths:
		var pathPoints := path.points;
		ImmediateGizmos2D.line_polygon(pathPoints, path.color);
	ImmediateGizmos2D.reset();
	
########################################################################################################################


########################################################################################################################

func register_tilemap(tileMap : TileMap, sourceMask : SourceMask) -> void:
	get_rail_group(sourceMask).register_tilemap(tileMap, sourceMask, tile_shapes);

func get_closest_rail(pos : Vector2, sourceMask : SourceMask) -> RailGroup.RailCloseInformation:
	var bestRailInformation : RailGroup.RailCloseInformation = null;
	var railGroup := get_rail_group(sourceMask);
	for railPath : RailGroup.RailPath in railGroup.rail_paths:
		var railInformation := railPath.get_closest_point_information(pos);
		if (railInformation == null || 
			(bestRailInformation != null && bestRailInformation.closest_distance <= railInformation.closest_distance)):
			continue;
		bestRailInformation = railInformation;
	return bestRailInformation;

########################################################################################################################
