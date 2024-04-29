extends CharacterBody3D

@export var acceleration = 20.0
@export var drag = 0.05

var time : float = 0.0
var fixed_time : float = 0.0

var input_acceleration : Vector3 = Vector3.ZERO
var real_acceleration : Vector3 = Vector3.ZERO
var previous_velocity : Vector3 = Vector3.ZERO

@onready var target_position : Variant = null
@export var left_foot : Node3D
var move_input : Vector2 = Vector2.ZERO
var last_position : Vector3 = Vector3.ZERO
var moved_dist : float = 0.0
var previous_position : Vector3 = Vector3.ZERO

func _process(delta):
	
	# poll user input
	move_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# update all the player animations
	update_player_animation()
	
	# increase time
	time += delta

func _physics_process(delta : float) -> void:
	
	# move the player on every physics update
	move_player(delta)
	
	# calcuate the acceleration that is actually experienced
	real_acceleration = get_real_velocity() - previous_velocity
	
	# save current velocity for next frame
	previous_velocity = get_real_velocity()
	
	# increase fixed time
	fixed_time += delta
	
	
func update_player_animation() -> void:
	
	if(get_real_velocity().length() > 0): 
		var velocity_direction = get_real_velocity().normalized()
		var look_direction = Quaternion(Vector3.FORWARD, velocity_direction).normalized()
		var look_direction2 = Quaternion(Vector3.UP, (real_acceleration + Vector3.UP).normalized()).normalized()
		$mesh/body.quaternion = $mesh/body.quaternion.slerp(look_direction2 * look_direction, 0.1)
	
	moved_dist += (global_position.slide(Vector3.UP) - previous_position).length()
	previous_position = global_position.slide(Vector3.UP)
	
	var scale_factor = 5.0
	var progress = min(fmod(time * scale_factor, 2.0), 1.0)
	var left_foot_height = max(0.0, sin(time * PI * scale_factor)) * 0.5
	
	if progress < 1.0:
		if target_position == null:
			target_position = $mesh/body/left_hip.global_position.slide(Vector3.UP) + (velocity.slide(Vector3.UP) / scale_factor)
		left_foot.global_position = Vector3(lerp(last_position.x, target_position.x, progress), left_foot_height, lerp(last_position.z, target_position.z, progress))
	else:
		if target_position != null:
			left_foot.global_position = target_position
			last_position = target_position
			target_position = null
	
func move_player(delta : float) -> void:
	
	# get direction to move on the xz plane
	var horizontal_movement_direction = Vector3(move_input.x, 0, move_input.y).normalized()
	
	# calculate the acceleration to apply
	input_acceleration = horizontal_movement_direction * acceleration
	
	# apply acceleration
	velocity += input_acceleration * delta
	
	# add simplified drag
	velocity = velocity.normalized() * (velocity.length() * (1.0 - drag))
	
	# move the player
	move_and_slide()
