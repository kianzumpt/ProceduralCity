class_name CustomPolygon2D

var edges : Array
var bounding_box : Vector4

# it is assumed edge[0].end == edge[1].start, and that this connects at the end
# todo: verify this is true in the constructor and throw an exception if not true

func _init(new_edges : Array):
	edges = new_edges
	recalculate_bounding_box()

func recalculate_bounding_box() -> void:
	
	var min_x : float = edges[0].start.x
	var max_x : float = edges[0].start.x
	var min_y : float = edges[0].start.y
	var max_y : float = edges[0].start.y
	
	for edge in edges:
		if edge.start.x < min_x:
			min_x = edge.start.x
		
		if edge.start.x > max_x:
			max_x = edge.start.x
			
		if edge.start.y < min_y:
			min_y = edge.start.y
		
		if edge.start.y > max_y:
			max_y = edge.start.y
	
	bounding_box = Vector4(min_x, min_y, max_x, max_y)

static func new_regular_polygon(center : Vector2, sides : int, radius : float) -> CustomPolygon2D:
	
	# create an empty list of edges
	var new_edges : Array = []
	
	# loop once for every side of the polygon
	for i in sides:
		
		# set the start of the edge by starting at the top and going clockwise based on i
		var start = center + (Vector2.UP.rotated(float(i) / float(sides) * 2.0 * PI) * radius)
		
		# set the end index to connect to the first edge
		var end_index = 0
		
		# if the next index is actually less than the number of edges, we don't connect to the first edge yet
		if i + 1 < sides:
			end_index = i +1
		
		# set the end of the edge (the start of the next edge or the start of the first edge)
		var end = center + (Vector2.UP.rotated(float(end_index) / float(sides) * 2.0 * PI) * radius)
		
		# create and add the edge to the list
		new_edges.append(FiniteLine2D.new(start, end))
	
	# return the edges as polygon object
	return CustomPolygon2D.new(new_edges)
	
func scale_from_point(point : Vector2, new_scale : Vector2) -> void:
	
	for edge in edges:
		edge.start -= point
		edge.start = Vector2(edge.start.x * new_scale.x, edge.start.y * new_scale.y)
		edge.start += point
		
		edge.end -= point
		edge.end = Vector2(edge.end.x * new_scale.x, edge.end.y * new_scale.y)
		edge.end += point
		
	recalculate_bounding_box()

func skew(radius : float) -> void:
	
	var first_skew_vectoer : Vector2 =  Vector2.UP.rotated(randf() * 2.0 * PI) * (randf() * radius)
	var skew_vector : Vector2 = first_skew_vectoer
	var next_skew_vector : Vector2 = Vector2.UP.rotated(randf() * 2.0 * PI) * (randf() * radius)
	
	var edges_count : int = edges.size()
	
	for i in edges_count:
		
		edges[i].start += skew_vector
		
		# check if we are at the end of the last edge, if so, skew the same as the start of the first edge
		if i + 1 < edges_count:
			edges[i].end += next_skew_vector
		else:
			edges[i].end += first_skew_vectoer
		
		skew_vector = next_skew_vector
		next_skew_vector = Vector2.UP.rotated(randf() * 2.0 * PI) * (randf() * radius)
		
	recalculate_bounding_box()

func is_line_intersecting(line : FiniteLine2D) -> Array:
	
	var intersections : Array = []
	
	for edge in edges:
		var intersection_point = line.is_intersecting(edge)
		if intersection_point != null:
			intersections.append(intersection_point)
	
	return intersections

func is_line_intersecting_detailed(line : FiniteLine2D) -> Dictionary:
	var intersections : Array = []
	var edge_indices : Array = []
	
	for i in edges.size():
		var intersection_point = line.is_intersecting(edges[i])
		if intersection_point != null:
			intersections.append(intersection_point)
			edge_indices.append(i)
	
	return {"intersections": intersections, "edge_indices": edge_indices}

func is_point_inside(point : Vector2) -> bool:
	# todo: use the bounding box instead of 0 here
	var intersections = is_line_intersecting(FiniteLine2D.new(Vector2(bounding_box.x + 1000.0, point.y), point))
	return intersections.size() % 2 != 0

func rotate_around_point(point : Vector2, angle : float) -> CustomPolygon2D:
	
	var new_edges : Array = []
	
	for edge in edges:
		new_edges.append(edge.rotate_around(point, angle))
		
	return CustomPolygon2D.new(new_edges)

func clamp_line(line : FiniteLine2D) -> Variant:
	
	var intersections = is_line_intersecting(line)

	if intersections.size() >= 2:
		return FiniteLine2D.new(intersections[0], intersections[1])
		
	if intersections.size() == 1:
		var is_start_in_polygon = is_point_inside(line.start)
		var is_end_in_polygon = is_point_inside(line.end)
		
		if is_start_in_polygon and not is_end_in_polygon:
			return FiniteLine2D.new(line.start, intersections[0])
			
		if is_end_in_polygon and not is_start_in_polygon:
			return FiniteLine2D.new(intersections[0], line.end)
		
	return null

func get_area() -> float:
	
	var area : float = 0
	
	for edge in edges:
		area += edge.signed_area_to_the_x_axis()
		
	return abs(area)

func split(line : FiniteLine2D) -> Array:
	
	var intersections_detailed = is_line_intersecting_detailed(line)
	
	if intersections_detailed["intersections"].size() != 2:
		return [self]
	
	var edges_1 : Array = []
	var edges_2 : Array = []
	
	var start_of_first_split_edge : FiniteLine2D = FiniteLine2D.new(
		edges[intersections_detailed["edge_indices"][0]].start, 
		intersections_detailed["intersections"][0]
	)
	
	var end_of_first_split_edge : FiniteLine2D  = FiniteLine2D.new(
		intersections_detailed["intersections"][0],
		edges[intersections_detailed["edge_indices"][0]].end
	)
	
	var start_of_second_split_edge : FiniteLine2D  = FiniteLine2D.new(
		edges[intersections_detailed["edge_indices"][1]].start, 
		intersections_detailed["intersections"][1]
	)
	
	var end_of_first_second_edge : FiniteLine2D  = FiniteLine2D.new(
		intersections_detailed["intersections"][1],
		edges[intersections_detailed["edge_indices"][1]].end
	)

	var split_edge : FiniteLine2D = FiniteLine2D.new(intersections_detailed["intersections"][0], intersections_detailed["intersections"][1])
	var reverse_split_edge : FiniteLine2D = FiniteLine2D.new(intersections_detailed["intersections"][1], intersections_detailed["intersections"][0])
	
	for i in edges.size():
		
		if i < intersections_detailed["edge_indices"][0] or i > intersections_detailed["edge_indices"][1]:
			edges_1.append(edges[i])
			
		if i > intersections_detailed["edge_indices"][0] and i < intersections_detailed["edge_indices"][1]:
			edges_2.append(edges[i])
		
		if i == intersections_detailed["edge_indices"][0]:
			
			edges_1.append(start_of_first_split_edge)
			edges_1.append(split_edge)
			edges_1.append(end_of_first_second_edge)
			
			edges_2.append(start_of_second_split_edge)
			edges_2.append(reverse_split_edge)
			edges_2.append(end_of_first_split_edge)
	
	return [CustomPolygon2D.new(edges_1), CustomPolygon2D.new(edges_2)]

func get_longest_line_index() -> int:
	
	var index : int = 0
	var distance : float = edges[0].start.distance_to(edges[0].end)
	
	for i in edges.size():
		var new_distance = edges[i].start.distance_to(edges[i].end)
		if new_distance > distance:
			distance = new_distance
			index = i
		
	return index
	
func get_mean_point() -> Vector2:
	
	var mean_point : Vector2 = Vector2.ZERO
	
	for edge in edges:
		mean_point += edge.start
		
	return mean_point / float(edges.size())
	
func get_bounding_box_center() -> Vector2:
	recalculate_bounding_box()
	return Vector2((bounding_box.x + bounding_box.z) / 2.0, (bounding_box.y + bounding_box.w) / 2.0)

func shrink(amount : float) -> CustomPolygon2D:
	
	var bisectors : Array = []
	
	for edge in edges:
		var angle : float = edge.angle()
		var rotated_end = (edge.end - edge.start).rotated(-angle) + edge.start
		# todo: extend this by some calculated value like the hypot of the bounding box
		var bisector : FiniteLine2D = FiniteLine2D.new(edge.start + Vector2(-10000.0, amount), rotated_end + Vector2(10000.0, amount))
		bisector = bisector.rotate_around(edge.start, angle)
		bisectors.append(bisector)
	
	var new_edges : Array = []
	new_edges.resize(edges.size())
	new_edges.fill(null)
	
	for i in bisectors.size():
		
		var previous_index : int
		var next_index : int
		
		if i == 0:
			previous_index = bisectors.size() - 1
		else:
			previous_index = i - 1
		
		if i + 1 < bisectors.size():
			next_index = i + 1
		else:
			next_index = 0
			
		var intersection1 = bisectors[previous_index].is_intersecting(bisectors[i])
		var intersection2 = bisectors[i].is_intersecting(bisectors[next_index])
		
		if intersection1 != null and intersection2 != null:
						
			new_edges[i] = FiniteLine2D.new(intersection1, intersection2)
		else:
			print("well fuck")
		
	return CustomPolygon2D.new(new_edges)

func simplify(min_edge_length : float) -> CustomPolygon2D:
	
	var new_edges : Array = duplicate().edges
	
	if edges.size() > 2:
		for i in new_edges.size():
			if new_edges[i].start.distance_to(new_edges[i].end) < min_edge_length:
				
				var edge_center = new_edges[i].get_center()
				
				var next_index : int = i + 1
				
				if next_index == new_edges.size():
					next_index = 0
				
				var previous_index : int = i - 1
				
				if i == 0:
					previous_index = new_edges.size() - 1
					
				new_edges[next_index] = FiniteLine2D.new(edge_center, new_edges[next_index].end)
				new_edges[previous_index] = FiniteLine2D.new(new_edges[previous_index].start, edge_center)
				
				new_edges.remove_at(i)
				
				return CustomPolygon2D.new(new_edges).simplify(min_edge_length)
				
	return self

func duplicate() -> CustomPolygon2D:
	var new_edges = []
	for edge in edges:
		new_edges.append(edge.duplicate())
		
	return CustomPolygon2D.new(new_edges)

func remove_ear(previous_index, current_index) -> CustomPolygon2D:
	
	var new_edges : Array = duplicate().edges
	
	new_edges[previous_index].end = new_edges[current_index].end
	new_edges.remove_at(current_index)
	
	return CustomPolygon2D.new(new_edges)
