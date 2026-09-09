extends Control

const TITLE_BACKGROUND_FILTER := preload("res://shaders/title_background_filter.gdshader")
const TITLE_WATER_EFFECT := preload("res://shaders/title_water_effect.gdshader")
const TITLE_LOGO := preload("res://assets/backgrounds/default_stage/main-image/10099.png")
const OSWALD_FONT := preload("res://assets/fonts/Oswald-Variable.ttf")

var press_start_label: Label
var title_logo: TextureRect
var neon_subtitle: Label
var neon_subtitle_glow: Label
var blink_accum := 0.0
var neon_flicker_time := 0.7
var neon_flicker_steps := 0
var neon_enabled := false
var neon_random := RandomNumberGenerator.new()
const BLINK_INTERVAL := 0.55
const LOGO_SIZE := Vector2(704.0, 384.0)
## Offset manuale rispetto al centro dello schermo: X orizzontale, Y verticale.
const LOGO_CENTER_OFFSET := Vector2(0.0, -60.0)
const LOGO_IMPACT_TIME := 0.48
const BACKGROUND_LAYERS := [
	"res://assets/backgrounds/default_stage/main-image/livello-01.png",
	"res://assets/backgrounds/default_stage/main-image/nuvole/nuvole-01.png",
	"res://assets/backgrounds/default_stage/main-image/nuvole/nuvole-02.png",
	"res://assets/backgrounds/default_stage/main-image/nuvole/nuvole-03.png",
	"res://assets/backgrounds/default_stage/main-image/livello-03.png",
	"res://assets/backgrounds/default_stage/main-image/water-level-03_5.png",
	"res://assets/backgrounds/default_stage/main-image/riflessi/riflesso-1.png",
	"res://assets/backgrounds/default_stage/main-image/riflessi/riflesso-2.png",
	"res://assets/backgrounds/default_stage/main-image/riflessi/riflesso-3.png",
	"res://assets/backgrounds/default_stage/main-image/livello-04.png",
]
const BACKGROUND_Z_INDEX := -40
const WATER_LAYER_INDEX := 5
const SCROLLING_LAYER_INDEXES := [1, 2, 3, 6, 7, 8]
const SCROLLING_LAYER_SPEEDS := {
	1: 2.5, # nuvole-01, livello lontano
	2: 4.5, # nuvole-02, livello intermedio
	3: 7.0, # nuvole-03, livello vicino
	6: 2.5, # riflesso-1: stessa parallasse di nuvole-01
	7: 4.5, # riflesso-2: stessa parallasse di nuvole-02
	8: 7.0, # riflesso-3: stessa parallasse di nuvole-03
}
const SCROLLING_LAYER_SEGMENTS := {
	1: 1.0,
	2: 1.0,
	3: 1.0,
	6: 1.0,
	7: 1.0,
	8: 1.0,
}

var cloud_textures: Dictionary = {}
var cloud_copies_by_layer: Dictionary = {}
var cloud_scroll_offsets: Dictionary = {}
var cloud_render_widths: Dictionary = {}


func _ready() -> void:
	neon_random.randomize()
	_build_ui()


func _build_ui() -> void:
	if not _add_layered_background():
		var bg := ColorRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(0.04, 0.04, 0.09, 1)
		bg.z_index = BACKGROUND_Z_INDEX
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	_add_background_filter()

	_add_animated_logo()
	_add_neon_subtitle()
	press_start_label = Label.new()
	press_start_label.text = "PRESS ENTER TO START"
	press_start_label.set_anchors_preset(Control.PRESET_CENTER)
	press_start_label.position = Vector2(-280.0, LOGO_SIZE.y * 0.5 - 20.0)
	press_start_label.size = Vector2(560.0, 48.0)
	press_start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	press_start_label.add_theme_font_override("font", OSWALD_FONT)
	press_start_label.add_theme_font_size_override("font_size", 28)
	add_child(press_start_label)


func _add_animated_logo() -> void:
	title_logo = TextureRect.new()
	title_logo.name = "TitleLogo"
	title_logo.texture = TITLE_LOGO
	title_logo.set_anchors_preset(Control.PRESET_CENTER)
	var final_left := -LOGO_SIZE.x * 0.5 + LOGO_CENTER_OFFSET.x
	var final_top := -LOGO_SIZE.y * 0.5 + LOGO_CENTER_OFFSET.y
	title_logo.offset_left = final_left
	title_logo.offset_right = final_left + LOGO_SIZE.x
	title_logo.offset_top = final_top - 340.0
	title_logo.offset_bottom = final_top - 340.0 + LOGO_SIZE.y
	title_logo.pivot_offset = LOGO_SIZE * 0.5
	title_logo.scale = Vector2(1.38, 1.38)
	title_logo.rotation = deg_to_rad(-14.0)
	title_logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	title_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_logo.z_index = 2
	add_child(title_logo)
	var impact_tween := create_tween().set_parallel(true)
	impact_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	impact_tween.tween_property(title_logo, "offset_top", final_top, LOGO_IMPACT_TIME)
	impact_tween.tween_property(title_logo, "offset_bottom", final_top + LOGO_SIZE.y, LOGO_IMPACT_TIME)
	impact_tween.tween_property(title_logo, "scale", Vector2.ONE, LOGO_IMPACT_TIME)
	impact_tween.tween_property(title_logo, "rotation", deg_to_rad(2.0), LOGO_IMPACT_TIME)
	var settle_tween := create_tween()
	settle_tween.tween_interval(LOGO_IMPACT_TIME)
	settle_tween.set_parallel(true)
	settle_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	settle_tween.tween_property(title_logo, "scale", Vector2(1.045, 1.045), 0.1)
	settle_tween.tween_property(title_logo, "rotation", 0.0, 0.1)
	settle_tween.chain().set_parallel(true)
	settle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	settle_tween.tween_property(title_logo, "scale", Vector2.ONE, 0.14)
	get_tree().create_timer(LOGO_IMPACT_TIME).timeout.connect(_on_logo_impact)


func _add_neon_subtitle() -> void:
	var subtitle_position := Vector2(-280.0, LOGO_SIZE.y * 0.5 - 150.0)
	neon_subtitle_glow = Label.new()
	neon_subtitle_glow.name = "BeverlyINPSGlow"
	neon_subtitle_glow.text = "Beverly INPS"
	neon_subtitle_glow.set_anchors_preset(Control.PRESET_CENTER)
	neon_subtitle_glow.position = subtitle_position
	neon_subtitle_glow.size = Vector2(560.0, 70.0)
	neon_subtitle_glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	neon_subtitle_glow.add_theme_font_override("font", OSWALD_FONT)
	neon_subtitle_glow.add_theme_font_size_override("font_size", 58)
	neon_subtitle_glow.add_theme_color_override("font_color", Color(0.82, 0.97, 1.0, 0.1))
	neon_subtitle_glow.add_theme_color_override("font_outline_color", Color(0.15, 0.86, 1.0, 0.35))
	neon_subtitle_glow.add_theme_constant_override("outline_size", 12)
	neon_subtitle_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	neon_subtitle_glow.z_index = 3
	neon_subtitle_glow.modulate.a = 0.0
	add_child(neon_subtitle_glow)

	neon_subtitle = Label.new()
	neon_subtitle.name = "BeverlyINPS"
	neon_subtitle.text = "Beverly INPS"
	neon_subtitle.set_anchors_preset(Control.PRESET_CENTER)
	neon_subtitle.position = subtitle_position
	neon_subtitle.size = Vector2(560.0, 70.0)
	neon_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	neon_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	neon_subtitle.add_theme_font_override("font", OSWALD_FONT)
	neon_subtitle.add_theme_font_size_override("font_size", 58)
	neon_subtitle.add_theme_color_override("font_color", Color.WHITE)
	neon_subtitle.add_theme_color_override("font_outline_color", Color(0.58, 0.94, 1.0, 0.95))
	neon_subtitle.add_theme_color_override("font_shadow_color", Color(0.04, 0.54, 0.86, 0.9))
	neon_subtitle.add_theme_constant_override("outline_size", 2)
	neon_subtitle.add_theme_constant_override("shadow_offset_x", 0)
	neon_subtitle.add_theme_constant_override("shadow_offset_y", 2)
	neon_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	neon_subtitle.z_index = 4
	neon_subtitle.modulate.a = 0.0
	add_child(neon_subtitle)


func _on_logo_impact() -> void:
	if not is_inside_tree():
		return
	var impact_center := get_viewport_rect().size * 0.5 + LOGO_CENTER_OFFSET
	var shockwave := Line2D.new()
	shockwave.name = "LogoShockwave"
	shockwave.position = impact_center
	shockwave.width = 7.0
	shockwave.default_color = Color(1.0, 0.64, 0.24, 0.9)
	shockwave.points = _make_shockwave_points()
	shockwave.scale = Vector2(0.25, 0.25)
	shockwave.z_index = 1
	add_child(shockwave)
	var shockwave_tween := create_tween().set_parallel(true)
	shockwave_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	shockwave_tween.tween_property(shockwave, "scale", Vector2(1.65, 0.86), 0.36)
	shockwave_tween.tween_property(shockwave, "modulate:a", 0.0, 0.36)
	shockwave_tween.tween_callback(shockwave.queue_free).set_delay(0.38)

	var dust := CPUParticles2D.new()
	dust.name = "LogoImpactDust"
	dust.position = impact_center + Vector2(0.0, LOGO_SIZE.y * 0.5)
	dust.amount = 42
	dust.one_shot = true
	dust.explosiveness = 1.0
	dust.lifetime = 0.65
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(220.0, 10.0)
	dust.direction = Vector2.UP
	dust.spread = 80.0
	dust.initial_velocity_min = 55.0
	dust.initial_velocity_max = 185.0
	dust.gravity = Vector2(0.0, 240.0)
	dust.scale_amount_min = 1.8
	dust.scale_amount_max = 4.5
	dust.color = Color(1.0, 0.7, 0.32, 0.82)
	dust.z_index = 3
	dust.emitting = true
	add_child(dust)
	get_tree().create_timer(0.9).timeout.connect(dust.queue_free)

	neon_enabled = true
	neon_flicker_time = 0.12
	_set_neon_lit(true)


func _make_shockwave_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(25):
		var angle := TAU * float(point_index) / 24.0
		points.append(Vector2(cos(angle) * 215.0, sin(angle) * 50.0))
	return points


func _add_background_filter() -> void:
	var filter_overlay := ColorRect.new()
	filter_overlay.name = "BackgroundColorGrade"
	filter_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	filter_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filter_overlay.z_index = -1
	var filter_material := ShaderMaterial.new()
	filter_material.shader = TITLE_BACKGROUND_FILTER
	filter_overlay.material = filter_material
	add_child(filter_overlay)


func _add_layered_background() -> bool:
	var textures: Array[Texture2D] = []
	for texture_path in BACKGROUND_LAYERS:
		var texture := load(texture_path) as Texture2D
		if texture == null:
			return false
		textures.append(texture)

	for layer_index in range(textures.size()):
		if layer_index in SCROLLING_LAYER_INDEXES:
			_add_scrolling_cloud_layer(textures[layer_index], layer_index)
			continue
		var layer := TextureRect.new()
		layer.name = "BackgroundLayer%02d" % (layer_index + 1)
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.texture = textures[layer_index]
		layer.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.z_index = BACKGROUND_Z_INDEX + layer_index
		if layer_index == WATER_LAYER_INDEX:
			var water_material := ShaderMaterial.new()
			water_material.shader = TITLE_WATER_EFFECT
			layer.material = water_material
		add_child(layer)
	return true


func _add_scrolling_cloud_layer(texture: Texture2D, layer_index: int) -> void:
	cloud_textures[layer_index] = texture
	cloud_scroll_offsets[layer_index] = 0.0
	var layer_copies: Array[TextureRect] = []
	var cloud_viewport := Control.new()
	cloud_viewport.name = "BackgroundLayer%02d" % (layer_index + 1)
	cloud_viewport.set_anchors_preset(Control.PRESET_FULL_RECT)
	cloud_viewport.clip_contents = true
	cloud_viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cloud_viewport.z_index = BACKGROUND_Z_INDEX + layer_index
	add_child(cloud_viewport)

	for copy_index in range(2):
		var cloud_copy := TextureRect.new()
		cloud_copy.name = "CloudCopy%02d" % (copy_index + 1)
		cloud_copy.texture = texture
		cloud_copy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cloud_copy.stretch_mode = TextureRect.STRETCH_SCALE
		cloud_copy.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cloud_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cloud_viewport.add_child(cloud_copy)
		layer_copies.append(cloud_copy)
	cloud_copies_by_layer[layer_index] = layer_copies
	_layout_cloud_layer()


func _layout_cloud_layer() -> void:
	if cloud_textures.is_empty():
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	for layer_index in SCROLLING_LAYER_INDEXES:
		if not cloud_textures.has(layer_index) or not cloud_copies_by_layer.has(layer_index):
			continue
		var texture: Texture2D = cloud_textures[layer_index]
		var texture_size := texture.get_size()
		if texture_size.x <= 0.0 or texture_size.y <= 0.0:
			continue
		var cover_scale := maxf(
			viewport_size.x / texture_size.x,
			viewport_size.y / texture_size.y
		)
		var render_size := texture_size * cover_scale
		var render_width := render_size.x
		cloud_render_widths[layer_index] = render_width
		var scroll_offset: float = fposmod(
			float(cloud_scroll_offsets.get(layer_index, 0.0)),
			render_width
		)
		cloud_scroll_offsets[layer_index] = scroll_offset
		var segment_count: float = float(SCROLLING_LAYER_SEGMENTS.get(layer_index, 1.0))
		# Ogni strato di nuvole contiene un singolo panorama ripetuto a runtime.
		var segment_width := render_width / segment_count
		var centered_x := (viewport_size.x - segment_width) * 0.5
		var layer_copies: Array = cloud_copies_by_layer[layer_index]
		for copy_index in range(layer_copies.size()):
			var cloud_copy := layer_copies[copy_index] as TextureRect
			cloud_copy.size = render_size
			cloud_copy.position = Vector2(
				centered_x - scroll_offset + render_width * copy_index,
				(viewport_size.y - render_size.y) * 0.5
			)


func _process(delta: float) -> void:
	_update_broken_neon(delta)
	if not cloud_render_widths.is_empty():
		for layer_index in SCROLLING_LAYER_INDEXES:
			var render_width: float = float(cloud_render_widths.get(layer_index, 0.0))
			if render_width <= 0.0:
				continue
			var scroll_speed: float = float(SCROLLING_LAYER_SPEEDS.get(layer_index, 6.0))
			cloud_scroll_offsets[layer_index] = fposmod(
				float(cloud_scroll_offsets.get(layer_index, 0.0))
					+ scroll_speed * delta,
				render_width
			)
		_layout_cloud_layer()
	if press_start_label == null:
		return
	blink_accum += delta
	if blink_accum >= BLINK_INTERVAL:
		blink_accum = 0.0
		press_start_label.visible = not press_start_label.visible


func _update_broken_neon(delta: float) -> void:
	if not neon_enabled or neon_subtitle == null or neon_subtitle_glow == null:
		return
	neon_flicker_time -= delta
	if neon_flicker_time > 0.0:
		return
	if neon_flicker_steps > 0:
		neon_flicker_steps -= 1
		_set_neon_lit(neon_flicker_steps % 2 == 0)
		neon_flicker_time = neon_random.randf_range(0.025, 0.075)
		return
	_set_neon_lit(true)
	if neon_random.randf() < 0.34:
		neon_flicker_steps = neon_random.randi_range(2, 5)
		neon_flicker_time = neon_random.randf_range(0.45, 1.5)
	else:
		neon_flicker_time = neon_random.randf_range(1.2, 3.2)


func _set_neon_lit(is_lit: bool) -> void:
	var intensity := 1.0 if is_lit else 0.08
	neon_subtitle.modulate = Color(1.0, 1.0, 1.0, intensity)
	neon_subtitle_glow.modulate = Color(1.0, 1.0, 1.0, intensity)


func _unhandled_input(event: InputEvent) -> void:
	var is_start := event.is_action_pressed("ui_accept")
	if not is_start and event is InputEventJoypadButton:
		is_start = (event as InputEventJoypadButton).button_index == 6 and event.pressed
	if is_start:
		get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")
