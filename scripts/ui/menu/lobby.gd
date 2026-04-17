class_name LobbyManager
extends PanelContainer

@onready var name_scene: PackedScene = load("res://scenes/ui/lobby/name.tscn")

@onready var player_list: VBoxContainer = $HBoxContainer/MarginContainer/VBoxContainer/PlayerList/MarginContainer2/VBoxContainer
#@onready var chat_box: VBoxContainer = $HBoxContainer/MarginContainer/VBoxContainer/Chat/MarginContainer/VBoxContainer/VBoxContainer
#@onready var chat_input: LineEdit = $HBoxContainer/MarginContainer/VBoxContainer/Chat/MarginContainer/VBoxContainer/Panel2

@onready var selected_map_name: Label = $HBoxContainer/MarginContainer2/VBoxContainer2/MarginContainer/Label3

@onready var host_only_options: Dictionary[String, Control] = {
	"map": $HBoxContainer/MarginContainer2/VBoxContainer2/HBoxContainer2/VBoxContainer2/OptionButton,
	"gamemode": $HBoxContainer/MarginContainer2/VBoxContainer2/HBoxContainer2/VBoxContainer2/OptionButton2,
	"score_target": $HBoxContainer/MarginContainer2/VBoxContainer2/HBoxContainer/VBoxContainer2/LineEdit,
	"respawn_time": $HBoxContainer/MarginContainer2/VBoxContainer2/HBoxContainer/VBoxContainer2/LineEdit2,
	"start_button": $HBoxContainer/MarginContainer2/VBoxContainer2/HostButton
}

func disable_control(control: Control, state: bool = false) -> void:
	if control is SpinBox:
		(control as SpinBox).editable = state
	if control is OptionButton:
		(control as OptionButton).disabled = not state

func set_host_mode(value: bool = true) -> void:
	for option in host_only_options:
		disable_control(host_only_options[option], value)
	
	var start_button := host_only_options["start_button"] as Button
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
