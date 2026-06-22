class_name PathfindingSystem
extends Node


func find_path(start: Vector2i, goal: Vector2i, grid: GridSystem) -> Array[Vector2i]:
	if start == goal:
		var single_cell_path: Array[Vector2i] = [start]
		return single_cell_path

	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {}
	var f_score: Dictionary = {}
	g_score[start] = 0
	f_score[start] = _heuristic(start, goal)

	while not open_set.is_empty():
		var current := _lowest_f_score(open_set, f_score)
		if current == goal:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in grid.get_cardinal_neighbors(current):
			if grid.is_blocked(neighbor) and neighbor != goal:
				continue

			var tentative_g := int(g_score[current]) + 1
			if tentative_g >= int(g_score.get(neighbor, 999999)):
				continue

			came_from[neighbor] = current
			g_score[neighbor] = tentative_g
			f_score[neighbor] = tentative_g + _heuristic(neighbor, goal)

			if not open_set.has(neighbor):
				open_set.append(neighbor)

	return []


func _lowest_f_score(open_set: Array[Vector2i], f_score: Dictionary) -> Vector2i:
	var best := open_set[0]
	var best_score := int(f_score.get(best, 999999))

	for cell in open_set:
		var score := int(f_score.get(cell, 999999))
		if score < best_score:
			best = cell
			best_score = score

	return best


func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)

	return path
