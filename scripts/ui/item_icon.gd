class_name ItemIcon
extends Control

@export var token_id: StringName = &"wall"
@export var color: Color = Color.WHITE


func configure(id: StringName, next_color: Color) -> void:
	token_id = id
	color = next_color
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34

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
		_:
			draw_circle(center, radius, color)


func _draw_obstacle_wall(center: Vector2, radius: float) -> void:
	var rect := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	draw_rect(rect, color)
	draw_rect(rect, Color(0.12, 0.10, 0.12), false, 4.0)
	draw_line(center + Vector2(-radius, -radius * 0.25), center + Vector2(radius, -radius * 0.25), Color(0.12, 0.10, 0.12), 3.0)
	draw_line(center + Vector2(-radius, radius * 0.25), center + Vector2(radius, radius * 0.25), Color(0.12, 0.10, 0.12), 3.0)


func _draw_item_wall(center: Vector2, radius: float) -> void:
	var rect := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	draw_rect(rect, color)
	draw_rect(rect, Color(0.98, 0.86, 0.74), false, 3.0)


func _draw_toy(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, color)
	draw_circle(center, radius * 0.48, Color(1.0, 0.91, 0.23))


func _draw_trap(center: Vector2, radius: float) -> void:
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-radius, -radius * 0.15),
			center + Vector2(-radius * 0.55, -radius * 0.75),
			center + Vector2(-radius * 0.15, -radius * 0.15),
			center + Vector2(radius * 0.25, -radius * 0.75),
			center + Vector2(radius * 0.65, -radius * 0.15),
			center + Vector2(radius, -radius * 0.75),
			center + Vector2(radius, radius * 0.75),
			center + Vector2(-radius, radius * 0.75),
		]),
		PackedColorArray([color, color, color, color, color, color, color, color])
	)
	draw_rect(Rect2(center + Vector2(-radius, radius * 0.18), Vector2(radius * 2.0, radius * 0.62)), Color(0.05, 0.12, 0.14))
	draw_line(center + Vector2(-radius * 0.62, radius * 0.48), center + Vector2(radius * 0.62, radius * 0.48), Color.WHITE, 3.0)
	draw_line(center + Vector2(-radius * 0.28, radius * 0.28), center + Vector2(-radius * 0.28, radius * 0.68), Color.WHITE, 2.0)
	draw_line(center + Vector2(radius * 0.28, radius * 0.28), center + Vector2(radius * 0.28, radius * 0.68), Color.WHITE, 2.0)


func _draw_net(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, Color(color.r, color.g, color.b, 0.28))
	draw_arc(center, radius, 0.0, TAU, 40, color, 5.0)
	draw_arc(center, radius * 0.62, 0.0, TAU, 32, color, 3.0)
	draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), color, 3.0)
	draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), color, 3.0)
	draw_line(center + Vector2(-radius * 0.72, -radius * 0.72), center + Vector2(radius * 0.72, radius * 0.72), color, 2.5)
	draw_line(center + Vector2(radius * 0.72, -radius * 0.72), center + Vector2(-radius * 0.72, radius * 0.72), color, 2.5)
	draw_line(center + Vector2(radius * 0.64, radius * 0.64), center + Vector2(radius * 1.05, radius * 1.05), color, 5.0)


func _draw_ice(center: Vector2, radius: float) -> void:
	var rect := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	draw_rect(rect, color)
	draw_rect(rect, Color.WHITE, false, 3.0)
	draw_line(center + Vector2(-radius * 0.55, -radius * 0.1), center + Vector2(radius * 0.45, -radius * 0.55), Color.WHITE, 3.0)
	draw_line(center + Vector2(-radius * 0.35, radius * 0.45), center + Vector2(radius * 0.55, radius * 0.05), Color.WHITE, 3.0)
