extends Node
# Сглаживатель поверхности мира

var world_data = []
var width = 0
var height = 0

func setup(p_world_data: Array):
	world_data = p_world_data
	height = world_data.size()
	if height > 0:
		width = world_data[0].size()

func smooth_surface(passes: int = 3):
	print("  Сглаживание поверхности...")
	for i in range(passes):
		_smooth_pass()
		_remove_surface_spikes()
	_fill_gaps()
	_remove_floating_islands()
	_ensure_grass_on_surface()
	print("  Поверхность сглажена")

func _smooth_pass():
	var changes = []
	for x in range(1, width - 1):
		var ground_y = _get_ground_level(x)
		if ground_y < 0: continue
		var left_y = _get_ground_level(x - 1)
		var right_y = _get_ground_level(x + 1)
		if left_y < 0 or right_y < 0: continue
		
		var avg = floori((left_y + right_y) / 2.0)
		var diff = ground_y - avg
		
		if abs(diff) > 2:
			if diff > 0:
				for dy in range(0, diff - 1):
					var y = ground_y - dy
					if y >= 0 and y < height:
						changes.append({"x": x, "y": y, "action": "remove"})
			else:
				for dy in range(0, abs(diff) - 1):
					var y = ground_y + 1 + dy
					if y < height:
						changes.append({"x": x, "y": y, "action": "add_dirt"})
	
	for change in changes:
		var x = change["x"]
		var y = change["y"]
		if x >= 0 and x < width and y >= 0 and y < height:
			if change["action"] == "remove":
				world_data[y][x] = -1
			elif change["action"] == "add_dirt":
				if world_data[y][x] == -1:
					world_data[y][x] = 0

func _remove_surface_spikes():
	for x in range(2, width - 2):
		var ground_y = _get_ground_level(x)
		if ground_y < 0: continue
		var left_y = _get_ground_level(x - 1)
		var right_y = _get_ground_level(x + 1)
		if left_y < 0 or right_y < 0: continue
		
		if ground_y < left_y - 3 and ground_y < right_y - 3:
			var target = floori((left_y + right_y) / 2.0)
			for dy in range(0, target - ground_y + 1):
				var y = ground_y - dy
				if y >= 0:
					world_data[y][x] = -1

func _fill_gaps():
	for x in range(2, width - 2):
		var ground_y = _get_ground_level(x)
		if ground_y < 0: continue
		var left_y = _get_ground_level(x - 1)
		var right_y = _get_ground_level(x + 1)
		if left_y < 0 or right_y < 0: continue
		
		if ground_y > left_y + 1 and ground_y > right_y + 1:
			var fill_to = max(left_y, right_y)
			for dy in range(0, ground_y - fill_to):
				var y = ground_y - dy
				if y >= 0 and y < height:
					world_data[y][x] = 0

func _remove_floating_islands():
	for x in range(width):
		for y in range(1, height - 1):
			if world_data[y][x] == -1 or world_data[y][x] == 5: continue
			var has_support = false
			for check_y in range(y + 1, min(y + 15, height)):
				if world_data[check_y][x] != -1:
					has_support = true
					break
				if x > 0 and world_data[check_y][x - 1] != -1:
					has_support = true
					break
				if x < width - 1 and world_data[check_y][x + 1] != -1:
					has_support = true
					break
			if not has_support:
				world_data[y][x] = -1

func _ensure_grass_on_surface():
	for x in range(width):
		var ground_y = _get_ground_level(x)
		if ground_y >= 0 and ground_y < height:
			if world_data[ground_y][x] != -1 and world_data[ground_y][x] != 5:
				world_data[ground_y][x] = 2

func _get_ground_level(x: int) -> int:
	for y in range(height):
		if world_data[y][x] != -1 and world_data[y][x] != 5:
			return y
	return -1
