extends Control

var roster: Array = []
var slots: Array = []
var p1_index := 0
var p2_index := 1
var p1_confirmed := false
var p2_confirmed := false
var p1_cursor: Panel
var p2_cursor: Panel
var p1_name_label: Label
var p2_name_label: Label
var roster_grid: GridContainer
var hint_label: Label


func _ready() -> void:
	roster = CharacterSelection.ROSTER
	p1_index = _find_index(CharacterSelection.player1_id)
	p2_index = _find_index(CharacterSelection.player2_id)
	_build_ui()
	_refresh_ui()


func _build_ui() -> void:
	_add_background()
	_add_title()
	_add_roster_area()
	_add_p1_preview()
	_add_vs_label()
	_add_p2_preview()
	_add_hint_label()
	_add_cursors()


func _add_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.12, 1)
	add_child(bg)


func _add_title() -> void:
	var lbl := Label.new()
	lbl.text = "CHARACTER SELECT"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.set_anchor(SIDE_LEFT, 0.0)
	lbl.set_anchor(SIDE_RIGHT, 1.0)
	lbl.set_anchor(SIDE_TOP, 0.0)
	lbl.set_anchor(SIDE_BOTTOM, 0.0)
	lbl.offset_top = 14.0
	lbl.offset_bottom = 54.0
	add_child(lbl)


func _add_roster_area() -> void:
	var area := CenterContainer.new()
	area.set_anchor(SIDE_LEFT, 0.0)
	area.set_anchor(SIDE_RIGHT, 1.0)
	area.set_anchor(SIDE_TOP, 0.0)
	area.set_anchor(SIDE_BOTTOM, 0.56)
	add_child(area)

	roster_grid = GridContainer.new()
	roster_grid.columns = 2
	roster_grid.add_theme_constant_override("h_separation", 14)
	roster_grid.add_theme_constant_override("v_separation", 14)
	area.add_child(roster_grid)

	for entry in roster:
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(156, 192)
		var lbl := Label.new()
		lbl.text = entry["label"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot.add_child(lbl)
		roster_grid.add_child(slot)
		slots.append(slot)


func _add_p1_preview() -> void:
	var preview := VBoxContainer.new()
	preview.set_anchor(SIDE_LEFT, 0.0)
	preview.set_anchor(SIDE_RIGHT, 0.0)
	preview.set_anchor(SIDE_TOP, 0.56)
	preview.set_anchor(SIDE_BOTTOM, 0.98)
	preview.offset_left = 20.0
	preview.offset_right = 270.0
	preview.add_theme_constant_override("separation", 8)
	add_child(preview)

	var player_lbl := Label.new()
	player_lbl.text = "PLAYER 1"
	player_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_lbl.add_theme_font_size_override("font_size", 20)
	preview.add_child(player_lbl)

	var portrait := Panel.new()
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var portrait_lbl := Label.new()
	portrait_lbl.text = "[PORTRAIT P1]"
	portrait_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.add_child(portrait_lbl)
	preview.add_child(portrait)

	p1_name_label = Label.new()
	p1_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_name_label.add_theme_font_size_override("font_size", 24)
	preview.add_child(p1_name_label)


func _add_vs_label() -> void:
	var lbl := Label.new()
	lbl.text = "VS"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 52)
	lbl.set_anchor(SIDE_LEFT, 0.5)
	lbl.set_anchor(SIDE_RIGHT, 0.5)
	lbl.set_anchor(SIDE_TOP, 0.64)
	lbl.set_anchor(SIDE_BOTTOM, 0.84)
	lbl.offset_left = -52.0
	lbl.offset_right = 52.0
	add_child(lbl)


func _add_p2_preview() -> void:
	var preview := VBoxContainer.new()
	preview.set_anchor(SIDE_LEFT, 1.0)
	preview.set_anchor(SIDE_RIGHT, 1.0)
	preview.set_anchor(SIDE_TOP, 0.56)
	preview.set_anchor(SIDE_BOTTOM, 0.98)
	preview.offset_left = -270.0
	preview.offset_right = -20.0
	preview.add_theme_constant_override("separation", 8)
	add_child(preview)

	var player_lbl := Label.new()
	player_lbl.text = "PLAYER 2"
	player_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_lbl.add_theme_font_size_override("font_size", 20)
	preview.add_child(player_lbl)

	var portrait := Panel.new()
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var portrait_lbl := Label.new()
	portrait_lbl.text = "[PORTRAIT P2]"
	portrait_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.add_child(portrait_lbl)
	preview.add_child(portrait)

	p2_name_label = Label.new()
	p2_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_name_label.add_theme_font_size_override("font_size", 24)
	preview.add_child(p2_name_label)


func _add_hint_label() -> void:
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 17)
	hint_label.set_anchor(SIDE_LEFT, 0.0)
	hint_label.set_anchor(SIDE_RIGHT, 1.0)
	hint_label.set_anchor(SIDE_TOP, 1.0)
	hint_label.set_anchor(SIDE_BOTTOM, 1.0)
	hint_label.offset_top = -36.0
	hint_label.offset_bottom = -6.0
	add_child(hint_label)


func _add_cursors() -> void:
	p1_cursor = _make_cursor(Color(0.3, 0.7, 1.0))
	p2_cursor = _make_cursor(Color(1.0, 0.38, 0.22))
	add_child(p1_cursor)
	add_child(p2_cursor)


func _make_cursor(color: Color) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.18)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = color
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _unhandled_input(event: InputEvent) -> void:
	if OS.has_feature("headless"):
		return
	if not p1_confirmed:
		if event.is_action_pressed("ui_left"):
			p1_index = wrapi(p1_index - 1, 0, roster.size())
			_refresh_ui()
		elif event.is_action_pressed("ui_right"):
			p1_index = wrapi(p1_index + 1, 0, roster.size())
			_refresh_ui()
		elif event.is_action_pressed("ui_accept"):
			p1_confirmed = true
			CharacterSelection.player1_id = roster[p1_index]["id"]
			_refresh_ui()
			_check_start()
	if not p2_confirmed:
		if event.is_action_pressed("p2_move_left"):
			p2_index = wrapi(p2_index - 1, 0, roster.size())
			_refresh_ui()
		elif event.is_action_pressed("p2_move_right"):
			p2_index = wrapi(p2_index + 1, 0, roster.size())
			_refresh_ui()
		elif event.is_action_pressed("p2_light_kick"):
			p2_confirmed = true
			CharacterSelection.player2_id = roster[p2_index]["id"]
			_refresh_ui()
			_check_start()


func _check_start() -> void:
	if p1_confirmed and p2_confirmed:
		get_tree().change_scene_to_file("res://scenes/MainArena.tscn")


func _process(_delta: float) -> void:
	_update_cursors()


func _refresh_ui() -> void:
	if p1_name_label != null:
		p1_name_label.text = roster[p1_index]["label"]
	if p2_name_label != null:
		p2_name_label.text = roster[p2_index]["label"]
	if hint_label == null:
		return
	if p1_confirmed and not p2_confirmed:
		hint_label.text = "P1 confermato!   P2: Num4/6 muovi | Num7 conferma"
	elif not p1_confirmed and p2_confirmed:
		hint_label.text = "P2 confermato!   P1: \u2190\u2192 muovi | ENTER conferma"
	else:
		hint_label.text = "P1: \u2190\u2192 | ENTER       P2: Num4/6 | Num7"
	_update_cursors()


func _update_cursors() -> void:
	if slots.is_empty() or p1_cursor == null:
		return
	if p1_index < slots.size():
		var slot: Control = slots[p1_index]
		p1_cursor.global_position = slot.global_position
		p1_cursor.size = slot.size
	if p2_index < slots.size():
		var slot: Control = slots[p2_index]
		p2_cursor.global_position = slot.global_position
		p2_cursor.size = slot.size


func _find_index(id: String) -> int:
	for i in range(roster.size()):
		if roster[i]["id"] == id:
			return i
	return 0
