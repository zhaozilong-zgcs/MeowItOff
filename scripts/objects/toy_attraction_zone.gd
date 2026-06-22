class_name ToyAttractionZone
extends Node2D

var cells: Array[Vector2i] = []
var cell_size: int = 64


func configure(effect_cells: Array[Vector2i], board: GridSystem) -> void:
	cells = effect_cells
	cell_size = board.cell_size
	queue_redraw()


func _draw() -> void:
	for cell in cells:
		var rect := Rect2(Vector2(cell.x, cell.y) * float(cell_size), Vector2.ONE * float(cell_size))
		draw_rect(rect, Color(1.0, 0.74, 0.18, 0.20))

		var center := rect.get_center()
		var radius := cell_size * 0.16
		draw_circle(center + Vector2(-cell_size * 0.12, -cell_size * 0.04), radius, Color(1.0, 0.82, 0.25, 0.34))
		draw_circle(center + Vector2(cell_size * 0.12, cell_size * 0.05), radius * 0.82, Color(1.0, 0.64, 0.12, 0.24))
		draw_circle(center + Vector2(0.0, -cell_size * 0.16), radius * 0.58, Color(1.0, 0.92, 0.48, 0.28))
