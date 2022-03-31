extends KinematicBody


# Simple player script
# move with arrow keys
# jump with spacebar

signal load_chunks_around_player
var cur_chunk = Vector2.ZERO

var acceleration = 0.12
var speed:= 4
var motion = Vector3.ZERO
var grv := 3.0
var jump_force := 5.0
var _snap_vector := Vector3.DOWN

onready var ray_cast = $RayCast

func _ready():
	connect("load_chunks_around_player",get_tree().current_scene,"update_player_chunk")

func _physics_process(delta):
	if !get_tree().current_scene.world_generated:
		return
	
	var new_chunk = get_tree().current_scene.get_chunk_coordinate(global_transform.origin)
	if cur_chunk != new_chunk:
		cur_chunk = new_chunk
		emit_signal("load_chunks_around_player",cur_chunk)
	
	move()
	var is_colliding_with_floor = ray_cast.is_colliding()
	
	handle_gravity(is_colliding_with_floor,delta)
	handle_jumping_and_landing(is_colliding_with_floor)

func move():
	var direction = Vector3()
	var h_movement = Input.get_axis("ui_left","ui_right")
	var v_movement = Input.get_axis("ui_up","ui_down")
	
	direction += v_movement*transform.basis.z
	direction += h_movement*transform.basis.x
	
	direction = direction.normalized()
	
	motion.x = lerp(motion.x,direction.x*speed,acceleration)
	motion.z = lerp(motion.z,direction.z*speed,acceleration)
	
	motion = move_and_slide(motion,Vector3.UP)

func handle_gravity(is_colliding_with_floor, _delta):
	if !is_colliding_with_floor:
		motion.y -=grv*_delta

func handle_jumping_and_landing(is_colliding_with_floor):
	var just_landed : bool = is_colliding_with_floor and _snap_vector == Vector3.ZERO
	var just_jumped : bool = is_colliding_with_floor and Input.is_action_just_pressed("ui_accept")
	if just_jumped:
		_snap_vector = Vector3.ZERO
		motion.y = jump_force
	elif just_landed:
			_snap_vector = Vector3.DOWN
