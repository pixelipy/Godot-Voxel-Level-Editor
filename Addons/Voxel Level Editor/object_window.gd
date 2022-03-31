tool
extends Control


var block_data = preload("res://Addons/Voxel Level Editor/block_types.gd").new()


var collision_plane_scene = preload("res://Addons/Voxel Level Editor/helpers/collision_plane.tscn")
var collision_plane_instance = null

var cursor_scene = preload("res://Addons/Voxel Level Editor/Cursor/block_cursor.tscn")
var object_cursor_scene = null
var cursor_instance = null

var mouse_position = Vector2()
var position_3D = Vector3()
var layer = 0
var active_block = -1
var active_object = -1
var active_group = -1
var cell = Vector3()
var changed_cell = false

enum object_types {block, object}
var cur_object_type = object_types.block
var can_rotate_object = false
var cur_obj_rotation = 0
var randomize_blocks = false
var brush_size : int = 1
var brush_height : int = 1

onready var block_contents = $ScrollContainer/VBoxContainer/Blocks/VBoxContainer/Block_Contents
onready var object_contents = $ScrollContainer/VBoxContainer/Objects/VBoxContainer/Object_Contents

onready var active_block_label = $ScrollContainer/VBoxContainer/debug/VBoxContainer/Active_Block
onready var active_object_label = $ScrollContainer/VBoxContainer/debug/VBoxContainer/Active_object
onready var snapping_x = $ScrollContainer/VBoxContainer/Objects/VBoxContainer/snapping_x
onready var snapping_y = $ScrollContainer/VBoxContainer/Objects/VBoxContainer/snapping_y
onready var deactivate_button = $ScrollContainer/VBoxContainer/deactivate
onready var randomize_block_button =$ScrollContainer/VBoxContainer/options/VBoxContainer/randomize_blocks
onready var brush_slider = $ScrollContainer/VBoxContainer/options/VBoxContainer/brush_size

onready var brush_size_label = $ScrollContainer/VBoxContainer/options/VBoxContainer/brush_size_label
onready var brush_height_slider = $ScrollContainer/VBoxContainer/options/VBoxContainer/brush_height
onready var brush_height_label = $ScrollContainer/VBoxContainer/options/VBoxContainer/brush_height_label

onready var cursor_parent = $cursors

var cur_snapping = Vector2(1,1)
var chunk_size = Vector3(8,8,5)

func _ready():
	collision_plane_instance = collision_plane_scene.instance()
	cursor_instance = cursor_scene.instance()
	add_child(collision_plane_instance)
	add_child(cursor_instance)
	
	
	load_buttons()
	
	snapping_x.select(1)
	snapping_y.select(1)
	snapping_x.connect("item_selected",self,"change_snapping_vector_x")
	snapping_y.connect("item_selected",self,"change_snapping_vector_y")
	deactivate_button.connect("pressed",self,"deactivate_plugin")
	randomize_block_button.connect("pressed",self,"activate_randomization")
	brush_slider.connect("value_changed", self, "change_brush_size")
	brush_height_slider.connect("value_changed", self, "change_brush_height")
	
	set_layer(5)
	pass # Replace with function body.


func load_buttons():
	for child in block_contents.get_children():
		child.free()
	for i in block_data.blocks:
		var b = block_button.new()
		b.text = block_data.blocks[i]["block_name"]
		b.name = block_data.blocks[i]["block_name"]
		b.block_type = block_data.blocks[i]["index"]
		b.block_name = i
		
		block_contents.add_child(b)
		
		b.connect("pressed",self,"update_active_block", [b.block_name])
		pass
	
	for child in object_contents.get_children():
		child.free()
	for i in block_data.objects:
		var b = object_button.new()
		b.text = block_data.objects[i]["block_name"]
		b.name = block_data.objects[i]["block_name"]
		b.object_type = block_data.objects[i]["index"]
		b.object_name = i
		
		object_contents.add_child(b)
		b.connect("pressed",self,"update_active_object", [b.object_name])
		pass
	pass

func update_active_block(new_block_name : String):
	active_object = -1
	active_object_label.set_text(str("Active object: NONE"))
	active_block = block_data.blocks[new_block_name]["index"]
	active_group = block_data.blocks[new_block_name]["group"]
	active_block_label.set_text(str("Active block: ", new_block_name))
	
	cur_object_type = object_types.block
	change_cursor(Vector2(1,1))
	pass

func update_active_object(new_object_name : String):
	active_block = -1
	active_block_label.set_text(str("Active block: NONE"))
	active_object = block_data.objects[new_object_name]["index"]
	
	active_object_label.set_text(str("Active object: ",new_object_name))
	can_rotate_object = block_data.objects[new_object_name]["rotateable"]
	cur_object_type = object_types.object
	
	change_cursor(cur_snapping)
	pass

func set_mouse_position(camera : Camera,pos):
	mouse_position = pos
	var intersection = raycast_from_mouse(mouse_position,1024, camera)
	
	if !intersection.empty():
		position_3D = intersection["position"]
		if cur_object_type == object_types.block:
			var current_cell = Vector3(floor(position_3D.x)+0.5,layer,floor(position_3D.z )+0.5)
			cursor_instance.translation = current_cell + Vector3(0,0.55,0)
			cursor_parent.translation = current_cell + Vector3(0,0.55,0)
			var new_cell = Vector3(sign(current_cell.x)*ceil(abs(current_cell.x)),layer,sign(current_cell.z)*ceil(abs(current_cell.z)))
			if new_cell != cell:
				changed_cell = true
			cell = new_cell
		elif cur_object_type == object_types.object:
			var current_cell = Vector3(position_3D.x+0.5*cur_snapping.x,layer,position_3D.z+0.5*cur_snapping.y).snapped(Vector3(cur_snapping.x,layer,cur_snapping.y))
			cursor_instance.translation = current_cell+ Vector3(-cursor_instance.scale.x/2,0.55,-cursor_instance.scale.z/2)
			cursor_instance.rotation.y = cur_obj_rotation
			cursor_parent.translation = current_cell+ Vector3(-cursor_parent.scale.x/2,0.55,-cursor_parent.scale.z/2)
			
			
			var new_cell = current_cell-Vector3(0,0,1)
			if new_cell != cell:
				changed_cell = true
			cell = new_cell
			pass
	pass


func raycast_from_mouse(mouse_position,collision_mask,camera : Camera):
	var ray_start = camera.project_ray_origin(mouse_position)
	var ray_end = ray_start + camera.project_ray_normal(mouse_position)*1000
	var space_state =  get_viewport().world.direct_space_state
	return space_state.intersect_ray(ray_start,ray_end, [], collision_mask)
	pass

func rotate_object(ang : float):
	if cur_object_type == object_types.object:
		cur_obj_rotation += ang
		cursor_instance.rotation.y = cur_obj_rotation
#place block or object
func left_click():
	if active_block == -1 and active_object == -1:
		return
	if !changed_cell:
		return
	changed_cell = false
	var root = get_tree().get_edited_scene_root()
	
	if active_block != -1:
		if root.has_method("place_block"):
			var position_array = []
			var block_array = []
			var block = active_block
			
			var min_brush = -(brush_size-1)/2
			var max_brush = (brush_size+1)/2
			
			for i in range(min_brush,max_brush):
				for j in range(min_brush,max_brush):
					for k in range(0,brush_height):
						if randomize_blocks:
							var array = block_data.groups[active_group]
							var rand_value = array[randi() % array.size()]
							block = rand_value
						block_array.append(block)
						position_array.append(cell + Vector3(cur_snapping.x*i,k,cur_snapping.y*j))
			root.call("place_block",position_array,block_array)

	elif active_object != -1:
		if root.has_method("place_object"):
			var cur_rot = 0
			if can_rotate_object:
				cur_rot = cur_obj_rotation
			
			var min_brush = -(brush_size-1)/2
			var max_brush = (brush_size+1)/2
			for i in range(min_brush,max_brush):
				for j in range(min_brush,max_brush):
					for k in range(0,brush_height):
						root.call("place_object",cell+ Vector3(cur_snapping.x*i,k,cur_snapping.y*j),active_object,cur_rot)
	pass

#delete block or object
func right_click():
	var root = get_tree().get_edited_scene_root()
	if cur_object_type == object_types.block:
		var position_array = []
		if root.has_method("erase_block"):
			var min_brush = -(brush_size-1)/2
			var max_brush = (brush_size+1)/2
			for i in range(min_brush,max_brush):
				for j in range(min_brush,max_brush):
					for k in range(0,brush_height):
						position_array.append(cell + Vector3(cur_snapping.x*i,k,cur_snapping.y*j))
			root.call("erase_block",position_array)
	elif cur_object_type == object_types.object:
		if root.has_method("erase_object"):
			var min_brush = -(brush_size-1)/2
			var max_brush = (brush_size+1)/2
			for i in range(min_brush,max_brush):
				for j in range(min_brush,max_brush):
					for k in range(0,brush_height):
						root.call("erase_object",cell+ Vector3(cur_snapping.x*i,k,cur_snapping.y*j))
	pass

func set_layer(increment):
	layer += increment
	collision_plane_instance.translation.y = layer
	
	pass

func change_snapping_vector_x(id: int):
	var new_value = float(snapping_x.get_item_text(id))
	cur_snapping = Vector2(new_value,cur_snapping.y)
	if cur_object_type != object_types.block:
		change_cursor(cur_snapping)
	
	pass

func change_snapping_vector_y(id: int):
	var new_value = float(snapping_y.get_item_text(id))
	cur_snapping = Vector2(cur_snapping.x,new_value)
	if cur_object_type != object_types.block:
		change_cursor(cur_snapping)
	pass

func change_cursor(snapping : Vector2):
	cursor_instance.scale.x = snapping.x+0.05
	cursor_instance.scale.z = snapping.y+0.05
	
	cursor_parent.scale.x = snapping.x+0.05
	cursor_parent.scale.z = snapping.y+0.05
	
	pass

func set_drag_preview(control : Control):
	pass

func deactivate_plugin():
	active_block = -1
	active_block_label.set_text(str("Active block: NONE"))
	active_object = -1
	active_object_label.set_text(str("Active object: NONE"))

func activate_randomization():
	randomize_blocks = !randomize_blocks
	
	if randomize_blocks:
		randomize_block_button.text = str("Randomize Blocks = on")
	else:
		randomize_block_button.text = str("Randomize Blocks = off")
	
	pass

func change_brush_size(new_brush_value):
	brush_size = new_brush_value+1
	brush_size_label.set_text(str("Brush Size = ",brush_size))
	update_brush()


func change_brush_height(new_height):
	brush_height = new_height
	brush_height_label.set_text(str("Brush Height = ",brush_height))
	update_brush()

func update_brush():
	var min_brush = -(brush_size-1)/2
	var max_brush = (brush_size+1)/2
	
	for i in cursor_parent.get_children():
		i.queue_free()
	
	for i in range(min_brush,max_brush):
		for j in range(min_brush,max_brush):
			for k in range(0,brush_height):
				if (i == 0 and j == 0 and k == 0):
					continue
				var new_cursor = cursor_scene.instance()
				cursor_parent.add_child(new_cursor)
				new_cursor.translation = Vector3(i,k,j)
	pass

