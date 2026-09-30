extends RefCounted

# Shared decoration for actual push buttons; toggles and photo inputs keep
# their dedicated rendering. Store existing colors and hover styles.
static func attach(button: Button) -> void:
	if button is CheckButton or button is CheckBox or button.has_meta("cartoon_style"):
		return
	# A playing card also extends Button, but is not a UI push button.
	# Player rows deliberately style the outer panel, not its inner controls.
	var ancestor: Node = button
	while ancestor != null:
		var script = ancestor.get_script()
		if ancestor.has_meta("cartoon_style_children_excluded") or (script != null and script.resource_path == "res://scenes/balatro/scripts/card.gd"):
			return
		ancestor = ancestor.get_parent()
	button.set_meta("cartoon_style", true)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		button.set_meta("cartoon_original_" + state, button.get_theme_stylebox(state).duplicate())
	var bevel := preload("res://scenes/balatro/scripts/button_bevel.gd").new()
	bevel.name = "Bevel"
	button.add_child(bevel)
	bevel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gloss := preload("res://scenes/balatro/scripts/button_gloss.gd").new()
	gloss.name = "Gloss"
	gloss.gloss_color = Color(1, 1, 1, 0.28)
	button.add_child(gloss)
	gloss.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var decorate := func():
		var resting := not button.is_hovered() and not button.has_focus() and not button.disabled
		bevel.visible = resting
		gloss.visible = resting and absf(button.size.x - button.size.y) > 1.0
	var refresh := func():
		apply(button)
		decorate.call()
	button.resized.connect(refresh, CONNECT_DEFERRED)
	for event in ["mouse_entered", "mouse_exited", "focus_entered", "focus_exited", "draw"]:
		button.connect(event, decorate)
	refresh.call()

static func apply(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var original: StyleBox = button.get_meta("cartoon_original_" + state)
		if not original is StyleBoxFlat:
			continue
		var style := original.duplicate() as StyleBoxFlat
		style.set_corner_radius_all(int(button.size.y * 0.5))
		if state not in ["hover", "focus", "disabled"]:
			style.border_color = Color("0c0918")
			style.set_border_width_all(4)
			style.border_width_bottom = 8
			style.corner_detail = 20
			style.anti_aliasing_size = 1.4
			style.shadow_color = Color(0.047059, 0.035294, 0.094118, 0.28)
			style.shadow_size = 1
			style.shadow_offset = Vector2(0, 2 if state in ["pressed", "hover_pressed"] else 5)
		button.add_theme_stylebox_override(state, style)
