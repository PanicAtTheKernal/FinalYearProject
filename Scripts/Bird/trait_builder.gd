extends Node

class_name TraitBuilder

var bird: Bird
var id: String
var root: BirdBehaviouralTree
var root_selector: Selector
var world_resources: WorldResources
var animated_sprite: AnimatedSprite2D
var at_target_lambda: Callable
var is_nest_available: Callable
var is_bird_ready_to_mate: Callable
var nest_location: Callable
var bird_avaliable_check: Callable
var resource_available_check: Callable
var nest_still_exists: Callable
var nest_built: Callable
var is_egg_hatched: Callable

var logger_key = {
	"type": Logger.LogType.BUILDER,
	"obj": "TraitBuilder"
}

func _init(new_bird: Bird) -> void:
	self.bird = new_bird
	root = new_bird.behavioural_tree
	world_resources = new_bird.world_resources
	animated_sprite = new_bird.animatated_spite
	at_target_lambda = func(): return bird.at_target()
	is_nest_available = func(): return bird.nest_manager.has_available_nest(bird.species.nest_type)
	nest_location = func(): if bird.nest != null: return bird.tile_map.map_to_world_space(bird.nest.position)		
	is_bird_ready_to_mate = func(): return bird.mate
	# This could have huge performance issues
	bird_avaliable_check = func(): return bird.bird_manager.get_bird(bird.partner)
	resource_available_check = func(target_resource: String): 
		var resource = bird.world_resources.get_resource(target_resource, bird.tile_map.world_to_map_space(bird.target))
		if resource == null or resource.current_state == "Empty":
			return false
		else:
			return true
	is_egg_hatched = func(): return bird.nest_manager.is_chick_alive(bird.nest.position)
	nest_built = func(): return bird.nest_manager.is_nest_built(bird.nest.position)
	nest_still_exists = func(): return bird.nest != null
	id = str(new_bird.id)


func build_root()->void:
	root.logger_key.obj = id+": Root"
	root_selector = Selector.new(id+": RootSelector")
	root.add_child(root_selector)

func build_exploration()->void:
	var exploration_sequence = Sequence.new(id+": ExplorationSequence")
	# Conditions
	var exploration_condition_selector = Selector.new(id+": ExplorationConditionSelector")
	var is_energetic = Inverter.new(id+": IsEnergetic")
	is_energetic.add_child(LessThan.new(bird, "current_stamina", (bird.species.max_stamina * bird.species.threshold),id+": CheckStamina"))
	var is_barren = Inverter.new(id+": IsBarren")
	is_barren.add_child(FindNearestResource.new(bird, bird.species.diet, id+": FindNearestFood"))
	exploration_condition_selector.add_child(is_energetic)
	exploration_condition_selector.add_child(is_barren)
	exploration_sequence.add_child(exploration_condition_selector)
	# Navigation
	exploration_sequence.add_child(UpdateStatus.new(bird, "exploring", id+": StartingExploringBehaviour"))
	exploration_sequence.add_child(_build_wander())
	root_selector.add_child(exploration_sequence)

func build_foraging()->void:
	var foraging_sequence = Sequence.new(id+": ForagingSequence")
	foraging_sequence.add_child(LessThan.new(bird, "current_stamina", (bird.species.max_stamina * bird.species.threshold),id+": CheckStamina"))
	foraging_sequence.add_child(UpdateStatus.new(bird, "foraging", id+": StartingForagingBehaviour"))
	foraging_sequence.add_child(FindNearestResource.new(bird, bird.species.diet, id+": FindNearestFood"))
	foraging_sequence.add_child(_build_navigation(resource_available_check.bind(bird.species.diet)))
	foraging_sequence.add_child(Consume.new(bird, bird.species.diet, id+": ConsumeFood"))
	root_selector.add_child(foraging_sequence)


func build_partner()->void:
	var partner_sequence = Sequence.new(id+": PartnerSequence")
	# CheckIfOldEnough
	partner_sequence.add_child(GreaterThan.new(bird, "current_age", bird.TEEN_THRESHOLD, id+": CheckIfOldEnough"))
	partner_sequence.add_child(Equal.new(bird, "nest", null, id+": NoNest"))
	if bird.info.gender == "male":
		# Male mating conditions
		partner_sequence.add_child(Equal.new(bird, is_bird_ready_to_mate, true, id+": ReadyToMate"))
		partner_sequence.add_child(Equal.new(bird, "partner", -1, id+": HasNoMate"))
		partner_sequence.add_child(Equal.new(bird, is_nest_available, true, id+": NestAvailable"))
		partner_sequence.add_child(UpdateStatus.new(bird, "mating", id+": StartingMatingBehaviour"))
		partner_sequence.add_child(FindNearestBird.new(bird, id+": FindNearestBird"))
		partner_sequence.add_child(_build_navigation())
		partner_sequence.add_child(Love.new(bird, id+": Love"))
	elif bird.info.gender == "female":
		var condition= func(): return bird.stop_now
		partner_sequence.add_child(Stop.new(bird,condition, id+": Stop"))
		partner_sequence.add_child(UpdateStatus.new(bird, "mating", id+": StartingMatingBehaviour"))
		partner_sequence.add_child(Land.new(bird,id+": Land"))	
	root_selector.add_child(partner_sequence)

func build_nest_building()->void:
	# If the male doesn't participate in the parenting then it won't have this behaviour
	if bird.info.gender == "male" and not bird.species.coparent:
		return
	var nest_building_sequence = Sequence.new(id+": NestBuildingSequence")
	# Conditions
	var has_nest = Inverter.new(id+": HasNest")
	has_nest.add_child(Equal.new(bird, "nest", null, id+": NoNest"))
	nest_building_sequence.add_child(has_nest)
	nest_building_sequence.add_child(Equal.new(bird, nest_built, false, id+": NestBuilt"))
	if bird.info.gender == "male":
		var has_partner = Inverter.new(id+": HasPartner")
		has_partner.add_child(Equal.new(bird, "partner", -1, id+": HasNoPartner"))
		nest_building_sequence.add_child(has_partner)
	# Actions
	nest_building_sequence.add_child(UpdateStatus.new(bird, "Building nest", id+": StartingMatingBehaviour"))
	nest_building_sequence.add_child(FindNearestResource.new(bird, "Stick", id+": FindNearestStick"))
	nest_building_sequence.add_child(_build_navigation(resource_available_check.bind("Stick")))
	nest_building_sequence.add_child(Consume.new(bird, "Stick", id+": GatherStick"))
	nest_building_sequence.add_child(FlyToTarget.new(bird, nest_location, id+": FlyToNest"))
	nest_building_sequence.add_child(_build_navigation(nest_still_exists))
	nest_building_sequence.add_child(PlayAnimation.new(bird, id+": PlayPlaceAnimation"))
	nest_building_sequence.add_child(BuildNest.new(bird, id+": BuildNest"))
	root_selector.add_child(nest_building_sequence)


func build_parenting()->void:
	# If the male doesn't participate in the parenting then it won't have this behaviour
	if bird.info.gender == "male" and not bird.species.coparent:
		return
	var parenting_sequence = Sequence.new(id+": ParentingSequence")
	# Conditions
	var has_nest = Inverter.new(id+": HasNest")
	has_nest.add_child(Equal.new(bird, "nest", null, id+": NoNest"))
	parenting_sequence.add_child(has_nest)
	parenting_sequence.add_child(Equal.new(bird, nest_built, true, id+": NestBuilt"))
	if bird.info.gender == "male":
		var abandon_nest_selector = Selector.new(id+": AbandonNest")
		abandon_nest_selector.add_child(Equal.new(bird, is_egg_hatched, true, id+": EggHatched"))
		var has_partner = Inverter.new(id+": HasPartner")
		has_partner.add_child(Equal.new(bird, "partner", -1, id+": HasNoPartner"))
		abandon_nest_selector.add_child(has_partner)
		parenting_sequence.add_child(abandon_nest_selector)
	# Actions
	if bird.info.gender == "female":
		parenting_sequence.add_child(UpdateStatus.new(bird, "nesting", id+": StartingNestingBehaviou"))
		parenting_sequence.add_child(FlyToTarget.new(bird, nest_location, id+": FlyToNest"))
		parenting_sequence.add_child(_build_navigation(nest_still_exists))
		parenting_sequence.add_child(LayEgg.new(bird, id+": LayEgg"))
		parenting_sequence.add_child(Nest.new(bird, id+": Nest"))
	elif bird.info.gender == "male":
		parenting_sequence.add_child(UpdateStatus.new(bird, "parenting", id+": StartingParentingBehaviou"))
	parenting_sequence.add_child(FindNearestResource.new(bird, bird.species.diet, id+": GetFood"))
	parenting_sequence.add_child(_build_navigation(resource_available_check.bind(bird.species.diet)))
	parenting_sequence.add_child(Consume.new(bird, bird.species.diet, id+": ConsumeFood"))
	parenting_sequence.add_child(FlyToTarget.new(bird, nest_location, id+": FlyToNest"))
	parenting_sequence.add_child(_build_navigation(nest_still_exists))
	parenting_sequence.add_child(PlayAnimation.new(bird, id+": PlayPlaceAnimation"))
	if bird.info.gender == "female":
		parenting_sequence.add_child(LeaveNest.new(bird, id+": LeaveNest"))
	root_selector.add_child(parenting_sequence)

# Keeps the old behaviour where the bird will move towards the target regardless if it is there
func _build_navigation(target_check: Callable = func(): return true)->Sequence:
	var navigation_sequence = Sequence.new(id+": NavigationSequence")
	# MovementSelector
	#navigation_sequence.add_child(CheckGroundType.new(bird, id+": CheckGroundType"))	
	var movement_selector = Selector.new(id+": MovementSelector")
	movement_selector.add_child(_build_ground_sequence())
	if bird.species.can_fly:
		movement_selector.add_child(_build_flying_sequence())
	navigation_sequence.add_child(movement_selector)
	# Move
	navigation_sequence.add_child(Move.new(bird, target_check, id+": Move"))
	# CheckIfTargetReached
	navigation_sequence.add_child(_build_check_if_reached_target())
	# Stop
	# navigation_sequence.add_child(Stop.new(bird,at_target_lambda, id+": Stop"))
	navigation_sequence.add_child(Land.new(bird,id+": Land"))
	return navigation_sequence

func _build_wander()->Sequence:
	var wander_sequence = Sequence.new(id+": WanderSequence")
	wander_sequence.add_child(Fly.new(bird, id+": Fly"))
	wander_sequence.add_child(WanderBehaviour.new(bird, id+": Wander"))
	return wander_sequence

func _build_ground_sequence()->Sequence:
	var ground_sequence = Sequence.new(id+": GroundSequence")
	var distance_lamdba = func(): return bird.global_position.distance_to(bird.target)
	ground_sequence.add_child(LessThan.new(bird,distance_lamdba,bird.species.ground_max_distance, id+": CheckIfMovingOnGround"))
	ground_sequence.add_child(_build_walking_sequence())
	if bird.species.can_swim:
		ground_sequence.add_child(_build_swimming_sequence())		
	return ground_sequence

func _build_walking_sequence()->Sequence:
	var walking_sequence = Sequence.new(id+": WalkingSequence")
	walking_sequence.add_child(_build_check_if_walking())
	walking_sequence.add_child(Walk.new(bird, id+": Walk"))
	return walking_sequence

func _build_swimming_sequence()->Sequence:
	var swimming_sequence = Sequence.new(id+": SwimmingSequence")
	swimming_sequence.add_child(_build_check_if_swimming())
	swimming_sequence.add_child(Swim.new(bird, id+": Swim"))
	return swimming_sequence

func _build_flying_sequence()->Sequence:
	var flying_sequence = Sequence.new(id+": FlyingSequence")
	var not_at_targert_inverter = Inverter.new(id+": IsNotAtTargert")
	not_at_targert_inverter.add_child(Equal.new(bird, "target_reached", true, id+": AtTarget"))
	#flying_sequence.add_child(TakeOff.new(bird, id+": TakeOff"))	
	flying_sequence.add_child(Fly.new(bird, id+": Fly"))
	return flying_sequence

func _build_check_if_reached_target()->Task:
	return Equal.new(bird, at_target_lambda, true, id+": CheckIfReachedTarget")

func _build_check_if_swimming()->Sequence:
	var check_if_swimming_sequence = Sequence.new(id+": CheckIfSwimmingSequence")
	check_if_swimming_sequence.add_child(Equal.new(bird, "current_tile", "Water", id+": CheckOnWaterTile"))
	var not_at_targert_inverter = Inverter.new(id+": IsNotAtTargert")
	not_at_targert_inverter.add_child(Equal.new(bird, "target_reached", true, id+": AtTarget"))
	check_if_swimming_sequence.add_child(not_at_targert_inverter)
	return check_if_swimming_sequence

func _build_check_if_walking()->Sequence:
	var check_if_walking_sequence = Sequence.new(id+": CheckIfSwimmingSequence")
	check_if_walking_sequence.add_child(Equal.new(bird, "current_tile", "Ground", id+": CheckOnGroundTile"))
	var not_at_targert_inverter = Inverter.new(id+": IsNotAtTargert")
	not_at_targert_inverter.add_child(Equal.new(bird, "target_reached", true, id+": AtTarget"))
	check_if_walking_sequence.add_child(not_at_targert_inverter)
	return check_if_walking_sequence
