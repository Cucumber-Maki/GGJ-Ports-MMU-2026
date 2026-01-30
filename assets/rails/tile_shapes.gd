class_name TileShapes

var tile_shapes : Dictionary = {}

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
		
		func _is_edge() -> bool:
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
	
	func has_edge(index : int, tileRotation : int) -> bool:
		var flipped := tileRotation >= 4;
		tileRotation = posmod(tileRotation, 4);
		index = posmod(index - tileRotation, c_checks.size());
		if (flipped):
			index = posmod(-index, c_checks.size());
		return edges[index]._is_edge();
	
	func get_points(index : int, hasTop : bool, tileRotation : int) -> Array[Vector2]:
		var tileRotationRaw := tileRotation;
		tileRotation = posmod(tileRotation, 4);
		var leftEdge : int = posmod(index - tileRotation, c_checks.size());
		var rightEdge : int = posmod(index - tileRotation, c_checks.size());
		
		if (get_edge_left(leftEdge, tileRotationRaw) <= 0 && hasTop):
			return [];
		
		var leftPoints : Array[Vector2] = [];
		var leftMarched := false;
		if (get_edge_left(leftEdge, tileRotationRaw) > 0):
			leftMarched = true;
			if (has_edge(leftEdge, tileRotationRaw)):
				leftPoints.append(get_edge_point_left(leftEdge, tileRotationRaw));
			leftEdge = (leftEdge - 1) % edges.size();
		if (!leftMarched && !hasTop):
			leftPoints.append(get_edge_point_left(leftEdge, tileRotationRaw));
		leftPoints.reverse();
		
			
		var rightPoints : Array[Vector2] = []
		var rightMarched := false;
		if (get_edge_right(rightEdge, tileRotationRaw) > 0):
			rightMarched = true;
			if (has_edge(rightEdge, tileRotationRaw)):
				rightPoints.append(get_edge_point_right(rightEdge, tileRotationRaw));
			rightEdge = (rightEdge + 1) % edges.size();
		if (!rightMarched && !hasTop):
			rightPoints.append(get_edge_point_right(rightEdge, tileRotationRaw));
			
		var middlePoints : Array[Vector2] = []
		var le = leftEdge;
		while (le != rightEdge || le == rightEdge): 
			var ci = get_safe_index(le, tileRotationRaw);
			if (edges[ci].inset > 0 && edges[ci].inset < c_tile_size):
				var middlePoint := get_edge_point_middle(le, tileRotationRaw);
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
		
		var midPoint := Vector2(c_tile_size, c_tile_size) / 2.0;
		for i : int in points.size():
			points[i] = (points[i] - midPoint).rotated((PI / 2) * tileRotation) + midPoint;
		
		return points;
		
	func get_safe_index(index : int, tileRotation : int) -> int:
		var flipped := tileRotation >= 4;
		if (flipped):
			return get_safe_index(-index, posmod(tileRotation, 4));
		return posmod(index, c_checks.size());
	func get_edge_left(index : int, tileRotation : int) -> int:
		var flipped := tileRotation >= 4;
		if (flipped):
			return get_edge_right(-index, posmod(tileRotation, 4));
		return edges[get_safe_index(index, tileRotation)].left;
	func get_edge_right(index : int, tileRotation : int) -> int:
		var flipped := tileRotation >= 4;
		if (flipped):
			return get_edge_left(-index, posmod(tileRotation, 4));
		return edges[get_safe_index(index, tileRotation)].right;
	func get_edge_inset(index : int, tileRotation : int) -> int:
		return edges[get_safe_index(index, tileRotation)].inset;
	func get_edge_point_left(index : int, tileRotation : int) -> Vector2i:
		var flipped := tileRotation >= 4;
		if (flipped):
			var point := get_edge_point_right(-index,  posmod(tileRotation, 4));
			point.x = c_tile_size - point.x;
			return point;
		index = posmod(index, c_checks.size());
		var checkDirection : Vector2i = c_checks[index][1];
		var checkLeft : Vector2i = (c_checks[index][0] * (c_tile_size));
		return checkLeft + (checkDirection * edges[index].left);
	func get_edge_point_right(index : int, tileRotation : int) -> Vector2i:
		var flipped := tileRotation >= 4;
		if (flipped):
			var point := get_edge_point_left(-index,  posmod(tileRotation, 4));
			point.x = c_tile_size - point.x;
			return point;
		index = posmod(index, c_checks.size());
		var checkDirection : Vector2i = c_checks[index][1];
		var checkLeft : Vector2i = (c_checks[index][0] * (c_tile_size));
		var checkRight : Vector2i = checkLeft + (checkDirection * (c_tile_size));
		return checkRight - (checkDirection * edges[index].right);
	func get_edge_point_middle(index : int, tileRotation : int) -> Vector2i:
		var flipped := tileRotation >= 4;
		if (flipped):
			var point := get_edge_point_middle(-index,  posmod(tileRotation, 4));
			point.x = c_tile_size - point.x;
			return point;
		index = posmod(index, c_checks.size());
		var checkDirection : Vector2i = c_checks[index][1];
		var checkLeft : Vector2i = (c_checks[index][0] * (c_tile_size));
		var checkRight : Vector2i = checkLeft + (checkDirection * (c_tile_size));
		@warning_ignore("integer_division")
		var checkMiddle : Vector2i = (checkLeft + checkRight) / 2;
		var checkMiddleDirection : Vector2i = c_checks[(index + 1) % c_checks.size()][1];
		var middlePoint := checkMiddle + (checkMiddleDirection * edges[index].inset);
		return middlePoint;

func _get_tile_info(tileId : Vector2i, tileSet : TileSet) -> TileInfo:
	if (!tile_shapes.has(tileId)): 
		tile_shapes.set(tileId, TileInfo.new(tileId, tileSet));
	return tile_shapes.get(tileId);
