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
		&"wall":
			draw_rect(Rect2(Vector2.ONE * -radius, Vector2.ONE * radius * 2.0), color)
			draw_rect(Rect2(Vector2.ONE * -radius, Vector2.ONE * radius * 2.0), Color(0.98, 0.86, 0.74), false, 3.0)
		&"toy":
			draw_circle(Vector2.ZERO, radius, color)
			draw_circle(Vector2.ZERO, radius * 0.48, Color(1.0, 0.91, 0.23))
		&"trap":
			draw_polygon(
				PackedVector2Array([
					Vector2(0, -radius),
					Vector2(radius, radius),
					Vector2(-radius, radius),
				]),
				PackedColorArray([color, color, color])
			)
			draw_line(Vector2(-radius * 0.65, radius * 0.15), Vector2(radius * 0.65, radius * 0.15), Color.WHITE, 3.0)
		&"net":
			draw_rect(Rect2(Vector2.ONE * -radius, Vector2.ONE * radius * 2.0), color, false, 5.0)
			draw_line(Vector2(-radius, 0), Vector2(radius, 0), color, 3.0)
			draw_line(Vector2(0, -radius), Vector2(0, radius), color, 3.0)
		_:
			draw_circle(Vector2.ZERO, radius, color)
