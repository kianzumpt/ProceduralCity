extends SubViewportContainer

@export var level : Level
@onready var jet : Node3D = level.get_jet()
@onready var car : Node3D = level.get_car()

var horizontal_dist : Vector3
var angle : float

var car_position : Vector3 = Vector3.ZERO
var show_radar : bool = false

func _process(_delta):
	if Input.is_action_just_released("face_button_left"):
		show_radar = !show_radar

func _physics_process(_delta):
	
	if car != null:
		car_position = car.global_position

	horizontal_dist = jet.global_position.slide(Vector3.UP) - car_position.slide(Vector3.UP)
	angle = level.jet_camera.basis.z.slide(Vector3.UP).signed_angle_to(Vector3.FORWARD, Vector3.UP)
	horizontal_dist = horizontal_dist.rotated(Vector3.UP, angle)
	queue_redraw()

func _draw():
	
	if show_radar:
		var height = jet.global_position.y
		var steps = height / 300.0
		var steps_int : int = ceili(steps)
		
		var radar_center : Vector2 = Vector2(320, 180)
		var radar_radius : float = 128.0
		
		for i in range(steps_int, 0, -1):
			var value = min((i / steps) * radar_radius, radar_radius)
			draw_circle(radar_center, value, Color.GREEN)
			draw_circle(radar_center, (value) - 1.0, Color.BLACK)
		
		var new_angle = Vector3.FORWARD.signed_angle_to(jet.basis.z.slide(Vector3.UP), Vector3.UP)
		
		var vertical_start_position = radar_center + (Vector2.UP.rotated(new_angle) * radar_radius)
		var vertical_end_position = radar_center + (Vector2.DOWN.rotated(new_angle) * radar_radius)
		
		draw_line(vertical_start_position, vertical_end_position, Color.GREEN)
		
		var horizontal_start_position = radar_center + (Vector2.LEFT.rotated(new_angle) * radar_radius)
		var horizontal_end_position = radar_center + (Vector2.RIGHT.rotated(new_angle) * radar_radius)
		
		draw_line(horizontal_start_position, horizontal_end_position, Color.GREEN)
		
		draw_line(radar_center + (Vector2.DOWN * 20.0), radar_center + (Vector2.UP * 20.0), Color.WHITE, 6.0)
		draw_line(radar_center + (Vector2.LEFT * 15.0) + (Vector2.DOWN * 10.0), radar_center + (Vector2.RIGHT * 15.0) + (Vector2.DOWN * 10.0), Color.WHITE, 20.0)

		var distance : float = min(horizontal_dist.length() / height, 1.0) * radar_radius
		var car_offset = Vector2(horizontal_dist.x, horizontal_dist.z).normalized() * distance
		
		if distance < radar_radius:
			draw_circle(radar_center + car_offset, 4.0, Color.WHITE)
