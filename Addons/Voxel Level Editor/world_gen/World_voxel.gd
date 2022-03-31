extends Spatial
tool
class_name voxel_world

var cur_chunk = Vector3(0,0,0)
var chunk_scene = preload("res://Addons/Voxel Level Editor/world_gen/Chunk.tscn")
var chunks = []
var cur_player_chunk = Vector3(0,0,0)
var first_loading = true
var player_position = Vector3.ZERO
var fences :Array = []
export (String) var level_name = ""

#this controls the render distance!!!!
var render_distance = Vector2(5,5)
var z_render_offset = 0

var loaded_chunks = []
var loaded_chunk_instances = []

onready var chunk_node = $Chunks
onready var player = $Player

var chunk_size = Vector2(16,16)
var can_generate_chunks = false
var first_thead_finished = false
var world_generated = false
######## THIS SCRIPT WILL PLACE AND ADD BLOCKS AND OBJECTS
######## IT WILL ALSO UPDATE THE BLOCKS DICTIONARY IN EACH CHUNK
####### AND CREATE/DELETE CHUNKS ON THE FLY

var thread


func _ready():
	for i in get_children():
		i.set_meta("_edit_lock_", true)
	chunk_size = chunk_node.chunk_size
	if !Engine.editor_hint:
		$WorldEnvironment.environment.dof_blur_far_enabled = true
		for i in chunk_node.get_children():
			i.queue_free()
			can_generate_chunks = true
#		load_chunks_around_player(null)
		thread = Thread.new()
		thread.start(self,"load_chunks_around_player",null)
	
	else:
		$WorldEnvironment.environment.dof_blur_far_enabled = false
	

#place a block of type t, at position pos (Vector 3)
#all the blocks are put, then update everything at the end
func place_block(array_of_pos : Array,block_array : Array):
	var chunks_to_update = []
	for i in array_of_pos.size():
		var pos = array_of_pos[i]
		var t = block_array[i]
		#makes some fancy positioning
		var position_x  = pos.x
		if pos.x > 0:
			position_x = pos.x-1
		
		var position_z  = pos.z
		if pos.z > 0:
			position_z = pos.z-1
		
		#determines the chunk a position belongs
		var pos_vec = Vector3(position_x,pos.y, position_z)
		var cur_chunk = get_chunk_coordinate(pos_vec)
		var chunk_key = [cur_chunk.x,cur_chunk.y]
		var chunk_name = str(cur_chunk.x,"_",cur_chunk.y)
		var chunk_to_edit = get_node_or_null(str("Chunks/"+chunk_name))
		
		#if chunk does not exists, then create chunk
		if chunk_to_edit == null:
			var chunk_instance = chunk_scene.instance().duplicate()
			chunk_instance.name = chunk_name
			chunk_node.chunks[chunk_key] = {"b":{},"o":{}}
			chunk_node.add_child(chunk_instance)
			chunk_instance.set_owner(self)
			chunk_to_edit = chunk_instance
			chunk_to_edit.set_meta("_edit_lock_", true)
			
		
		#this will add the block into a dictionary Blocks, inside the chunk data
		#the dictionary is an export, meaning i will be saved automagically
		#each block has a key (that is also its position/name) and a value t fot type
		var key = [pos_vec.x,pos_vec.y,pos_vec.z]
		
		if chunk_to_edit.blocks.has(key) == false:
			chunk_to_edit.blocks[key]= {"t": t}
			chunk_node.chunks[chunk_key]["b"][key]= {"t": t}
		elif chunk_to_edit.blocks.has(key) == true:
			var type = chunk_to_edit.blocks[key]["t"]
			if type != t:
				chunk_to_edit.blocks[key]["t"]=t
				chunk_node.chunks[chunk_key]["b"][key]["t"]=t
		
		if chunks_to_update.find(chunk_to_edit) == -1:
			chunks_to_update.append(chunk_to_edit)
		var neighboors = return_neighboor_chunks_at_pos(pos_vec)
		for j in neighboors:
			if chunks_to_update.find(j) == -1:
				chunks_to_update.append(j)
	
	for i in chunks_to_update:
		i.update()
	pass

#this erases a block at position pos,
#and update the dictionary of blocks within a chunk
#functions basically the same way as place_block
func erase_block(array_of_pos : Array):
	var chunks_to_update = []
	for i in array_of_pos.size():
		var pos = array_of_pos[i]
		
		var position_x  = pos.x
		if pos.x > 0:
			position_x = pos.x-1
		
		var position_z  = pos.z
		if pos.z > 0:
			position_z = pos.z-1
		
		var pos_vec = Vector3(position_x,pos.y, position_z)
		
		var cur_chunk = get_chunk_coordinate(pos_vec)
		var chunk_key = [cur_chunk.x,cur_chunk.y]
		var chunk_name = str(cur_chunk.x,"_",cur_chunk.y)
		var chunk_to_edit = get_node_or_null(str("Chunks/"+chunk_name))
		var key = [pos_vec.x,pos_vec.y,pos_vec.z]
		
		if chunk_to_edit != null:
			if chunk_to_edit.blocks.has(key) == false:
				continue
		
		#check if the block is is a chunk border
		#if yes, then update the neighboor chunk as well
		
		if chunk_to_edit != null:
			if chunk_to_edit.blocks.has(key) == true:
				chunk_to_edit.blocks.erase(key)
				chunk_node.chunks[chunk_key]["b"].erase(key)
				if chunks_to_update.find(chunk_to_edit) == -1:
					chunks_to_update.append(chunk_to_edit)
				var neighboors = return_neighboor_chunks_at_pos(pos_vec)
				
				for j in neighboors:
					if chunks_to_update.find(j) == -1:
						chunks_to_update.append(j)
				if chunk_to_edit.blocks.size() == 0 and chunk_to_edit.objects.size() == 0:
					chunk_to_edit.queue_free()
					chunk_node.chunks.erase(chunk_key)
	for i in chunks_to_update:
		i.update()
		pass

func return_neighboor_chunks_at_pos(pos_vec):
	var neighboor_chunks = []
	var neighboor_pos = [
	pos_vec + Vector3(1,0,0),
	pos_vec + Vector3(-1,0,0),
	pos_vec + Vector3(0,1,0),
	pos_vec + Vector3(0,-1,0),
	pos_vec + Vector3(0,0,1),
	pos_vec + Vector3(0,0,-1)]
	
	for i in neighboor_pos:
		var chunk = get_chunk_in_coordinate(i.x,i.y,i.z)
		if chunk != null:
			neighboor_chunks.append(chunk)
	return neighboor_chunks

func get_chunk_in_coordinate(x,y,z):
	var pos_vec = Vector3(x,y,z)
	var cur_chunk = get_chunk_coordinate(pos_vec)
	var chunk_name = str(cur_chunk.x,"_",cur_chunk.y)
	
	var chunk_to_edit = get_node_or_null(str("Chunks/"+chunk_name))
	return chunk_to_edit
	pass

func get_chunk_coordinate(vec3 : Vector3):
	var cur_chunk = Vector2(floor(vec3.x/chunk_size.x),floor(vec3.z/chunk_size.y))
	return cur_chunk
	pass

#place a block of type t, at position pos (Vector 3), with a rotation rot
#objects can be rotated, blocks currently can't
#functions the same way as place blocks
#it also updates the objects{} dictionary of the chunk accordingly
func place_object(pos,t,rot):
	var position_x  = pos.x-1
	var position_z  = pos.z
	
	var pos_vec = Vector3(position_x,pos.y, position_z)
	
	var cur_chunk = get_chunk_coordinate(pos_vec)
	var chunk_key = [cur_chunk.x,cur_chunk.y]
	var chunk_name = str(cur_chunk.x,"_",cur_chunk.y)
	
	var chunk_to_edit = get_node_or_null(str("Chunks/"+chunk_name))
	
	#if chunk does not exists
	if chunk_to_edit == null:
		var chunk_instance = chunk_scene.instance().duplicate()
		chunk_instance.name = chunk_name
		chunk_node.chunks[chunk_key] = {"b":{},"o":{}}
		chunk_node.add_child(chunk_instance)
		chunk_instance.set_owner(self)
		chunk_to_edit = chunk_instance
		chunk_to_edit.set_meta("_edit_lock_", true)
	
	var key = [pos_vec.x,pos_vec.y,pos_vec.z]
	
	if chunk_to_edit.objects.has(key) == false:
		chunk_to_edit.objects[key]= {"t": t, "rot":rot}
		chunk_node.chunks[chunk_key]["o"][key]= {"t": t, "rot":rot}
		chunk_to_edit.create_object(pos_vec.x,pos_vec.y,pos_vec.z, t,rot)
		pass

#this erases a block at position pos,
#and update the dictionary of blocks within a chunk
#functions basically the same way as place_block
func erase_object(pos):
	var position_x  = pos.x-1
	var position_z  = pos.z
	
	var pos_vec = Vector3(position_x,pos.y, position_z)
	
	var cur_chunk = get_chunk_coordinate(pos_vec)
	var chunk_key = [cur_chunk.x,cur_chunk.y]
	var chunk_name = str(cur_chunk.x,"_",cur_chunk.y)
	
	var chunk_to_edit = get_node_or_null(str("Chunks/"+chunk_name))
	var key = [pos_vec.x,pos_vec.y,pos_vec.z]
	if chunk_to_edit != null:
		if chunk_to_edit.objects.has(key) ==true:
			chunk_to_edit.objects.erase(key)
			chunk_node.chunks[chunk_key]["o"].erase(key)
			chunk_to_edit.delete_object(pos_vec.x,pos_vec.y,pos_vec.z)
			if chunk_to_edit.blocks.size() == 0 and chunk_to_edit.objects.size() == 0:
				chunk_to_edit.queue_free()
				chunk_node.chunks.erase(chunk_key)
				

func update_player_chunk(new_pos):
	player_position = new_pos
	if !Engine.editor_hint:
		if first_thead_finished:
			if thread != null and !thread.is_active():
#				thread.wait_to_finish()
				thread = Thread.new()
				thread.start(self,"load_chunks_around_player",null)
		pass

func load_chunks_around_player(data):
	if !Engine.editor_hint:
		var player_global_pos = player.translation
		var player_pos = get_chunk_coordinate(player_global_pos)
		var new_chunks_to_load = []
		
		for i in range(-(render_distance.x-1)/2,(render_distance.x+1)/2):
			for j in range(-(render_distance.y-1)/2,(render_distance.y+1)/2):
				var chunk_key = [player_position.x+i,player_position.y+j-z_render_offset]
				if chunk_node.chunks.has(chunk_key):
					new_chunks_to_load.append(chunk_key)
#				print (chunk_key)

		var cur_loaded = loaded_chunks
		for i in new_chunks_to_load:
			if loaded_chunks.find(i) == -1:
				var new_chunk = chunk_scene.instance()
				
				new_chunk.blocks = chunk_node.chunks[i]["b"]
				new_chunk.objects = chunk_node.chunks[i]["o"]
				chunk_node.add_child(new_chunk,true)
				new_chunk.update_all()
				loaded_chunks.append(i)
				loaded_chunk_instances.append(new_chunk)
			pass

		for i in cur_loaded:
			if new_chunks_to_load.find(i) == -1:
				var key = loaded_chunks.find(i)
				loaded_chunks.erase(i)
				var chunk = loaded_chunk_instances[key]
				chunk.queue_free()
				loaded_chunk_instances.remove(key)
		call_deferred("finished_current_thread")
		
	pass

func finished_current_thread():
	if thread.is_active():
		thread.wait_to_finish()
	first_thead_finished = true
	world_generated = true
	$UI/Control/VBoxContainer/generating.text = "Done Generating World!!"
	$UI/Control/VBoxContainer/generating.set("custom_colors/font_color", Color.green)

func _exit_tree():
	if thread:
		thread.wait_to_finish()

func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_R and event.pressed:
			get_tree().reload_current_scene()
