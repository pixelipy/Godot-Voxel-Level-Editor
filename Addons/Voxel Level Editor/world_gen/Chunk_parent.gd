tool
extends Spatial

var chunk_size = Vector2(16,16)


export (Dictionary) var chunks = {} 

func _ready():
	if Engine.editor_hint:
		for i in get_children():
			i.update()
			i.update_objects()
	for i in get_children():
		i.set_meta("_edit_lock_", true)
	pass # Replace with function body.

#returns the chunk at some coordinate
#it is useful to hide chunks when the player moves.
#or even for hiding unecessary faces between chunks, as I'm using it
func get_chunk_in_coordinate(x,y,z):
	var pos_vec = Vector3(x,y,z)
	var cur_chunk = get_chunk_coordinate(pos_vec)
	var chunk_name = str(cur_chunk.x,"_",cur_chunk.y)
	
	var chunk_to_edit = get_node_or_null(str(chunk_name))
	return chunk_to_edit
	pass


#returns the chunk coordinate, which is a vector2 (no vertical chunks)
func get_chunk_coordinate(vec3 : Vector3):
	var cur_chunk = Vector2(floor(vec3.x/chunk_size.x),floor(vec3.z/chunk_size.y))
	return cur_chunk
	pass
