class_name BoardToken
extends Node2D

const UI_THEME_SCRIPT := preload("res://scripts/ui/hand_drawn_theme.gd")

@export var token_id: StringName = &"wall"
@export var label: String = "?"
@export var color: Color = Color.WHITE
@export var cell_size: int = 64

var grid_position: Vector2i = Vector2i.ZERO
var ui_theme := UI_THEME_SCRIPT.new()


func configure(id: StringName, next_label: String, next_color: Color, cell: Vector2i, board: GridSystem) -> void:
	token_id = id
	label = next_label
	color = next_color
	cell_size = board.cell_size
	grid_position = cell
	position = board.grid_to_local_center(cell)
	queue_redraw()


func _draw() -> void:
	var radius := cell_size * 0.28
	draw_circle(Vector2(radius * 0.18, radius * 0.22), radius * 1.05, Color(0.10, 0.07, 0.04, 0.20))
	match token_id:
		&"obstacle_wall":
			_draw_wobbly_box(radius, color, ui_theme.INK, 4.0)
			draw_line(Vector2(-radius * 0.86, -radius * 0.22), Vector2(radius * 0.82, -radius * 0.31), ui_theme.INK, 3.0)
			draw_line(Vector2(-radius * 0.74, radius * 0.27), Vector2(radius * 0.88, radius * 0.19), ui_theme.INK, 3.0)
			draw_line(Vector2(-radius * 0.18, -radius * 0.86), Vector2(-radius * 0.22, radius * 0.82), ui_theme.INK, 2.5)
		&"wall":
			_draw_wobbly_box(radius, color, ui_theme.PAPER_LIGHT, 3.0)
			draw_line(Vector2(-radius * 0.7, 0), Vector2(radius * 0.72, -radius * 0.06), ui_theme.INK_FADED, 2.0)
		&"toy":
			draw_circle(Vector2.ZERO, radius, color)
			draw_circle(Vector2.ZERO, radius * 0.48, ui_theme.GOLD)
			draw_arc(Vector2.ZERO, radius, 0.15, TAU - 0.25, 26, ui_theme.INK, 3.2)
			draw_line(Vector2(-radius * 0.44, -radius * 0.12), Vector2(radius * 0.38, radius * 0.18), ui_theme.PAPER_LIGHT, 2.4)
			draw_circle(Vector2(radius * 0.24, -radius * 0.18), radius * 0.10, ui_theme.INK)
		&"trap":
			var trap_points := PackedVector2Array([
				Vector2(-radius, -radius * 0.10),
				Vector2(-radius * 0.54, -radius * 0.78),
				Vector2(-radius * 0.12, -radius * 0.08),
				Vector2(radius * 0.24, -radius * 0.72),
				Vector2(radius * 0.60, -radius * 0.12),
				Vector2(radius, -radius * 0.68),
				Vector2(radius * 0.92, radius * 0.72),
				Vector2(-radius * 0.94, radius * 0.78),
			])
			draw_polygon(trap_points, _colors(trap_points.size(), color))
			_draw_closed_line(trap_points, ui_theme.INK, 3.2)
			draw_line(Vector2(-radius * 0.62, radius * 0.46), Vector2(radius * 0.62, radius * 0.40), ui_theme.PAPER_LIGHT, 3.0)
			draw_line(Vector2(-radius * 0.28, radius * 0.25), Vector2(-radius * 0.34, radius * 0.66), ui_theme.PAPER_LIGHT, 2.0)
			draw_line(Vector2(radius * 0.26, radius * 0.24), Vector2(radius * 0.32, radius * 0.65), ui_theme.PAPER_LIGHT, 2.0)
		&"net":
			draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, 0.28))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, ui_theme.INK, 4.0)
			draw_arc(Vector2(1, -1), radius * 0.62, 0.0, TAU, 24, color, 3.0)
			draw_line(Vector2(-radius, -2), Vector2(radius, 2), color, 3.0)
			draw_line(Vector2(2, -radius), Vector2(-2, radius), color, 3.0)
			draw_line(Vector2(-radius * 0.72, -radius * 0.64), Vector2(radius * 0.70, radius * 0.78), color, 2.4)
			draw_line(Vector2(radius * 0.72, -radius * 0.72), Vector2(-radius * 0.68, radius * 0.70), color, 2.4)
			draw_line(Vector2(radius * 0.64, radius * 0.64), Vector2(radius * 1.05, radius * 1.05), ui_theme.INK, 5.0)
		&"ice":
			var ice_points := PackedVector2Array([
				Vector2(-radius * 0.90, -radius * 0.50),
				Vector2(-radius * 0.22, -radius),
				Vector2(radius * 0.82, -radius * 0.70),
				Vector2(radius, radius * 0.20),
				Vector2(radius * 0.24, radius),
				Vector2(-radius * 0.78, radius * 0.66),
			])
			draw_polygon(ice_points, _colors(ice_points.size(), color))
			_draw_closed_line(ice_points, ui_theme.PAPER_LIGHT, 3.0)
			draw_line(Vector2(-radius * 0.55, -radius * 0.1), Vector2(radius * 0.45, -radius * 0.55), Color.WHITE, 3.0)
			draw_line(Vector2(-radius * 0.35, radius * 0.45), Vector2(radius * 0.55, radius * 0.05), Color.WHITE, 3.0)
		_:
			draw_circle(Vector2.ZERO, radius, color)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 26, ui_theme.INK, 3.0)


func _draw_wobbly_box(radius: float, fill: Color, stroke: Color, width: float) -> void:
	var points := PackedVector2Array([
		Vector2(-radius * 0.92, -radius),
		Vector2(radius * 0.86, -radius * 0.94),
		Vector2(radius, radius * 0.84),
		Vector2(-radius * 0.82, radius),
	])
	draw_polygon(points, _colors(points.size(), fill))
	_draw_closed_line(points, stroke, width)


func _draw_closed_line(points: PackedVector2Array, stroke: Color, width: float) -> void:
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, stroke, width, true)


func _colors(count: int, fill: Color) -> PackedColorArray:
	var colors := PackedColorArray()
	for _index in range(count):
		colors.append(fill)
	return colors
