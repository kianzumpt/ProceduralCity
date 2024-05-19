class_name Car extends RigidBody3D

@export var level : Level
@onready var camera : Camera3D = level.car_camera

var input_throttle : float = 0.0

var input_steer : float = 0.0

var linear_drag_coeffiecint : float = 0.5

var drift : float = 1.0

func _process(_delta):
	input_throttle = Input.get_axis("ui_up", "ui_down")
	input_steer = Input.get_axis("ui_right", "ui_left")

func _physics_process(delta):
	
	var steer_angle = deg_to_rad(input_steer * 5.0)
	var local_velocity = global_transform.basis.inverse() * linear_velocity
	
	var real_angle : float = 0.0
	var linear_distance : float = input_throttle * 10.0 * delta
	
	if sin(steer_angle) != 0.0:
		var turning_circle_radius : float = 2.5 / sin(steer_angle)
		real_angle = -sign(steer_angle) * (local_velocity.z + linear_distance) / turning_circle_radius
		
		var center_front_axel : Vector3 = global_position + (basis.z * (2.5 / 2.0))
		var turning_circle_center : Vector3 = center_front_axel - (basis.x * turning_circle_radius)
		var new_center_front_axel : Vector3  = (center_front_axel - turning_circle_center).rotated(Vector3.UP, -real_angle) + turning_circle_center
		linear_distance = turning_circle_center.distance_to(new_center_front_axel)
	
	var applied_impluse = Quaternion.from_euler(Vector3.UP * real_angle) * basis.z * linear_distance

	var applied_torque_impluse = Vector3.UP * real_angle
	apply_torque_impulse(-angular_velocity + applied_torque_impluse)
	
	var lateral_linear_velocity = global_transform.basis * Vector3(local_velocity.x, 0.0, 0.0)
	apply_impulse(-lateral_linear_velocity + applied_impluse)
	
	$front_left_wheel.rotation = Vector3(0.0, steer_angle, deg_to_rad(90.0))
	$front_right_wheel.rotation = Vector3(0.0, steer_angle, deg_to_rad(90.0))
	
	# move camera
	var look_target = global_position + (-basis.z * 5.0).slide(Vector3.UP)
	camera.look_at(look_target)
	camera.global_position = lerp(camera.global_position, global_position + (quaternion * Vector3(0.0, 3.0, 10.0)), 0.05)

func damage():
	print("dead")
	queue_free()
