extends CharacterBody3D
const SPEED = 5.0

var input_acceleration : Vector3 = Vector3.ZERO
var real_acceleration : Vector3 = Vector3.ZERO
var previous_velocity : Vector3 = Vector3.ZERO
var time = 0.0

func _physics_process(delta):
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	input_acceleration = direction * delta * 1000.0
	velocity += input_acceleration * delta
	
	velocity = velocity.normalized() * (velocity.length() * 0.975)
	
	move_and_slide()
	
	real_acceleration = velocity - previous_velocity
	
	# animation
	print(velocity.length())
	
	if(velocity.length() > 0): 
		var velocity_direction = velocity.normalized()
		var look_direction = Quaternion(Vector3.FORWARD, velocity_direction).normalized()
		var look_direction2 = Quaternion(Vector3.UP, (real_acceleration + Vector3.UP).normalized()).normalized()
		$mesh.quaternion = $mesh.quaternion.slerp(look_direction2 * look_direction, 0.1)
		
	previous_velocity = velocity
	time += delta
