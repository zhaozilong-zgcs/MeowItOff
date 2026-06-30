class_name GridSystem
extends Node2D

const UI_THEME_SCRIPT := preload("res://scripts/ui/hand_drawn_theme.gd")

signal cell_selected(cell: Vector2i)

@export var cell_size: int = 68

var board_size: Vector2i = Vector2i(10, 10)
var button_position: Vector2i = Vector2i(9, 0)
var blocked_cells: Dictionary = {}
var highlights: Dictionary = {}
var ui_theme := UI_THEME_SCRIPT.new()


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


func set_highlights(cells: Array[Vector2i], color: Color, style: StringName = &"fill") -> void:
	highlights.clear()
	for cell in cells:
		if is_inside(cell):
			highlights[cell] = {
				"color": color,
				"style": style,
			}
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
	draw_rect(Rect2(Vector2.ZERO, board_pixel_size), ui_theme.INK)

	for y in board_size.y:
		for x in board_size.x:
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(x, y) * float(cell_size), Vector2.ONE * float(cell_size))
			var base_color := ui_theme.BOARD_LIGHT if (x + y) % 2 == 0 else ui_theme.BOARD_DARK
			draw_rect(rect, base_color)
			draw_rect(rect.grow(-1.0), Color(1.0, 0.92, 0.70, 0.06))

			if highlights.has(cell):
				var highlight: Dictionary = highlights[cell]
				var highlight_color: Color = highlight.get("color", Color.WHITE)
				var highlight_style: StringName = highlight.get("style", &"fill")
				if highlight_style == &"border":
					draw_rect(rect.grow(-5.0), highlight_color, false, 4.0)
				else:
					draw_rect(rect, highlight_color)

			if blocked_cells.has(cell):
				draw_rect(rect.grow(-8.0), Color(0.42, 0.22, 0.20, 0.88))

			draw_rect(rect, ui_theme.BOARD_LINE, false, 2.0)
			draw_line(rect.position + Vector2(2.0, 1.0), rect.position + Vector2(rect.size.x - 2.0, 0.0), Color(0.98, 0.88, 0.66, 0.12), 1.0)
			draw_line(rect.position + Vector2(1.0, rect.size.y - 2.0), rect.position + Vector2(rect.size.x - 1.0, rect.size.y - 1.0), Color(0.02, 0.02, 0.02, 0.16), 1.0)

	var button_center := grid_to_local_center(button_position)
	draw_circle(button_center, cell_size * 0.28, Color(0.94, 0.18, 0.42))
	draw_arc(button_center, cell_size * 0.28, 0.0, TAU, 28, ui_theme.INK, 4.0)
	draw_circle(button_center, cell_size * 0.17, Color(1.0, 0.80, 0.72))
