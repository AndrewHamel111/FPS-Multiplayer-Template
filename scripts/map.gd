class_name Map
extends Node

var spawns : Array[Node3D]

func _ready() -> void:
	for node in $spawns.get_children():
		var spawn := node as Node3D
		spawns.push_back(spawn)
		var arrow := spawn.get_child(0)
		spawn.remove_child(arrow)
		arrow.free()
