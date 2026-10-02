extends Control

const ARENA_SCENE := "res://scenes/MainArena.tscn"
const TITLE_SCENE := "res://scenes/TitleScreen.tscn"
const LOADING_BACKGROUND := preload("res://assets/backgrounds/sul-ponte.png")
const DOT_INTERVAL := 0.45
const MAX_DOTS := 3

var dot_accum := 0.0
var dot_count := 0
var loading_label: Label
var loading_done := false
var loading_failed := false
var error_panel: VBoxContainer
var retry_button: Button
var rising_particles: GPUParticles2D
var rising_particle_material: ParticleProcessMaterial


func _ready() -> void:
	_build_ui()
	resized.connect(_layout_rising_particles)
	call_deferred("_layout_rising_particles")
	_start_loading()


func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = LOADING_BACKGROUND
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_add_rising_particles()

	loading_label = Label.new()
	loading_label.set_anchor(SIDE_LEFT, 0.0)
	loading_label.set_anchor(SIDE_RIGHT, 1.0)
	loading_label.set_anchor(SIDE_TOP, 1.0)
	loading_label.set_anchor(SIDE_BOTTOM, 1.0)
	loading_label.offset_top = -70.0
	loading_label.offset_bottom = -20.0
	loading_label.text = "LOADING"
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 32)
	add_child(loading_label)
	_build_error_ui()


func _build_error_ui() -> void:
	error_panel = VBoxContainer.new()
	error_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	error_panel.anchor_left = 0.1
	error_panel.anchor_right = 0.9
	error_panel.anchor_top = 0.35
	error_panel.anchor_bottom = 0.75
	error_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	error_panel.add_theme_constant_override("separation", 16)
	error_panel.hide()
	add_child(error_panel)

	var message := Label.new()
	message.text = "UNABLE TO LOAD THE ARENA\nPlease try again or return to the title screen."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 24)
	error_panel.add_child(message)

	retry_button = Button.new()
	retry_button.text = "TRY AGAIN"
	retry_button.pressed.connect(_start_loading)
	error_panel.add_child(retry_button)

	var title_button := Button.new()
	title_button.text = "BACK TO TITLE"
	title_button.pressed.connect(_return_to_title)
	error_panel.add_child(title_button)


func _start_loading() -> void:
	loading_done = false
	loading_failed = false
	dot_accum = 0.0
	dot_count = 0
	loading_label.text = "LOADING"
	loading_label.show()
	error_panel.hide()
	var error := _request_arena_load()
	if error != OK:
		_show_loading_error("Unable to request arena loading: %s" % error_string(error))


func _show_loading_error(reason: String) -> void:
	loading_failed = true
	loading_label.hide()
	error_panel.show()
	retry_button.grab_focus()
	push_warning(reason)


func _return_to_title() -> void:
	var error := _open_title()
	if error != OK:
		_show_loading_error("Unable to open title screen: %s" % error_string(error))


# Keep loader and scene transitions separate so failure paths can be tested.
func _request_arena_load() -> Error:
	return ResourceLoader.load_threaded_request(ARENA_SCENE)


func _get_arena_load_status() -> int:
	return ResourceLoader.load_threaded_get_status(ARENA_SCENE)


func _get_loaded_arena() -> Resource:
	return ResourceLoader.load_threaded_get(ARENA_SCENE)


func _open_arena(packed: PackedScene) -> Error:
	return get_tree().change_scene_to_packed(packed)


func _open_title() -> Error:
	return get_tree().change_scene_to_file(TITLE_SCENE)


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


func _process(delta: float) -> void:
	if loading_done or loading_failed:
		return

	dot_accum += delta
	if dot_accum >= DOT_INTERVAL:
		dot_accum = 0.0
		dot_count = (dot_count + 1) % (MAX_DOTS + 1)
		loading_label.text = "LOADING" + ".".repeat(dot_count)

	var status := _get_arena_load_status()
	match status:
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_show_loading_error("Arena loading failed (status %d)." % status)
		ResourceLoader.THREAD_LOAD_LOADED:
			var packed := _get_loaded_arena() as PackedScene
			if packed == null or not packed.can_instantiate():
				_show_loading_error("Loaded arena is not an instantiable PackedScene.")
				return
			var error := _open_arena(packed)
			if error != OK:
				_show_loading_error("Unable to open arena: %s" % error_string(error))
				return
			loading_done = true


func _unhandled_input(event: InputEvent) -> void:
	if loading_failed and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_title()
