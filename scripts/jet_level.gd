class_name Level extends Node3D

@export var jet_camera : Camera3D
@export var car_camera : Camera3D

func get_jet():
	return $jet
	
func get_car():
	return $car_placeholder
