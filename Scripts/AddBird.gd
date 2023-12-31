extends CanvasLayer

@export
var bird_scene: PackedScene

@export
var world_rescources: WorldResources
@export
var player_cam: Camera2D
@export
var tile_map: TileMap

@onready
var line_edit := $VBoxContainer/HBoxContainer/BirdNameLineEdit as LineEdit
@onready
var find_species_request := $FindSpeciesRequest as HTTPRequest
@onready
var progress_bar := $VBoxContainer/HBoxContainer/Control/TextureProgressBar as TextureProgressBar
@onready
var submit_button := $VBoxContainer/HBoxContainer/Button as Button

var config

const ASSET_PATH = "user://Assets/Download/"
const ENVIRONMENT_VARIABLES = "environment" 

# Called when the node enters the scene tree for the first time.
func _ready():
	config = Database.config
	
	progress_bar.hide()
	# TEMP
	if !DirAccess.dir_exists_absolute(ASSET_PATH):
		DirAccess.make_dir_recursive_absolute(ASSET_PATH)


func _on_button_pressed():
	var users_bird_name = line_edit.text
	if users_bird_name == "":
		print("User didn't enter bird name")
	
	# Disable the form until the bird spawns
	progress_bar.show()
	line_edit.editable = false
	submit_button.hide()
	var bird_species_file = find_potential_files(line_edit.text)
	line_edit.clear()
	if bird_species_file != "":
		add_bird_to_scene(bird_species_file)
	else:
		get_bird_from_cloud(users_bird_name)
		
	

func find_potential_files(bird_name: String) -> String:
	# The species rescoure files don't use spaces, files instead use hyphens
	var bird_file_name = bird_name.replace(" ", "-")
	var files = DirAccess.get_files_at(ASSET_PATH)
	var file_regex = RegEx.new()
	file_regex.compile("[^*]*"+bird_file_name+"[^*]*[.]tres")
	print(files)
	for file in files:
		if file_regex.search(file):
			print(file)
			return file
	return ""

func get_bird_from_cloud(bird_name: String):
	# Don't make the request if the env file didn't load in
	if config == null:
		return
	var data = JSON.stringify({name:"Functions"})
	var auth_header = "Authorization: Bearer " + config.get_value(ENVIRONMENT_VARIABLES, "ANON_TOKEN", "")
	var content_type_header = "Content-Type: application/json"
	var headers = [auth_header, content_type_header]
	# Encode all spaces with the url space code value 
	var url_bird_name = bird_name.replace(" ", "%20")
	var find_species_url = config.get_value(ENVIRONMENT_VARIABLES, "FIND_SPECIES_URL", "") + "?species=" + url_bird_name
	find_species_request.request_completed.connect(find_species_request_result)
	find_species_request.request(find_species_url, headers, HTTPClient.METHOD_POST, data)
	
func find_species_request_result(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("1: "+ str(result))
	print("2: "+ str(response_code))
	print("3: "+ str(headers))
	print("4: "+ body.get_string_from_ascii())
	if response_code == 200:
		build_simulation(JSON.parse_string(body.get_string_from_ascii()))
	else:
		line_edit.editable = true
		line_edit.placeholder_text = "Error. Please try again"
		progress_bar.hide()
		submit_button.show()
		print("There was an error retriving the data")

func build_simulation(request_body: Dictionary):
	var body: Dictionary = request_body.get("data")
	var new_species: BirdSpecies = BirdSpecies.new()
	var bird_name: String = body.get("birdName")
	var bird_file_name: String = bird_name.replace(" ", "-") + ".tres"
	var simulation_info: Dictionary = body.get("birdSimulationInfo")
	var bird_shape_id: String = body.get("birdShapeId")
	var bird_template_url: String = body.get("birdImageUrl")
	
	var animations = await build_animation(bird_shape_id, bird_template_url)
	# If failed to build animation then return and not create the resource
	if animations == null:
		return
	new_species.bird_animations = animations
	new_species.bird_flight_cost = simulation_info.get("birdFlightCost")
	new_species.bird_ground_cost = simulation_info.get("birdGroundCost")
	new_species.bird_max_stamina = simulation_info.get("birdMaxStamina")
	new_species.bird_range = simulation_info.get("birdRange")
	new_species.bird_stamina = simulation_info.get("birdStamina")
	new_species.bird_take_off_cost = simulation_info.get("birdTakeOffCost")
	
	for bird_trait in simulation_info.get("birdTraits"):
		new_species.bird_traits.append(bird_trait)
	
	ResourceSaver.save(new_species, ASSET_PATH + bird_file_name)
	add_bird_to_scene(bird_file_name)

func build_animation(shape_id: String, template_url: String) -> SpriteFrames:
	var image_name_index = template_url.rfind("BirdAssets")
	var image_name = template_url.substr(image_name_index).replace("BirdAssets/", "")	
	var image_file_name = image_name.split("/")[1]
	
	var animationTemplateQuery: SupabaseQuery = SupabaseQuery.new().from("BirdShape").select().eq("BirdShapeId", shape_id)
	var animationTemplateResult = await Supabase.database.query(animationTemplateQuery).completed
	var animatinoTemplate = animationTemplateResult.data[0]["BirdShapeAnimationTemplate"]
	
	# TODO CHECK IF IMAGE EXISTS ALREADY
	var storageResult: StorageTask = await Supabase.storage.from("BirdAssets").download(image_name, ASSET_PATH + image_file_name).completed
	
	if storageResult.error != null:
		print(storageResult.error)
		return null
	
	var texture = Image.new()
	texture.load(ASSET_PATH + image_file_name)
	var image: ImageTexture = ImageTexture.create_from_image(texture)
	var height = image.get_height() as float
	var width = image.get_width() as float
	var size = height
	# Each frame is equal in size and the sprite sheet is in a 1x? configuration therefore to get 
	# the amount of frame is to divide the width by the height
	var amount_of_frames = floor(width/height)
	var frames: Array[AtlasTexture] = []
	for i in range(0, amount_of_frames):
		var newFrame = AtlasTexture.new()
		newFrame.atlas = image
		newFrame.region = Rect2(size*i, 0, size, size)
		frames.push_back(newFrame)
	
	var sprite_frames = SpriteFrames.new()
	var animations = animatinoTemplate["animation"]
	var animation_names = animations.keys()
	print(animation_names)
	for animation_name in animation_names:
		var animation_info = animations.get(animation_name)
		var animation_frames = animation_info["frames"]
		var fps = animation_info["fps"]
		var loop = animation_info["loop"]
		# Fix the error with "default" already existing on new spriteFrames
		if !sprite_frames.has_animation(animation_name):
			sprite_frames.add_animation(animation_name)
		sprite_frames.set_animation_loop(animation_name, loop)
		sprite_frames.set_animation_speed(animation_name, fps)
		for animation_frame in animation_frames:
			sprite_frames.add_frame(animation_name, frames[animation_frame])
	
	return sprite_frames
	
func add_bird_to_scene(file_name: String):
		var bird_species_resource: BirdSpecies = ResourceLoader.load(ASSET_PATH + file_name)
		var bird = bird_scene.instantiate()
		var center_pos = player_cam.get_screen_center_position()
		bird.bird_species = bird_species_resource
		bird.position = center_pos
		bird.tile_map = tile_map
		bird.world_resources = world_rescources
		
		get_parent().add_child(bird)
		# Reset the form
		line_edit.editable = true
		line_edit.placeholder_text = "Name"
		progress_bar.hide()
		submit_button.show()
