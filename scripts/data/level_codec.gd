class_name LevelCodec
extends RefCounted

const SUPPORTED_VERSION := 1
const SUPPORTED_BOARD_SIZE := Vector2i(10, 10)
const VALID_ITEM_IDS := [&"wall", &"toy", &"trap", &"net", &"ice"]


static func level_to_json(level: LevelData) -> String:
	return JSON.stringify(level_to_dictionary(level), "\t")


static func level_to_dictionary(level: LevelData) -> Dictionary:
	var walls: Array = []
	for wall_cell in level.walls:
		walls.append(_cell_to_dict(wall_cell))

	var items: Array = []
	for item_entry in level.items:
		var item_cell := item_entry.get("position", Vector2i.ZERO) as Vector2i
		items.append({
			"id": String(item_entry.get("id", &"wall")),
			"x": item_cell.x,
			"y": item_cell.y,
			"count": int(item_entry.get("count", 1)),
		})

	return {
		"version": SUPPORTED_VERSION,
		"name": level.level_name,
		"board_size": _cell_to_dict(level.board_size),
		"delay_turns": level.delay_turns,
		"player_start": _cell_to_dict(level.player_start),
		"cat_start": _cell_to_dict(level.cat_start),
		"button_pos": _cell_to_dict(level.button_pos),
		"walls": walls,
		"items": items,
	}


static func json_to_level(json_text: String) -> Dictionary:
	var parser := JSON.new()
	var parse_error := parser.parse(json_text)
	if parse_error != OK:
		return {
			"ok": false,
			"error": "JSON 解析失败：%s" % parser.get_error_message(),
		}

	if typeof(parser.data) != TYPE_DICTIONARY:
		return {"ok": false, "error": "JSON 根节点必须是对象。"}

	return dictionary_to_level(parser.data as Dictionary)


static func dictionary_to_level(data: Dictionary) -> Dictionary:
	var required_fields := [
		"version",
		"name",
		"board_size",
		"delay_turns",
		"player_start",
		"cat_start",
		"button_pos",
		"walls",
		"items",
	]
	for field in required_fields:
		if not data.has(field):
			return {"ok": false, "error": "缺少字段：%s" % field}

	if int(data["version"]) != SUPPORTED_VERSION:
		return {"ok": false, "error": "不支持的关卡版本。"}

	var board_size := _parse_cell(data["board_size"])
	if board_size != SUPPORTED_BOARD_SIZE:
		return {"ok": false, "error": "首版只支持 10x10 关卡。"}

	var level := LevelData.new()
	level.level_name = str(data["name"])
	level.board_size = board_size
	level.delay_turns = maxi(int(data["delay_turns"]), 1)
	level.player_start = _parse_cell(data["player_start"])
	level.cat_start = _parse_cell(data["cat_start"])
	level.button_pos = _parse_cell(data["button_pos"])

	var validation := _validate_unique_core_positions(level)
	if not validation["ok"]:
		return validation

	level.walls = []
	if typeof(data["walls"]) != TYPE_ARRAY:
		return {"ok": false, "error": "walls 必须是数组。"}
	for wall_data in data["walls"]:
		var wall_cell := _parse_cell(wall_data)
		if not _is_inside(wall_cell, level.board_size):
			return {"ok": false, "error": "墙坐标越界：%s" % str(wall_cell)}
		level.walls.append(wall_cell)

	level.items = []
	if typeof(data["items"]) != TYPE_ARRAY:
		return {"ok": false, "error": "items 必须是数组。"}
	for item_data in data["items"]:
		if typeof(item_data) != TYPE_DICTIONARY:
			return {"ok": false, "error": "道具条目必须是对象。"}

		var item_id := StringName(str((item_data as Dictionary).get("id", "")))
		if not VALID_ITEM_IDS.has(item_id):
			return {"ok": false, "error": "未知道具 id：%s" % String(item_id)}

		var item_cell := Vector2i(int((item_data as Dictionary).get("x", -1)), int((item_data as Dictionary).get("y", -1)))
		if not _is_inside(item_cell, level.board_size):
			return {"ok": false, "error": "道具坐标越界：%s" % str(item_cell)}

		level.items.append({
			"id": item_id,
			"position": item_cell,
			"count": maxi(int((item_data as Dictionary).get("count", 1)), 1),
		})

	validation = validate_level(level)
	if not validation["ok"]:
		return validation

	return {"ok": true, "level": level, "error": ""}


static func validate_level(level: LevelData) -> Dictionary:
	if level.board_size != SUPPORTED_BOARD_SIZE:
		return {"ok": false, "error": "首版只支持 10x10 关卡。"}

	for core_cell in [level.player_start, level.cat_start, level.button_pos]:
		if not _is_inside(core_cell, level.board_size):
			return {"ok": false, "error": "玩家、猫或按钮坐标越界。"}

	var validation := _validate_unique_core_positions(level)
	if not validation["ok"]:
		return validation

	var occupied := {}
	occupied[_cell_key(level.player_start)] = "玩家"
	var cat_key := _cell_key(level.cat_start)
	if occupied.has(cat_key):
		occupied[cat_key] = "玩家和猫咪"
	else:
		occupied[cat_key] = "猫咪"
	occupied[_cell_key(level.button_pos)] = "按钮"

	for wall_cell in level.walls:
		var key := _cell_key(wall_cell)
		if occupied.has(key):
			return {"ok": false, "error": "墙与%s重叠。" % occupied[key]}
		if not _is_inside(wall_cell, level.board_size):
			return {"ok": false, "error": "墙坐标越界：%s" % str(wall_cell)}
		occupied[key] = "墙"

	for item_entry in level.items:
		var item_cell := item_entry.get("position", Vector2i.ZERO) as Vector2i
		var key := _cell_key(item_cell)
		if occupied.has(key):
			return {"ok": false, "error": "道具与%s重叠。" % occupied[key]}
		if not _is_inside(item_cell, level.board_size):
			return {"ok": false, "error": "道具坐标越界：%s" % str(item_cell)}
		occupied[key] = "道具"

	return {"ok": true, "error": ""}


static func _validate_unique_core_positions(level: LevelData) -> Dictionary:
	if level.player_start == level.button_pos:
		return {"ok": false, "error": "玩家和按钮不能重叠。"}
	if level.cat_start == level.button_pos:
		return {"ok": false, "error": "猫咪和按钮不能重叠。"}
	return {"ok": true, "error": ""}


static func _parse_cell(value: Variant) -> Vector2i:
	if typeof(value) != TYPE_DICTIONARY:
		return Vector2i(-1, -1)

	var dict := value as Dictionary
	return Vector2i(int(dict.get("x", -1)), int(dict.get("y", -1)))


static func _cell_to_dict(cell: Vector2i) -> Dictionary:
	return {"x": cell.x, "y": cell.y}


static func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


static func _is_inside(cell: Vector2i, board_size: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < board_size.x and cell.y < board_size.y
