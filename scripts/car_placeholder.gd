class_name CarPlaceholder extends CharacterBody3D

func _physics_process(_delta):
	velocity = Vector3.FORWARD * 100.0

	move_and_slide()
	
	if global_position.z <= -5000.0:
		print("game over!")

func damage():
	print("dead")
	queue_free()
