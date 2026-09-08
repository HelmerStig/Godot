extends Control

var press_start_label: Label
var blink_accum := 0.0
const BLINK_INTERVAL := 0.55


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg_texture := load("res://assets/backgrounds/default_stage/ponte-pixel-v1.png") as Texture2D
	if bg_texture != null:
		var bg := TextureRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.texture = bg_texture
		bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(bg)
	else:
		var bg := ColorRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(0.04, 0.04, 0.09, 1)
		add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 60)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var logo_panel := Panel.new()
	logo_panel.custom_minimum_size = Vector2(480, 200)
	vbox.add_child(logo_panel)

	var logo_label := Label.new()
	logo_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo_label.text = "SANMO"
	logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	logo_label.add_theme_font_size_override("font_size", 72)
	logo_panel.add_child(logo_label)

	press_start_label = Label.new()
	press_start_label.text = "PRESS ENTER TO START"
	press_start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	press_start_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(press_start_label)


func _process(delta: float) -> void:
	if press_start_label == null:
		return
	blink_accum += delta
	if blink_accum >= BLINK_INTERVAL:
		blink_accum = 0.0
		press_start_label.visible = not press_start_label.visible


func _unhandled_input(event: InputEvent) -> void:
	var is_start := event.is_action_pressed("ui_accept")
	if not is_start and event is InputEventJoypadButton:
		is_start = (event as InputEventJoypadButton).button_index == 6 and event.pressed
	if is_start:
		get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")
