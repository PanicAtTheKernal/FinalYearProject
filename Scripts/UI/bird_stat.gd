extends Control

@onready
var image: TextureRect = %BirdImage
@onready
var bird_name_label: Label = %BirdNameData
@onready
var date_found_label: Label = %DateFoundData
@onready
var status_label: Label = %StatusData
@onready
var new_frame_timer: Timer = %NewFrameTimer
@onready
var description: RichTextLabel = %DescriptionData
@onready
var family_label: Label = %FamilyData
@onready
var scientific_label: Label = %ScientificData
@onready
var gender_label: Label = %GenderData
@onready
var diet_label: Label = %DietData
@onready
var fly_label: Label = %FlyData
@onready
var swim_label: Label = %SwimData
@onready
var cleaning_label: Label = %CleaningMethodsData

@export
var default_frames: SpriteFrames

var bird_frames: SpriteFrames
var anim_names: PackedStringArray
var current_anim_name: String
var current_anim_index: int
var current_frame_index: int
var max_frames: int
var logger_key = {
	"type": Logger.LogType.UI,
	"obj": "BirdStat"
}

func _ready()->void:
	if not is_visible_in_tree():
		new_frame_timer.stop()

func load_new_bird(bird: BirdInfo)->void:
	var date_dict = Time.get_datetime_dict_from_datetime_string(bird.date_found, false)
	var date_found = str(date_dict.get("day"),"/",date_dict.get("month"),"/",date_dict.get("year"))
	bird_name_label.text = bird.species.name
	family_label.text = bird.family
	scientific_label.text = bird.scientific_name
	gender_label.text = bird.gender
	diet_label.text = bird.species.diet
	date_found_label.text = date_found
	status_label.text = bird.get_status_message(bird.status)
	description.text = bird.description
	fly_label.text = "Yes" if bird.species.can_fly else "No"
	swim_label.text = "Yes" if bird.species.can_swim else "No"
	_build_cleaning_label(bird)
	if bird.status != BirdInfo.StatusTypes.NOT_GENERATED:
		_load_image(bird.species.animations)
	else:
		Logger.print_debug("Bird isn't generated, using image placeholder", logger_key)
		_load_image(default_frames)
	Logger.print_debug(str("Updated UI with ",bird.species.name), logger_key)
	
func _build_cleaning_label(bird: BirdInfo)->void:
	var cleaning_methods: String = ""
	if bird.species.preen:
		cleaning_methods += "Preening, "
	if bird.species.takes_dust_baths:
		cleaning_methods += "Dust Baths, "
	if bird.species.does_sunbathing:
		cleaning_methods += "Sunbathing, "
	cleaning_label.text = cleaning_methods.trim_suffix(", ")

func _load_image(frames: SpriteFrames)->void:
	if len(frames.get_animation_names()) > 0:
		bird_frames = frames
		anim_names = bird_frames.get_animation_names()
		current_anim_index = 0
		current_anim_name = anim_names[current_anim_index]
		current_frame_index = 0
		max_frames = bird_frames.get_frame_count(current_anim_name)-1
		image.texture = bird_frames.get_frame_texture(current_anim_name, current_frame_index)	
		new_frame_timer.start()


func _on_new_frame_timer_timeout()->void:
	image.texture = bird_frames.get_frame_texture(current_anim_name, current_frame_index)
	if current_frame_index == max_frames:
		current_anim_index = (current_anim_index + 1) % len(anim_names)
		current_anim_name = anim_names[current_anim_index]
		current_frame_index = 0
		max_frames = bird_frames.get_frame_count(current_anim_name)-1
	else:
		current_frame_index += 1


func _on_close_button_pressed()->void:
	new_frame_timer.stop()
	hide()
