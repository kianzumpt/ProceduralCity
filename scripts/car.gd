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
	
	var max_turn_angle_per_second = deg_to_rad(90.0)
	var applied_torque_impluse = Vector3.UP * max_turn_angle_per_second * input_steer
	
	var applied_impluse = Quaternion.from_euler(applied_torque_impluse) * basis.z * input_throttle * 10.0 * delta
	
	var local_velocity = global_transform.basis.inverse() * linear_velocity
	var lateral_linear_velocity = global_transform.basis * Vector3(local_velocity.x, 0.0, 0.0)
	
	if Input.is_action_pressed("ui_accept"):
		drift = lerp(drift, 0.01, 0.5) 
	else:
		drift = lerp(drift, 1.0, 0.1)
	
	apply_impulse(-(lateral_linear_velocity * drift) + applied_impluse)
	apply_torque_impulse(-angular_velocity + applied_torque_impluse)
	
	# move camera
	var look_target = global_position + (-basis.z * 5.0).slide(Vector3.UP)
	camera.look_at(look_target)
	camera.global_position = lerp(camera.global_position, global_position + (quaternion * Vector3(0.0, 3.0, 10.0)), 0.05)

func damage():
	print("dead")
	queue_free()
