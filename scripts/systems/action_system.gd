class_name ActionSystem
extends Node

signal ap_changed(current_ap: int, max_ap: int)

@export var max_ap: int = 4

var current_ap: int = 4


func reset_ap() -> void:
	current_ap = max_ap
	ap_changed.emit(current_ap, max_ap)


func can_spend(cost: int) -> bool:
	return cost >= 0 and current_ap >= cost


func spend(cost: int) -> bool:
	if not can_spend(cost):
		return false

	current_ap -= cost
	ap_changed.emit(current_ap, max_ap)
	return true

