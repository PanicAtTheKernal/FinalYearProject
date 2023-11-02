extends Task

class_name MoveOnGround

@export_range(0.1, 3.0)
var speed_multiplier: float = 1.0

var ground_agent: NavigationAgent2D
var character_body: CharacterBody2D

func run():
	var direction = character_body.to_local(ground_agent.get_next_path_position()).normalized()
	character_body.velocity = direction * BirdHelperFunctions.SPEED * self.data["delta"]
	
	if ground_agent.is_target_reached() == false and ground_agent.is_target_reachable():
		character_body.move_and_slide()
		BirdHelperFunctions.find_tile_type(character_body.global_position, data)
		super.running()	
	elif ground_agent.is_target_reached() and BirdHelperFunctions.character_at_target(character_body.position, data["target"]):
		data["target_reached"] = true
		super.success()
	elif not ground_agent.is_target_reachable():
		super.fail()
	
func start():
	ground_agent = self.data["ground_agent"]
	character_body = self.data["character_body"]
	super.start()
