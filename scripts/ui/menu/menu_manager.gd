class_name MenuManager
extends CanvasLayer

signal join_pressed(address: String)
signal host_pressed
signal pause_state_changed(is_paused: bool)

@onready var menus : Dictionary[int, PanelContainer] = {
	Menu.MAIN: $MainMenu,
	Menu.OPTIONS: $Options,
	Menu.PAUSE: $PauseMenu,
	Menu.LOBBY: $LobbyMenu,
}

@onready var blur : ColorRect = $Blur
@onready var lobby : LobbyManager = $LobbyMenu
@onready var name_entry: LineEdit = $MainMenu/MarginContainer/VBoxContainer/HBoxContainer2/NameEntry

var options_opened_from_pause : bool

func show_menu(menu: int) -> void:
	hide_all()
	blur.show()
	menus[menu].show()

func hide_all() -> void:
	for m in menus:
		menus[m].hide()
	blur.hide()

func is_menu(menu: int) -> bool:
	if menu == Menu.NONE:
		var value := true
		for m in menus:
			value = value and (not menus[m].visible)
		return value
	
	return menus[menu].visible

func handle_back() -> void:
	if is_menu(Menu.OPTIONS) and not options_opened_from_pause:
		show_menu(Menu.MAIN)
	elif is_menu(Menu.OPTIONS) and options_opened_from_pause:
		show_menu(Menu.PAUSE)
	elif is_menu(Menu.PAUSE):
		_on_resume_pressed()

func _on_resume_pressed() -> void:
	hide_all()
	pause_state_changed.emit(false)

func _on_host_button_pressed() -> void:
	host_pressed.emit()

func _on_join_button_pressed() -> void:
	join_pressed.emit(%AddressEntry.text)

func _on_main_menu_options_pressed() -> void:
	options_opened_from_pause = false
	pause_state_changed.emit(true)
	show_menu(Menu.OPTIONS)

func _on_pause_options_pressed() -> void:
	options_opened_from_pause = true
	pause_state_changed.emit(true)
	show_menu(Menu.OPTIONS)

func _on_options_back_pressed() -> void:
	if options_opened_from_pause:
		show_menu(Menu.PAUSE)
	else:
		show_menu(Menu.MAIN)
