extends Node

@onready var menu_music: AudioStreamPlayer = %MenuMusic

const PlayerScene = preload("res://player.tscn")
const UserScene = preload("res://scenes/networking/user.tscn")
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
@onready var current_level := $Map.get_child(0) as Map

func _ready() -> void:
	menu_manager.host_pressed.connect(_on_host_button_pressed)
	menu_manager.join_pressed.connect(join_game)
	menu_manager.pause_state_changed.connect(set_pause)
	menu_manager.lobby.start_game.connect(start_game)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("pause"):
		if !paused and menu_manager.is_menu(Menu.NONE):
			paused = true
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
	paused = is_paused
	
	if is_paused:
		menu_manager.show_menu(Menu.PAUSE)

#func _ready() -> void:
func _on_host_button_pressed() -> void:
	menu_manager.show_menu(Menu.LOBBY)
	$Menu/DollyCamera.hide()
	menu_music.stop()

	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	var new_user := UserScene.instantiate() as User
	new_user.name = "%d" % multiplayer.get_unique_id() # should always be 1 anyway :P
	new_user.username = menu_manager.name_entry.text
	$Users.add_child(new_user)

	#upnp_setup()
	
	menu_manager.lobby.set_host_mode(true)
	menu_manager.lobby.set_player_list(get_player_list())

func start_game() -> void:
	state = GameState.STARTING
	# TODO: for each user, append their peer id to this list
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
func _on_connected_to_host() -> void:
	menu_manager.show_menu(Menu.LOBBY)
	menu_manager.lobby.set_host_mode(false)
	
	# set username
	var peer := multiplayer.get_unique_id()
	var my_user := get_node("Users/%d" % peer) as User
	if not my_user:
		push_error("Failed to get user in _on_connected_to_host")
	my_user.username = menu_manager.name_entry.text
	
	menu_manager.lobby.set_player_list(get_player_list())

func get_player_list() -> Array[User]:
	var users: Array[User] = []
	for user in $Users.get_children():
		if user is User:
			users.push_back(user as User)
	return users

@rpc("any_peer", "call_local", "reliable")
func _prepare_client() -> void:
	menu_manager.show_menu(Menu.LOADING)
	# TODO: check "game configuration" object synced in tree for following information
	# game rules
	# game map
	
	# TODO: load map
	# tell the server when loading is done
	get_tree().create_timer(randf_range(1.5, 5.0)).timeout.connect(_on_client_loading_complete)

func _on_client_loading_complete() -> void:
	# TODO: is this the appropriate way for a client to get it's own unique id?
	_client_finished_loading.rpc_id(1, multiplayer.get_unique_id())

@rpc("any_peer", "call_local", "reliable")
func _client_finished_loading(peer_id: int) -> void:
	loading_players.erase(peer_id)
	if loading_players.is_empty():
		finally_start_game()

func finally_start_game() -> void:
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
	$Users.add_child(new_user)
	
	if state == GameState.STARTED:
		add_player(peer_id)
	elif state == GameState.STARTING:
		# TODO: idk, maybe we can tell the peer they can't connect while the game is starting?
		# or maybe we just let their game hang for a second until everyone else has loaded, or
		# do we just add them to the "loading queue"?
		pass
	else:
		_on_connected_to_host.rpc_id(peer_id)
	
	menu_manager.lobby.set_player_list(get_player_list())

func _on_peer_disconnected(peer_id: int) -> void:
	if state == GameState.STARTED:
		remove_player(peer_id)
	elif state == GameState.STARTING:
		# TODO: handle peer disconnect while game is loading
		pass
	else:
		# TODO: handle peer disconnect from lobby view
		pass

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
