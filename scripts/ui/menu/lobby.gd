class_name LobbyManager
extends PanelContainer

signal start_game
signal setting_changed(setting: String, value: Variant)

var maps : Dictionary[String, String] = {
	"Shipment": "res://maps/shipment.tscn",
	"Nuketown": "res://maps/nuketown.tscn"
}

@onready var name_scene: PackedScene = load("res://scenes/ui/lobby/name.tscn")

@onready var player_list: VBoxContainer = $HBoxContainer/MarginContainer/VBoxContainer/PlayerList/MarginContainer2/VBoxContainer
#@onready var chat_box: VBoxContainer = $HBoxContainer/MarginContainer/VBoxContainer/Chat/MarginContainer/VBoxContainer/VBoxContainer
#@onready var chat_input: LineEdit = $HBoxContainer/MarginContainer/VBoxContainer/Chat/MarginContainer/VBoxContainer/Panel2

@onready var selected_map_name: Label = $HBoxContainer/MarginContainer2/VBoxContainer2/MarginContainer/Label3

@onready var map: OptionButton = %Map
@onready var mode: OptionButton = %Mode
@onready var score_target: SpinBox = %ScoreTarget
@onready var respawn_time: SpinBox = %RespawnTime
@onready var start_button: Button = %StartButton

@onready var host_only_options: Dictionary[String, Control] = {
	"map": map,
	"gamemode": mode,
	"score_target": score_target,
	"respawn_time": respawn_time,
	"start_button": start_button
}

func _ready() -> void:
	map.clear()
	for m in maps:
		map.add_item(m)
		
	mode.clear()
	mode.add_item("Deathmatch")

func disable_control(control: Control, state: bool = false) -> void:
	if control is SpinBox:
		(control as SpinBox).editable = state
	if control is OptionButton:
		(control as OptionButton).disabled = not state

func set_host_mode(value: bool = true) -> void:
	for option in host_only_options:
		disable_control(host_only_options[option], value)
	
	start_button.text = "Start Game" if value else "Only Host Can Start Game"
	start_button.disabled = not value

func set_player_list(players: Array[User]) -> void:
	for node in player_list.get_children():
		player_list.remove_child(node)
		node.queue_free()
	
	for player in players:
		var label := name_scene.instantiate()
		label.set_text(player.username)
		player_list.add_child(label)

func set_game_rules(game_rules: GameRules) -> void:
	map.selected = maps.values().find(game_rules.map_resource_path)
	#mode.selected = game_rules.mode
	score_target.value = game_rules.score_target
	respawn_time.value = game_rules.respawn_time

func _on_start_match_pressed() -> void:
	start_game.emit()

func _on_map_item_selected(index: int) -> void:
	setting_changed.emit("map_resource_path", maps.values()[index])
	
func _on_mode_item_selected(index: int) -> void:
	pass # Replace with function body. 

func _score_target_changed(value: float) -> void:
	setting_changed.emit("score_target", value as int)

func _respawn_time_changed(value: float) -> void:
	setting_changed.emit("respawn_time", value)
