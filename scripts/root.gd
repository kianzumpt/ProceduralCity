extends Node

var settings_open : bool = true

func _ready():
	
	var screen_half_width : float = get_viewport().get_visible_rect().size.x * 0.5
	var screen_height : float = get_viewport().get_visible_rect().size.y
	
	$left_sub_viewport_container.size = Vector2(screen_half_width, screen_height)
	$left_sub_viewport_container.position = Vector2(0, 0)
	$left_sub_viewport_container/left_sub_viewport.size = Vector2(screen_half_width, screen_height)
	
	$right_sub_viewport_container.size = Vector2(screen_half_width, screen_height)
	$right_sub_viewport_container.position = Vector2(screen_half_width, 0)
	$right_sub_viewport_container/right_sub_viewport.size = Vector2(screen_half_width, screen_height)
	
	get_tree().paused = settings_open
	
	if settings_open:
		$pause_menu.show()
		$pause_menu.mouse_filter = 0
	else:
		$pause_menu.hide()
		$pause_menu.mouse_filter = 1

func _process(_delta):
	
	$MarginContainer/fps_counter.text = str(Engine.get_frames_per_second()) + " FPS"
	
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
