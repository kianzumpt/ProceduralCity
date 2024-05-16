extends VehicleBody3D

var steer: float = 0.0
var max_torque = 100

var max_rpm = 500


func _physics_process(delta):
	steer = lerp(steer, Input.get_axis("right_D", "left_A") * 0.4, 5.1 * delta)
	steering = steer
	var acceleration = Input.get_axis("back_S", "forward_W")
	var rpm = abs($back_left_wheel.get_rpm())
	$back_left_wheel.engine_force = acceleration * max_torque * (1 - rpm / max_rpm)
	rpm = abs($back_right_wheel.get_rpm())
	$back_right_wheel.engine_force = acceleration * max_torque * (1 - rpm / max_rpm)
	
