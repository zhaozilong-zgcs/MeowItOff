class_name LevelData
extends Resource

@export var level_name: String = "教学关"
@export var board_size: Vector2i = Vector2i(10, 10)
@export var player_start: Vector2i = Vector2i(0, 9)
@export var cat_start: Vector2i = Vector2i(4, 2)
@export var button_pos: Vector2i = Vector2i(9, 0)
@export var delay_turns: int = 18
@export var walls: Array[Vector2i] = []
@export var items: Array[Dictionary] = []
