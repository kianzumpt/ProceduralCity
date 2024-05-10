class_name CarPlaceholder extends CharacterBody3D

@export var level : Level
@onready var camera : Camera3D = level.car_camera

@onready var offset : Vector3 = camera.global_position - global_position 

func _physics_process(_delta):
	velocity = Vector3.FORWARD * 100.0

	move_and_slide()
	
	camera.global_position = global_position + offset
	
	if global_position.z <= -5000.0:
		print("game over!")

func damage():
	print("dead")
	queue_free()
