extends Task

class_name LeaveNest

var bird: Bird

func _init(parent_bird: Bird, node_name:String="LeaveNest") -> void:
	super(node_name)
	bird = parent_bird

func run()->void:
	if not bird.at_target():
		super.fail()
		return
	if bird.info.gender == "female":
		var nest_map_cords: Vector2i = bird.nest.position
		bird.nest_manager.leave_nest(nest_map_cords, bird.info)
		bird.nest = null
		if bird.partner != -1:
			var partner = bird.bird_manager.get_bird(bird.partner)
			if partner != null:
				partner.listener.emit(bird.BirdCalls.LEAVE, bird.id, nest_map_cords)
				bird.partner = -1
				bird.mate = false
				bird.reset_mate()
	super.success()
	
func start()->void:
	super.start()
