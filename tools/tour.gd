## Entry point for the screenshot tour. Hands off to a driver parented to the
## window root, so scene changes do not take the driver down with them.
extends Node


func _ready() -> void:
	get_tree().root.add_child.call_deferred(TourDriver.new())
