class_name GameManager
extends Node2D

const GRID_ORIGIN := Vector2(40, 150)
const MOVE_COST := 1
const CATCH_COST := 3

signal return_requested(return_mode: StringName)

var grid: GridSystem
var pathfinder: PathfindingSystem
var inventory: Inventory
var action_system: ActionSystem
var turn_system: TurnSystem
var ui: UIManager

var unit_layer: Node2D
var token_layer: Node2D
var player: TacticalUnit
var cat: TacticalUnit

var level: LevelData
var item_defs: Dictionary = {}
var board_items: Dictionary = {}
var board_tokens: Dictionary = {}
var trap_cells: Dictionary = {}
var toy_cells: Dictionary = {}
var selected_item_id: StringName = &""
var remaining_turns: int = 0
var cat_stun_turns: int = 0
var game_finished: bool = false
var _nodes_created: bool = false
var _active_return_mode: StringName = &"menu"
var _active_level: LevelData


func _ready() -> void:
	_ensure_game_nodes()


func start_level(next_level: LevelData, return_mode: StringName = &"menu") -> void:
	_ensure_game_nodes()
	_active_return_mode = return_mode
	_active_level = _duplicate_level(next_level)
	_load_level(_active_level)


func _ensure_game_nodes() -> void:
	if _nodes_created:
		return

	_ensure_input_actions()
	_create_item_defs()
	_create_scene_nodes()
	_nodes_created = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		_cancel_selection()
	elif event.is_action_pressed("end_turn"):
		_end_player_turn()
	elif event.is_action_pressed("restart"):
		_restart()
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_cancel_selection()


func _create_scene_nodes() -> void:
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

	pathfinder = PathfindingSystem.new()
	add_child(pathfinder)

	inventory = Inventory.new()
	inventory.inventory_changed.connect(_on_inventory_changed)
	add_child(inventory)

	action_system = ActionSystem.new()
	action_system.ap_changed.connect(_on_ap_changed)
	add_child(action_system)

	turn_system = TurnSystem.new()
	turn_system.phase_changed.connect(_on_phase_changed)
	turn_system.turn_changed.connect(_on_turn_changed)
	add_child(turn_system)

	ui = UIManager.new()
	ui.build(item_defs)
	ui.end_turn_requested.connect(_end_player_turn)
	ui.pickup_requested.connect(_try_pickup_item)
	ui.item_selected.connect(_select_item)
	ui.cancel_requested.connect(_cancel_selection)
	ui.restart_requested.connect(_restart)
	ui.back_requested.connect(_on_back_requested)
	add_child(ui)


func _load_level(next_level: LevelData) -> void:
	level = next_level
	remaining_turns = level.delay_turns
	cat_stun_turns = 0
	game_finished = false
	selected_item_id = &""
	board_items.clear()
	trap_cells.clear()
	toy_cells.clear()

	_clear_children(token_layer)
	_clear_children(unit_layer)
	board_tokens.clear()

	grid.setup(level.board_size, level.button_pos)
	for wall_cell in level.walls:
		_place_wall(wall_cell)

	for item_entry in level.items:
		var id := item_entry.get("id", &"wall") as StringName
		var item_cell := item_entry.get("position", Vector2i.ZERO) as Vector2i
		var count := int(item_entry.get("count", 1))
		_add_board_item(item_cell, id, count)

	player = TacticalUnit.new()
	player.configure(&"player", level.player_start, grid)
	unit_layer.add_child(player)

	cat = TacticalUnit.new()
	cat.configure(&"cat", level.cat_start, grid)
	unit_layer.add_child(cat)

	inventory.reset()
	turn_system.reset()
	action_system.reset_ap()
	_cancel_selection()
	ui.hide_result()
	ui.update_inventory(inventory.counts, item_defs)
	_refresh_ui()


func _create_default_level() -> LevelData:
	return LevelFactory.create_tutorial_level()


func _create_item_defs() -> void:
	item_defs[&"wall"] = _make_item(&"wall", "墙", "墙", 1, 1, 1, ItemData.EffectType.WALL, Color(0.45, 0.24, 0.24))
	item_defs[&"toy"] = _make_item(&"toy", "玩具", "玩", 2, 2, 1, ItemData.EffectType.TOY, Color(0.97, 0.76, 0.16))
	item_defs[&"trap"] = _make_item(&"trap", "陷阱", "陷", 2, 2, 1, ItemData.EffectType.TRAP, Color(0.08, 0.75, 0.78))
	item_defs[&"net"] = _make_item(&"net", "捕捉网", "网", 3, 3, 1, ItemData.EffectType.NET, Color(0.73, 0.92, 0.86))


func _make_item(
	id: StringName,
	display_name: String,
	short_label: String,
	ap_cost: int,
	placement_range: int,
	effect_range: int,
	effect_type: int,
	color: Color
) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.display_name = display_name
	item.short_label = short_label
	item.ap_cost = ap_cost
	item.placement_range = placement_range
	item.effect_range = effect_range
	item.effect_type = effect_type
	item.color = color
	return item


func _on_cell_selected(cell: Vector2i) -> void:
	if game_finished or turn_system.phase != &"player":
		return

	if selected_item_id != &"":
		_try_use_selected_item(cell)
		return

	if cell == cat.grid_position and _grid_distance(player.grid_position, cat.grid_position) <= 1:
		_try_catch_cat()
	elif cell == player.grid_position and board_items.has(cell):
		_try_pickup_item()
	else:
		_try_move_player(cell)


func _try_move_player(cell: Vector2i) -> void:
	if not _is_player_move_target(cell):
		ui.set_message("只能移动到相邻的空格。")
		return

	if not action_system.spend(MOVE_COST):
		ui.set_message("AP 不足，不能移动。")
		return

	player.set_grid_position(cell, grid)
	ui.set_message("移动到 %s。" % str(cell))
	_cancel_selection()
	_check_pickup_hint()


func _try_pickup_item() -> void:
	if game_finished or turn_system.phase != &"player":
		return

	if not board_items.has(player.grid_position):
		ui.set_message("脚下没有可拾取道具。")
		return

	var entry := board_items[player.grid_position] as Dictionary
	var id := entry["id"] as StringName
	var count := int(entry["count"])
	inventory.add_item(id, count)
	board_items.erase(player.grid_position)
	_remove_board_token(player.grid_position)
	ui.set_message("拾取了 %s x%d。" % [(item_defs[id] as ItemData).display_name, count])
	_check_pickup_hint()


func _select_item(id: StringName) -> void:
	if game_finished or turn_system.phase != &"player":
		return

	if not item_defs.has(id):
		return

	var item := item_defs[id] as ItemData
	if inventory.get_count(id) <= 0:
		ui.set_message("背包里没有这个道具。")
		return

	if not action_system.can_spend(item.ap_cost):
		ui.set_message("AP 不足，不能使用 %s。" % item.display_name)
		return

	selected_item_id = id
	var cells := _get_valid_item_targets(item)
	grid.set_highlights(cells, Color(0.96, 0.22, 0.56, 0.42))
	ui.set_selection_active(true, item.display_name)


func _try_use_selected_item(cell: Vector2i) -> void:
	if selected_item_id == &"":
		return

	var item := item_defs[selected_item_id] as ItemData
	var valid_targets := _get_valid_item_targets(item)
	if not valid_targets.has(cell):
		ui.set_message("这个格子不能放置/使用 %s。" % item.display_name)
		return

	if not action_system.spend(item.ap_cost):
		ui.set_message("AP 不足。")
		return

	if not inventory.consume_item(item.id):
		ui.set_message("背包数量不足。")
		return

	match item.effect_type:
		ItemData.EffectType.WALL:
			_place_wall(cell)
			ui.set_message("放置了墙，猫的路径会重新计算。")
		ItemData.EffectType.TOY:
			toy_cells[cell] = true
			_add_board_token(cell, item)
			ui.set_message("放置了玩具，小猫会优先过去。")
		ItemData.EffectType.TRAP:
			trap_cells[cell] = true
			_add_board_token(cell, item)
			ui.set_message("放置了陷阱，小猫踩中会停一回合。")
		ItemData.EffectType.NET:
			cat_stun_turns = maxi(cat_stun_turns, 1)
			ui.set_message("捕捉网命中，小猫下一回合会停住。")

	_cancel_selection()


func _try_catch_cat() -> void:
	if not action_system.spend(CATCH_COST):
		ui.set_message("抓住小猫需要 3AP。")
		return

	cat_stun_turns = maxi(cat_stun_turns, 1)
	ui.set_message("你拦住了小猫，它下一回合会停住。")


func _end_player_turn() -> void:
	if game_finished or turn_system.phase != &"player":
		return

	_cancel_selection()
	_run_cat_turn()


func _run_cat_turn() -> void:
	turn_system.set_phase(&"cat")
	ui.set_message("小猫正在寻找最短路径...")

	if cat_stun_turns > 0:
		cat_stun_turns -= 1
		ui.set_message("小猫被控制住，停了一回合。")
	else:
		var target := _get_cat_target()
		var path := pathfinder.find_path_with_blockers(cat.grid_position, target, grid, [player.grid_position])
		if path.size() > 1:
			cat.set_grid_position(path[1], grid)
			ui.set_message("小猫向目标移动了一格。")
		else:
			ui.set_message("小猫暂时找不到路。")

	_resolve_cat_cell_effects()
	if cat.grid_position == level.button_pos:
		_finish_game(false)
		return

	remaining_turns -= 1
	if remaining_turns <= 0:
		_finish_game(true)
		return

	turn_system.next_round()
	action_system.reset_ap()
	_check_pickup_hint()
	_refresh_ui()


func _get_cat_target() -> Vector2i:
	var best_cell := level.button_pos
	var best_path_length := 999999

	for toy_cell in toy_cells.keys():
		var path := pathfinder.find_path_with_blockers(cat.grid_position, toy_cell, grid, [player.grid_position])
		if path.size() > 0 and path.size() < best_path_length:
			best_cell = toy_cell
			best_path_length = path.size()

	return best_cell


func _resolve_cat_cell_effects() -> void:
	if toy_cells.has(cat.grid_position):
		toy_cells.erase(cat.grid_position)
		_remove_board_token(cat.grid_position)
		ui.set_message("小猫被玩具吸引住，然后又想起按钮。")

	if trap_cells.has(cat.grid_position):
		trap_cells.erase(cat.grid_position)
		_remove_board_token(cat.grid_position)
		cat_stun_turns = maxi(cat_stun_turns, 1)
		ui.set_message("小猫踩中陷阱，下一回合停住。")


func _finish_game(won: bool) -> void:
	game_finished = true
	grid.clear_highlights()
	turn_system.set_phase(&"finished")
	ui.update_status(action_system.current_ap, action_system.max_ap, turn_system.turn_number, remaining_turns, turn_system.phase)
	ui.show_result(won)


func _restart() -> void:
	if _active_level:
		_load_level(_duplicate_level(_active_level))
	else:
		_load_level(_create_default_level())


func _on_back_requested() -> void:
	return_requested.emit(_active_return_mode)


func _cancel_selection() -> void:
	selected_item_id = &""
	grid.clear_highlights()
	if ui:
		ui.set_selection_active(false, "")
		_check_pickup_hint()


func _get_valid_item_targets(item: ItemData) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	if item.effect_type == ItemData.EffectType.NET:
		if _grid_distance(player.grid_position, cat.grid_position) <= item.placement_range:
			cells.append(cat.grid_position)
		return cells

	for y in level.board_size.y:
		for x in level.board_size.x:
			var cell := Vector2i(x, y)
			if _grid_distance(player.grid_position, cell) > item.placement_range:
				continue
			if cell == player.grid_position or cell == cat.grid_position or cell == level.button_pos:
				continue
			if grid.is_blocked(cell) or board_items.has(cell) or trap_cells.has(cell) or toy_cells.has(cell):
				continue

			cells.append(cell)

	return cells


func _is_player_move_target(cell: Vector2i) -> bool:
	if not grid.is_inside(cell):
		return false
	if grid.is_blocked(cell):
		return false
	if cell == cat.grid_position:
		return false
	var distance := _grid_distance(player.grid_position, cell)
	return distance == 1


func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _place_wall(cell: Vector2i) -> void:
	if not grid.is_inside(cell):
		return

	grid.set_blocked(cell, true)
	_add_board_token(cell, item_defs[&"wall"] as ItemData)


func _add_board_item(cell: Vector2i, id: StringName, count: int) -> void:
	if not item_defs.has(id) or not grid.is_inside(cell):
		return

	board_items[cell] = {"id": id, "count": count}
	_add_board_token(cell, item_defs[id] as ItemData)


func _add_board_token(cell: Vector2i, item: ItemData) -> void:
	_remove_board_token(cell)
	var token := BoardToken.new()
	token.configure(item.id, item.short_label, item.color, cell, grid)
	token_layer.add_child(token)
	board_tokens[cell] = token


func _remove_board_token(cell: Vector2i) -> void:
	if not board_tokens.has(cell):
		return

	var token := board_tokens[cell] as Node
	board_tokens.erase(cell)
	token.queue_free()


func _check_pickup_hint() -> void:
	if not ui:
		return

	var can_pickup := board_items.has(player.grid_position)
	ui.set_pickup_enabled(can_pickup)
	if can_pickup and selected_item_id == &"":
		var entry := board_items[player.grid_position] as Dictionary
		var id := entry["id"] as StringName
		ui.set_message("脚下有 %s，点击拾取。" % (item_defs[id] as ItemData).display_name)


func _on_inventory_changed(counts: Dictionary) -> void:
	if ui:
		ui.update_inventory(counts, item_defs)


func _on_ap_changed(_current_ap: int, _max_ap: int) -> void:
	_refresh_ui()


func _on_phase_changed(_phase: StringName) -> void:
	_refresh_ui()


func _on_turn_changed(_turn_number: int) -> void:
	_refresh_ui()


func _refresh_ui() -> void:
	if ui and action_system and turn_system:
		ui.update_status(action_system.current_ap, action_system.max_ap, turn_system.turn_number, remaining_turns, turn_system.phase)


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()


func _ensure_input_actions() -> void:
	_add_key_action("end_turn", KEY_SPACE)
	_add_key_action("cancel", KEY_ESCAPE)
	_add_key_action("restart", KEY_R)


func _add_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var event := InputEventKey.new()
	event.keycode = keycode
	for existing_event in InputMap.action_get_events(action_name):
		if existing_event is InputEventKey and (existing_event as InputEventKey).keycode == keycode:
			return

	InputMap.action_add_event(action_name, event)


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
