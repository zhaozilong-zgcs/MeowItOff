class_name AppController
extends Node2D

const COVER_PATH := "res://assets/cover.png"

var current_view: Node
var last_editor_level: LevelData
var status_message: String = ""


func _ready() -> void:
	last_editor_level = LevelFactory.create_blank_level()
	_show_home()


func _clear_view() -> void:
	if current_view:
		current_view.queue_free()
		current_view = null


func _show_home(message: String = "") -> void:
	_clear_view()

	var root := _make_fullscreen_root()
	current_view = root
	add_child(root)
	_add_cover_background(root)

	var panel := PanelContainer.new()
	panel.position = Vector2(120, 720)
	panel.custom_minimum_size = Vector2(480, 470)
	root.add_child(panel)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)

	var title := Label.new()
	title.text = "别按那个键"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	column.add_child(title)

	column.add_child(_make_button("开始游戏", _start_game.bind(LevelFactory.create_tutorial_level(), &"menu"), Vector2(360, 58)))
	column.add_child(_make_button("关卡列表", _show_level_list, Vector2(360, 58)))
	column.add_child(_make_button("编辑器", _show_editor, Vector2(360, 58)))
	column.add_child(_make_button("导入关卡 JSON", _open_import_dialog.bind(root), Vector2(360, 58)))

	var hint := Label.new()
	hint.text = message if not message.is_empty() else "选择关卡、编辑关卡，或导入 JSON 开始游戏。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(430, 70)
	hint.add_theme_font_size_override("font_size", 18)
	column.add_child(hint)


func _show_level_list() -> void:
	_clear_view()

	var root := _make_fullscreen_root()
	current_view = root
	add_child(root)
	_add_plain_background(root)

	var panel := PanelContainer.new()
	panel.position = Vector2(70, 180)
	panel.custom_minimum_size = Vector2(580, 640)
	root.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	var title := Label.new()
	title.text = "关卡列表"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	column.add_child(title)

	var tutorial_button := _make_button("教学关", _start_game.bind(LevelFactory.create_tutorial_level(), &"level_list"), Vector2(500, 64))
	column.add_child(tutorial_button)

	var note := Label.new()
	note.text = "更多内置关卡以后可以直接加入这里。"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 18)
	column.add_child(note)

	column.add_child(_make_button("返回入口", _show_home, Vector2(500, 58)))


func _show_editor() -> void:
	_clear_view()

	var editor := LevelEditorPage.new()
	current_view = editor
	add_child(editor)
	editor.set_level(_duplicate_level(last_editor_level))
	editor.back_requested.connect(_on_editor_back_requested)
	editor.preview_requested.connect(_on_editor_preview_requested)


func _start_game(level: LevelData, return_mode: StringName) -> void:
	_clear_view()

	var game := GameManager.new()
	current_view = game
	add_child(game)
	game.return_requested.connect(_on_game_return_requested)
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

	var result := LevelCodec.json_to_level(json_text)
	if not result["ok"]:
		_show_home("导入失败：%s" % result["error"])
		return

	_start_game(result["level"] as LevelData, &"menu")


func _make_fullscreen_root() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	return root


func _add_cover_background(root: Control) -> void:
	var texture := load(COVER_PATH) as Texture2D
	if texture:
		var cover := TextureRect.new()
		cover.set_anchors_preset(Control.PRESET_FULL_RECT)
		cover.texture = texture
		cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		root.add_child(cover)
	else:
		_add_plain_background(root)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.05, 0.04, 0.04, 0.25)
	root.add_child(shade)


func _add_plain_background(root: Control) -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.12, 0.10, 0.10)
	root.add_child(background)


func _make_button(text: String, callback: Callable, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = size
	button.pressed.connect(callback)
	return button


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
