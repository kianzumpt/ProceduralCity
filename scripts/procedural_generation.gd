extends Node2D

var center : Vector2 = Vector2(1280.0, 720.0) / 2.0
var radius : float = 90.0
var max_sides : int = 5
var min_sides : int = 13
var polygon_points : Array

func slope_of_line_given_two_points(p1 : Vector2, p2 : Vector2):
	
	if p1.x - p2.x == 0.0:
		return null
	
	return (p1.y - p2.y) / (p1.x - p2.x)

func finite_line_intersection_given_points(p1 : Vector2, p2 : Vector2, p3 : Vector2, p4 : Vector2):
	
	var relative_p2 = p2 - p1
	var relative_p3 = p3 - p1
	var relative_p4 = p4 - p1
	
	var angle = relative_p2.angle()
	
	
	var rotated_p2 = relative_p2.rotated(-angle)
	var rotated_p3 = relative_p3.rotated(-angle)
	var rotated_p4 = relative_p4.rotated(-angle)
	
	var result = finite_x_intercept_given_two_points(rotated_p2.x, rotated_p3, rotated_p4)
	
	if result == null:
		return null
		
	var intersection_point = p1 + Vector2(result, 0.0).rotated(angle)
	return intersection_point

func finite_x_intercept_given_two_points(l : float, p1 : Vector2, p2 : Vector2):
	var x = x_intercept_given_two_points(p1, p2)
	
	if l == 0.0:
		return null
		
	var within_y_range : bool = (0.0 <= p1.y and 0.0 >= p2.y) or (0.0 >= p1.y and 0.0 <= p2.y)
	
	if not within_y_range:
		return null
	
	var within_x_range : bool = x >= 0.0 and x <= l
	
	if not within_x_range:
		return null
	
	return x

func x_intercept_given_two_points(p1 : Vector2, p2 : Vector2):
	var m = slope_of_line_given_two_points(p1, p2)
	
	if m == 0.0:
		return null
		
	if m == null:
		return p1.x
	
	var c = p1.y - (m * p1.x)
	var x = -c / m
	
	return x

func generate_regular_polygon(polygon_center : Vector2, polygon_sides : int, polygon_radius : float) -> Array:
	
	var points : Array = []
	
	for i in polygon_sides:
		var point = polygon_center + (Vector2.UP.rotated(float(i) / float(polygon_sides) * 2.0 * PI) * polygon_radius)
		points.append(point)
		
	return points

func scale_polygon(polygon : Array, polygon_center : Vector2, scale : Vector2) -> Array:
	
	for i in polygon.size():
		var local_point = polygon[i] - polygon_center
		polygon[i] = Vector2(local_point.x * scale.x, local_point.y * scale.y) + polygon_center
		
	return polygon

func jiggle_polygon_points(polygon : Array, jiggle_radius : float) -> Array:
	
	for i in polygon.size():
		polygon[i] = polygon[i] + (Vector2.UP.rotated(randf() * 2.0 * PI) * (randf() * jiggle_radius))
		
	return polygon

func _ready():
	polygon_points = generate_regular_polygon(center, randi_range(min_sides, max_sides), radius)
	polygon_points = scale_polygon(polygon_points, center, Vector2(randf() + 1.0, randf() + 1.0))
	polygon_points = jiggle_polygon_points(polygon_points, 32.0)
	
func _draw():
	
	for i in polygon_points.size():
		
		var start_point = polygon_points[i]
		var end_point = polygon_points[0]
		if i + 1 < polygon_points.size():
			end_point = polygon_points[i + 1]
					
		draw_line(start_point, end_point, Color.WHITE, 4.0)
		
