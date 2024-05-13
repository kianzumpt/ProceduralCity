class_name CustomPolygon2D

var center : Vector2
var local_lines : Array
var local_bounding_box : Vector4

# it is assumed line[0].end == line[1].start, and that this connects at the end
# todo: verify this is true in the constructor and throw an exception if not true

func _init(new_center : Vector2, new_local_lines : Array):
	center = new_center
	local_lines = new_local_lines
	calculate_local_bounding_box()

func calculate_local_bounding_box() -> void:
	
	var min_x = 0.0
	var max_x = 0.0
	var min_y = 0.0
	var max_y = 0.0
	
	for local_line in local_lines:
		if local_line.start.x < min_x:
			min_x = local_line.start.x
		
		if local_line.start.x > max_x:
			max_x = local_line.start.x
			
		if local_line.start.y < min_y:
			min_y = local_line.start.y
		
		if local_line.start.y > max_y:
			max_y = local_line.start.y
	
	local_bounding_box = Vector4(min_x, min_y, max_x, max_y)

func get_global_bounding_box() -> Vector4:
	return Vector4(
		local_bounding_box.x + center.x, 
		local_bounding_box.y + center.y,
		local_bounding_box.z + center.x,
		local_bounding_box.w + center.y,
	)

static func new_regular_polygon(new_center : Vector2, sides : int, radius : float) -> CustomPolygon2D:
	
	# create an empty list of line segments
	var lines : Array = []
	
	# loop once for every side of the polygon
	for i in sides:
		
		# set the start of the line by starting at the top and going clockwise based on i
		var start = Vector2.UP.rotated(float(i) / float(sides) * 2.0 * PI) * radius
		
		# set the end index to connect to the first line
		var end_index = 0
		
		# if the next index is actually less than the number of lines, we don't connect to the first line yet
		if i + 1 < sides:
			end_index = i +1
		
		# set the end of the line (the start of the next line or the start of the first line)
		var end = Vector2.UP.rotated(float(end_index) / float(sides) * 2.0 * PI) * radius
		
		# create and add the line to the list
		lines.append(FiniteLine2D.new(start, end))
	
	# return the lines as polygon object
	return CustomPolygon2D.new(new_center, lines)
	
func scale(new_scale : Vector2) -> void:
	
	for line in local_lines:
		line.start = Vector2(line.start.x * new_scale.x, line.start.y * new_scale.y)
		line.end = Vector2(line.end.x * new_scale.x, line.end.y * new_scale.y)
		
	calculate_local_bounding_box()

func skew(radius : float) -> void:
	
	var first_skew_vectoer : Vector2 =  Vector2.UP.rotated(randf() * 2.0 * PI) * (randf() * radius)
	var skew_vector : Vector2 = first_skew_vectoer
	var next_skew_vector : Vector2 = Vector2.UP.rotated(randf() * 2.0 * PI) * (randf() * radius)
	
	for i in local_lines.size():
		
		local_lines[i].start += skew_vector
		
		# check if we are at the end of the last line, if so, skew the same as the start of the first line
		if i + 1 < local_lines.size():
			local_lines[i].end += next_skew_vector
		else:
			local_lines[i].end += first_skew_vectoer
		
		skew_vector = next_skew_vector
		next_skew_vector = Vector2.UP.rotated(randf() * 2.0 * PI) * (randf() * radius)
		
	calculate_local_bounding_box()

func local_line_to_global_line(line : FiniteLine2D) -> FiniteLine2D:
	return FiniteLine2D.new(line.start + center, line.end + center)

func global_lines() -> Array:
	var new_global_lines : Array = []
	
	for local_line in local_lines:
		new_global_lines.append(local_line_to_global_line(local_line))
	
	return new_global_lines

func is_line_intersecting(line : FiniteLine2D) -> Array:
	
	var intersections : Array = []
	
	for global_line in global_lines():
		var intersection_point = line.is_intersecting(global_line)
		if intersection_point != null:
			intersections.append(intersection_point)
	
	return intersections

func is_line_intersecting_detailed(line : FiniteLine2D) -> Dictionary:
	var intersections : Array = []
	var lines_indices : Array = []
	
	for i in local_lines.size():
		var intersection_point = line.is_intersecting(local_line_to_global_line(local_lines[i]))
		if intersection_point != null:
			intersections.append(intersection_point)
			lines_indices.append(i)
	
	return {"intersections": intersections, "lines_indices": lines_indices}

func is_point_inside(point : Vector2) -> bool:
	# todo: use the bounding box instead of 0 here
	var intersections = is_line_intersecting(FiniteLine2D.new(Vector2(0.0, point.y), point))
	return intersections.size() % 2 != 0

func rotate_around_center(angle : float) -> CustomPolygon2D:
	
	var new_local_lines : Array = []
	
	for local_line in local_lines:
		new_local_lines.append(local_line.rotate_around(Vector2.ZERO, angle))
		
	return CustomPolygon2D.new(center, new_local_lines)

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
	
	for local_line in local_lines:
		area += local_line.signed_area_to_the_x_axis()
		
	return abs(area)

func split(line : FiniteLine2D) -> Array:
	
	var intersections_detailed = is_line_intersecting_detailed(line)
	
	if intersections_detailed["intersections"].size() != 2:
		return [self]
	
	var local_lines_1 : Array = []
	var local_lines_2 : Array = []
	
	var start_of_first_split_line : FiniteLine2D = FiniteLine2D.new(
		local_lines[intersections_detailed["lines_indices"][0]].start, 
		intersections_detailed["intersections"][0] - center
	)
	
	var end_of_first_split_line : FiniteLine2D  = FiniteLine2D.new(
		intersections_detailed["intersections"][0] - center,
		local_lines[intersections_detailed["lines_indices"][0]].end
	)
	
	var start_of_second_split_line : FiniteLine2D  = FiniteLine2D.new(
		local_lines[intersections_detailed["lines_indices"][1]].start, 
		intersections_detailed["intersections"][1] - center
	)
	
	var end_of_first_second_line : FiniteLine2D  = FiniteLine2D.new(
		intersections_detailed["intersections"][1] - center,
		local_lines[intersections_detailed["lines_indices"][1]].end
	)

	var split_line : FiniteLine2D = FiniteLine2D.new(intersections_detailed["intersections"][0] - center, intersections_detailed["intersections"][1] - center)
	var reverse_split_line : FiniteLine2D = FiniteLine2D.new(intersections_detailed["intersections"][1] - center, intersections_detailed["intersections"][0] - center)
	
	for i in local_lines.size():
		
		if i < intersections_detailed["lines_indices"][0] or i > intersections_detailed["lines_indices"][1]:
			local_lines_1.append(local_lines[i])
			
		if i > intersections_detailed["lines_indices"][0] and i < intersections_detailed["lines_indices"][1]:
			local_lines_2.append(local_lines[i])
		
		if i == intersections_detailed["lines_indices"][0]:
			
			local_lines_1.append(start_of_first_split_line)
			local_lines_1.append(split_line)
			local_lines_1.append(end_of_first_second_line)
			
			local_lines_2.append(start_of_second_split_line)
			local_lines_2.append(reverse_split_line)
			local_lines_2.append(end_of_first_split_line)
	
	return [CustomPolygon2D.new(center, local_lines_1), CustomPolygon2D.new(center, local_lines_2)]

func get_longest_line_index() -> int:
	
	var index : int = 0
	var distance : float = local_lines[0].start.distance_to(local_lines[0].end)
	
	for i in local_lines.size():
		var new_distance = local_lines[i].start.distance_to(local_lines[i].end)
		if new_distance > distance:
			distance = new_distance
			index = i
		
	return index
		
