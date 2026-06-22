class_name Inventory
extends Node

signal inventory_changed(counts: Dictionary)

var counts: Dictionary = {}


func reset() -> void:
	counts.clear()
	inventory_changed.emit(counts.duplicate())


func add_item(id: StringName, amount: int = 1) -> void:
	counts[id] = get_count(id) + amount
	inventory_changed.emit(counts.duplicate())


func consume_item(id: StringName, amount: int = 1) -> bool:
	if get_count(id) < amount:
		return false

	counts[id] = get_count(id) - amount
	if counts[id] <= 0:
		counts.erase(id)

	inventory_changed.emit(counts.duplicate())
	return true


func get_count(id: StringName) -> int:
	return int(counts.get(id, 0))

