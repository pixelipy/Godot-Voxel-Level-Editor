tool
extends EditorPlugin

var object_window
var mouse_left_pressed = false
var shift_pressed = false

func _enter_tree():
	object_window = preload("res://Addons/Voxel Level Editor/object_window.tscn").instance()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UL,object_window)
	add_custom_type("block_button","Button",preload("res://Addons/Voxel Level Editor/UI/block_button.gd"),preload("res://Addons/Voxel Level Editor/UI/button_icon.png"))
	add_custom_type("object_button", "Button", preload("res://Addons/Voxel Level Editor/UI/object_button.gd"),preload("res://Addons/Voxel Level Editor/UI/object_button_icon.png"))
	pass

func _exit_tree():
	remove_control_from_docks(object_window)
	object_window.free()
	remove_custom_type("block_button")
	remove_custom_type("object_button")
	pass

func handles(object):
	return true

func forward_spatial_gui_input(camera, event):
	if event is InputEventMouseMotion:
		object_window.set_mouse_position(camera,event.position)
	elif event is InputEventMouseButton:
		if event.button_mask == BUTTON_LEFT and event.pressed:
			mouse_left_pressed = true
		else:
			mouse_left_pressed = false
	elif event is InputEventKey:
		if event.scancode == KEY_X and event.pressed:
			object_window.set_layer(1)
		elif event.scancode == KEY_Z and event.pressed:
			object_window.set_layer(-1)
		elif event.scancode == KEY_SHIFT and event.pressed:
			shift_pressed = true
		else:
			shift_pressed = false
		
		if event.scancode == KEY_COMMA and event.pressed:
			object_window.rotate_object(PI/2)
		elif event.scancode == KEY_PERIOD and event.pressed:
			object_window.rotate_object(-PI/2)
	pass

func _physics_process(delta):
	if mouse_left_pressed and !shift_pressed:
		object_window.left_click()
	if mouse_left_pressed and shift_pressed:
		object_window.right_click()
	pass
