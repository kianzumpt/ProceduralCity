class_name Jet extends RigidBody3D

@export var level : Level
@export var gravity : Vector3 = Vector3(0.0, -10.0, 0.0)
@export var max_thrust : float = 5000.0
@export var min_drag_coefficient : float = 0.1
@export var max_lift_coefficient : float = 2.0
@export var stall_angle_in_degrees : float = 30.0
@onready var stall_angle_in_radians : float = deg_to_rad(stall_angle_in_degrees)
@export var pitch_sensitivity : float = 100.0
@export var yaw_sensitivity : float = 100.0
@export var roll_sensitivity : float = 100.0

@onready var camera : Camera3D = level.jet_camera
@onready var camera_offset = camera.global_position - global_position

func apply_gravity(delta : float) -> void:
	apply_force(gravity * mass)

func apply_thrust(input : float) -> void:
	apply_force(quaternion * Vector3.FORWARD * max_thrust * input)
	
func apply_drag(dynamic_pressure : float) -> void:
	var drag_direction = -linear_velocity.normalized()
	apply_force(drag_direction * get_drag_coefficient(get_angle_of_attack_in_radians()) * dynamic_pressure)
	
func apply_lift(dynamic_pressure : float) -> void:
	var lift_direction = (-linear_velocity.normalized()).cross(basis.x).normalized()
	apply_force(lift_direction * get_lift_coefficient(get_angle_of_attack_in_radians()) * dynamic_pressure)
	
func get_dynamic_pressure() -> float:
	return 0.5 * linear_velocity.length_squared()

func get_angle_of_attack_in_radians() -> float:
	return (-linear_velocity.normalized()).signed_angle_to(basis.z, basis.x)
	
func get_drag_coefficient(angle_of_attack_in_radians : float) -> float:
	return (angle_of_attack_in_radians * angle_of_attack_in_radians) + min_drag_coefficient
	
func get_lift_coefficient(angle_of_attack_in_radians : float) -> float:
	return sin(angle_of_attack_in_radians * 0.5 * PI / stall_angle_in_radians) * max_lift_coefficient

func _physics_process(delta):
	
	var dynamic_pressure = get_dynamic_pressure()
	apply_lift(dynamic_pressure)
	apply_drag(dynamic_pressure)
	apply_gravity(delta)
	
	apply_thrust(Input.get_action_strength("right_trigger"))
	
	var yaw_input = -Input.get_axis("left_shoulder", "right_shoulder")
	var input : Vector2 = Input.get_vector("left_stick_left", "left_stick_right", "left_stick_down", "left_stick_up")
	
	var pitch_angle = -input.y * pitch_sensitivity
	var yaw_angle = yaw_input * yaw_sensitivity
	var roll_angle = -input.x * roll_sensitivity
	
	
	apply_torque(basis * Vector3(pitch_angle, yaw_angle, roll_angle) / delta)
	
	angular_velocity *= 0.95
	
	camera.quaternion = camera.quaternion.slerp(quaternion, 0.05)
	camera.global_position = global_position + (camera.basis * Vector3(0.0, 10.0, 50.0))
