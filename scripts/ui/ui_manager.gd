class_name UIManager
extends CanvasLayer

signal end_turn_requested
signal pickup_requested
signal item_selected(id: StringName)
signal cancel_requested
signal restart_requested
signal back_requested

var _ap_label: Label
var _turn_label: Label
var _remaining_label: Label
var _phase_label: Label
var _message_label: Label
var _inventory_box: HBoxContainer
var _pickup_button: Button
var _cancel_button: Button
var _result_panel: PanelContainer
var _result_label: Label
var _current_ap: int = 0
var _inventory_counts: Dictionary = {}
var _item_defs: Dictionary = {}
var _selected_item_id: StringName = &""


func build(item_defs: Dictionary) -> void:
	_item_defs = item_defs

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(20, 18)
	top_panel.custom_minimum_size = Vector2(680, 112)
	root.add_child(top_panel)

	var top_column := VBoxContainer.new()
	top_column.add_theme_constant_override("separation", 8)
	top_panel.add_child(top_column)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	top_column.add_child(top_row)

	_ap_label = _make_status_label()
	_turn_label = _make_status_label()
	_remaining_label = _make_status_label()
	_phase_label = _make_status_label()
	top_row.add_child(_ap_label)
	top_row.add_child(_turn_label)
	top_row.add_child(_remaining_label)
	top_row.add_child(_phase_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	top_column.add_child(action_row)

	_pickup_button = Button.new()
	_pickup_button.text = "拾取"
	_pickup_button.custom_minimum_size = Vector2(150, 42)
	_pickup_button.pressed.connect(_on_pickup_button_pressed)
	action_row.add_child(_pickup_button)

	var end_turn_button := Button.new()
	end_turn_button.text = "结束回合"
	end_turn_button.custom_minimum_size = Vector2(180, 42)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	action_row.add_child(end_turn_button)

	_cancel_button = Button.new()
	_cancel_button.text = "取消"
	_cancel_button.custom_minimum_size = Vector2(150, 42)
	_cancel_button.pressed.connect(_on_cancel_button_pressed)
	action_row.add_child(_cancel_button)

	var back_button := Button.new()
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(150, 42)
	back_button.pressed.connect(_on_back_button_pressed)
	action_row.add_child(back_button)

	_inventory_box = HBoxContainer.new()
	_inventory_box.position = Vector2(20, 810)
	_inventory_box.add_theme_constant_override("separation", 10)
	root.add_child(_inventory_box)

	for id in [&"wall", &"toy", &"trap", &"net", &"ice"]:
		var item := item_defs[id] as ItemData
		var button := _make_inventory_button(item)
		_inventory_box.add_child(button)

	_message_label = Label.new()
	_message_label.position = Vector2(20, 900)
	_message_label.custom_minimum_size = Vector2(680, 80)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.add_theme_font_size_override("font_size", 19)
	root.add_child(_message_label)

	_result_panel = PanelContainer.new()
	_result_panel.visible = false
	_result_panel.position = Vector2(180, 520)
	_result_panel.custom_minimum_size = Vector2(360, 190)
	root.add_child(_result_panel)

	var result_column := VBoxContainer.new()
	result_column.alignment = BoxContainer.ALIGNMENT_CENTER
	result_column.add_theme_constant_override("separation", 18)
	_result_panel.add_child(result_column)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 30)
	result_column.add_child(_result_label)

	var restart_button := Button.new()
	restart_button.text = "重新开始"
	restart_button.custom_minimum_size = Vector2(180, 48)
	restart_button.pressed.connect(_on_restart_button_pressed)
	result_column.add_child(restart_button)

	set_message("点击相邻格移动，站在道具上可拾取。")
	set_selection_active(false, "")


func update_status(ap: int, max_ap: int, turn_number: int, remaining_turns: int, phase: StringName) -> void:
	_current_ap = ap

	var phase_text := "玩家"
	if phase == &"cat":
		phase_text = "小猫"
	elif phase == &"finished":
		phase_text = "结束"

	_ap_label.text = "AP %d/%d" % [ap, max_ap]
	_turn_label.text = "回合 %d" % turn_number
	_remaining_label.text = "剩余拖延 %d" % remaining_turns
	_phase_label.text = "阶段 %s" % phase_text
	_refresh_inventory_buttons()


func update_inventory(counts: Dictionary, item_defs: Dictionary) -> void:
	_inventory_counts = counts
	_item_defs = item_defs
	_refresh_inventory_buttons()


func set_selection_active(active: bool, item_name: String, item_id: StringName = &"") -> void:
	_selected_item_id = item_id if active else &""
	_cancel_button.visible = active
	_refresh_inventory_buttons()
	if active:
		set_message("选择 %s 的目标格，右键或 Esc 取消。" % item_name)


func _refresh_inventory_buttons() -> void:
	if not _inventory_box:
		return

	for child in _inventory_box.get_children():
		var button := child as Button
		var id := StringName(button.name)
		if not _item_defs.has(id):
			continue

		var item := _item_defs[id] as ItemData
		var count := int(_inventory_counts.get(id, 0))
		var count_label := button.get_node("Content/CountLabel") as Label
		var ap_label := button.get_node("Content/ApLabel") as Label
		count_label.text = "%s x%d" % [item.display_name, count]
		ap_label.text = "%dAP" % item.ap_cost
		button.disabled = count <= 0 or _current_ap < item.ap_cost
		button.button_pressed = _selected_item_id == id


func set_pickup_enabled(enabled: bool) -> void:
	_pickup_button.disabled = not enabled


func set_message(message: String) -> void:
	_message_label.text = message


func show_result(won: bool) -> void:
	_result_panel.visible = true
	_result_label.text = "胜利！\n小猫被拦住了" if won else "失败！\n小猫按到按钮"


func hide_result() -> void:
	_result_panel.visible = false


func _make_status_label() -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(160, 34)
	label.add_theme_font_size_override("font_size", 18)
	return label


func _make_inventory_button(item: ItemData) -> Button:
	var button := Button.new()
	button.name = String(item.id)
	button.custom_minimum_size = Vector2(126, 86)
	button.text = ""
	button.toggle_mode = true
	button.pressed.connect(_on_inventory_button_pressed.bind(item.id))

	var content := VBoxContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 6
	content.offset_top = 4
	content.offset_right = -6
	content.offset_bottom = -4
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 0)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)

	var icon := ItemIcon.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(40, 38)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.configure(item.id, item.color)
	content.add_child(icon)

	var count_label := Label.new()
	count_label.name = "CountLabel"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 13)
	count_label.text = "%s x0" % item.display_name
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(count_label)

	var ap_label := Label.new()
	ap_label.name = "ApLabel"
	ap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ap_label.add_theme_font_size_override("font_size", 12)
	ap_label.text = "%dAP" % item.ap_cost
	ap_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(ap_label)

	return button


func _on_inventory_button_pressed(id: StringName) -> void:
	item_selected.emit(id)


func _on_pickup_button_pressed() -> void:
	pickup_requested.emit()


func _on_end_turn_button_pressed() -> void:
	end_turn_requested.emit()


func _on_cancel_button_pressed() -> void:
	cancel_requested.emit()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()


func _on_back_button_pressed() -> void:
	back_requested.emit()
