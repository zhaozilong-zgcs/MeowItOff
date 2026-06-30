class_name HandDrawnTheme
extends RefCounted

var PAPER := Color(0.98, 0.91, 0.78)
var PAPER_LIGHT := Color(1.0, 0.96, 0.84)
var PAPER_DARK := Color(0.89, 0.75, 0.56)
var BACKGROUND := Color(0.51, 0.47, 0.40)
var BACKGROUND_WASH := Color(1.0, 0.84, 0.54, 0.16)
var BACKGROUND_SHADOW := Color(0.20, 0.13, 0.08, 0.12)
var INK := Color(0.16, 0.11, 0.08)
var INK_FADED := Color(0.38, 0.27, 0.19)
var CAT_ORANGE := Color(0.96, 0.48, 0.18)
var GOLD := Color(0.98, 0.75, 0.22)
var DISABLED := Color(0.62, 0.56, 0.49)
var BOARD_LIGHT := Color(0.92, 0.90, 0.80)
var BOARD_DARK := Color(0.07, 0.08, 0.07)
var BOARD_LINE := Color(0.24, 0.18, 0.12, 0.58)
var MOVE_HIGHLIGHT := Color(0.37, 0.88, 0.44, 0.42)
var ITEM_HIGHLIGHT := Color(0.98, 0.70, 0.25, 0.50)
var TOY_SMOKE := Color(1.0, 0.72, 0.20, 0.20)


func apply_panel(panel: PanelContainer, variant: StringName = &"paper") -> void:
	var bg := PAPER
	var border := INK
	if variant == &"dark":
		bg = Color(0.18, 0.14, 0.11, 0.92)
		border = PAPER_LIGHT
	elif variant == &"warm":
		bg = Color(1.0, 0.88, 0.62)

	panel.add_theme_stylebox_override("panel", _make_stylebox(bg, border, 8, 3, Vector2(3, 4)))


func add_paper_background(parent: Node, viewport_size: Vector2 = Vector2(720, 1280)) -> void:
	var background := ColorRect.new()
	background.size = viewport_size
	background.color = BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(background)

	var wash := ColorRect.new()
	wash.size = viewport_size
	wash.color = BACKGROUND_WASH
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(wash)

	var shadow := ColorRect.new()
	shadow.size = Vector2(viewport_size.x, viewport_size.y * 0.30)
	shadow.color = BACKGROUND_SHADOW
	shadow.position = Vector2(0, viewport_size.y * 0.70)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shadow)


func add_control_background(root: Control) -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background)

	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.color = BACKGROUND_WASH
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wash)

	var shadow := ColorRect.new()
	shadow.anchor_left = 0.0
	shadow.anchor_top = 0.70
	shadow.anchor_right = 1.0
	shadow.anchor_bottom = 1.0
	shadow.offset_left = 0.0
	shadow.offset_top = 0.0
	shadow.offset_right = 0.0
	shadow.offset_bottom = 0.0
	shadow.color = BACKGROUND_SHADOW
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shadow)


func apply_button(button: Button, variant: StringName = &"paper") -> void:
	var base := PAPER_LIGHT
	var hover := Color(1.0, 0.89, 0.60)
	var pressed := GOLD
	if variant == &"accent":
		base = Color(1.0, 0.78, 0.44)
		hover = Color(1.0, 0.84, 0.54)
		pressed = CAT_ORANGE
	elif variant == &"quiet":
		base = Color(0.90, 0.82, 0.68)
		hover = PAPER
		pressed = PAPER_DARK

	button.add_theme_stylebox_override("normal", _make_stylebox(base, INK, 8, 3, Vector2(2, 3)))
	button.add_theme_stylebox_override("hover", _make_stylebox(hover, INK, 8, 3, Vector2(2, 3)))
	button.add_theme_stylebox_override("pressed", _make_stylebox(pressed, INK, 8, 4, Vector2(1, 2)))
	button.add_theme_stylebox_override("disabled", _make_stylebox(Color(0.72, 0.67, 0.58), DISABLED, 8, 2, Vector2.ZERO))
	button.add_theme_stylebox_override("focus", _make_stylebox(Color(1.0, 0.95, 0.72, 0.35), CAT_ORANGE, 8, 2, Vector2.ZERO))
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.38, 0.34, 0.30))
	button.add_theme_font_size_override("font_size", 18)


func apply_inventory_button(button: Button) -> void:
	apply_button(button, &"quiet")
	button.add_theme_stylebox_override("pressed", _make_stylebox(Color(1.0, 0.83, 0.38), CAT_ORANGE, 8, 4, Vector2(1, 2)))
	button.add_theme_stylebox_override("hover", _make_stylebox(Color(0.95, 0.87, 0.70), INK, 8, 3, Vector2(2, 3)))


func apply_label(label: Label, size: int = 18, emphasis: bool = false) -> void:
	label.add_theme_color_override("font_color", INK)
	label.add_theme_color_override("font_shadow_color", Color(1.0, 0.94, 0.78, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", size)
	if emphasis:
		label.add_theme_color_override("font_color", Color(0.12, 0.08, 0.05))


func apply_message_label(label: Label) -> void:
	apply_label(label, 19)
	label.add_theme_color_override("font_color", PAPER_LIGHT)
	label.add_theme_color_override("font_shadow_color", Color(0.06, 0.04, 0.03, 0.85))


func apply_spinbox(spinbox: SpinBox) -> void:
	spinbox.add_theme_stylebox_override("normal", _make_stylebox(PAPER_LIGHT, INK, 8, 3, Vector2(1, 2)))
	spinbox.add_theme_stylebox_override("focus", _make_stylebox(Color(1.0, 0.95, 0.70), CAT_ORANGE, 8, 3, Vector2(1, 2)))
	spinbox.add_theme_color_override("font_color", INK)
	spinbox.add_theme_font_size_override("font_size", 18)


func _make_stylebox(bg: Color, border: Color, radius: int, border_width: int, shadow_offset: Vector2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius - 1
	box.corner_radius_bottom_right = radius
	box.corner_radius_bottom_left = radius - 2
	box.content_margin_left = 14
	box.content_margin_top = 10
	box.content_margin_right = 14
	box.content_margin_bottom = 10
	box.shadow_color = Color(0.10, 0.07, 0.04, 0.28)
	box.shadow_size = 4
	box.shadow_offset = shadow_offset
	return box
