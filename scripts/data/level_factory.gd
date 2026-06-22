class_name LevelFactory
extends RefCounted


static func create_tutorial_level() -> LevelData:
	var level := LevelData.new()
	level.level_name = "教学关"
	level.board_size = Vector2i(10, 10)
	level.player_start = Vector2i(1, 8)
	level.cat_start = Vector2i(4, 2)
	level.button_pos = Vector2i(9, 1)
	level.delay_turns = 18
	level.walls = [
		Vector2i(3, 3),
		Vector2i(4, 3),
		Vector2i(5, 3),
		Vector2i(6, 4),
		Vector2i(6, 5),
		Vector2i(2, 6),
		Vector2i(3, 6),
	]
	level.items = [
		{"id": &"wall", "position": Vector2i(1, 7), "count": 2},
		{"id": &"toy", "position": Vector2i(2, 8), "count": 1},
		{"id": &"trap", "position": Vector2i(5, 8), "count": 1},
		{"id": &"net", "position": Vector2i(7, 7), "count": 1},
		{"id": &"ice", "position": Vector2i(8, 6), "count": 1},
	]
	return level


static func create_blank_level() -> LevelData:
	var level := LevelData.new()
	level.level_name = "自定义关卡"
	level.board_size = Vector2i(10, 10)
	level.player_start = Vector2i(1, 8)
	level.cat_start = Vector2i(4, 2)
	level.button_pos = Vector2i(9, 1)
	level.delay_turns = 18
	level.walls = []
	level.items = []
	return level
