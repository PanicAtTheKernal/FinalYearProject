# Code based from https://gdscript.com/solutions/godot-behaviour-tree/

extends Node

class_name Task

enum {
	LOADED,
	RUNNING,
	FAILED,
	SUCCEEDED,
	CANCELLED
}

var parent = null
var tree = null
var status = LOADED
var data = null
var logger_key = {
	"type": Logger.LogType.AI,
	"obj": self.name
}

func _init(node_name: String) -> void:
	logger_key.obj = node_name

func running()->void:
	status = RUNNING
	if parent != null:
		parent.child_running()

func success()->void:
	status = SUCCEEDED
	if parent != null:
		parent.child_success()

func fail()->void:
	status = FAILED
	if parent != null:
		parent.child_fail()

# Modified this
func cancel()->void:
	if status != CANCELLED:
		status = CANCELLED
		for child in get_children():
			child.cancel()

# Abstract functions
func run()->void:
	pass

func child_success()->void:
	pass

func child_fail()->void:
	pass

func child_running():
	pass

# Overwrite this
func start()->void:
	status = LOADED
	for child in get_children():
		child.parent = self
		child.tree = self.tree
		child.data = self.data
		child.start()
		

func reset()->void:
	cancel()
	status = LOADED



