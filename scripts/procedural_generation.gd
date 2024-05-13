extends Node2D

# regular polygon properties
var center : Vector2 = Vector2(1280.0, 720.0) / 2.0
var min_sides : int = 3
var max_sides : int = 5
var radius : float = 90.0

var polygon : CustomPolygon2D
var global_lines : Array

var random_line_index : int
var angle : float
var rotated_polygon : CustomPolygon2D
var rotated_global_bounding_box : Vector4

func _ready():
	
	polygon = CustomPolygon2D.new_regular_polygon(center, randi_range(min_sides, max_sides), radius)
	polygon.scale(Vector2(randf() + 1.0, randf() + 1.0))
	polygon.skew(32.0)
	global_lines = polygon.global_lines()
	
	random_line_index = randi_range(0, polygon.local_lines.size() - 1)
	angle = global_lines[random_line_index].angle()
	
	rotated_polygon = polygon.rotate_around_center(-angle)
	rotated_global_bounding_box = rotated_polygon.get_global_bounding_box()

func _draw():
	
	var blocks_y = floor(abs(rotated_global_bounding_box.x - rotated_global_bounding_box.z) / 50.0)
	
	for i in range(1, blocks_y):
		var line = FiniteLine2D.new(
			Vector2(rotated_global_bounding_box.x + (i * 50.0), rotated_global_bounding_box.y), 
			Vector2(rotated_global_bounding_box.x + (i * 50.0), rotated_global_bounding_box.w), 
		).rotate_around(polygon.center, angle)
			
		line = polygon.clamp_line(line)
			
		if line:
			draw_line(line.start, line.end, Color.WHITE, 2.0, true)
			
	var blocks_x = floor(abs(rotated_global_bounding_box.y - rotated_global_bounding_box.w) / 25.0)
	
	for i in range(1, blocks_x):
		var line = FiniteLine2D.new(
			Vector2(rotated_global_bounding_box.x, rotated_global_bounding_box.y + (i * 25.0)), 
			Vector2(rotated_global_bounding_box.z, rotated_global_bounding_box.y + (i * 25.0)), 
		).rotate_around(polygon.center, angle)
			
		line = polygon.clamp_line(line)
			
		if line:
			draw_line(line.start, line.end, Color.WHITE, 2.0, true)
			
	for i in global_lines.size():
		if i == random_line_index:
			draw_line(global_lines[i].start, global_lines[i].end, Color.RED, 2.0, true)
		else:
			draw_line(global_lines[i].start, global_lines[i].end, Color.WHITE, 2.0, true)
