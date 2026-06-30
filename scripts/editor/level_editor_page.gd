class_name LevelEditorPage
extends Node2D

const UI_THEME_SCRIPT := preload("res://scripts/ui/hand_drawn_theme.gd")

signal back_requested
signal preview_requested(level: LevelData)

const GRID_ORIGIN := Vector2(20, 150)

var grid: GridSystem
var token_layer: Node2D
var unit_layer: Node2D
var player_unit: TacticalUnit
var cat_unit: TacticalUnit
var level: LevelData
var selected_tool: StringName = &"obstacle_wall"
var status_label: Label
var delay_spin: SpinBox
var export_dialog: FileDialog
var item_defs: Dictionary = {}
var token_nodes: Array[Node] = []
var tool_buttons: Dictionary = {}
var ui_theme := UI_THEME_SCRIPT.new()


func _ready() -> void:
	_create_item_defs()
	level = LevelFactory.create_blank_level()
	_build_board()
	_build_ui()
	_redraw_level()


func set_level(next_level: LevelData) -> void:
	level = next_level
	if grid:
		_redraw_level()
	if delay_spin:
		delay_spin.value = level.delay_turns


func get_current_level() -> LevelData:
	level.delay_turns = int(delay_spin.value) if delay_spin else level.delay_turns
	return _duplicate_level(level)


func _build_board() -> void:
	ui_theme.add_paper_background(self)

	grid = GridSystem.new()
	grid.position = GRID_ORIGIN
	grid.cell_selected.connect(_on_cell_selected)
	add_child(grid)

	token_layer = Node2D.new()
	token_layer.position = GRID_ORIGIN
	add_child(token_layer)

	unit_layer = Node2D.new()
	unit_layer.position = GRID_ORIGIN
	add_child(unit_layer)

	player_unit = TacticalUnit.new()
	player_unit.configure(&"player", level.player_start, grid)
	unit_layer.add_child(player_unit)

	cat_unit = TacticalUnit.new()
	cat_unit.configure(&"cat", level.cat_start, grid)
	unit_layer.add_child(cat_unit)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(20, 18)
	top_panel.custom_minimum_size = Vector2(680, 112)
	ui_theme.apply_panel(top_panel, &"paper")
	root.add_child(top_panel)

	var top_column := VBoxContainer.new()
	top_column.add_theme_constant_override("separation", 8)
	top_panel.add_child(top_column)

	var title := Label.new()
	title.text = "关卡编辑器"
	ui_theme.apply_label(title, 24, true)
	top_column.add_child(title)

	var action_row := HBoxContainer.new()
	action_row.custom_minimum_size = Vector2(652, 42)
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_theme_constant_override("separation", 8)
	top_column.add_child(action_row)

	action_row.add_child(_make_button("预览试玩", _on_preview_pressed, Vector2(0, 42)))
	action_row.add_child(_make_button("导出 JSON", _on_export_pressed, Vector2(0, 42)))
	action_row.add_child(_make_button("清空关卡", _on_clear_pressed, Vector2(0, 42)))
	action_row.add_child(_make_button("返回入口", _on_back_pressed, Vector2(0, 42)))

	var tool_panel := PanelContainer.new()
	tool_panel.position = Vector2(20, 850)
	tool_panel.custom_minimum_size = Vector2(680, 190)
	ui_theme.apply_panel(tool_panel, &"paper")
	root.add_child(tool_panel)

	var tool_column := VBoxContainer.new()
	tool_column.add_theme_constant_override("separation", 8)
	tool_panel.add_child(tool_column)

	var tool_row := GridContainer.new()
	tool_row.columns = 5
	tool_row.add_theme_constant_override("h_separation", 8)
	tool_row.add_theme_constant_override("v_separation", 6)
	tool_column.add_child(tool_row)

	var tools := [
		{"id": &"obstacle_wall", "label": "障碍墙"},
		{"id": &"wall", "label": "道具墙"},
		{"id": &"toy", "label": "玩具"},
		{"id": &"trap", "label": "陷阱"},
		{"id": &"net", "label": "捕捉网"},
		{"id": &"ice", "label": "冰块"},
		{"id": &"button", "label": "按钮"},
		{"id": &"cat", "label": "猫咪"},
		{"id": &"player", "label": "玩家"},
		{"id": &"eraser", "label": "橡皮"},
	]
	for tool in tools:
		var tool_id := tool["id"] as StringName
		var tool_button := _make_tool_button(tool_id, str(tool["label"]))
		tool_row.add_child(tool_button)
		tool_buttons[tool_id] = tool_button

	_refresh_tool_buttons()

	var setting_row := HBoxContainer.new()
	setting_row.add_theme_constant_override("separation", 10)
	tool_column.add_child(setting_row)

	var delay_label := Label.new()
	delay_label.text = "剩余拖延回合"
	delay_label.custom_minimum_size = Vector2(150, 36)
	ui_theme.apply_label(delay_label, 18)
	setting_row.add_child(delay_label)

	delay_spin = SpinBox.new()
	delay_spin.min_value = 1
	delay_spin.max_value = 99
	delay_spin.step = 1
	delay_spin.value = level.delay_turns
	delay_spin.custom_minimum_size = Vector2(130, 42)
	ui_theme.apply_spinbox(delay_spin)
	delay_spin.value_changed.connect(_on_delay_changed)
	setting_row.add_child(delay_spin)

	status_label = Label.new()
	status_label.text = "当前工具：障碍墙。点击棋盘放置。"
	status_label.custom_minimum_size = Vector2(640, 44)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui_theme.apply_label(status_label, 17)
	tool_column.add_child(status_label)

	export_dialog = FileDialog.new()
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	export_dialog.filters = PackedStringArray(["*.json ; JSON 关卡"])
	export_dialog.title = "导出关卡 JSON"
	export_dialog.size = Vector2i(680, 720)
	export_dialog.file_selected.connect(_on_export_file_selected)
	root.add_child(export_dialog)


func _on_cell_selected(cell: Vector2i) -> void:
	if selected_tool == &"":
		_set_status("未选择工具。点击下方工具按钮后再编辑棋盘。")
		return

	match selected_tool:
		&"obstacle_wall":
			_place_wall(cell)
		&"wall", &"toy", &"trap", &"net", &"ice":
			_place_item(cell, selected_tool)
		&"button":
			_move_button(cell)
		&"cat":
			_move_cat(cell)
		&"player":
			_move_player(cell)
		&"eraser":
			_erase_cell(cell)

	_redraw_level()


func _place_wall(cell: Vector2i) -> void:
	if _is_core_cell(cell):
		_set_status("障碍墙不能放在玩家、猫咪或按钮上。")
		return

	_remove_item_at(cell)
	if not level.walls.has(cell):
		level.walls.append(cell)
	_set_status("已放置障碍墙：%s" % str(cell))


func _place_item(cell: Vector2i, item_id: StringName) -> void:
	if _is_core_cell(cell) or level.walls.has(cell):
		_set_status("道具不能和墙、玩家、猫咪或按钮重叠。")
		return

	_remove_item_at(cell)
	level.items.append({"id": item_id, "position": cell, "count": 1})
	_set_status("已放置%s：%s" % [_tool_name(item_id), str(cell)])


func _move_button(cell: Vector2i) -> void:
	if cell == level.player_start or cell == level.cat_start:
		_set_status("按钮不能和玩家或猫咪重叠。")
		return

	_clear_cell_for_core_move(cell)
	level.button_pos = cell
	_set_status("按钮移动到：%s" % str(cell))


func _move_cat(cell: Vector2i) -> void:
	if cell == level.button_pos:
		_set_status("猫咪不能和按钮重叠。")
		return

	_clear_cell_for_core_move(cell)
	level.cat_start = cell
	_set_status("猫咪移动到：%s" % str(cell))


func _move_player(cell: Vector2i) -> void:
	if cell == level.button_pos:
		_set_status("玩家不能和按钮重叠。")
		return

	_clear_cell_for_core_move(cell)
	level.player_start = cell
	_set_status("玩家移动到：%s" % str(cell))


func _erase_cell(cell: Vector2i) -> void:
	level.walls.erase(cell)
	_remove_item_at(cell)
	_set_status("已擦除墙或道具：%s" % str(cell))


func _redraw_level() -> void:
	grid.setup(level.board_size, level.button_pos)
	for node in token_nodes:
		node.queue_free()
	token_nodes.clear()

	for wall_cell in level.walls:
		grid.set_blocked(wall_cell, true)
		_add_token(wall_cell, item_defs[&"obstacle_wall"] as ItemData)

	for item_entry in level.items:
		var item_id := item_entry.get("id", &"toy") as StringName
		var item_cell := item_entry.get("position", Vector2i.ZERO) as Vector2i
		_add_token(item_cell, item_defs[item_id] as ItemData)

	player_unit.set_grid_position(level.player_start, grid)
	cat_unit.set_grid_position(level.cat_start, grid)
	_refresh_unit_positions()


func _add_token(cell: Vector2i, item: ItemData) -> void:
	var token := BoardToken.new()
	token.configure(item.id, item.short_label, item.color, cell, grid)
	token_layer.add_child(token)
	token_nodes.append(token)


func _select_tool(tool_id: StringName) -> void:
	if selected_tool == tool_id:
		selected_tool = &""
		_set_status("已取消选择工具。")
	else:
		selected_tool = tool_id
		_set_status("当前工具：%s。点击棋盘放置或移动。" % _tool_name(tool_id))
	_refresh_tool_buttons()


func _on_delay_changed(value: float) -> void:
	level.delay_turns = int(value)
	_set_status("剩余拖延回合设置为 %d。" % level.delay_turns)


func _on_preview_pressed() -> void:
	level.delay_turns = int(delay_spin.value)
	var validation := LevelCodec.validate_level(level)
	if not validation["ok"]:
		_set_status(validation["error"])
		return

	preview_requested.emit(get_current_level())


func _on_export_pressed() -> void:
	level.delay_turns = int(delay_spin.value)
	var validation := LevelCodec.validate_level(level)
	if not validation["ok"]:
		_set_status(validation["error"])
		return

	export_dialog.current_file = "%s.json" % level.level_name
	export_dialog.popup_centered()


func _on_export_file_selected(path: String) -> void:
	if not path.to_lower().ends_with(".json"):
		path += ".json"

	var json_text := LevelCodec.level_to_json(get_current_level())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_set_status("导出失败：无法写入文件。")
		return

	file.store_string(json_text)
	file.close()
	_set_status("已导出：%s" % path)


func _on_clear_pressed() -> void:
	level = LevelFactory.create_blank_level()
	delay_spin.value = level.delay_turns
	_redraw_level()
	_set_status("已清空为默认空白关卡。")


func _on_back_pressed() -> void:
	back_requested.emit()


func _make_button(text: String, callback: Callable, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = size
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_theme.apply_button(button)
	button.pressed.connect(callback)
	return button


func _make_tool_button(tool_id: StringName, label_text: String) -> Button:
	var button := Button.new()
	button.name = String(tool_id)
	button.text = ""
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(124, 40)
	ui_theme.apply_inventory_button(button)
	button.pressed.connect(_select_tool.bind(tool_id))

	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 7
	content.offset_top = 4
	content.offset_right = -7
	content.offset_bottom = -4
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 4)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)

	var icon := ItemIcon.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.configure(tool_id, _tool_color(tool_id))
	content.add_child(icon)

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_theme.apply_label(label, 14)
	content.add_child(label)

	return button


func _refresh_tool_buttons() -> void:
	for tool_id in tool_buttons.keys():
		var button := tool_buttons[tool_id] as Button
		if button:
			button.button_pressed = (tool_id as StringName) == selected_tool


func _create_item_defs() -> void:
	item_defs[&"wall"] = _make_item(&"wall", "道具墙", "墙", Color(0.90, 0.60, 0.30))
	item_defs[&"obstacle_wall"] = _make_item(&"obstacle_wall", "障碍墙", "障", Color(0.34, 0.34, 0.38))
	item_defs[&"toy"] = _make_item(&"toy", "玩具", "玩", Color(0.97, 0.76, 0.16))
	item_defs[&"trap"] = _make_item(&"trap", "陷阱", "陷", Color(0.88, 0.18, 0.28))
	item_defs[&"net"] = _make_item(&"net", "捕捉网", "网", Color(0.73, 0.92, 0.86))
	item_defs[&"ice"] = _make_item(&"ice", "冰块", "冰", Color(0.50, 0.90, 1.0))


func _make_item(id: StringName, display_name: String, short_label: String, color: Color) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.display_name = display_name
	item.short_label = short_label
	item.color = color
	return item


func _set_status(message: String) -> void:
	if status_label:
		status_label.text = message


func _tool_name(tool_id: StringName) -> String:
	match tool_id:
		&"obstacle_wall":
			return "障碍墙"
		&"wall":
			return "道具墙"
		&"toy":
			return "玩具"
		&"trap":
			return "陷阱"
		&"net":
			return "捕捉网"
		&"ice":
			return "冰块"
		&"button":
			return "按钮"
		&"cat":
			return "猫咪"
		&"player":
			return "玩家"
		&"eraser":
			return "橡皮"
		_:
			return "未知"


func _tool_color(tool_id: StringName) -> Color:
	if item_defs.has(tool_id):
		return (item_defs[tool_id] as ItemData).color
	match tool_id:
		&"button":
			return Color(0.94, 0.18, 0.42)
		&"cat":
			return Color(0.04, 0.04, 0.04)
		&"player":
			return Color(1.0, 0.42, 0.17)
		&"eraser":
			return Color(0.95, 0.77, 0.62)
		_:
			return Color.WHITE


func _is_core_cell(cell: Vector2i) -> bool:
	return cell == level.player_start or cell == level.cat_start or cell == level.button_pos


func _refresh_unit_positions() -> void:
	if not player_unit or not cat_unit or not grid:
		return

	player_unit.position = grid.grid_to_local_center(level.player_start)
	cat_unit.position = grid.grid_to_local_center(level.cat_start)
	if level.player_start == level.cat_start:
		var offset := Vector2(grid.cell_size * 0.14, 0.0)
		player_unit.position -= offset
		cat_unit.position += offset


func _clear_cell_for_core_move(cell: Vector2i) -> void:
	level.walls.erase(cell)
	_remove_item_at(cell)


func _remove_item_at(cell: Vector2i) -> void:
	for index in range(level.items.size() - 1, -1, -1):
		var entry := level.items[index] as Dictionary
		if (entry.get("position", Vector2i.ZERO) as Vector2i) == cell:
			level.items.remove_at(index)


func _duplicate_level(source: LevelData) -> LevelData:
	var copy := LevelData.new()
	copy.level_name = source.level_name
	copy.board_size = source.board_size
	copy.player_start = source.player_start
	copy.cat_start = source.cat_start
	copy.button_pos = source.button_pos
	copy.delay_turns = source.delay_turns
	copy.walls = source.walls.duplicate()
	copy.items = source.items.duplicate(true)
	return copy
