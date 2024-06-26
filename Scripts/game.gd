extends Node2D

@onready
var bird_manager: BirdManager = %Birds

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		bird_manager.save_all_birds()
		Logger.print_debug("Close request was sent", {
			"type": Logger.LogType.GENERAL,
			"obj": "Game"
		})
		get_tree().quit()
	#elif what == NOTIFICATION_APPLICATION_PAUSED:
		#bird_manager.save_all_birds()		

func _on_save_timer_timeout() -> void:
	pass
	#bird_manager.save_all_birds()
