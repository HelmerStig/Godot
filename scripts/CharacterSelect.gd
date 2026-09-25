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
var p1_nav_cooldown := 0.0
var p2_nav_cooldown := 0.0
const NAV_COOLDOWN := 0.22
const CHARACTER_SELECT_BACKGROUND := preload("res://assets/backgrounds/character-selection.png")
const ARIANNA_PORTRAIT := preload("res://assets/ui/portraits/arianna-portrait-v2.png")
const MANGLER_PORTRAIT := preload("res://assets/ui/portraits/mangler-portrait-v1.png")
const BUE_PORTRAIT := preload("res://assets/ui/portraits/bue-portrait-v1.png")
const PEIRO_PORTRAIT := preload("res://assets/ui/portraits/peirolo-portrait-v1.png")
const TORPE_PORTRAIT := preload("res://assets/ui/portraits/torpe-portrait-v1.png")
const MILETO_PORTRAIT := preload("res://assets/ui/portraits/mileto-portrait-v1.png")
# [0] LP  [1] MP  [2] HP — placeholder: i personaggi futuri sostituiranno questi path.
const PUNCH_PREVIEW_SOUNDS: Dictionary = {
	"arianna": [
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/strong-punch.wav",
	],
	"mangler": [
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/strong-punch.wav",
	],
	"bue": [
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/strong-punch.wav",
	],
	"peiro": [
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/strong-punch.wav",
	],
	"oscare": [
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/strong-punch.wav",
	],
	"torpe": [
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/strong-punch.wav",
	],
	"mileto": [
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/light-punch.wav",
		"res://assets/sounds/sfx/strong-punch.wav",
	],
}

var p1_portrait: TextureRect
var p2_portrait: TextureRect
var rising_particles: GPUParticles2D
var rising_particle_material: ParticleProcessMaterial
var preview_audio_player: AudioStreamPlayer
var p1_punch_panels: Array = []
var p2_punch_panels: Array = []
var p1_last_preview_index := -1
var p2_last_preview_index := -1


func _ready() -> void:
	roster = CharacterSelection.ROSTER
	p1_index = _find_index(CharacterSelection.player1_id)
	p2_index = _find_index(CharacterSelection.player2_id)
	_build_ui()
	preview_audio_player = AudioStreamPlayer.new()
	preview_audio_player.name = "PunchPreviewAudio"
	add_child(preview_audio_player)
	resized.connect(_layout_rising_particles)
	call_deferred("_layout_rising_particles")
	_refresh_ui()


func _build_ui() -> void:
	_add_background()
	_add_rising_particles()
	_add_title()
	_add_roster_area()
	_add_p1_preview()
	_add_vs_label()
	_add_p2_preview()
	_add_hint_label()
	_add_cursors()


func _add_background() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = CHARACTER_SELECT_BACKGROUND
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


func _add_rising_particles() -> void:
	var particle_gradient := Gradient.new()
	particle_gradient.offsets = PackedFloat32Array([0.0, 0.28, 1.0])
	particle_gradient.colors = PackedColorArray([
		Color(1.0, 0.82, 0.42, 0.0),
		Color(1.0, 0.88, 0.58, 0.82),
		Color(1.0, 0.88, 0.58, 0.0),
	])
	var particle_texture := GradientTexture2D.new()
	particle_texture.gradient = particle_gradient
	particle_texture.fill = GradientTexture2D.FILL_RADIAL
	particle_texture.fill_from = Vector2(0.5, 0.5)
	particle_texture.fill_to = Vector2(1.0, 0.5)
	particle_texture.width = 16
	particle_texture.height = 16

	rising_particle_material = ParticleProcessMaterial.new()
	rising_particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rising_particle_material.direction = Vector3(0.0, -1.0, 0.0)
	rising_particle_material.spread = 12.0
	rising_particle_material.initial_velocity_min = 24.0
	rising_particle_material.initial_velocity_max = 46.0
	rising_particle_material.gravity = Vector3(0.0, -3.0, 0.0)
	rising_particle_material.scale_min = 0.45
	rising_particle_material.scale_max = 1.1
	rising_particle_material.color = Color(1.0, 0.86, 0.58, 0.72)

	rising_particles = GPUParticles2D.new()
	rising_particles.name = "RisingBackgroundParticles"
	rising_particles.amount = 72
	rising_particles.lifetime = 8.0
	rising_particles.preprocess = 8.0
	rising_particles.texture = particle_texture
	rising_particles.process_material = rising_particle_material
	add_child(rising_particles)


func _layout_rising_particles() -> void:
	if rising_particles == null or rising_particle_material == null:
		return
	var viewport_size := get_viewport_rect().size
	rising_particles.position = Vector2(viewport_size.x * 0.5, viewport_size.y + 12.0)
	rising_particle_material.emission_box_extents = Vector3(viewport_size.x * 0.5, 6.0, 0.0)
	rising_particles.visibility_rect = Rect2(
		-viewport_size.x * 0.5 - 32.0,
		-viewport_size.y - 96.0,
		viewport_size.x + 64.0,
		viewport_size.y + 128.0
	)


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
	area.set_anchor(SIDE_TOP, 0.08)
	area.set_anchor(SIDE_BOTTOM, 0.58)
	add_child(area)

	roster_grid = GridContainer.new()
	roster_grid.columns = 4
	roster_grid.add_theme_constant_override("h_separation", 14)
	roster_grid.add_theme_constant_override("v_separation", 14)
	area.add_child(roster_grid)

	for entry in roster:
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(120, 148)
		var portrait_texture := _get_portrait(entry["id"])
		if portrait_texture != null:
			var portrait := TextureRect.new()
			portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
			portrait.texture = portrait_texture
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(portrait)

			var name_backdrop := ColorRect.new()
			name_backdrop.color = Color(0.015, 0.02, 0.05, 0.78)
			name_backdrop.set_anchor(SIDE_LEFT, 0.0)
			name_backdrop.set_anchor(SIDE_RIGHT, 1.0)
			name_backdrop.set_anchor(SIDE_TOP, 0.78)
			name_backdrop.set_anchor(SIDE_BOTTOM, 1.0)
			name_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(name_backdrop)

		var lbl := Label.new()
		lbl.text = entry["label"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if portrait_texture != null:
			lbl.set_anchor(SIDE_LEFT, 0.0)
			lbl.set_anchor(SIDE_RIGHT, 1.0)
			lbl.set_anchor(SIDE_TOP, 0.78)
			lbl.set_anchor(SIDE_BOTTOM, 1.0)
			lbl.offset_top = -5.0
			lbl.offset_bottom = -5.0
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 22)
		else:
			lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot.add_child(lbl)
		roster_grid.add_child(slot)
		slots.append(slot)


func _add_p1_preview() -> void:
	var preview := VBoxContainer.new()
	preview.set_anchor(SIDE_LEFT, 0.0)
	preview.set_anchor(SIDE_RIGHT, 0.0)
	preview.set_anchor(SIDE_TOP, 0.60)
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

	p1_portrait = _make_portrait()
	portrait.add_child(p1_portrait)
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
	lbl.set_anchor(SIDE_TOP, 0.66)
	lbl.set_anchor(SIDE_BOTTOM, 0.84)
	lbl.offset_left = -52.0
	lbl.offset_right = 52.0
	add_child(lbl)


func _add_p2_preview() -> void:
	var preview := VBoxContainer.new()
	preview.set_anchor(SIDE_LEFT, 1.0)
	preview.set_anchor(SIDE_RIGHT, 1.0)
	preview.set_anchor(SIDE_TOP, 0.60)
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

	p2_portrait = _make_portrait()
	portrait.add_child(p2_portrait)
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


func _make_portrait() -> TextureRect:
	var portrait := TextureRect.new()
	portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return portrait


func _get_portrait(character_id: String) -> Texture2D:
	if character_id == "arianna":
		return ARIANNA_PORTRAIT
	if character_id == "mangler":
		return MANGLER_PORTRAIT
	if character_id == "bue":
		return BUE_PORTRAIT
	if character_id == "peiro":
		return PEIRO_PORTRAIT
	if character_id == "torpe":
		return TORPE_PORTRAIT
	if character_id == "mileto":
		return MILETO_PORTRAIT
	return null


func _unhandled_input(event: InputEvent) -> void:
	if OS.has_feature("headless"):
		return
	if event.is_action_pressed("p1_light_punch"):
		_play_and_flash(roster[p1_index]["id"], 0, p1_punch_panels)
	elif event.is_action_pressed("p1_medium_punch"):
		_play_and_flash(roster[p1_index]["id"], 1, p1_punch_panels)
	elif event.is_action_pressed("p1_heavy_punch"):
		_play_and_flash(roster[p1_index]["id"], 2, p1_punch_panels)
	if event.is_action_pressed("p2_light_punch"):
		_play_and_flash(roster[p2_index]["id"], 0, p2_punch_panels)
	elif event.is_action_pressed("p2_medium_punch"):
		_play_and_flash(roster[p2_index]["id"], 1, p2_punch_panels)
	elif event.is_action_pressed("p2_heavy_punch"):
		_play_and_flash(roster[p2_index]["id"], 2, p2_punch_panels)
	if not p1_confirmed:
		if p1_nav_cooldown <= 0.0 and event.is_action_pressed("ui_left"):
			p1_index = wrapi(p1_index - 1, 0, roster.size())
			p1_nav_cooldown = NAV_COOLDOWN
			_refresh_ui()
		elif p1_nav_cooldown <= 0.0 and event.is_action_pressed("ui_right"):
			p1_index = wrapi(p1_index + 1, 0, roster.size())
			p1_nav_cooldown = NAV_COOLDOWN
			_refresh_ui()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("p1_light_kick"):
			p1_confirmed = true
			CharacterSelection.player1_id = roster[p1_index]["id"]
			_refresh_ui()
			_check_start()
	if not p2_confirmed:
		if p2_nav_cooldown <= 0.0 and event.is_action_pressed("p2_move_left"):
			p2_index = wrapi(p2_index - 1, 0, roster.size())
			p2_nav_cooldown = NAV_COOLDOWN
			_refresh_ui()
		elif p2_nav_cooldown <= 0.0 and event.is_action_pressed("p2_move_right"):
			p2_index = wrapi(p2_index + 1, 0, roster.size())
			p2_nav_cooldown = NAV_COOLDOWN
			_refresh_ui()
		elif event.is_action_pressed("p2_light_kick"):
			p2_confirmed = true
			CharacterSelection.player2_id = roster[p2_index]["id"]
			_refresh_ui()
			_check_start()


func _check_start() -> void:
	if not p1_confirmed or not p2_confirmed:
		return
	var p1_scene: String = roster[p1_index].get("scene", "")
	var p2_scene: String = roster[p2_index].get("scene", "")
	if p1_scene.is_empty() or p2_scene.is_empty():
		if hint_label != null:
			hint_label.text = "Personaggio non ancora disponibile — scegline un altro!"
		p1_confirmed = false
		p2_confirmed = false
		_refresh_ui()
		return
	get_tree().change_scene_to_file("res://scenes/LoadingScreen.tscn")


func _process(delta: float) -> void:
	p1_nav_cooldown = maxf(p1_nav_cooldown - delta, 0.0)
	p2_nav_cooldown = maxf(p2_nav_cooldown - delta, 0.0)
	_update_cursors()


func _refresh_ui() -> void:
	if p1_name_label != null:
		p1_name_label.text = roster[p1_index]["label"]
	if p1_portrait != null:
		p1_portrait.texture = _get_portrait(roster[p1_index]["id"])
	if p2_name_label != null:
		p2_name_label.text = roster[p2_index]["label"]
	if p2_portrait != null:
		p2_portrait.texture = _get_portrait(roster[p2_index]["id"])
	if p1_index != p1_last_preview_index:
		p1_last_preview_index = p1_index
		if not p1_confirmed:
			_play_and_flash(roster[p1_index]["id"], 0, p1_punch_panels)
	if p2_index != p2_last_preview_index:
		p2_last_preview_index = p2_index
		if not p2_confirmed:
			_play_and_flash(roster[p2_index]["id"], 0, p2_punch_panels)
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


func _make_punch_row(panels_ref: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for label_text in ["LP", "MP", "HP"]:
		var btn := _make_punch_button(label_text)
		row.add_child(btn)
		panels_ref.append(btn)
	return row


func _make_punch_button(label_text: String) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(48, 28)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.22, 0.88)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.45, 0.6, 0.6)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	panel.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)
	return panel


func _play_and_flash(character_id: String, punch_index: int, panels: Array) -> void:
	if preview_audio_player == null or OS.has_feature("headless"):
		return
	var sounds: Array = PUNCH_PREVIEW_SOUNDS.get(character_id, [])
	if punch_index < sounds.size():
		var stream := load(sounds[punch_index]) as AudioStream
		if stream != null:
			preview_audio_player.stream = stream
			preview_audio_player.play()
	if punch_index < panels.size():
		var panel: Panel = panels[punch_index]
		panel.modulate = Color(0.35, 1.0, 0.55)
		var tween := panel.create_tween()
		tween.tween_property(panel, "modulate", Color.WHITE, 0.45)
