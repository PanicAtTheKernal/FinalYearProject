extends Node

# Android camera variables
var plugin
var plugin_name = "GodotGetImage"
var options = {
	"image_height" : 1920,
	"image_width" : 1080,
	"keep_aspect" : true,
	"image_format" : "jpg"
}


func _ready()->void:
	var os_name = OS.get_name()
	match os_name:
		"Android":
			_setup_camera_andorid()


func _on_image_request_completed(image_buffers)->void:
	var image = image_buffers.values()[0]
	get_tree().call_group("LoadingButton", "show_loading")
	var image_identification = ImageIdentification.new(image)
	add_child(image_identification)
	image_identification.send_request()

func _on_error(e):
	get_tree().call_group("Dialog", "display", e)

func _on_permission_not_granted_by_user():
	get_tree().call_group("Dialog", "display", "You need to allow the camera for the app")
	plugin.resendPermission()

func take_picture()->void:
	var os_name = OS.get_name()
	match os_name:
		"Android":
			_take_picture_andorid()	
		"iOS":
			_take_picture_ios()
		_:
			get_tree().call_group("Dialog", "display", ("Platform "+os_name+" is not supported"))

func _take_picture_andorid()->void:
	if plugin:
		plugin.getGalleryImage()
	else:
		print(plugin_name, " plugin not loaded!")
	
func _take_picture_ios()->void:
	pass

func _setup_camera_andorid()->void:
	if Engine.has_singleton(plugin_name):
		plugin = Engine.get_singleton(plugin_name)
	else:
		get_tree().call_group("Dialog", "display", ("Could not load plugin: "+plugin_name))
	
	if plugin:
		plugin.connect("image_request_completed", _on_image_request_completed)
		plugin.connect("error", _on_error)
		plugin.connect("permission_not_granted_by_user", _on_permission_not_granted_by_user)
		plugin.setOptions(options)