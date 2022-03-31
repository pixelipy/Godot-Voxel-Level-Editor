extends StaticBody
tool

#(texture block size / separation between blocks)
#the textures are 16x16, with a 4px separation for texture bleeding
#texture bleeding is important to avoid inbetween texture seams!!
const tile_size = 16
const separation_between_textures = 4

#size of your atlas image
const atlas_width = 96
const atlas_height = 160

var tex_sep = tile_size/separation_between_textures

#96/16 = 6
#160/16 = 10
var TEXTURE_ATLAS_SIZE = Vector2((atlas_width/tile_size)*tex_sep,(atlas_height/tile_size)*tex_sep)

var division = tex_sep+1
var block_script = preload("res://Addons/Voxel Level Editor/block_types.gd")

enum {TOP,BOTTOM,LEFT,RIGHT,FRONT,BACK,SOLID,GENERATE_FACES, SCENE, OFFSET}

#vertices of a cube
const vertices = [
	Vector3(0,0,0),
	Vector3(1,0,0),
	Vector3(0,1,0),
	Vector3(1,1,0),
	Vector3(0,0,1),
	Vector3(1,0,1),
	Vector3(0,1,1),
	Vector3(1,1,1)
]

#Faces of a cube
const TOP_VERT = [2,3,7,6]
const BOTTOM_VERT = [0,4,5,1]
const LEFT_VERT = [6,4,0,2]
const RIGHT_VERT = [3,1,5,7]
const FRONT_VERT = [7,5,4,6]
const BACK_VERT = [2,0,1,3]

### with vector 3 positions
export (Dictionary) var blocks = {}
export (Dictionary) var objects = {}
var fences : Array = []


#the surfacetool that will generate the mesh of a chunk.
#it will only generate faces that we need to see.
var st = SurfaceTool.new()
var mesh = null
var mesh_instance = null

var material = preload("res://Addons/Voxel Level Editor/Textures/atlas_texture_material.tres")

func _ready():
#	set_owner(get_parent())
	material.albedo_texture.set_flags(2)

func update_all():
	update()
	update_objects()
#updates the surface tool everytime a new block
#is added or deleted
#it also remakes it's collision
func update():
	if mesh_instance != null:
		mesh_instance.call_deferred("queue_free")
		mesh_instance = null

	mesh = Mesh.new()
	mesh_instance = MeshInstance.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in blocks:
#		var array_idx = blocks.find(Vector3(i.x,i.y,i.z))
#		var block_type_idx = blocks_indexes[array_idx]
		var pos = i
		var type = blocks[i]["t"]
		create_block(pos[0],pos[1],pos[2],type)

	st.generate_normals(false)
	st.set_material(material)
	st.commit(mesh)
	st.generate_tangents()
	mesh_instance.set_mesh(mesh)
	add_child(mesh_instance)
	mesh_instance.create_trimesh_collision()
	pass

#this functions checks for a transparent block/object in the x,y,z coordinate
#if it is transparent, we render the block through it
#if it is solid, then we hide the mesh /face.
#that way, only the faces that are shown will be rendered

#try to set the cactus SOLID value to true, to see what happens.
#it should delete the face underneath it >:D
func check_transparent(x,y,z):
	var chunk_coords = get_parent().get_chunk_coordinate(Vector3(x,y,z))
	var chunk_key = [chunk_coords.x,chunk_coords.y]
	
	if !get_parent().chunks.has(chunk_key):
		return true
	var chunk_to_check = get_parent().chunks[chunk_key]
	
	if chunk_to_check["b"].has([x,y,z]) == true:
		var idx = [x,y,z]
		var type = chunk_to_check["b"][idx]["t"]
		return not block_script.block_types[type][SOLID]
	else:
		if chunk_to_check["o"].has([x,y,z]) == true:
			var idx = [x,y,z]
			var type = chunk_to_check["o"][idx]["t"]
			return not block_script.object_types[type][SOLID]
		else:
			return true
	pass

#this updates the objects
#it will initialize the objects in the array basically
func update_objects():
	for i in objects:
		var pos = i
		var type = objects[i]["t"]
		var rot = objects[i]["rot"]
		
		create_object(pos[0],pos[1],pos[2],type, rot)
		pass

#this creates the faces of a block, based on its type
#it will also check if it actually needs to create a face, based on if
#it is hidden by a solid block or not
func create_block(x,y,z, block_type):
	var block = block_type
	if block == 0: #AIR
		
		return
	
	var block_info = block_script.block_types[block]
	
	if block_info[GENERATE_FACES]:
		if check_transparent(x,y+1,z):
			create_face(TOP_VERT,x,y,z,block_info[TOP])
		if check_transparent(x,y-1,z):
			create_face(BOTTOM_VERT,x,y,z,block_info[BOTTOM])
		if check_transparent(x-1,y,z):
			create_face(LEFT_VERT,x,y,z,block_info[LEFT])
		if check_transparent(x+1,y,z):
			create_face(RIGHT_VERT,x,y,z,block_info[RIGHT])
		if check_transparent(x,y,z+1):
			create_face(FRONT_VERT,x,y,z,block_info[FRONT])
		if check_transparent(x,y,z-1):
			create_face(BACK_VERT,x,y,z,block_info[BACK])
	else:
		pass
	pass

#this function creates an object at a position and set rotation
#currently only objects can be rotated
func create_object(x : float,y : float,z : float, object_type, rot : float):
	var object = object_type
	var block_info = block_script.object_types[object_type]
	var instance = block_info[SCENE].instance()
	var offset = block_info[OFFSET]
	var fence_index = 0
	instance.translation = Vector3(x+offset.x,y+offset.y,z+offset.z)
	instance.rotation.y = rot
	instance.name = str(x*10," ",y*10, " ", z*10)
	
	add_child(instance)
	
	var root = get_tree().get_edited_scene_root()
#	instance.set_owner(root)
	instance.set_meta("_edit_lock_", true)
	pass


#deletes an object at a position
func delete_object(x,y,z):
	var instance = get_node(str(x*10," ",y*10, " ", z*10))
	if is_instance_valid(instance):
		instance.queue_free()
	pass


#creates a face, and sets it's texture accordingly.
#it takes into account the atlas texture with the block textures
#and also the separation between them
func create_face(i,x,y,z, texture_atlas_offset):
	var offset = Vector3(int(x),int(y),int(z))
	var a = vertices[i[0]] + offset
	var b = vertices[i[1]] + offset
	var c = vertices[i[2]] + offset
	var d = vertices[i[3]] + offset
	
	var uv_offset = (texture_atlas_offset*division)/TEXTURE_ATLAS_SIZE
	var height = tex_sep/TEXTURE_ATLAS_SIZE.y 
	var width = tex_sep/TEXTURE_ATLAS_SIZE.x
	
	var uv_a = uv_offset + Vector2(0,0)
	var uv_b = uv_offset + Vector2(0,height)
	var uv_c = uv_offset + Vector2(width,height)
	var uv_d = uv_offset + Vector2(width,0)
	
	st.add_triangle_fan([a,b,c],[uv_a,uv_b,uv_c])
	st.add_triangle_fan([a,c,d],[uv_a,uv_c,uv_d])
	pass


