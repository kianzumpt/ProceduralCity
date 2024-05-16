extends RigidBody3D

@export var camera : Camera3D

var input_throttle : float = 0.0
var input_steer : float = 0.0

var linear_drag_coeffiecint : float = 0.5

func _process(delta):
	input_throttle = Input.get_axis("face_button_bottom", "face_button_left")
	input_steer = -Input.get_axis("left_stick_left", "left_stick_right")

func _physics_process(delta):
	
	apply_force(Vector3.DOWN * 10.0)
	
	apply_force(basis.z * input_throttle * 15.0)
	var local_velocity = to_local(linear_velocity + global_position)
	apply_torque(basis.y * input_steer * 100.0)

	
	apply_impulse((to_global(Vector3.LEFT * local_velocity.x) - global_position) * 1.0)
	apply_torque_impulse(-Vector3.UP * angular_velocity.y * 1.0)
	
	var look_target = global_position + (-basis.z * 5.0).slide(Vector3.UP)
	camera.look_at(look_target)
	
	camera.global_position = lerp(camera.global_position, global_position + (quaternion * Vector3(0.0, 3.0, 10.0)), 0.05)
