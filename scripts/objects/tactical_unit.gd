class_name TacticalUnit
extends Node2D

@export var unit_kind: StringName = &"player"
@export var cell_size: int = 64

var grid_position: Vector2i = Vector2i.ZERO
var facing: StringName = &"down"
var _player_textures: Dictionary = {}


func configure(kind: StringName, start_cell: Vector2i, board: GridSystem) -> void:
	unit_kind = kind
	cell_size = board.cell_size
	set_grid_position(start_cell, board)


func set_facing(next_facing: StringName) -> void:
	facing = next_facing
	queue_redraw()


func set_grid_position(next_cell: Vector2i, board: GridSystem) -> void:
	grid_position = next_cell
	position = board.grid_to_local_center(grid_position)
	queue_redraw()


func _draw() -> void:
	if unit_kind == &"cat":
		_draw_cat()
	else:
		_draw_player()


func _draw_player() -> void:
	var texture := _get_player_texture()
	if texture:
		var source_size := texture.get_size()
		var max_size := Vector2.ONE * cell_size * 0.82
		var texture_scale := minf(max_size.x / source_size.x, max_size.y / source_size.y)
		var draw_size := source_size * texture_scale
		draw_texture_rect(texture, Rect2(draw_size * -0.5, draw_size), false)
		return

	var radius := cell_size * 0.32
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.42, 0.17))
	draw_circle(Vector2(-radius * 0.45, -radius * 0.15), radius * 0.09, Color(0.12, 0.08, 0.06))
	draw_circle(Vector2(radius * 0.45, -radius * 0.15), radius * 0.09, Color(0.12, 0.08, 0.06))
	draw_arc(Vector2(0, radius * 0.08), radius * 0.32, 0.2, 2.9, 16, Color(0.12, 0.08, 0.06), 3.0)
	draw_rect(Rect2(Vector2(-radius, radius * 0.95), Vector2(radius * 2.0, radius * 0.26)), Color(0.12, 0.82, 0.84))


func _get_player_texture() -> Texture2D:
	if _player_textures.is_empty():
		_player_textures[&"down"] = load("res://assets/player/down.png")
		_player_textures[&"left"] = load("res://assets/player/left.png")
		_player_textures[&"right"] = load("res://assets/player/right.png")
		_player_textures[&"up"] = load("res://assets/player/top.png")

	return _player_textures.get(facing, _player_textures.get(&"down", null)) as Texture2D


func _draw_cat() -> void:
	var radius := cell_size * 0.34
	draw_circle(Vector2.ZERO, radius, Color(0.04, 0.04, 0.04))
	draw_polygon(
		PackedVector2Array([
			Vector2(-radius * 0.75, -radius * 0.55),
			Vector2(-radius * 0.35, -radius * 1.18),
			Vector2(-radius * 0.08, -radius * 0.52),
		]),
		PackedColorArray([Color(0.04, 0.04, 0.04), Color(0.04, 0.04, 0.04), Color(0.04, 0.04, 0.04)])
	)
	draw_polygon(
		PackedVector2Array([
			Vector2(radius * 0.75, -radius * 0.55),
			Vector2(radius * 0.35, -radius * 1.18),
			Vector2(radius * 0.08, -radius * 0.52),
		]),
		PackedColorArray([Color(0.04, 0.04, 0.04), Color(0.04, 0.04, 0.04), Color(0.04, 0.04, 0.04)])
	)
	draw_circle(Vector2(-radius * 0.35, -radius * 0.1), radius * 0.17, Color(0.95, 0.86, 0.18))
	draw_circle(Vector2(radius * 0.35, -radius * 0.1), radius * 0.17, Color(0.95, 0.86, 0.18))
	draw_circle(Vector2(0, radius * 0.18), radius * 0.08, Color(1.0, 0.52, 0.48))
	draw_arc(Vector2(0, radius * 0.18), radius * 0.34, 0.25, 2.9, 16, Color.WHITE, 2.0)
