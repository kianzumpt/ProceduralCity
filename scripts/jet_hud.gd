extends SubViewportContainer

@export var level : Level
@onready var jet : Node3D = level.get_jet()
@onready var car : Node3D = level.get_car()

var horizontal_dist : Vector3

func _physics_process(_delta):

	horizontal_dist = jet.global_position.slide(Vector3.UP) - car.global_position.slide(Vector3.UP)
	horizontal_dist = horizontal_dist.rotated(Vector3.UP, jet.basis.z.slide(Vector3.UP).signed_angle_to(Vector3.FORWARD, Vector3.UP))
	queue_redraw()

func _draw():
	
	var height = 1000.0
	var steps = height / 100.0
	var steps_int : int = floori(steps)
	
	for i in steps_int:
		var value : float = (1 - ((i + 1) / steps))
		draw_circle(Vector2(320, 180), value * 128.0, Color(0.0, value, 0.0))
	
	var distance : float = min(horizontal_dist.length() / height, 1.0) * 128.0
	var offset = Vector2(horizontal_dist.x, horizontal_dist.z).normalized() * distance
	
	if distance < 128.0:
		draw_circle(Vector2(320, 180) + offset, 4.0, Color.GREEN)
