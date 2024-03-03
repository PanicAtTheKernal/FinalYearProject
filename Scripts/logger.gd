extends Node

enum LogType {
	RESOURCE,
	CAMERA,
	DATABASE,
	NAVIGATION,
	AI,
	GENERAL,
	UI,
	BUILDER,
	ANIMATION
}

var isDebug: bool = true
var allowed_logs: Dictionary = {
	LogType.RESOURCE: true,
	LogType.CAMERA: true,
	LogType.DATABASE: true,
	LogType.NAVIGATION: true,
	LogType.AI: true,
	LogType.GENERAL: true,
	LogType.UI: true,
	LogType.BUILDER: true,
	LogType.ANIMATION: true
}

var log_colours: Dictionary = {
	LogType.RESOURCE: "[color=green][b]Resource (<>): [/b][/color]",
	LogType.CAMERA: "[color=orange][b]Camera (<>): [/b][/color]",
	LogType.DATABASE: "[color=red][b]Database (<>): [/b][/color]",
	LogType.NAVIGATION: "[color=cyan][b]Navigation (<>): [/b][/color]",
	LogType.AI: "[color=yellow][b]AI (<>): [/b][/color]",
	LogType.GENERAL: "[color=white][b]General (<>): [/b][/color]",
	LogType.UI: "[color=purple][b]UI (<>): [/b][/color]",
	LogType.BUILDER: "[color=blue][b]Builder (<>): [/b][/color]",
	LogType.ANIMATION: "[color=pink][b]Animation (<>): [/b][/color]"
}
var log_file

func _ready() -> void:
	log_file = FileAccess.open("user://log.md", FileAccess.WRITE)

func _is_log_allowed(type:LogType)->bool:
	return allowed_logs.get(type)

func print_debug(message: Variant, key: Dictionary)->void:
	var type = key.get("type")
	var object_name = key.get("obj")
	if not isDebug or not _is_log_allowed(type):
		return
	var get_log_colour: String = log_colours.get(type)
	var replace_obj_name: String = "<>" if object_name != "" else " (<>)" 
	get_log_colour = get_log_colour.replace(replace_obj_name, object_name)
	log_file.store_string(str(get_log_colour,message,"\n"))
	print_rich(get_log_colour,message)
	

	
