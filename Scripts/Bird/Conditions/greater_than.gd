extends Condition

class_name GreaterThan

func run() -> void:
	super.run()
	if value > condition:
		super.success()
	else:
		super.fail()