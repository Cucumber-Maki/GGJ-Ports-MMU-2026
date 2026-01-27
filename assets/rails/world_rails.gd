extends Node
class_name WorldRailsInternal

var rail_paths : Array[RailPath];
var rail_paths_lookup : Dictionary;

var tile_shapes : Dictionary = {}

const target_layer := 0;

class RailPath:
	var points : Array[Vector2] = [];
	var final : bool = false;
	var index : int = -1;
	var color : Color = Color.from_hsv(randf(), 0.5, 1.0);
	
	var total_length : float = 0.0;

	func get_point_along_path(distance : float) -> RailPointInformation:
		distance = fposmod(distance, total_length);
		
		var pointIndex : int = 0;
		var p1 := points[pointIndex];
		var i2 := (pointIndex + 1) % points.size();
		var p2 := points[i2];
		var dist := (p2 - p1).length();
		while (distance > 0.0 && pointIndex < points.size()):
			p1 = points[pointIndex];
			p2 = points[(pointIndex + 1) % points.size()];
			dist = (p2 - p1).length();
			if (dist > distance):
				break;
			distance -= dist;
			pointIndex += 1;
			
		if (pointIndex >= points.size()):
			return get_point_along_path(distance);
			
		p1 = points[pointIndex];
		p2 = points[(pointIndex + 1) % points.size()];
		var diff := (p2 - p1);
		var dir := diff.normalized();
		var normal := Vector2(dir.y, -dir.x);
		var smoothNormal := normal;
		
		var percentage := distance / diff.length();
		if (percentage < 0.5):
			var p0 := points[posmod(pointIndex - 1, points.size())];
			var lastNormal := (p1 - p0).normalized();
			lastNormal = Vector2(lastNormal.y, -lastNormal.x);
			smoothNormal = lastNormal.slerp(normal, remap(percentage, 0.0, 0.5, 0.5, 1.0));			
		else:
			var p3 := points[(pointIndex + 2) % points.size()];
			var nextNormal := (p3 - p2).normalized();
			nextNormal = Vector2(nextNormal.y, -nextNormal.x);
			smoothNormal = normal.slerp(nextNormal, remap(percentage, 0.5, 1.0, 0.0, 0.5));		
		
		return RailPointInformation.new(
			p1 + (dir * distance),
			normal, 
			smoothNormal
		);

	func get_closest_point_information(pos : Vector2) -> RailCloseInformation:
		var bestDistanceSquared := INF;
		var bestInformation = null;
		
		var totalDistance : float = 0.0;
		for i : int in points.size():
			var p1 := points[i];
			var p2 := points[(i + 1) % points.size()];
			
			var line := p2 - p1;
			var lineDirection := line.normalized();
			var posRelative := pos - p1;
			var lineDistance := lineDirection.dot(posRelative);
			
			var closestAccross := clampf(lineDistance, 0, line.length());
			var closestPos := p1 + (lineDirection * closestAccross);
			var distanceSquared := (pos - closestPos).length_squared();
			
			if (bestDistanceSquared > distanceSquared):
				bestDistanceSquared = distanceSquared;
				bestInformation = RailCloseInformation.new(
					self, 
					totalDistance + closestAccross,
					i,
					Vector2(lineDirection.y, -lineDirection.x), # TODO: might be wrong...
					closestPos,
					sqrt(distanceSquared)
				);
			totalDistance += line.length();
		return bestInformation;

	func _recalculate_information() -> void:
		total_length = 0.0;
		for i : int in points.size():
			var p1 := points[i];
			var p2 := points[(i + 1) % points.size()];
			total_length += (p2 - p1).length();

class RailPointInformation: 
	var position : Vector2;
	var normal : Vector2;
	var smooth_normal : Vector2;
	func _init(_position : Vector2, _normal : Vector2, smoothNormal : Vector2) -> void:
		position = _position;
		normal = _normal;
		smooth_normal = smoothNormal

class RailCloseInformation:
	var rail_path : RailPath;
	var rail_path_distance : float;
	var rail_index : int;
	var rail_normal : Vector2;
	var closest_position : Vector2;
	var closest_distance : float;
	
	func _init(railPath : RailPath, railPathDistance : float, railIndex : int, railNormal : Vector2, closestPosition : Vector2, closestDistance : float) -> void:
		rail_path = railPath;
		rail_path_distance = railPathDistance;
		rail_index = railIndex;
		rail_normal = railNormal;
		closest_position = closestPosition;
		closest_distance = closestDistance;

class TileInfo:
	const c_tile_size : int = 32;
	const c_checks : Array = [
		[ Vector2i(0, 0), Vector2i(1, 0) ],
		[ Vector2i(1, 0), Vector2i(0, 1) ],
		[ Vector2i(1, 1), Vector2i(-1, 0) ],
		[ Vector2i(0, 1), Vector2i(0, -1) ],
	];
	
	var edges : Array[TileEdgeInfo] = [
		TileEdgeInfo.new(),
		TileEdgeInfo.new(),
		TileEdgeInfo.new(),
		TileEdgeInfo.new()
	];
	
	class TileEdgeInfo:
		var left : int = 0;
		var right : int = 0;
		var inset : int = 0;
		
		func is_edge() -> bool:
			return left < (c_tile_size - right);

	func _init(tileId : Vector2i, tileset : TileSet) -> void:
		var source : TileSetAtlasSource = tileset.get_source(0);
		var tileSize := source.texture_region_size;
		var image := source.texture.get_image();
		
		assert(tileSize.x == c_tile_size && tileSize.y == c_tile_size);
		
		## read pixels.....
		for i : int in c_checks.size():
			var checkDirection : Vector2i = c_checks[i][1];
			var checkLeft : Vector2i = (tileId * c_tile_size) + (c_checks[i][0] * (c_tile_size - 1));
			var checkRight : Vector2i = checkLeft + (checkDirection * (c_tile_size - 1));
			
			for c : int in c_tile_size:
				var pixelPos := checkLeft + (checkDirection * edges[i].left);
				var hasPixel := image.get_pixel(pixelPos.x, pixelPos.y).a > 0;
				if (hasPixel): break;
				edges[i].left += 1;
				
			for c : int in c_tile_size:
				var pixelPos := checkRight - (checkDirection * edges[i].right);
				var hasPixel := image.get_pixel(pixelPos.x, pixelPos.y).a > 0;
				if (hasPixel): break;
				edges[i].right += 1;
				
			@warning_ignore("integer_division")
			var checkMiddle : Vector2i = (checkLeft + checkRight) / 2;
			var checkMiddleDirection : Vector2i = c_checks[(i + 1) % c_checks.size()][1];
			for c : int in c_tile_size:
				var pixelPos := checkMiddle + (checkMiddleDirection * edges[i].inset);
				var hasPixel := image.get_pixel(pixelPos.x, pixelPos.y).a > 0;
				if (hasPixel): break;
				edges[i].inset += 1;
	
	func get_points(index : int, hasTop : bool) -> Array[Vector2]:
		var leftEdge : int = index;
		var rightEdge : int = index;
		
		if (edges[leftEdge].left <= 0 && hasTop):
			return [];
		
		var leftPoints : Array[Vector2] = [];
		var leftMarched := false;
		if (edges[leftEdge].left > 0):
			leftMarched = true;
			if (edges[leftEdge].is_edge()):
				leftPoints.append(get_edge_point_left(leftEdge));
			leftEdge = (leftEdge - 1) % edges.size();
		if (!leftMarched && !hasTop):
			leftPoints.append(get_edge_point_left(leftEdge));
		leftPoints.reverse();
		
			
		var rightPoints : Array[Vector2] = []
		var rightMarched := false;
		if (edges[rightEdge].right > 0):
			rightMarched = true;
			if (edges[rightEdge].is_edge()):
				rightPoints.append(get_edge_point_right(rightEdge));
			rightEdge = (rightEdge + 1) % edges.size();
		if (!rightMarched && !hasTop):
			rightPoints.append(get_edge_point_right(rightEdge));
			
		var middlePoints : Array[Vector2] = []
		var le = leftEdge;
		while (le != rightEdge || le == rightEdge): 
			var ci = le;
			if (edges[ci].inset < c_tile_size):
				var checkDirection : Vector2i = c_checks[ci][1];
				var checkLeft : Vector2i = (c_checks[ci][0] * (c_tile_size));
				var checkRight : Vector2i = checkLeft + (checkDirection * (c_tile_size));
				@warning_ignore("integer_division")
				var checkMiddle : Vector2i = (checkLeft + checkRight) / 2;
				var checkMiddleDirection : Vector2i = c_checks[(ci + 1) % c_checks.size()][1];
				var middlePoint := checkMiddle + (checkMiddleDirection * edges[ci].inset);
				@warning_ignore("integer_division")
				if (edges[ci].inset > c_tile_size / 2):
					middlePoints.append(middlePoint);
				else:
					var temp = middlePoints;
					middlePoints = [ middlePoint ]
					middlePoints.append_array(temp);
			if (le == rightEdge): break;
			le = (le + 1) % c_checks.size();
		
		
		var points : Array[Vector2] = []
		if (leftMarched && !rightMarched && !hasTop && !middlePoints.is_empty()):
			points.append(middlePoints[0]);
		points.append_array(leftPoints);
		points.append_array(rightPoints);
		if (!leftMarched && rightMarched && !hasTop && !middlePoints.is_empty()):
			middlePoints.reverse();
			points.append(middlePoints[0]);
		
		return points;
		
	func get_edge_point_left(index : int) -> Vector2i:
		var checkDirection : Vector2i = c_checks[index][1];
		var checkLeft : Vector2i = (c_checks[index][0] * (c_tile_size));
		return checkLeft + (checkDirection * edges[index].left);
	func get_edge_point_right(index : int) -> Vector2i:
		var checkDirection : Vector2i = c_checks[index][1];
		var checkLeft : Vector2i = (c_checks[index][0] * (c_tile_size));
		var checkRight : Vector2i = checkLeft + (checkDirection * (c_tile_size));
		return checkRight - (checkDirection * edges[index].right);

var draw_rails : bool = false;

func _physics_process(_delta: float) -> void:	
	if (Input.is_action_just_pressed("debug_drawRails")):
		draw_rails = !draw_rails;
	if (draw_rails):
		_draw_rail_paths();

#######################################################################################

func _get_tile_info(tileId : Vector2i, tileSet : TileSet) -> TileInfo:
	if (!tile_shapes.has(tileId)): 
		tile_shapes.set(tileId, TileInfo.new(tileId, tileSet));
	return tile_shapes.get(tileId);
func _recurse_rail(tileMap : TileMap, cellCoord : Vector2i, checkDirection : int = 0) -> RailPath:
	const checks : Array[Vector2i] = [ 
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 0),
	];
	checkDirection = checkDirection % checks.size();
	
	var tileId = tileMap.get_cell_atlas_coords(target_layer, cellCoord);
	if (tileId.x == -1 || tileId.y == -1):
		return null;
		
	var railKey := Vector4i(cellCoord.x, cellCoord.y, checkDirection, tileMap.get_instance_id());
	if (rail_paths_lookup.has(railKey)):
		var index : int = rail_paths_lookup.get(railKey);
		if (index < 0 || index >= rail_paths.size()):
			return RailPath.new();
		return rail_paths[index];

	var cellPos : Vector2 = (cellCoord as Vector2) * (tileMap.tile_set.tile_size as Vector2);
	
	const edges : Array = [ 
		[ Vector2(0, 0), Vector2(1, 0) ],
		[ Vector2(1, 0), Vector2(1, 1) ],
		[ Vector2(1, 1), Vector2(0, 1) ],
		[ Vector2(0, 1), Vector2(0, 0) ],
	];
	assert(checks.size() == edges.size());
	
	rail_paths_lookup.set(railKey, rail_paths.size());

	var tileInfo = _get_tile_info(tileId, tileMap.tile_set);

	var railData : RailPath = null;
	var points : Array[Vector2] = [];
	for checkIndexBefore : int in checks.size(): 
		var checkIndex := (checkIndexBefore + checkDirection) % checks.size();
		var checkCell := cellCoord + checks[checkIndex];
		
		if (!tileInfo.edges[checkIndex].is_edge()):
			continue;
		
		railData = _recurse_rail(tileMap, checkCell, checkIndex - 1);
		if (railData == null): 
			for point in tileInfo.get_points(checkIndex, false):
				points.append(cellPos + point);
			continue;
			
		if (railData.final):
			rail_paths_lookup.set(railKey, railData.index);
			return railData;
			
		for point in tileInfo.get_points(checkIndex, true):
			points.append(cellPos + point);
			
		points.reverse();
		railData.points.append_array(points);
		return railData;

	railData = RailPath.new();
	railData.points = points;
	railData.points.reverse();
	return railData;

func _draw_rail_paths() -> void:
	for path : RailPath in rail_paths:
		var pathPoints := path.points;
		ImmediateGizmos2D.line_polygon(pathPoints, path.color);
	ImmediateGizmos2D.reset();

#######################################################################################

var registered_tilemaps : Array[TileMap] = [];
func register_tilemap(tileMap : TileMap) -> void:
	if (registered_tilemaps.has(tileMap)):
		return;
	registered_tilemaps.append(tileMap);
	
	var used_cells = tileMap.get_used_cells(target_layer);
	for cellCoord : Vector2i in used_cells:		
		var railKey := Vector4i(cellCoord.x, cellCoord.y, 0, tileMap.get_instance_id());
		if (rail_paths_lookup.has(railKey)):
			continue;

		var path := _recurse_rail(tileMap, cellCoord);
		if (path == null || path.final): 
			continue;
		
		if (path.points.size() <= 0): 
			#ImmediateGizmos2D.line_circle((cellCoord * 32.0) + (Vector2.ONE * 16), 10.0);
			continue;
		#ImmediateGizmos2D.line_square((cellCoord * 32.0) + (Vector2.ONE * 16), 12.0);

		for i : int in path.points.size():
			path.points[i] += tileMap.position;
			
		var i := 0;
		while (i < path.points.size()):
			var p1 := path.points[i];
			var i2 := (i + 1) % path.points.size();
			var p2 := path.points[i2];
			if ((p1 - p2).length() >= 5.0): 
				i += 1;
				continue;
			var p3 = (p1 + p2) * 0.5;
			path.points[i2] = p3;
			path.points.remove_at(i);

		path._recalculate_information();
		
		path.final = true;
		path.index = rail_paths.size();
		path.points.reverse();
		rail_paths.append(path);

func get_closest_rail(pos : Vector2) -> RailCloseInformation:
	var bestRailInformation : RailCloseInformation = null;
	for railPath : RailPath in rail_paths:
		var railInformation := railPath.get_closest_point_information(pos);
		if (bestRailInformation != null && bestRailInformation.closest_distance <= railInformation.closest_distance):
			continue;
		bestRailInformation = railInformation;
	return bestRailInformation;

#######################################################################################
