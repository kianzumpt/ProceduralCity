class_name Bullet extends Node3D

@export var life_time : float = 0.5
@export var direction : Vector3 = Vector3.FORWARD
@export var start_position : Vector3 = Vector3.ZERO

func _ready():
	var space_state = get_world_3d().direct_space_state
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start_position, start_position + (direction * 1000.0))
	var result = space_state.intersect_ray(query)
	
	if result:
		
		if result.collider is Car:
			result.collider.damage()
		
		$mesh_instance.global_position = result.position
		$mesh_instance.show()
	else:
		queue_free()

func _physics_process(delta):
	life_time -= delta
	if life_time <= 0.0:
		queue_free()
