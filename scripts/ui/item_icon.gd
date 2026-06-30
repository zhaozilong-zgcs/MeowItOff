class_name ItemIcon
extends Control

const UI_THEME_SCRIPT := preload("res://scripts/ui/hand_drawn_theme.gd")

@export var token_id: StringName = &"wall"
@export var color: Color = Color.WHITE

var ui_theme := UI_THEME_SCRIPT.new()


func configure(id: StringName, next_color: Color) -> void:
	token_id = id
	color = next_color
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	draw_circle(center + Vector2(radius * 0.18, radius * 0.22), radius * 1.04, Color(0.10, 0.07, 0.04, 0.16))

	match token_id:
		&"obstacle_wall":
			_draw_obstacle_wall(center, radius)
		&"wall":
			_draw_item_wall(center, radius)
		&"toy":
			_draw_toy(center, radius)
		&"trap":
			_draw_trap(center, radius)
		&"net":
			_draw_net(center, radius)
		&"ice":
			_draw_ice(center, radius)
		&"button":
			_draw_button(center, radius)
		&"cat":
			_draw_cat(center, radius)
		&"player":
			_draw_player(center, radius)
		&"eraser":
			_draw_eraser(center, radius)
		_:
			draw_circle(center, radius, color)
			draw_arc(center, radius, 0.0, TAU, 26, ui_theme.INK, 3.0)


func _draw_obstacle_wall(center: Vector2, radius: float) -> void:
	_draw_wobbly_box(center, radius, color, ui_theme.INK, 4.0)
	draw_line(center + Vector2(-radius * 0.86, -radius * 0.22), center + Vector2(radius * 0.82, -radius * 0.31), ui_theme.INK, 3.0)
	draw_line(center + Vector2(-radius * 0.74, radius * 0.27), center + Vector2(radius * 0.88, radius * 0.19), ui_theme.INK, 3.0)
	draw_line(center + Vector2(-radius * 0.18, -radius * 0.86), center + Vector2(-radius * 0.22, radius * 0.82), ui_theme.INK, 2.5)


func _draw_item_wall(center: Vector2, radius: float) -> void:
	_draw_wobbly_box(center, radius, color, ui_theme.PAPER_LIGHT, 3.0)
	draw_line(center + Vector2(-radius * 0.7, 0), center + Vector2(radius * 0.72, -radius * 0.06), ui_theme.INK_FADED, 2.0)


func _draw_toy(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, color)
	draw_circle(center, radius * 0.48, ui_theme.GOLD)
	draw_arc(center, radius, 0.15, TAU - 0.25, 26, ui_theme.INK, 3.2)
	draw_line(center + Vector2(-radius * 0.44, -radius * 0.12), center + Vector2(radius * 0.38, radius * 0.18), ui_theme.PAPER_LIGHT, 2.4)
	draw_circle(center + Vector2(radius * 0.24, -radius * 0.18), radius * 0.10, ui_theme.INK)


func _draw_trap(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(-radius, -radius * 0.10),
		center + Vector2(-radius * 0.54, -radius * 0.78),
		center + Vector2(-radius * 0.12, -radius * 0.08),
		center + Vector2(radius * 0.24, -radius * 0.72),
		center + Vector2(radius * 0.60, -radius * 0.12),
		center + Vector2(radius, -radius * 0.68),
		center + Vector2(radius * 0.92, radius * 0.72),
		center + Vector2(-radius * 0.94, radius * 0.78),
	])
	draw_polygon(points, _colors(points.size(), color))
	_draw_closed_line(points, ui_theme.INK, 3.2)
	draw_line(center + Vector2(-radius * 0.62, radius * 0.46), center + Vector2(radius * 0.62, radius * 0.40), ui_theme.PAPER_LIGHT, 3.0)
	draw_line(center + Vector2(-radius * 0.28, radius * 0.25), center + Vector2(-radius * 0.34, radius * 0.66), ui_theme.PAPER_LIGHT, 2.0)
	draw_line(center + Vector2(radius * 0.26, radius * 0.24), center + Vector2(radius * 0.32, radius * 0.65), ui_theme.PAPER_LIGHT, 2.0)


func _draw_net(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, Color(color.r, color.g, color.b, 0.28))
	draw_arc(center, radius, 0.0, TAU, 32, ui_theme.INK, 4.0)
	draw_arc(center + Vector2(1, -1), radius * 0.62, 0.0, TAU, 24, color, 3.0)
	draw_line(center + Vector2(-radius, -2), center + Vector2(radius, 2), color, 3.0)
	draw_line(center + Vector2(2, -radius), center + Vector2(-2, radius), color, 3.0)
	draw_line(center + Vector2(-radius * 0.72, -radius * 0.64), center + Vector2(radius * 0.70, radius * 0.78), color, 2.4)
	draw_line(center + Vector2(radius * 0.72, -radius * 0.72), center + Vector2(-radius * 0.68, radius * 0.70), color, 2.4)
	draw_line(center + Vector2(radius * 0.64, radius * 0.64), center + Vector2(radius * 1.05, radius * 1.05), ui_theme.INK, 5.0)


func _draw_ice(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(-radius * 0.90, -radius * 0.50),
		center + Vector2(-radius * 0.22, -radius),
		center + Vector2(radius * 0.82, -radius * 0.70),
		center + Vector2(radius, radius * 0.20),
		center + Vector2(radius * 0.24, radius),
		center + Vector2(-radius * 0.78, radius * 0.66),
	])
	draw_polygon(points, _colors(points.size(), color))
	_draw_closed_line(points, ui_theme.PAPER_LIGHT, 3.0)
	draw_line(center + Vector2(-radius * 0.55, -radius * 0.1), center + Vector2(radius * 0.45, -radius * 0.55), Color.WHITE, 3.0)
	draw_line(center + Vector2(-radius * 0.35, radius * 0.45), center + Vector2(radius * 0.55, radius * 0.05), Color.WHITE, 3.0)


func _draw_button(center: Vector2, radius: float) -> void:
	draw_circle(center, radius * 0.88, color)
	draw_arc(center, radius * 0.88, 0.0, TAU, 28, ui_theme.INK, 3.2)
	draw_circle(center, radius * 0.50, Color(1.0, 0.80, 0.72))


func _draw_cat(center: Vector2, radius: float) -> void:
	draw_circle(center, radius * 0.78, color)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-radius * 0.58, -radius * 0.42),
			center + Vector2(-radius * 0.34, -radius),
			center + Vector2(-radius * 0.08, -radius * 0.48),
		]),
		_colors(3, color)
	)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(radius * 0.58, -radius * 0.42),
			center + Vector2(radius * 0.34, -radius),
			center + Vector2(radius * 0.08, -radius * 0.48),
		]),
		_colors(3, color)
	)
	draw_circle(center + Vector2(-radius * 0.25, -radius * 0.06), radius * 0.12, ui_theme.GOLD)
	draw_circle(center + Vector2(radius * 0.25, -radius * 0.06), radius * 0.12, ui_theme.GOLD)
	draw_circle(center + Vector2(0, radius * 0.20), radius * 0.08, Color(1.0, 0.52, 0.48))


func _draw_player(center: Vector2, radius: float) -> void:
	draw_circle(center + Vector2(0, -radius * 0.34), radius * 0.30, color)
	draw_arc(center + Vector2(0, -radius * 0.34), radius * 0.30, 0.0, TAU, 24, ui_theme.INK, 2.8)
	var body := Rect2(center + Vector2(-radius * 0.38, radius * 0.02), Vector2(radius * 0.76, radius * 0.78))
	draw_rect(body, Color(0.25, 0.50, 0.72))
	draw_rect(body, ui_theme.INK, false, 2.8)
	draw_line(center + Vector2(-radius * 0.56, radius * 0.18), center + Vector2(radius * 0.56, radius * 0.18), ui_theme.INK, 2.4)


func _draw_eraser(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(-radius * 0.92, radius * 0.08),
		center + Vector2(-radius * 0.22, -radius * 0.72),
		center + Vector2(radius * 0.92, -radius * 0.18),
		center + Vector2(radius * 0.22, radius * 0.72),
	])
	draw_polygon(points, _colors(points.size(), color))
	_draw_closed_line(points, ui_theme.INK, 3.0)
	draw_line(center + Vector2(-radius * 0.20, -radius * 0.64), center + Vector2(radius * 0.34, radius * 0.52), ui_theme.PAPER_LIGHT, 2.2)


func _draw_wobbly_box(center: Vector2, radius: float, fill: Color, stroke: Color, width: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(-radius * 0.92, -radius),
		center + Vector2(radius * 0.86, -radius * 0.94),
		center + Vector2(radius, radius * 0.84),
		center + Vector2(-radius * 0.82, radius),
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
