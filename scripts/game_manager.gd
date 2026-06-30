class_name GameManager
extends Node2D

const UI_THEME_SCRIPT := preload("res://scripts/ui/hand_drawn_theme.gd")
const GRID_ORIGIN := Vector2(20, 112)
const MOVE_COST := 1
const CATCH_COST := 3

signal return_requested(return_mode: StringName)
signal music_requested(track_id: StringName)
signal sting_requested(sting_id: StringName)

var grid: GridSystem
var pathfinder: PathfindingSystem
var inventory: Inventory
var action_system: ActionSystem
var turn_system: TurnSystem
var ui: UIManager
var ui_theme := UI_THEME_SCRIPT.new()

var effect_layer: Node2D
var unit_layer: Node2D
var token_layer: Node2D
var player: TacticalUnit
var cat: TacticalUnit
var item_preview_token: BoardToken
var item_preview_effect: Node2D

var level: LevelData
var item_defs: Dictionary = {}
var board_items: Dictionary = {}
var board_tokens: Dictionary = {}
var toy_effect_nodes: Dictionary = {}
var trap_cells: Dictionary = {}
var toy_cells: Dictionary = {}
var ice_cells: Dictionary = {}
var selected_item_id: StringName = &""
var pending_item_target: Vector2i = Vector2i(-1, -1)
var remaining_turns: int = 0
var cat_stun_turns: int = 0
var player_facing: StringName = &"down"
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
	ui_theme.add_paper_background(self)

	grid = GridSystem.new()
	grid.position = GRID_ORIGIN
	grid.cell_selected.connect(_on_cell_selected)
	add_child(grid)

	effect_layer = Node2D.new()
	effect_layer.position = GRID_ORIGIN
	add_child(effect_layer)

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
	ui.item_selected.connect(_select_item)
	ui.item_use_confirmed.connect(_confirm_selected_item_use)
	ui.restart_requested.connect(_restart)
	ui.back_requested.connect(_on_back_requested)
	add_child(ui)


func _load_level(next_level: LevelData) -> void:
	music_requested.emit(&"BGM_PLAY_L1")
	level = next_level
	remaining_turns = level.delay_turns
	cat_stun_turns = 0
	player_facing = &"down"
	game_finished = false
	selected_item_id = &""
	pending_item_target = Vector2i(-1, -1)
	_clear_item_preview()
	board_items.clear()
	toy_effect_nodes.clear()
	trap_cells.clear()
	toy_cells.clear()
	ice_cells.clear()

	_clear_children(effect_layer)
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
	player.set_facing(player_facing)
	unit_layer.add_child(player)

	cat = TacticalUnit.new()
	cat.configure(&"cat", level.cat_start, grid)
	unit_layer.add_child(cat)
	_refresh_unit_positions()

	inventory.reset()
	turn_system.reset()
	action_system.reset_ap()
	_cancel_selection()
	ui.hide_result()
	ui.update_inventory(inventory.counts, item_defs)
	_refresh_ui()
	_refresh_movement_highlights()


func _create_default_level() -> LevelData:
	return LevelFactory.create_tutorial_level()


func _create_item_defs() -> void:
	item_defs[&"wall"] = _make_item(&"wall", "道具墙", "墙", 1, 1, 1, ItemData.EffectType.WALL, Color(0.90, 0.60, 0.30))
	item_defs[&"obstacle_wall"] = _make_item(&"obstacle_wall", "障碍墙", "障", 0, 0, 0, ItemData.EffectType.WALL, Color(0.34, 0.34, 0.38))
	item_defs[&"toy"] = _make_item(&"toy", "玩具", "玩", 2, 2, 1, ItemData.EffectType.TOY, Color(0.97, 0.76, 0.16))
	item_defs[&"trap"] = _make_item(&"trap", "陷阱", "陷", 2, 2, 1, ItemData.EffectType.TRAP, Color(0.88, 0.18, 0.28))
	item_defs[&"net"] = _make_item(&"net", "捕捉网", "网", 3, 3, 1, ItemData.EffectType.NET, Color(0.73, 0.92, 0.86))
	item_defs[&"ice"] = _make_item(&"ice", "冰块", "冰", 2, 2, 1, ItemData.EffectType.ICE, Color(0.50, 0.90, 1.0))


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
		_select_item_target(cell)
		return

	_try_move_player(cell)


func _try_move_player(cell: Vector2i) -> void:
	var reachable_cells := _get_reachable_player_cells()
	if not reachable_cells.has(cell):
		ui.set_message("只能移动到高亮范围内的空格。")
		return

	var move_cost := int(reachable_cells[cell])
	if not action_system.spend(move_cost):
		ui.set_message("AP 不足，不能移动。")
		return

	var slide_direction := _get_direction_to_player_target(cell, reachable_cells)
	player.set_grid_position(cell, grid)
	_set_player_facing_from_direction(slide_direction)
	var slide_distance := _resolve_ice_slide(player, slide_direction, 1, true)
	if slide_distance > 0:
		ui.set_message("移动到 %s，消耗 %dAP；踩到冰块滑行 %d 格。" % [str(player.grid_position), move_cost, slide_distance])
	else:
		ui.set_message("移动到 %s，消耗 %dAP。" % [str(cell), move_cost])
	_refresh_unit_positions()
	_cancel_selection()
	_try_auto_pickup_item()


func _try_auto_pickup_item() -> void:
	if game_finished or turn_system.phase != &"player":
		return

	if not board_items.has(player.grid_position):
		return

	var entry := board_items[player.grid_position] as Dictionary
	var id := entry["id"] as StringName
	var count := int(entry["count"])
	inventory.add_item(id, count)
	board_items.erase(player.grid_position)
	if id == &"ice":
		ice_cells.erase(player.grid_position)
	elif id == &"toy":
		toy_cells.erase(player.grid_position)
		_remove_toy_attraction_zone(player.grid_position)
	_remove_board_token(player.grid_position)
	ui.set_message("拾取了 %s x%d。" % [(item_defs[id] as ItemData).display_name, count])


func _select_item(id: StringName) -> void:
	if game_finished or turn_system.phase != &"player":
		return

	if not item_defs.has(id):
		return

	if selected_item_id == id:
		_cancel_selection()
		return

	var item := item_defs[id] as ItemData
	if inventory.get_count(id) <= 0:
		ui.set_message("背包里没有这个道具。")
		return

	if not action_system.can_spend(item.ap_cost):
		ui.set_message("AP 不足，不能使用 %s。" % item.display_name)
		return

	_clear_item_preview()
	selected_item_id = id
	pending_item_target = Vector2i(-1, -1)
	var cells := _get_valid_item_targets(item)
	grid.set_highlights(cells, ui_theme.ITEM_HIGHLIGHT)
	ui.set_selection_active(true, item.display_name, id)


func _select_item_target(cell: Vector2i) -> void:
	if selected_item_id == &"":
		return

	var item := item_defs[selected_item_id] as ItemData
	var valid_targets := _get_valid_item_targets(item)
	if not valid_targets.has(cell):
		pending_item_target = Vector2i(-1, -1)
		_clear_item_preview()
		ui.set_item_target_ready(false)
		ui.set_message("这个格子不能放置/使用 %s。" % item.display_name)
		return

	if item.effect_type == ItemData.EffectType.NET and cell != cat.grid_position:
		pending_item_target = Vector2i(-1, -1)
		_clear_item_preview()
		ui.set_item_target_ready(false)
		ui.set_message("捕捉网只能捕获玩家朝向的前方一格。")
		return

	pending_item_target = cell
	_show_item_preview(cell, item)
	ui.set_item_target_ready(true)
	ui.set_message("已选择 %s 的目标格 %s，点击底部确认使用。" % [item.display_name, str(cell)])


func _confirm_selected_item_use() -> void:
	if selected_item_id == &"":
		return
	if pending_item_target == Vector2i(-1, -1):
		ui.set_message("先选择一个高亮目标格。")
		return

	_try_use_selected_item(pending_item_target)


func _try_use_selected_item(cell: Vector2i) -> void:
	if selected_item_id == &"":
		return

	var item := item_defs[selected_item_id] as ItemData
	var valid_targets := _get_valid_item_targets(item)
	if not valid_targets.has(cell):
		ui.set_message("这个格子不能放置/使用 %s。" % item.display_name)
		return

	if item.effect_type == ItemData.EffectType.NET and cell != cat.grid_position:
		ui.set_message("捕捉网只能捕获玩家朝向的前方一格。")
		return

	if not action_system.spend(item.ap_cost):
		ui.set_message("AP 不足。")
		return

	if not inventory.consume_item(item.id):
		ui.set_message("背包数量不足。")
		return

	_clear_item_preview()
	match item.effect_type:
		ItemData.EffectType.WALL:
			_place_wall(cell)
			ui.set_message("放置了墙，猫的路径会重新计算。")
		ItemData.EffectType.TOY:
			toy_cells[cell] = true
			_add_board_token(cell, item)
			_add_toy_attraction_zone(cell)
			ui.set_message("放置了玩具，小猫进入金色烟雾范围才会被吸引。")
		ItemData.EffectType.TRAP:
			trap_cells[cell] = true
			_add_board_token(cell, item)
			ui.set_message("放置了陷阱，小猫踩中会停一回合。")
		ItemData.EffectType.NET:
			ui.set_message("捕捉网命中，小猫被抓住了！")
			_finish_game(true, &"STING_CATCH")
			return
		ItemData.EffectType.ICE:
			ice_cells[cell] = true
			_add_board_token(cell, item)
			ui.set_message("放置了冰块，踩上会沿移动方向滑行。")

	_cancel_selection()


func _try_catch_cat() -> void:
	if not action_system.spend(CATCH_COST):
		ui.set_message("抓住小猫需要 3AP。")
		return

	cat_stun_turns = maxi(cat_stun_turns, 1)
	ui.set_message("你拦住了小猫，它下一回合会停住。")
	_refresh_movement_highlights()


func _end_player_turn() -> void:
	if game_finished or turn_system.phase != &"player":
		return

	_cancel_selection()
	_run_cat_turn()


func _run_cat_turn() -> void:
	turn_system.set_phase(&"cat")
	grid.clear_highlights()
	ui.set_message("小猫正在寻找最短路径...")

	if cat_stun_turns > 0:
		cat_stun_turns -= 1
		ui.set_message("小猫被控制住，停了一回合。")
	else:
		var target := _get_cat_target()
		var path := pathfinder.find_path(cat.grid_position, target, grid)
		if path.size() > 1:
			var cat_direction := path[1] - cat.grid_position
			cat.set_grid_position(path[1], grid)
			var cat_slide_distance := _resolve_ice_slide(cat, cat_direction, 2, false)
			if cat_slide_distance > 0:
				ui.set_message("小猫踩到冰块，滑行了 %d 格。" % cat_slide_distance)
			else:
				ui.set_message("小猫向目标移动了一格。")
		else:
			ui.set_message("小猫暂时找不到路。")

	_resolve_cat_cell_effects()
	_refresh_unit_positions()
	if cat.grid_position == level.button_pos:
		_finish_game(false)
		return

	remaining_turns -= 1
	if remaining_turns <= 0:
		_finish_game(true)
		return
	if remaining_turns <= 5:
		music_requested.emit(&"BGM_TENSE")

	turn_system.next_round()
	action_system.reset_ap()
	_check_pickup_hint()
	_refresh_ui()
	_refresh_movement_highlights()


func _get_cat_target() -> Vector2i:
	var best_cell := level.button_pos
	var best_path_length := 999999

	for toy_cell in toy_cells.keys():
		if not _is_cat_in_toy_effect_area(toy_cell):
			continue

		var path := pathfinder.find_path(cat.grid_position, toy_cell, grid)
		if path.size() > 0 and path.size() < best_path_length:
			best_cell = toy_cell
			best_path_length = path.size()

	return best_cell


func _is_cat_in_toy_effect_area(toy_cell: Vector2i) -> bool:
	return _get_toy_effect_cells(toy_cell).has(cat.grid_position)


func _resolve_cat_cell_effects() -> void:
	if toy_cells.has(cat.grid_position):
		toy_cells.erase(cat.grid_position)
		board_items.erase(cat.grid_position)
		_remove_toy_attraction_zone(cat.grid_position)
		_remove_board_token(cat.grid_position)
		ui.set_message("小猫被玩具吸引住，然后又想起按钮。")

	if trap_cells.has(cat.grid_position):
		trap_cells.erase(cat.grid_position)
		_remove_board_token(cat.grid_position)
		cat_stun_turns = maxi(cat_stun_turns, 1)
		ui.set_message("小猫踩中陷阱，下一回合停住。")


func _finish_game(won: bool, sting_id: StringName = &"") -> void:
	game_finished = true
	selected_item_id = &""
	pending_item_target = Vector2i(-1, -1)
	_clear_item_preview()
	grid.clear_highlights()
	turn_system.set_phase(&"finished")
	ui.update_status(action_system.current_ap, action_system.max_ap, turn_system.turn_number, remaining_turns, turn_system.phase)
	ui.set_selection_active(false, "")
	ui.show_result(won)
	if sting_id != &"":
		sting_requested.emit(sting_id)
	elif won:
		sting_requested.emit(&"STING_WIN")
	else:
		sting_requested.emit(&"STING_LOSE")


func _restart() -> void:
	if _active_level:
		_load_level(_duplicate_level(_active_level))
	else:
		_load_level(_create_default_level())


func _on_back_requested() -> void:
	return_requested.emit(_active_return_mode)


func _cancel_selection() -> void:
	selected_item_id = &""
	pending_item_target = Vector2i(-1, -1)
	_clear_item_preview()
	if ui:
		ui.set_selection_active(false, "")
		_check_pickup_hint()
	_refresh_movement_highlights()


func _get_valid_item_targets(item: ItemData) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if item.effect_type == ItemData.EffectType.NET:
		var target_cell := _get_player_front_cell()
		if grid.is_inside(target_cell) and not grid.is_blocked(target_cell):
			cells.append(target_cell)
		return cells

	var offsets := _get_item_target_offsets(item)

	for offset in offsets:
		var cell := player.grid_position + offset
		if not grid.is_inside(cell):
			continue
		if cell == player.grid_position or cell == level.button_pos:
			continue
		if grid.is_blocked(cell):
			continue

		if cell == cat.grid_position:
			continue
		if board_items.has(cell) or trap_cells.has(cell) or toy_cells.has(cell) or ice_cells.has(cell):
			continue

		cells.append(cell)

	return cells


func _get_item_target_offsets(item: ItemData) -> Array[Vector2i]:
	match item.effect_type:
		ItemData.EffectType.WALL:
			return _get_manhattan_ring_offsets(2)
		ItemData.EffectType.TOY:
			var offsets: Array[Vector2i] = [
				Vector2i(-1, -2),
				Vector2i(1, -2),
				Vector2i(-2, -1),
				Vector2i(2, -1),
				Vector2i(-2, 1),
				Vector2i(2, 1),
				Vector2i(-1, 2),
				Vector2i(1, 2),
			]
			return offsets
		ItemData.EffectType.TRAP:
			return _get_trap_target_offsets()
		ItemData.EffectType.NET:
			var offsets: Array[Vector2i] = [_get_facing_offset()]
			return offsets
		ItemData.EffectType.ICE:
			return _get_ice_target_offsets()

	return _get_king_offsets()


func _get_manhattan_ring_offsets(distance: int) -> Array[Vector2i]:
	var offsets: Array[Vector2i] = []
	for y in range(-distance, distance + 1):
		for x in range(-distance, distance + 1):
			if x == 0 and y == 0:
				continue
			if absi(x) + absi(y) == distance:
				offsets.append(Vector2i(x, y))

	return offsets


func _get_trap_target_offsets() -> Array[Vector2i]:
	var offsets: Array[Vector2i] = []
	for y in range(-2, 3):
		for x in range(-2, 3):
			if x == 0 and y == 0:
				continue
			if maxi(absi(x), absi(y)) != 2:
				continue
			if (x == 0 and absi(y) == 2) or (absi(x) == 2 and y == 0):
				continue
			offsets.append(Vector2i(x, y))

	return offsets


func _get_ice_target_offsets() -> Array[Vector2i]:
	var offsets: Array[Vector2i] = []
	for y in range(-2, 3):
		for x in range(-2, 3):
			if x == 0 and y == 0:
				continue
			if maxi(absi(x), absi(y)) > 2:
				continue
			if absi(x) == 2 and absi(y) == 2:
				continue
			offsets.append(Vector2i(x, y))

	return offsets


func _is_player_move_target(cell: Vector2i) -> bool:
	return _get_reachable_player_cells().has(cell)


func _refresh_movement_highlights() -> void:
	if not grid or not player or not action_system or not turn_system:
		return

	if game_finished or turn_system.phase != &"player" or selected_item_id != &"":
		grid.clear_highlights()
		return

	var highlight_cells: Array[Vector2i] = []
	for cell in _get_reachable_player_cells().keys():
		highlight_cells.append(cell)

	grid.set_highlights(highlight_cells, ui_theme.MOVE_HIGHLIGHT)


func _get_reachable_player_cells() -> Dictionary:
	var reachable := {}
	if not player or not action_system:
		return reachable

	if action_system.current_ap < MOVE_COST:
		return reachable

	for offset in _get_cardinal_move_offsets():
		var next_cell := player.grid_position + offset
		if not grid.is_inside(next_cell):
			continue
		if grid.is_blocked(next_cell):
			continue

		reachable[next_cell] = MOVE_COST

	return reachable


func _get_direction_to_player_target(target: Vector2i, reachable_cells: Dictionary) -> Vector2i:
	var current := target
	var current_cost := int(reachable_cells.get(current, 0))

	while current_cost > MOVE_COST:
		var previous := _find_previous_reachable_step(current, current_cost, reachable_cells)
		if previous == current:
			break

		current = previous
		current_cost = int(reachable_cells.get(current, MOVE_COST))

	return current - player.grid_position


func _find_previous_reachable_step(cell: Vector2i, cost: int, reachable_cells: Dictionary) -> Vector2i:
	for offset in _get_cardinal_move_offsets():
		var candidate := cell + offset
		if candidate == player.grid_position and cost == MOVE_COST:
			return candidate
		if reachable_cells.has(candidate) and int(reachable_cells[candidate]) == cost - MOVE_COST:
			return candidate

	return cell


func _resolve_ice_slide(unit: TacticalUnit, direction: Vector2i, max_steps: int, is_player: bool) -> int:
	if direction == Vector2i.ZERO:
		return 0
	if not ice_cells.has(unit.grid_position):
		return 0

	var moved_steps := 0
	for _step in range(max_steps):
		var next_cell := unit.grid_position + direction
		if not _can_slide_into(next_cell, is_player):
			break

		unit.set_grid_position(next_cell, grid)
		moved_steps += 1
		if not is_player and unit.grid_position == level.button_pos:
			break

	return moved_steps


func _can_slide_into(cell: Vector2i, _is_player: bool) -> bool:
	if not grid.is_inside(cell):
		return false
	if grid.is_blocked(cell):
		return false

	return true


func _refresh_unit_positions() -> void:
	if not player or not cat or not grid:
		return

	player.set_facing(player_facing)
	player.position = grid.grid_to_local_center(player.grid_position)
	cat.position = grid.grid_to_local_center(cat.grid_position)
	if player.grid_position == cat.grid_position:
		var offset := Vector2(grid.cell_size * 0.14, 0.0)
		player.position -= offset
		cat.position += offset


func _set_player_facing_from_direction(direction: Vector2i) -> void:
	if direction == Vector2i(0, -1):
		player_facing = &"up"
	elif direction == Vector2i(0, 1):
		player_facing = &"down"
	elif direction == Vector2i(-1, 0):
		player_facing = &"left"
	elif direction == Vector2i(1, 0):
		player_facing = &"right"

	if player:
		player.set_facing(player_facing)


func _get_player_front_cell() -> Vector2i:
	return player.grid_position + _get_facing_offset()


func _get_facing_offset() -> Vector2i:
	match player_facing:
		&"up":
			return Vector2i(0, -1)
		&"left":
			return Vector2i(-1, 0)
		&"right":
			return Vector2i(1, 0)
		_:
			return Vector2i(0, 1)


func _get_cardinal_move_offsets() -> Array[Vector2i]:
	return [
		Vector2i(0, -1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, 1),
	]


func _get_king_offsets() -> Array[Vector2i]:
	return [
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
		Vector2i(1, 1),
	]


func _place_wall(cell: Vector2i) -> void:
	if not grid.is_inside(cell):
		return

	grid.set_blocked(cell, true)
	_add_board_token(cell, item_defs[&"obstacle_wall"] as ItemData)


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


func _show_item_preview(cell: Vector2i, item: ItemData) -> void:
	_clear_item_preview()
	var preview_item := item
	if item.effect_type == ItemData.EffectType.WALL:
		preview_item = item_defs[&"obstacle_wall"] as ItemData

	item_preview_token = BoardToken.new()
	item_preview_token.configure(preview_item.id, preview_item.short_label, preview_item.color, cell, grid)
	item_preview_token.modulate = Color(1.0, 1.0, 1.0, 0.62)
	item_preview_token.z_index = 30
	token_layer.add_child(item_preview_token)

	if item.effect_type == ItemData.EffectType.TOY:
		item_preview_effect = ToyAttractionZone.new()
		item_preview_effect.modulate = Color(1.0, 1.0, 1.0, 0.72)
		item_preview_effect.z_index = 20
		(item_preview_effect as ToyAttractionZone).configure(_get_toy_effect_cells(cell), grid)
		effect_layer.add_child(item_preview_effect)


func _clear_item_preview() -> void:
	if item_preview_effect:
		item_preview_effect.queue_free()
		item_preview_effect = null
	if item_preview_token:
		item_preview_token.queue_free()
		item_preview_token = null


func _remove_board_token(cell: Vector2i) -> void:
	_remove_toy_attraction_zone(cell)
	if not board_tokens.has(cell):
		return

	var token := board_tokens[cell] as Node
	board_tokens.erase(cell)
	token.queue_free()


func _add_toy_attraction_zone(cell: Vector2i) -> void:
	_remove_toy_attraction_zone(cell)
	var zone := ToyAttractionZone.new()
	zone.configure(_get_toy_effect_cells(cell), grid)
	effect_layer.add_child(zone)
	toy_effect_nodes[cell] = zone


func _remove_toy_attraction_zone(cell: Vector2i) -> void:
	if not toy_effect_nodes.has(cell):
		return

	var zone := toy_effect_nodes[cell] as Node
	toy_effect_nodes.erase(cell)
	zone.queue_free()


func _get_toy_effect_cells(toy_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in _get_toy_effect_offsets():
		var cell := toy_cell + offset
		if grid.is_inside(cell):
			cells.append(cell)

	return cells


func _get_toy_effect_offsets() -> Array[Vector2i]:
	var offsets: Array[Vector2i] = []
	for y in range(-2, 3):
		for x in range(-2, 3):
			if x == 0 and y == 0:
				continue
			if absi(x) == 2 and absi(y) == 2:
				continue
			offsets.append(Vector2i(x, y))

	return offsets


func _check_pickup_hint() -> void:
	if not ui:
		return

	var can_pickup := board_items.has(player.grid_position)
	if can_pickup and selected_item_id == &"":
		var entry := board_items[player.grid_position] as Dictionary
		var id := entry["id"] as StringName
		ui.set_message("脚下有 %s，移动结束后会自动拾取。" % (item_defs[id] as ItemData).display_name)


func _on_inventory_changed(counts: Dictionary) -> void:
	if ui:
		ui.update_inventory(counts, item_defs)


func _on_ap_changed(_current_ap: int, _max_ap: int) -> void:
	_refresh_ui()
	_refresh_movement_highlights()


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
