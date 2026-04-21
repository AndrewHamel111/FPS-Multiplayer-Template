class_name LobbyManager
extends PanelContainer

signal start_game_pressed
signal setting_changed(setting: String, value: Variant)

@onready var name_scene: PackedScene = load("res://scenes/ui/lobby/name.tscn")
@onready var map_library : MapLibrary = load("res://maps/default_maps.tres")

@onready var player_list: VBoxContainer = $HBoxContainer/MarginContainer/VBoxContainer/PlayerList/MarginContainer2/VBoxContainer
#@onready var chat_box: VBoxContainer = $HBoxContainer/MarginContainer/VBoxContainer/Chat/MarginContainer/VBoxContainer/VBoxContainer
#@onready var chat_input: LineEdit = $HBoxContainer/MarginContainer/VBoxContainer/Chat/MarginContainer/VBoxContainer/Panel2

@onready var selected_map_name: Label = $HBoxContainer/MarginContainer2/VBoxContainer2/MarginContainer/Label3
@onready var selected_map_preview: TextureRect = $HBoxContainer/MarginContainer2/VBoxContainer2/TextureRect

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
	for m in map_library.maps:
		map.add_item(m)
		
	mode.clear()
	mode.add_item("Deathmatch")

func set_host_mode(value: bool = true) -> void:
	for option in host_only_options:
		disable_control(host_only_options[option], value)
	
	start_button.text = "Start Game" if value else "Only Host Can Start Game"
	start_button.disabled = not value

func disable_control(control: Control, state: bool = false) -> void:
	if control is SpinBox:
		(control as SpinBox).editable = state
	if control is OptionButton:
		(control as OptionButton).disabled = not state

func set_player_list(players: Array[User]) -> void:
	for node in player_list.get_children():
		player_list.remove_child(node)
		node.queue_free()
	
	for player in players:
		var label := name_scene.instantiate()
		label.set_text(player.username)
		player_list.add_child(label)

func set_game_rules(game_rules: GameRules) -> void:
	map.selected = map_library.maps.keys().find(game_rules.map)
	selected_map_name.text = game_rules.map
	selected_map_preview.texture = map_library.maps[game_rules.map].map_preview
	#mode.selected = game_rules.mode
	score_target.value = game_rules.score_target
	respawn_time.value = game_rules.respawn_time

#  button handlers
func _on_start_match_pressed() -> void:
	start_game_pressed.emit()

func _on_map_item_selected(index: int) -> void:
	var map_name : String = map_library.maps.keys()[index]
	setting_changed.emit("map", map_name)
	selected_map_name.text = map_name
	selected_map_preview.texture = map_library.maps[map_name].map_preview
	
func _on_mode_item_selected(_index: int) -> void: 
	pass # Replace with function body. 

func _score_target_changed(value: float) -> void:
	setting_changed.emit("score_target", value as int)

func _respawn_time_changed(value: float) -> void:
	setting_changed.emit("respawn_time", value)
