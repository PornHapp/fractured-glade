extends CanvasLayer

func _ready():
	# Изначально меню спрятано
	visible = false

func open_menu():
	visible = true
	get_tree().paused = true # Ставим игру на паузу

func close_menu():
	visible = false
	get_tree().paused = false # Снимаем с паузы
