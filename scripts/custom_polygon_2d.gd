class_name CustomPolygon2D

var center : Vector2
var local_lines : Array

func _init(new_center : Vector2, new_local_lines : Array):
	center = new_center
	local_lines = new_local_lines
	
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

func local_line_to_global_line(line : FiniteLine2D) -> FiniteLine2D:
	return FiniteLine2D.new(line.start + center, line.end + center)

func global_lines() -> Array:
	var global_lines : Array = []
	
	for local_line in local_lines:
		global_lines.append(local_line_to_global_line(local_line))
	
	return global_lines

func is_line_intersecting(line : FiniteLine2D) -> Array:
	
	var intersections : Array = []
	
	for global_line in global_lines():
		var intersection_point = line.is_intersecting(global_line)
		if intersection_point != null:
			intersections.append(intersection_point)
	
	return intersections

func is_point_inside(point : Vector2) -> bool:
	var intersections = is_line_intersecting(FiniteLine2D.new(Vector2(0.0, point.y), point))
	print(intersections.size())
	return intersections.size() % 2 != 0

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
