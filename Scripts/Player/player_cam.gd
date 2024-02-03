extends Camera2D

const MIN_ZOOM: float = 6.0
const MAX_ZOOM: float = 9.0
const TILE_SIZE: int = WorldResources.TILE_SIZE
const MAX_ZOOM_VEC: Vector2 = Vector2(MAX_ZOOM, MAX_ZOOM)
const MIN_ZOOM_VEC: Vector2 = Vector2(MIN_ZOOM, MIN_ZOOM)

@export
var zoom_increment: float = 1.0
@onready
var tile_map: TileMap = %TileMap

var dragging: bool = false
var isActive: bool = true
var logger_key = {
	"type": Logger.LogType.UI,
	"obj": "PlayerCamera"
}

func _ready()->void:
	# Create the camera limits
	var map_size = tile_map.get_used_rect()
	var start = Vector2(map_size.position * TILE_SIZE)
	var end = Vector2((map_size.size + map_size.position) * TILE_SIZE)
	limit_top = start.y
	limit_left = start.x
	limit_bottom = end.y
	# Just to make the right limit is within the visible bounds of the map
	limit_right = end.x - TILE_SIZE
	
func _input(event)->void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not dragging and event.pressed:
				dragging = true
			elif dragging and not event.pressed:
				dragging = false
	
	# Move the camera
	if event is InputEventMouseMotion and dragging and isActive:
		position -= event.relative / zoom

func zoom_in()->void:
	if zoom < MAX_ZOOM_VEC:
		zoom += Vector2(zoom_increment, zoom_increment) 

func zoom_out()->void:
	if zoom > MIN_ZOOM_VEC:
		zoom -= Vector2(zoom_increment, zoom_increment) 

# This is when the dialog box show up the player camera stops
func display(message: String, heading: String = "Notice:")->void:
	Logger.print_debug("Player camera movement is disabled", logger_key)
	isActive = false

func turn_on_movement()->void:
	Logger.print_debug("Player camera movement is enabled", logger_key)	
	isActive = true
