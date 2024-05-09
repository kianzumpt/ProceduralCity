extends RigidBody3D

@export var camera : Camera3D

var pitch_angle : float = 0.0
var roll_angle : float = 0.0

@onready var camera_offset = camera.global_position - global_position

var gravity : Vector3 = Vector3(0.0, -9.8, 0.0)
var max_thrust : float = 5000.0

var max_lift_coefficient : float = 2.0
var min_drag_coefficient : float = 0.1
var stall_angle_in_radians : float = deg_to_rad(30.0)

func apply_gravity() -> void:
	apply_force(mass * gravity)

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
	return (10.0 * angle_of_attack_in_radians * angle_of_attack_in_radians) + min_drag_coefficient
	
func get_lift_coefficient(angle_of_attack_in_radians : float) -> float:
	return sin(angle_of_attack_in_radians * 0.5 * PI / stall_angle_in_radians) * max_lift_coefficient

func _physics_process(delta):
	
	var dynamic_pressure = get_dynamic_pressure()
	apply_lift(dynamic_pressure)
	apply_drag(dynamic_pressure)
	apply_gravity()
	
	
	if Input.is_action_pressed("ui_accept"):
		apply_thrust(1.0)
	
	var input : Vector2 = Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	roll_angle = -input.x * 10000.0
	pitch_angle = -input.y * 10000.0
	
	apply_torque(basis * Vector3(pitch_angle, 0.0, roll_angle))
	
	angular_velocity *= 0.9
	
	camera.quaternion = camera.quaternion.slerp(quaternion, 0.05)
	camera.global_position = global_position + (camera.basis * Vector3(0.0, 10.0, 50.0))
