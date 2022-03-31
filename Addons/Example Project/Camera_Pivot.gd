extends Spatial

export var target : NodePath
export var lerp_speed := 0.1

func _process(delta):
	var player = get_node(target)
	if player != null:
		self.transform.origin = lerp(self.transform.origin,player.transform.origin,lerp_speed)
