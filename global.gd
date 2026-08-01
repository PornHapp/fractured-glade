extends Node

var world_width = 1000 # или то число, которое ты хочешь
var world_height = 1000 
var world_seed = 12345
var world_name = "Мой мир"
var return_from_loading = false
var temp_world_data = {}

# Функция сохранения мира в файл
func save_new_world(data: Dictionary):
	# Проверяем, есть ли папка для сохранений, и создаем её, если нет
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("worlds"):
		dir.make_dir("worlds")
		
	# Создаем уникальное имя файла с помощью текущего времени
	var file_name = "user://worlds/world_" + str(Time.get_unix_time_from_system()) + ".save"
	
	# Открываем файл и записываем туда наш словарь с данными
	var file = FileAccess.open(file_name, FileAccess.WRITE)
	file.store_var(data)
	file.close()
	print("Мир успешно сохранен в: ", file_name)
