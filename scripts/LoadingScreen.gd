extends Control

const ARENA_SCENE := "res://scenes/MainArena.tscn"
const LOADING_BACKGROUND := preload("res://assets/backgrounds/sul-ponte.png")
const DOT_INTERVAL := 0.45
const MAX_DOTS := 3

var dot_accum := 0.0
var dot_count := 0
var loading_label: Label
var loading_done := false
var rising_particles: GPUParticles2D
var rising_particle_material: ParticleProcessMaterial


func _ready() -> void:
	_build_ui()
	resized.connect(_layout_rising_particles)
	call_deferred("_layout_rising_particles")
	ResourceLoader.load_threaded_request(ARENA_SCENE)


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
	if loading_done:
		return

	dot_accum += delta
	if dot_accum >= DOT_INTERVAL:
		dot_accum = 0.0
		dot_count = (dot_count + 1) % (MAX_DOTS + 1)
		loading_label.text = "LOADING" + ".".repeat(dot_count)

	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(ARENA_SCENE, progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		loading_done = true
		var packed := ResourceLoader.load_threaded_get(ARENA_SCENE) as PackedScene
		get_tree().change_scene_to_packed(packed)
