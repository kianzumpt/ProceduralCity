extends Node

var settings_open : bool = true

func _ready():

	get_tree().paused = settings_open
	
	if settings_open:
		$pause_menu.show()
		$pause_menu.mouse_filter = 0
	else:
		$pause_menu.hide()
		$pause_menu.mouse_filter = 1

func _process(_delta):
	
	if Input.is_action_just_pressed("ui_cancel"):
		settings_open = !settings_open
	
	get_tree().paused = settings_open
	
	if settings_open:
		$pause_menu.show()
		$pause_menu.mouse_filter = 0
	else:
		$pause_menu.hide()
		$pause_menu.mouse_filter = 1

func _on_button_resume_pressed():
	settings_open = false

func _on_button_quit_pressed():
	get_tree().quit()
