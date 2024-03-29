extends Node2D

class_name NestManager

const FREE_NEST = "Free"
const TAKEN_NEST = "Taken"
const NESTS = "Nests"

var nests: Dictionary
@onready
var tile_map: TileMapManager = %TileMap
@onready
var world_resources: WorldResources = %WorldResources
@onready
var bird_manager: BirdManager = %Birds

func _ready() -> void:
	_initialise_nests()
	_get_nests()

func _initialise_nests() -> void:
	var nest_group_template = world_resources.get_resource_group_from_name(NESTS)
	for template in nest_group_template.resource_templates:
		nests[template.name] = {
			FREE_NEST: [],
			TAKEN_NEST: []
		}
		
func _get_nests() -> void:
	for partition in world_resources.resource_partitions.values():
		var nest_resources = partition[NESTS]
		for nest in nest_resources.values():
			nests[nest.template.name][FREE_NEST].push_back(nest)

func request_nest(nest_type: String) -> WorldResource:
	if nests[nest_type][FREE_NEST].size() > 0:
		var nest = nests[nest_type][FREE_NEST].pop_front()
		nests[nest_type][TAKEN_NEST].push_back(nest)
		return nest
	else:
		return null

func has_available_nest(nest_type: String) -> bool:
	return nests[nest_type][FREE_NEST].size() > 0

func build_nest(nest_map_cords: Vector2) -> void:
	var nest = world_resources.get_resource("Nests", nest_map_cords)
	if nest != null and nest.current_state == "Empty":
		world_resources.set_resource_state(nest, "StartBuild")
	elif nest != null and nest.current_state == "StartBuild":
		world_resources.set_resource_state(nest, "EmptyNest")
	
func is_nest_built(nest_map_cords: Vector2) -> bool:
	var nest = world_resources.get_resource("Nests", nest_map_cords)
	if nest != null and (nest.current_state != "Empty" and nest.current_state != "StartBuild"):
		return true
	else:
		return false

func is_egg_laid(nest_map_cords: Vector2) -> bool:
	var nest = world_resources.get_resource("Nests", nest_map_cords)
	if nest != null and nest.current_state == "Egg":
		return true
	else:
		return false

func is_chick_alive(nest_map_cords: Vector2) -> bool:
	var nest = world_resources.get_resource("Nests", nest_map_cords)
	if nest != null and (nest.current_state == "Hatch" or "Alive"):
		return true
	else:
		return false

func lay_egg(nest_map_cords: Vector2) -> void:
	var nest = world_resources.get_resource("Nests", nest_map_cords)
	if nest != null and nest.current_state == "EmptyNest":
		world_resources.set_resource_state(nest, "Egg")

func hatch_egg(nest_map_cords: Vector2) -> void:
	var nest = world_resources.get_resource("Nests", nest_map_cords)
	if nest != null and nest.current_state == "Egg":
		world_resources.set_resource_state(nest, "Hatch")
		await get_tree().create_timer(3).timeout
		world_resources.set_resource_state(nest, "Alive")

func leave_nest(nest_map_cords: Vector2, bird_info: BirdInfo) -> bool:
	var nest = world_resources.get_resource("Nests", nest_map_cords)
	if nest != null and nest.current_state == "Alive":
		world_resources.set_resource_state(nest, "Empty")
		var type = nest.template.name
		nests[type][TAKEN_NEST].erase(nest)
		nests[type][FREE_NEST].push_back(nest)
		var child_bird_info = BirdResourceManager.load_bird(bird_info.species.name)
		var child_bird = bird_manager.create_bird(child_bird_info)
		bird_manager.spawn_bird(child_bird, tile_map.map_to_world_space(nest_map_cords))
		BirdResourceManager.add_bird_to_list(child_bird_info)
		return true
	return false
