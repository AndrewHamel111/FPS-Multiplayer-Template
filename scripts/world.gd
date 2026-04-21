extends Node

@onready var menu_music: AudioStreamPlayer = %MenuMusic

@onready var map_library : MapLibrary = load("res://maps/default_maps.tres")
const PlayerScene = preload("res://player.tscn")
const UserScene = preload("res://scenes/networking/user.tscn")
const GameRulesScene = preload("res://scenes/networking/game_rules.tscn")
const PORT = 9999
const PLAYER_HEALTH_DEFAULT = 2
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var paused: bool = false
var controller: bool = false

enum GameState
{
	PRE = 0,
	STARTING,
	STARTED
}
var state: GameState = GameState.PRE

var loading_players: Array[int]

@onready var menu_manager := $Menu as MenuManager
@onready var current_level : Map

func _ready() -> void:
	menu_manager.host_pressed.connect(_on_host_button_pressed)
	menu_manager.join_pressed.connect(join_game)
	menu_manager.pause_state_changed.connect(set_pause)
	menu_manager.exit_lobby.connect(_on_exit_lobby)
	menu_manager.lobby.start_game.connect(start_game)
	menu_manager.show_menu(Menu.MAIN)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		if !paused and menu_manager.is_menu(Menu.NONE):
			set_pause(true)
		else:
			menu_manager.handle_back()
	if event is InputEventJoypadMotion:
		controller = true
	elif event is InputEventMouseMotion:
		controller = false

#func _on_resume_pressed() -> void:
func set_pause(is_paused: bool) -> void:
	if !controller and !is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	paused = is_paused
	
	if is_paused:
		menu_manager.show_menu(Menu.PAUSE)

#func _ready() -> void:
func _on_host_button_pressed() -> void:
	menu_manager.show_menu(Menu.LOBBY)
	menu_music.stop()

	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	var new_user := UserScene.instantiate() as User
	new_user.name = "%d" % multiplayer.get_unique_id() # should always be 1 anyway :P
	new_user.username = menu_manager.name_entry.text
	$Users.add_child(new_user)
	
	var game_rules : GameRules = get_node_or_null("GameRules")
	if not game_rules:
		game_rules = GameRulesScene.instantiate()
		add_child(game_rules)
	game_rules.changed.connect(_update_game_rules_ui)

	#upnp_setup()
	
	menu_manager.lobby.set_host_mode(true)
	menu_manager.lobby.set_player_list(get_player_list())
	menu_manager.lobby.setting_changed.connect(_on_setting_changed)
	menu_manager.lobby.set_game_rules(game_rules)

func start_game() -> void:
	state = GameState.STARTING
	loading_players = []
	for user in get_player_list():
		loading_players.push_back(user.get_name().to_int())
	_prepare_client.rpc()

#func _on_join_button_pressed() -> void:
func join_game(address: String) -> void:
	menu_manager.hide_all()
	menu_music.stop()
	
	enet_peer.create_client(address, PORT)
	multiplayer.multiplayer_peer = enet_peer

@rpc("any_peer", "call_remote", "reliable")
func _on_connected_to_host(server_state: int) -> void:
	var peer := multiplayer.get_unique_id()
	var my_user := get_node("Users/%d" % peer) as User
	if not my_user:
		push_error("Failed to get user in _on_connected_to_host")
	my_user.username = menu_manager.name_entry.text
	
	multiplayer.server_disconnected.connect(_on_host_disconnected)
	
	if server_state as GameState == GameState.PRE:
		menu_manager.show_menu(Menu.LOBBY)
		menu_manager.lobby.set_host_mode(false)
		menu_manager.lobby.set_player_list(get_player_list())
		(get_node("GameRules") as GameRules).changed.connect(_update_game_rules_ui)

func get_player_list() -> Array[User]:
	var users: Array[User] = []
	for user in $Users.get_children():
		if user is User:
			users.push_back(user as User)
	return users

@rpc("any_peer", "call_local", "reliable")
func _player_list_changed() -> void:
	menu_manager.lobby.set_player_list(get_player_list())

@rpc("any_peer", "call_local", "reliable")
func _prepare_client() -> void:
	menu_manager.show_menu(Menu.LOADING)
	var game_rules := get_node("GameRules") as GameRules
	var map_to_load := game_rules.map
	
	var on_complete := func(map_scene: PackedScene) -> void:
		var map := map_scene.instantiate()
		$Map.add_child(map)
		current_level = map as Map
		_on_client_loading_complete()
	
	var update_progress := func(progress: float) -> void:
		menu_manager.loading_progress_bar.value = progress
	
	MapLoader.load_map(map_library.maps[map_to_load].map_resource_path, on_complete, update_progress)

func _on_client_loading_complete() -> void:
	_client_finished_loading.rpc_id(1, multiplayer.get_unique_id())

@rpc("any_peer", "call_local", "reliable")
func _client_finished_loading(peer_id: int) -> void:
	loading_players.erase(peer_id)
	if loading_players.is_empty():
		finally_start_game()

func finally_start_game() -> void:
	state = GameState.STARTED
	for user in get_player_list():
		add_player(user.get_name().to_int())
	_on_start_game.rpc()

@rpc("any_peer", "call_local", "reliable")
func _on_start_game() -> void:
	menu_manager.hide_all()
	# play game started sting / chime / music

#func _on_music_toggle_toggled(toggled_on: bool) -> void:
	#if !toggled_on:
		#menu_music.stop()
	#else:
		#menu_music.play()

func _on_peer_connected(peer_id: int) -> void:
	var new_user := UserScene.instantiate() as User
	new_user.name = "%d" % peer_id
	new_user.name_changed.connect(func()->void: _player_list_changed())
	$Users.add_child(new_user)
	
	_on_connected_to_host.rpc_id(peer_id, state)
	
	if state == GameState.STARTED:
		add_player(peer_id)
	elif state == GameState.STARTING:
		loading_players.push_back(peer_id)
		_prepare_client.rpc_id(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	if state == GameState.STARTED:
		remove_player(peer_id)
	elif state == GameState.STARTING:
		var user := get_node("Users/%d" % peer_id) as User
		$Users.remove_child(user)
		user.free()
		_client_finished_loading(peer_id)
	else:
		var user := get_node("Users/%d" % peer_id) as User
		$Users.remove_child(user)
		user.free()
		_player_list_changed.rpc()

func _on_host_disconnected() -> void:
	# TODO: modal menu explaining disconnect reason
	menu_manager.show_menu(Menu.MAIN)

func add_player(peer_id: int) -> void:
	var player: Player = PlayerScene.instantiate()
	player.name = str(peer_id)
	add_child(player)
	player.on_death.connect(_on_player_death)
	_on_player_death(player)

func remove_player(peer_id: int) -> void:
	var player: Node = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func upnp_setup() -> void:
	var upnp: UPNP = UPNP.new()

	upnp.discover()
	upnp.add_port_mapping(PORT)

	var ip: String = upnp.query_external_address()
	if ip == "":
		print("Failed to establish upnp connection!")
	else:
		print("Success! Join Address: %s" % upnp.query_external_address())

func get_player_spawn() -> Node3D:
	if not current_level:
		return null
	
	return current_level.spawns.pick_random() as Node3D

func _on_player_death(player: Player) -> void:
	player.health = PLAYER_HEALTH_DEFAULT
	var spawn := get_player_spawn()
	player.position = spawn.position
	player.rotation = spawn.rotation

func _on_user_spawner_spawned(node: Node) -> void:
	(node as User).name_changed.connect(func() -> void: _player_list_changed())

func _on_setting_changed(setting: String, value: Variant) -> void:
	var rules := get_node("GameRules") as GameRules
	rules.set(setting, value)
	rules.changed.emit()

func _update_game_rules_ui() -> void:
	menu_manager.lobby.set_game_rules(get_node("GameRules") as GameRules)

func _on_exit_lobby() -> void:
	if multiplayer and multiplayer:
		multiplayer.multiplayer_peer.close()
	for user in $Users.get_children():
		$Users.remove_child(user)
		user.free()
	#get_tree().reload_current_scene()
