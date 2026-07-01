class_name AppController
extends Node2D

const UI_THEME_SCRIPT := preload("res://scripts/ui/hand_drawn_theme.gd")
const HOME_DECOR_SCRIPT := preload("res://scripts/ui/home_background_decor.gd")
const VIEWPORT_SIZE := Vector2(720, 1280)
const LEVEL_LIST_PATH := "res://scripts/level/level_list.json"
const PROGRESS_SAVE_PATH := "user://level_progress.json"

var current_view: Node
var last_editor_level: LevelData
var status_message: String = ""
var audio: AudioManager
var ui_theme := UI_THEME_SCRIPT.new()
var level_entries: Array = []
var completed_levels: Dictionary = {}
var _active_level_id: String = ""


func _ready() -> void:
	_ensure_audio()
	_load_progress()
	_load_level_list()
	last_editor_level = LevelFactory.create_blank_level()
	_show_home()


func _clear_view() -> void:
	if current_view:
		current_view.queue_free()
		current_view = null


func _show_home(message: String = "") -> void:
	_clear_view()
	_play_bgm(&"BGM_MENU")

	var root := _make_fullscreen_root()
	current_view = root
	add_child(root)
	_add_home_background(root, true)

	var panel := PanelContainer.new()
	var panel_height := 360
	if not message.is_empty():
		panel_height = 430
	var panel_size := Vector2(480, panel_height)
	panel.position = (VIEWPORT_SIZE - panel_size) * 0.5
	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	ui_theme.apply_panel(panel, &"paper")
	root.add_child(panel)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)

	var title := Label.new()
	title.text = "别按那个键"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_theme.apply_label(title, 34, true)
	column.add_child(title)

	column.add_child(_make_button("开始游戏", _start_first_level, Vector2(360, 58)))
	column.add_child(_make_button("关卡列表", _show_level_list, Vector2(360, 58)))
	column.add_child(_make_button("编辑器", _show_editor, Vector2(360, 58)))
	column.add_child(_make_button("导入关卡 JSON", _open_import_dialog.bind(root), Vector2(360, 58)))

	if not message.is_empty():
		var hint := Label.new()
		hint.text = message
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.custom_minimum_size = Vector2(430, 70)
		ui_theme.apply_label(hint, 18)
		column.add_child(hint)


func _show_level_list() -> void:
	_clear_view()
	_play_bgm(&"BGM_MENU")

	var root := _make_fullscreen_root()
	current_view = root
	add_child(root)
	_add_home_background(root)

	var panel := PanelContainer.new()
	panel.position = Vector2(50, 140)
	panel.custom_minimum_size = Vector2(620, 900)
	ui_theme.apply_panel(panel, &"paper")
	root.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	var title := Label.new()
	title.text = "关卡列表"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_theme.apply_label(title, 32, true)
	column.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 690)
	column.add_child(scroll)

	var list_column := VBoxContainer.new()
	list_column.add_theme_constant_override("separation", 10)
	scroll.add_child(list_column)

	if level_entries.is_empty():
		var empty_note := Label.new()
		empty_note.text = "未找到关卡配置。"
		empty_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ui_theme.apply_label(empty_note, 18)
		list_column.add_child(empty_note)
	else:
		for entry in level_entries:
			var button := _make_level_button(entry)
			list_column.add_child(button)

	column.add_child(_make_button("返回入口", _show_home, Vector2(500, 58)))


func _show_editor() -> void:
	_clear_view()
	_play_bgm(&"BGM_EDITOR")

	var editor := LevelEditorPage.new()
	current_view = editor
	add_child(editor)
	editor.set_level(_duplicate_level(last_editor_level))
	editor.back_requested.connect(_on_editor_back_requested)
	editor.preview_requested.connect(_on_editor_preview_requested)


func _start_game(level: LevelData, return_mode: StringName, level_id: String = "") -> void:
	_clear_view()
	_play_bgm(&"BGM_PLAY_L1")
	_active_level_id = level_id

	var game := GameManager.new()
	current_view = game
	add_child(game)
	game.return_requested.connect(_on_game_return_requested)
	game.music_requested.connect(_on_music_requested)
	game.sting_requested.connect(_on_sting_requested)
	game.level_completed.connect(_on_level_completed)
	game.start_level(level, return_mode)


func _on_editor_back_requested() -> void:
	if current_view is LevelEditorPage:
		last_editor_level = (current_view as LevelEditorPage).get_current_level()
	_show_home()


func _on_editor_preview_requested(level: LevelData) -> void:
	last_editor_level = _duplicate_level(level)
	_start_game(level, &"editor")


func _on_game_return_requested(return_mode: StringName) -> void:
	match return_mode:
		&"editor":
			_show_editor()
		&"level_list":
			_show_level_list()
		_:
			_show_home()


func _on_music_requested(track_id: StringName) -> void:
	_play_bgm(track_id)


func _on_sting_requested(sting_id: StringName) -> void:
	if audio:
		audio.play_sting(sting_id)


func _open_import_dialog(root: Control) -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json ; JSON 关卡"])
	dialog.title = "导入关卡 JSON"
	dialog.size = Vector2i(680, 720)
	dialog.file_selected.connect(_on_import_file_selected)
	root.add_child(dialog)
	dialog.popup_centered()


func _on_import_file_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_show_home("导入失败：无法读取文件。")
		return

	var json_text := file.get_as_text()
	file.close()

	var result = LevelCodec.json_to_level(json_text)
	if not result["ok"]:
		_show_home("导入失败：%s" % result["error"])
		return

	_start_game(result["level"] as LevelData, &"menu")


func _start_first_level() -> void:
	if level_entries.is_empty():
		_start_game(LevelFactory.create_tutorial_level(), &"menu")
		return

	_start_config_level(level_entries[0])


func _start_config_level(entry) -> void:
	var result = _load_level_from_entry(entry)
	if not result["ok"]:
		_show_home("关卡读取失败：%s" % result["error"])
		return

	var level := result["level"] as LevelData
	level.level_name = str(entry["name"])
	_start_game(level, &"level_list", str(entry["id"]))


func _load_level_from_entry(entry) -> Dictionary:
	var path = str(entry.get("path", ""))
	if path.is_empty():
		return {"ok": false, "level": null, "error": "关卡路径为空。"}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "level": null, "error": "无法读取 %s。" % path}

	var json_text := file.get_as_text()
	file.close()

	var result = LevelCodec.json_to_level(json_text)
	if not result["ok"]:
		return {"ok": false, "level": null, "error": result["error"]}

	return result


func _make_level_button(entry) -> Button:
	var id = str(entry.get("id", ""))
	var display_name = str(entry.get("name", "未命名关卡"))
	var complete_suffix := ""
	if completed_levels.has(id):
		complete_suffix = "  已完成"
	var button := _make_button("%s. %s%s" % [id, display_name, complete_suffix], _start_config_level.bind(entry), Vector2(560, 58))
	return button


func _load_level_list() -> void:
	level_entries.clear()
	if not FileAccess.file_exists(LEVEL_LIST_PATH):
		push_warning("Level list config not found: %s" % LEVEL_LIST_PATH)
		return

	var file := FileAccess.open(LEVEL_LIST_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not read level list config: %s" % LEVEL_LIST_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Level list config must be a dictionary.")
		return

	var data = parsed
	var levels_variant = data.get("levels", [])
	if typeof(levels_variant) != TYPE_ARRAY:
		push_warning("Level list config field 'levels' must be an array.")
		return

	var levels_array = levels_variant
	for level_variant in levels_array:
		if typeof(level_variant) != TYPE_DICTIONARY:
			continue

		var entry = level_variant
		var id = str(entry.get("id", ""))
		var display_name = str(entry.get("name", ""))
		var path = str(entry.get("path", ""))
		if id.is_empty() or display_name.is_empty() or path.is_empty():
			continue

		level_entries.append({
			"id": id,
			"name": display_name,
			"path": path,
		})


func _load_progress() -> void:
	completed_levels.clear()
	if not FileAccess.file_exists(PROGRESS_SAVE_PATH):
		return

	var file := FileAccess.open(PROGRESS_SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var data = parsed
	var completed_variant = data.get("completed_levels", [])
	if typeof(completed_variant) != TYPE_ARRAY:
		return

	var completed_array = completed_variant
	for id_variant in completed_array:
		var id = str(id_variant)
		if not id.is_empty():
			completed_levels[id] = true


func _save_progress() -> void:
	var completed_ids = completed_levels.keys()
	completed_ids.sort()
	var file := FileAccess.open(PROGRESS_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write progress save: %s" % PROGRESS_SAVE_PATH)
		return

	file.store_string(JSON.stringify({"completed_levels": completed_ids}, "\t"))
	file.close()


func _on_level_completed() -> void:
	if _active_level_id == "":
		return

	var id := _active_level_id
	if completed_levels.has(id):
		return

	completed_levels[id] = true
	_save_progress()


func _make_fullscreen_root() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	return root


func _add_home_background(root: Control, decorated: bool = false) -> void:
	ui_theme.add_control_background(root)
	if decorated:
		var decor := HOME_DECOR_SCRIPT.new()
		decor.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(decor)


func _add_plain_background(root: Control) -> void:
	ui_theme.add_control_background(root)


func _make_button(text: String, callback: Callable, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = size
	ui_theme.apply_button(button)
	button.pressed.connect(callback)
	return button


func _ensure_audio() -> void:
	if audio:
		return

	audio = AudioManager.new()
	add_child(audio)


func _play_bgm(track_id: StringName) -> void:
	_ensure_audio()
	audio.play_bgm(track_id)


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
