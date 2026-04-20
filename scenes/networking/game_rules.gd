class_name GameRules
extends Node

signal changed

enum Mode {
	DEATHMATCH = 0,
	TEAM_DEATHMATCH
}

@export var map : String = "Shipment"
@export var mode : Mode = Mode.DEATHMATCH

@export var score_target := 30
@export var respawn_time := 5.0

func _on_multiplayer_synchronizer_delta_synchronized() -> void:
	changed.emit()
