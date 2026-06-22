class_name BoardToken
extends Node2D

@export var token_id: StringName = &"wall"
@export var label: String = "?"
@export var color: Color = Color.WHITE
@export var cell_size: int = 64

var grid_position: Vector2i = Vector2i.ZERO


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
	match token_id:
		&"obstacle_wall":
			draw_rect(Rect2(Vector2.ONE * -radius, Vector2.ONE * radius * 2.0), color)
			draw_rect(Rect2(Vector2.ONE * -radius, Vector2.ONE * radius * 2.0), Color(0.12, 0.10, 0.12), false, 4.0)
			draw_line(Vector2(-radius, -radius * 0.25), Vector2(radius, -radius * 0.25), Color(0.12, 0.10, 0.12), 3.0)
			draw_line(Vector2(-radius, radius * 0.25), Vector2(radius, radius * 0.25), Color(0.12, 0.10, 0.12), 3.0)
		&"wall":
			draw_rect(Rect2(Vector2.ONE * -radius, Vector2.ONE * radius * 2.0), color)
			draw_rect(Rect2(Vector2.ONE * -radius, Vector2.ONE * radius * 2.0), Color(0.98, 0.86, 0.74), false, 3.0)
		&"toy":
			draw_circle(Vector2.ZERO, radius, color)
			draw_circle(Vector2.ZERO, radius * 0.48, Color(1.0, 0.91, 0.23))
		&"trap":
			draw_polygon(
				PackedVector2Array([
					Vector2(-radius, -radius * 0.15),
					Vector2(-radius * 0.55, -radius * 0.75),
					Vector2(-radius * 0.15, -radius * 0.15),
					Vector2(radius * 0.25, -radius * 0.75),
					Vector2(radius * 0.65, -radius * 0.15),
					Vector2(radius, -radius * 0.75),
					Vector2(radius, radius * 0.75),
					Vector2(-radius, radius * 0.75),
				]),
				PackedColorArray([color, color, color, color, color, color, color, color])
			)
			draw_rect(Rect2(Vector2(-radius, radius * 0.18), Vector2(radius * 2.0, radius * 0.62)), Color(0.05, 0.12, 0.14))
			draw_line(Vector2(-radius * 0.62, radius * 0.48), Vector2(radius * 0.62, radius * 0.48), Color.WHITE, 3.0)
			draw_line(Vector2(-radius * 0.28, radius * 0.28), Vector2(-radius * 0.28, radius * 0.68), Color.WHITE, 2.0)
			draw_line(Vector2(radius * 0.28, radius * 0.28), Vector2(radius * 0.28, radius * 0.68), Color.WHITE, 2.0)
		&"net":
			draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, 0.28))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, color, 5.0)
			draw_arc(Vector2.ZERO, radius * 0.62, 0.0, TAU, 32, color, 3.0)
			draw_line(Vector2(-radius, 0), Vector2(radius, 0), color, 3.0)
			draw_line(Vector2(0, -radius), Vector2(0, radius), color, 3.0)
			draw_line(Vector2(-radius * 0.72, -radius * 0.72), Vector2(radius * 0.72, radius * 0.72), color, 2.5)
			draw_line(Vector2(radius * 0.72, -radius * 0.72), Vector2(-radius * 0.72, radius * 0.72), color, 2.5)
			draw_line(Vector2(radius * 0.64, radius * 0.64), Vector2(radius * 1.05, radius * 1.05), color, 5.0)
		&"ice":
			draw_rect(Rect2(Vector2.ONE * -radius, Vector2.ONE * radius * 2.0), color)
			draw_rect(Rect2(Vector2.ONE * -radius, Vector2.ONE * radius * 2.0), Color.WHITE, false, 3.0)
			draw_line(Vector2(-radius * 0.55, -radius * 0.1), Vector2(radius * 0.45, -radius * 0.55), Color.WHITE, 3.0)
			draw_line(Vector2(-radius * 0.35, radius * 0.45), Vector2(radius * 0.55, radius * 0.05), Color.WHITE, 3.0)
		_:
			draw_circle(Vector2.ZERO, radius, color)
