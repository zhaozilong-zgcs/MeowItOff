class_name HomeBackgroundDecor
extends Control

const UI_THEME_SCRIPT := preload("res://scripts/ui/hand_drawn_theme.gd")

var ui_theme := UI_THEME_SCRIPT.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	_draw_paper_patches()
	_draw_scribbles()
	_draw_chess_patch(Vector2(42, 78), 142, 0.16)
	_draw_chess_patch(Vector2(526, 948), 132, 0.12)
	_draw_cat_face(Vector2(598, 178), 74, 0.18)
	_draw_cat_face(Vector2(112, 1016), 92, 0.14)
	_draw_button_doodle(Vector2(574, 760), 54, 0.18)


func _draw_paper_patches() -> void:
	draw_rect(Rect2(Vector2(0, 0), Vector2(720, 310)), Color(1.0, 0.86, 0.58, 0.10))
	draw_rect(Rect2(Vector2(0, 900), Vector2(720, 380)), Color(0.20, 0.13, 0.08, 0.08))
	draw_circle(Vector2(88, 188), 136, Color(1.0, 0.96, 0.84, 0.07))
	draw_circle(Vector2(648, 1048), 180, Color(0.96, 0.48, 0.18, 0.07))
	draw_circle(Vector2(620, 404), 118, Color(0.55, 0.88, 0.78, 0.08))


func _draw_scribbles() -> void:
	var ink := Color(ui_theme.INK.r, ui_theme.INK.g, ui_theme.INK.b, 0.14)
	var orange := Color(ui_theme.CAT_ORANGE.r, ui_theme.CAT_ORANGE.g, ui_theme.CAT_ORANGE.b, 0.16)
	var gold := Color(ui_theme.GOLD.r, ui_theme.GOLD.g, ui_theme.GOLD.b, 0.18)

	draw_line(Vector2(54, 358), Vector2(204, 326), ink, 3.0)
	draw_line(Vector2(64, 384), Vector2(226, 348), ink, 2.0)
	draw_line(Vector2(504, 310), Vector2(666, 286), orange, 4.0)
	draw_line(Vector2(514, 336), Vector2(676, 318), orange, 2.0)
	draw_arc(Vector2(84, 744), 58, -0.3, 2.8, 30, gold, 4.0)
	draw_arc(Vector2(642, 640), 42, 0.6, 4.0, 30, ink, 3.0)


func _draw_chess_patch(top_left: Vector2, tile_size: int, alpha: float) -> void:
	var cell := tile_size / 3.0
	for y in range(3):
		for x in range(3):
			var dark := (x + y) % 2 == 0
			var fill := Color(0.07, 0.08, 0.07, alpha) if dark else Color(1.0, 0.96, 0.84, alpha)
			draw_rect(Rect2(top_left + Vector2(x * cell, y * cell), Vector2(cell, cell)), fill)
	draw_rect(Rect2(top_left, Vector2(tile_size, tile_size)), Color(ui_theme.INK.r, ui_theme.INK.g, ui_theme.INK.b, alpha + 0.04), false, 2.0)


func _draw_cat_face(center: Vector2, radius: float, alpha: float) -> void:
	var ink := Color(ui_theme.INK.r, ui_theme.INK.g, ui_theme.INK.b, alpha)
	var gold := Color(ui_theme.GOLD.r, ui_theme.GOLD.g, ui_theme.GOLD.b, alpha + 0.08)
	draw_arc(center, radius, 0.18, TAU - 0.18, 42, ink, 4.0)
	draw_line(center + Vector2(-radius * 0.58, -radius * 0.50), center + Vector2(-radius * 0.35, -radius * 1.08), ink, 4.0)
	draw_line(center + Vector2(-radius * 0.35, -radius * 1.08), center + Vector2(-radius * 0.08, -radius * 0.60), ink, 4.0)
	draw_line(center + Vector2(radius * 0.58, -radius * 0.50), center + Vector2(radius * 0.35, -radius * 1.08), ink, 4.0)
	draw_line(center + Vector2(radius * 0.35, -radius * 1.08), center + Vector2(radius * 0.08, -radius * 0.60), ink, 4.0)
	draw_circle(center + Vector2(-radius * 0.26, -radius * 0.06), radius * 0.10, gold)
	draw_circle(center + Vector2(radius * 0.26, -radius * 0.06), radius * 0.10, gold)
	draw_arc(center + Vector2(0, radius * 0.12), radius * 0.24, 0.15, PI - 0.15, 20, ink, 3.0)


func _draw_button_doodle(center: Vector2, radius: float, alpha: float) -> void:
	var ink := Color(ui_theme.INK.r, ui_theme.INK.g, ui_theme.INK.b, alpha + 0.06)
	var orange := Color(ui_theme.CAT_ORANGE.r, ui_theme.CAT_ORANGE.g, ui_theme.CAT_ORANGE.b, alpha)
	draw_circle(center, radius, orange)
	draw_arc(center, radius, 0.0, TAU, 42, ink, 4.0)
	draw_circle(center, radius * 0.55, Color(1.0, 0.96, 0.84, alpha + 0.06))
