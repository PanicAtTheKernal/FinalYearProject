extends Control

@onready
var line_edit: LineEdit = %LineEdit
@onready
var families: RichTextLabel = %SupportedFamiles
@onready
var panel: PanelContainer = %Panel

func _ready() -> void:
	var supported_families = await Database.fetch_supported_familes()
	for family in supported_families:
		families.text += family + "\n"

func _process(_delta: float) -> void:
	var window = get_window()
	if window.size.x > Startup.NON_MOBLIE_SIZE:
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		panel.custom_minimum_size.x = 960
	else:
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.custom_minimum_size.x = 0

func show_search()->void:
	show()
	line_edit.clear()
	get_tree().call_group("PlayerCamera", "turn_off_movement")

func _validate_input(input: String)->bool:
	var validator_regex = RegEx.new()
	validator_regex.compile("^[A-Za-z ]+$")
	return validator_regex.search(input) != null
	
func _on_ok_button_pressed()->void:
	hide()
	var input = line_edit.text.strip_edges()
	if _validate_input(input):
		get_tree().root.find_child("BTimer", true, false).start_timer()
		BirdResourceManager.find_bird(input)
		get_tree().call_group("LoadingSearchButton", "show_loading")
		get_tree().call_group("PlayerCamera", "turn_on_movement")
	else:
		var error_dialog = Dialog.new().message("Please enter a valid name without numbers or special characters").regular_notification()
		GlobalDialog.create(error_dialog)


func _on_cancel_button_pressed() -> void:
	hide()
	get_tree().call_group("PlayerCamera", "turn_on_movement")
