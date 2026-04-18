class_name User
extends Node

signal name_changed

@export var username: String

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _on_multiplayer_synchronizer_delta_synchronized() -> void:
	name_changed.emit()
