class_name ItemData
extends Resource

enum EffectType {
	WALL,
	TOY,
	TRAP,
	NET,
}

@export var id: StringName = &"wall"
@export var display_name: String = "Wall"
@export var short_label: String = "W"
@export var ap_cost: int = 1
@export var placement_range: int = 1
@export var effect_range: int = 1
@export var effect_type: int = EffectType.WALL
@export var color: Color = Color.WHITE
