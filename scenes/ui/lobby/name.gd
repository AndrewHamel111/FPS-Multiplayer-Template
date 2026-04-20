extends Panel

func set_text(value: String) -> void:
	($MarginContainer/Label as Label).text = value
