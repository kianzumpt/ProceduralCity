extends Node2D

var center : Vector2 = Vector2(1280.0, 720.0) / 2.0
var radius : float = 90.0
var max_sides : int = 13
var min_sides : int = 7
var time : float = 0.0
var polygon : CustomPolygon2D

func _process(delta):
	queue_redraw()
	time += delta
	
func _ready():
	polygon = CustomPolygon2D.new_regular_polygon(center, randi_range(min_sides, max_sides), radius)
	polygon.scale(Vector2(randf() + 1.0, randf() + 1.0))
	polygon.skew(32.0)

func _draw():
	
	for line in polygon.local_lines:
		draw_line(line.start + polygon.center, line.end + polygon.center, Color.WHITE, 4.0, true)
		
	var line = FiniteLine2D.new(
		center + Vector2(sin(time) * radius * 2.0, cos(time) * radius * 2.0), 
		center + Vector2(cos(time) * radius * 2.0, sin(time) * radius * 2.0),
	)
	
	line = polygon.clamp_line(line)
	
	if line:
		draw_line(line.start, line.end, Color.WHITE, 4.0, true)
		draw_circle(line.start, 8.0, Color.WHITE)
		draw_circle(line.end, 8.0, Color.WHITE)
