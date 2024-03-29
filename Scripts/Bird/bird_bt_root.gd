extends Task

class_name BirdBehaviouralTree

@export
var root_timer: Timer

var bird_id: String = "0"
var cycle: int = 0
var pause: bool

func _init() -> void:
	# Actually id is set in trait builder
	super(str(bird_id)+": Root")

func _ready():
	super.start()
	pause = false

# Start running the tree
func _physics_process(_delta):
	if not pause:
		cycle += 1
		Logger.print_debug("Cycle: " + str(cycle), logger_key)
		run()


func run()->void:
	Logger.print_debug("RUNNING: ROOT", logger_key)
	for child in get_children():
		Logger.print_debug("RUNNING: ("+child.logger_key.obj+")", logger_key)
		child.run()

func cancel()->void:
	Logger.print_debug("CANCELING: ROOT", logger_key)
	super.reset()

func pause_execution(time: float)->void:
	pause = true
	root_timer.start(time)
	await root_timer.timeout
	pause = false 

func wait_for_signal(signal_to_wait: Signal)->void:
	pause = true
	await signal_to_wait
	pause = false

func wait_for_function(function_to_wait: Callable)->void:
	pause = true
	await function_to_wait.call()
	pause = false
