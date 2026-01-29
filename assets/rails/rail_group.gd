class_name RailGroup

########################################################################################################################

var rail_paths : Array[RailPath];
var rail_paths_lookup : Dictionary;

const target_layer := 0;

########################################################################################################################

class RailPath:
	var points : Array[Vector2] = [];
	var final : bool = false;
	var index : int = -1;
	var color : Color = Color.from_hsv(randf(), 0.5, 1.0);
	
	var total_length : float = 0.0;

	func get_point_along_path(distance : float, sharpAngle : float = PI) -> RailPointInformation:
		distance = fposmod(distance, total_length);
		
		var pointIndex : int = 0;
		var p1 := points[pointIndex];
		var p2 := points[posmod(pointIndex + 1, points.size())];
		var dist := (p2 - p1).length();
		while (distance > 0.0 && pointIndex < points.size()):
			p1 = points[pointIndex];
			p2 = points[posmod(pointIndex + 1, points.size())];
			dist = (p2 - p1).length();
			if (dist > distance):
				break;
			distance -= dist;
			pointIndex += 1;
			
		if (pointIndex >= points.size()):
			return get_point_along_path(distance, sharpAngle);
			
		p1 = points[pointIndex];
		p2 = points[posmod(pointIndex + 1, points.size())];
		var diff := (p2 - p1);
		var dir := diff.normalized();
		var normal := Vector2(dir.y, -dir.x);
		var smoothNormal := normal;
		
		var percentage := distance / diff.length();
		if (percentage < 0.5):
			var p0 := points[posmod(pointIndex - 1, points.size())];
			var lastNormal := (p1 - p0).normalized();
			lastNormal = Vector2(lastNormal.y, -lastNormal.x);
			if (absf(normal.angle_to(lastNormal)) < sharpAngle):
				smoothNormal = lastNormal.slerp(normal, remap(percentage, 0.0, 0.5, 0.5, 1.0));			
		else:
			var p3 := points[posmod(pointIndex + 2, points.size())];
			var nextNormal := (p3 - p2).normalized();
			nextNormal = Vector2(nextNormal.y, -nextNormal.x);
			if (absf(normal.angle_to(nextNormal)) < sharpAngle):
				smoothNormal = normal.slerp(nextNormal, remap(percentage, 0.5, 1.0, 0.0, 0.5));		
		
		return RailPointInformation.new(
			p1 + (dir * distance),
			normal, 
			smoothNormal
		);

	func seek_point_along_path(start : float, targetChange : float, sharpAngle : float) -> RailSeekInformation:
		var changeSign := signf(targetChange) as int;
		start = fposmod(start, total_length);
		targetChange = fposmod(start + targetChange, total_length);
		
		var result := RailSeekInformation.new();
		if (changeSign == 0):
			return result;
		
		var pointIndex : int = 0;
		while (start > 0.0 && pointIndex < points.size()):
			var p1 := points[pointIndex];
			var p2 := points[posmod(pointIndex + 1, points.size())];
			var dist := (p2 - p1).length();
			if (dist > start):
				break;
			start -= dist;
			pointIndex += 1;
		pointIndex = posmod(pointIndex, points.size())

		var targetChangeIndex : int = 0;
		while (targetChange > 0.0 && targetChangeIndex < points.size()):
			var p1 := points[targetChangeIndex];
			var p2 := points[posmod(targetChangeIndex + 1, points.size())];
			var dist := (p2 - p1).length();
			if (dist > targetChange):
				break;
			targetChange -= dist;
			targetChangeIndex += 1;
		targetChangeIndex = posmod(targetChangeIndex, points.size());
		
		var distanceTravelled : float = 0.0;
		while (pointIndex != targetChangeIndex):
			var nextIndex := posmod(pointIndex + changeSign, points.size());
			
			# Bump.
			var p1 := points[pointIndex];
			var p2 := points[posmod(pointIndex + 1, points.size())];
			var dist := (p2 - p1).length();
			var normal := (p2 - p1).normalized();
			normal = Vector2(normal.y, -normal.x);

			var pn := points[posmod(nextIndex + maxi(changeSign, 0), points.size())];
			var pnNormal : Vector2;
			
			# Set distanceTravelled to the start of pn.
			if (changeSign == 1):
				distanceTravelled += dist - start;
				start = 0;
				pnNormal = (pn - p2).normalized();
			else: # changeSign == -1
				distanceTravelled += start;
				start = (p1 - pn).length();
				pnNormal = (p1 - pn).normalized();
				
			# Perpendicularize.
			pnNormal = Vector2(pnNormal.y, -pnNormal.x);
			
			if (WorldRails.draw_rails):
				var debugPoint : Vector2 = p2 if changeSign == 1 else p1;
				ImmediateGizmos2D.line(debugPoint, debugPoint + pnNormal * 20.0);
				ImmediateGizmos2D.line(debugPoint, debugPoint + normal * 20.0);
				var dangle := normal.angle_to(pnNormal);
				ImmediateGizmos2D.line_arc(debugPoint, normal * 20.0, dangle);
				ImmediateGizmos2D.line_arc(debugPoint, pnNormal * 20.0, -dangle);
			
			# Move accross.
			pointIndex = nextIndex;
			
			# Check for sharp angle.
			var angle := normal.angle_to(pnNormal);
			if (result.detatch_index == -1 &&
				((angle >= sharpAngle && changeSign == 1) || 
				(angle <= -sharpAngle && changeSign == -1))):
				result.detatch_distance = distanceTravelled * changeSign;
				result.detatch_index = pointIndex;
				if (WorldRails.draw_rails):
					var debugPoint : Vector2 = p2 if changeSign == 1 else p1;
					ImmediateGizmos2D.line_arc(debugPoint, normal * 20.0, angle, Color.RED);
					ImmediateGizmos2D.line_arc(debugPoint, pnNormal * 20.0, -angle, Color.RED);
			elif (result.wall_index == -1 && 
				((angle >= sharpAngle && changeSign == -1) || 
				(angle <= -sharpAngle && changeSign == 1))):
				result.wall_distance = distanceTravelled * changeSign;
				result.wall_index = pointIndex;
				if (WorldRails.draw_rails):
					var debugPoint : Vector2 = p2 if changeSign == 1 else p1;
					ImmediateGizmos2D.line_arc(debugPoint, normal * 20.0, angle, Color.GREEN);
					ImmediateGizmos2D.line_arc(debugPoint, pnNormal * 20.0, -angle, Color.GREEN);
				
			if (result.wall_index != -1 && result.detatch_distance != -1):
				break;
			
		# Indices are now the same.
		return result;

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

class RailSeekInformation: 
	var detatch_distance : float = INF;
	var detatch_index : int = -1;
	var wall_distance : float = INF;
	var wall_index : int = -1;
		
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


########################################################################################################################

func _get_tile_rotation(tileMap : TileMap, cellCoord : Vector2i) -> int:
	var tileAlternative := tileMap.get_cell_alternative_tile(target_layer, cellCoord);
	var transpose := (tileAlternative & TileSetAtlasSource.TRANSFORM_TRANSPOSE) > 0;
	var flip_h := (tileAlternative & TileSetAtlasSource.TRANSFORM_FLIP_H) > 0;
	var flip_v := (tileAlternative & TileSetAtlasSource.TRANSFORM_FLIP_V) > 0;
	
	if (!transpose && !flip_h && !flip_v):
		return 0;
	if (transpose && flip_h && !flip_v):
		return 1;
	if (!transpose && flip_h && flip_v):
		return 2;
	if (transpose && !flip_h && flip_v):
		return 3;
		
	if (!transpose && flip_h && !flip_v):
		return 4;
	if (transpose && flip_h && flip_v):
		return 5;
	if (!transpose && !flip_h && flip_v):
		return 6;
	if (transpose && !flip_h && !flip_v):
		return 7;
		
	assert(false, "heck.");
	return -1;

func _recurse_rail(tileMap : TileMap, sourceMask : WorldRailsInternal.SourceMask, tileShapes : TileShapes, cellCoord : Vector2i, checkDirection : int = 0, recursed : bool = false) -> RailGroup.RailPath:
	const checks : Array[Vector2i] = [ 
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 0),
	];
	checkDirection = checkDirection % checks.size();
	
	if (!sourceMask.source_mask.has(tileMap.get_cell_source_id(target_layer, cellCoord))):
		return null;
	var tileId := tileMap.get_cell_atlas_coords(target_layer, cellCoord);
	if (tileId.x == -1 || tileId.y == -1):
		return null;
	
	var tileInfo = tileShapes._get_tile_info(tileId, tileMap.tile_set);
	var tileRotation := _get_tile_rotation(tileMap, cellCoord);
	if (recursed && !tileInfo.has_edge(checkDirection - 1, tileRotation)):
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
	
	var railData : RailPath = null;
	var points : Array[Vector2] = [];
	for checkIndexBefore : int in checks.size(): 
		var checkIndex := posmod(checkIndexBefore + checkDirection, checks.size());
		var checkCell := cellCoord + checks[checkIndex];
		
		railKey.z = checkIndex;
		if (rail_paths_lookup.has(railKey)):
			var index : int = rail_paths_lookup.get(railKey);
			if (index < 0 || index >= rail_paths.size()):
				railData = RailPath.new();
			else:
				railData = rail_paths[index];
			
		if (railData == null):
			rail_paths_lookup.set(railKey, rail_paths.size());
			
			if (!tileInfo.has_edge(checkIndex, tileRotation)):
				continue;
			
			railData = _recurse_rail(tileMap, sourceMask, tileShapes, checkCell, checkIndex - 1, true);
			if (railData == null): 
				for point in tileInfo.get_points(checkIndex, false, tileRotation):
					points.append(cellPos + point);
				continue;
			
		if (railData.final):
			return railData;
			
		for point in tileInfo.get_points(checkIndex, true, tileRotation):
			points.append(cellPos + point);
			
		points.reverse();
		railData.points.append_array(points);
		return railData;

	railData = RailPath.new();
	railData.points = points;
	railData.points.reverse();
	return railData;

########################################################################################################################

func _draw_rail_paths() -> void:
	for path : RailPath in rail_paths:
		var pathPoints := path.points;
		ImmediateGizmos2D.line_polygon(pathPoints, path.color);
	ImmediateGizmos2D.reset();

########################################################################################################################

var registered_tilemaps : Array[TileMap] = [];
func register_tilemap(tileMap : TileMap, sourceMask : WorldRailsInternal.SourceMask, tileShapes : TileShapes) -> void:
	if (registered_tilemaps.has(tileMap)):
		return;
	registered_tilemaps.append(tileMap);
	
	var used_cells : Array[Vector2i] = [];
	
	for source : int in sourceMask.source_mask:
		used_cells.append_array(tileMap.get_used_cells_by_id(target_layer, source));
	
	for cellCoord : Vector2i in used_cells:		
		var railKey := Vector4i(cellCoord.x, cellCoord.y, 0, tileMap.get_instance_id());
		if (rail_paths_lookup.has(railKey)):
			continue;

		var path := _recurse_rail(tileMap, sourceMask, tileShapes, cellCoord);
		if (path == null): 
			continue;
			
		if (path.final):
			var replaceValue = rail_paths.size();
			for key in rail_paths_lookup.keys():
				if (rail_paths_lookup.get(key) == replaceValue):
					rail_paths_lookup.set(key, path.index);
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
			var i2 := posmod(i + 1, path.points.size());
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
