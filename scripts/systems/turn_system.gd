class_name TurnSystem
extends Node

signal turn_changed(turn_number: int)
signal phase_changed(phase: StringName)

var turn_number: int = 1
var phase: StringName = &"player"


func reset() -> void:
	turn_number = 1
	set_phase(&"player")
	turn_changed.emit(turn_number)


func set_phase(next_phase: StringName) -> void:
	if phase == next_phase:
		return

	phase = next_phase
	phase_changed.emit(phase)


func next_round() -> void:
	turn_number += 1
	turn_changed.emit(turn_number)
	set_phase(&"player")

