extends Node2D

var polygons : Array

func _ready():
	
	var original_polygon = generate_city_outline(Vector2(1280.0, 720.0) / 2.0, 7, 17, 180.0)
	polygons = [original_polygon]
	
	for i in 15:
		var line = find_split_line(original_polygon)
		var new_polygons = []
		for polygon in polygons:
			var split_polygon : Array = polygon.split(line)
			if split_polygon.size() == 2.0:
				var area1 = split_polygon[0].get_area()
				var area2 = split_polygon[1].get_area()
				if area1 < 1000.0 or area2 < 1000.0:
					split_polygon = [polygon]
					
			new_polygons.append_array(split_polygon)
			
		polygons = new_polygons
	
	

func generate_city_outline(center : Vector2, min_sides : int, max_sides : int, radius : float) -> CustomPolygon2D:
	var polygon : CustomPolygon2D = CustomPolygon2D.new_regular_polygon(center, randi_range(min_sides, max_sides), radius)
	polygon.scale(Vector2(randf() + 1.0, randf() + 1.0))
	polygon.skew(64.0)
	
	return polygon

func find_split_line(polygon : CustomPolygon2D) -> FiniteLine2D:
	var line : FiniteLine2D
	var max_radius = sqrt((polygon.local_bounding_box.x *  polygon.local_bounding_box.x) + (polygon.local_bounding_box.y *  polygon.local_bounding_box.y))
	
	while true:
			var start_point : Vector2 = polygon.center + (Vector2.UP.rotated(randf() * 2.0 * PI) * max_radius)
			var end_point : Vector2 = polygon.center + (Vector2.UP.rotated(randf() * 2.0 * PI) * max_radius)
			line = FiniteLine2D.new(start_point, end_point)
			var intersections = polygon.is_line_intersecting(line)
			
			if intersections.size() == 2:
				break
				
	return line

func _draw():
	for polygon in polygons:
		
		
		var global_lines : Array = polygon.global_lines()
		var random_line_index : int = polygon.get_longest_line_index()
		var angle = global_lines[random_line_index].angle()
		var rotated_polygon : CustomPolygon2D = polygon.rotate_around_center(-angle)
		var rotated_global_bounding_box : Vector4 = rotated_polygon.get_global_bounding_box()
		
		var width : float = 30
		var blocks_y = floor(abs(rotated_global_bounding_box.x - rotated_global_bounding_box.z) / width)
		
		for i in range(1, blocks_y):
			
			var line = FiniteLine2D.new(
				Vector2(rotated_global_bounding_box.x + (i * width), rotated_global_bounding_box.y), 
				Vector2(rotated_global_bounding_box.x + (i * width), rotated_global_bounding_box.w), 
			).rotate_around(polygon.center, angle)
				
			line = polygon.clamp_line(line)
				
			if line:
				draw_line(line.start, line.end, Color.GRAY, 1.0, true)
		
		var height : float = 15
		var blocks_x = floor(abs(rotated_global_bounding_box.y - rotated_global_bounding_box.w) / height)
		
		for i in range(1, blocks_x):
			
			var line = FiniteLine2D.new(
				Vector2(rotated_global_bounding_box.x, rotated_global_bounding_box.y + (i * height)), 
				Vector2(rotated_global_bounding_box.z, rotated_global_bounding_box.y + (i * height)), 
			).rotate_around(polygon.center, angle)
			
			line = polygon.clamp_line(line)
			
			if line:
				draw_line(line.start, line.end, Color.GRAY, 1.0, true)
				
		for line in global_lines:
			draw_line(line.start, line.end, Color.WHITE, 1.0, true)
