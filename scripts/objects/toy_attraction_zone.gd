class_name ToyAttractionZone
extends Node2D

const UI_THEME_SCRIPT := preload("res://scripts/ui/hand_drawn_theme.gd")

var cells: Array[Vector2i] = []
var cell_size: int = 64
var ui_theme := UI_THEME_SCRIPT.new()


func configure(effect_cells: Array[Vector2i], board: GridSystem) -> void:
	cells = effect_cells
	cell_size = board.cell_size
	queue_redraw()


func _draw() -> void:
	for cell in cells:
		var rect := Rect2(Vector2(cell.x, cell.y) * float(cell_size), Vector2.ONE * float(cell_size))
		draw_rect(rect, ui_theme.TOY_SMOKE)

		var center := rect.get_center()
		var radius := cell_size * 0.16
		draw_circle(center + Vector2(-cell_size * 0.12, -cell_size * 0.04), radius, Color(1.0, 0.80, 0.28, 0.30))
		draw_circle(center + Vector2(cell_size * 0.12, cell_size * 0.05), radius * 0.82, Color(0.96, 0.52, 0.14, 0.22))
		draw_circle(center + Vector2(0.0, -cell_size * 0.16), radius * 0.58, Color(1.0, 0.92, 0.52, 0.26))
