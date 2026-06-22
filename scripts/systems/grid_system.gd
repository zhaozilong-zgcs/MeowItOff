class_name GridSystem
extends Node2D

signal cell_selected(cell: Vector2i)

@export var cell_size: int = 64

var board_size: Vector2i = Vector2i(10, 10)
var button_position: Vector2i = Vector2i(9, 0)
var blocked_cells: Dictionary = {}
var highlights: Dictionary = {}


func setup(next_board_size: Vector2i, next_button_position: Vector2i) -> void:
	board_size = next_board_size
	button_position = next_button_position
	blocked_cells.clear()
	clear_highlights()
	queue_redraw()


func grid_to_local_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size + cell_size * 0.5, cell.y * cell_size + cell_size * 0.5)


func world_to_grid(world_position: Vector2) -> Vector2i:
	var local_position := to_local(world_position)
	return Vector2i(floori(local_position.x / float(cell_size)), floori(local_position.y / float(cell_size)))


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < board_size.x and cell.y < board_size.y


func is_blocked(cell: Vector2i) -> bool:
	return blocked_cells.has(cell)


func set_blocked(cell: Vector2i, blocked: bool) -> void:
	if blocked:
		blocked_cells[cell] = true
	else:
		blocked_cells.erase(cell)
	queue_redraw()


func set_highlights(cells: Array[Vector2i], color: Color) -> void:
	highlights.clear()
	for cell in cells:
		if is_inside(cell):
			highlights[cell] = color
	queue_redraw()


func clear_highlights() -> void:
	highlights.clear()
	queue_redraw()


func get_cardinal_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
	]

	for offset in offsets:
		var neighbor := cell + offset
		if is_inside(neighbor):
			neighbors.append(neighbor)

	return neighbors


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var cell := world_to_grid(get_global_mouse_position())
			if is_inside(cell):
				cell_selected.emit(cell)


func _draw() -> void:
	var board_pixel_size := Vector2(board_size.x, board_size.y) * float(cell_size)
	draw_rect(Rect2(Vector2.ZERO, board_pixel_size), Color(0.38, 0.70, 0.65))

	for y in board_size.y:
		for x in board_size.x:
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(x, y) * float(cell_size), Vector2.ONE * float(cell_size))
			var base_color := Color(0.97, 0.88, 0.74) if (x + y) % 2 == 0 else Color(0.42, 0.75, 0.70)
			draw_rect(rect, base_color)

			if highlights.has(cell):
				draw_rect(rect.grow(-4.0), highlights[cell])

			if blocked_cells.has(cell):
				draw_rect(rect.grow(-7.0), Color(0.45, 0.24, 0.24))

			draw_rect(rect, Color(0.16, 0.37, 0.36, 0.45), false, 2.0)

	var button_center := grid_to_local_center(button_position)
	draw_circle(button_center, cell_size * 0.28, Color(0.94, 0.18, 0.42))
	draw_circle(button_center, cell_size * 0.18, Color(1.0, 0.83, 0.76))
