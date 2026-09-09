extends Control

const TITLE_BACKGROUND_FILTER := preload("res://shaders/title_background_filter.gdshader")
const TITLE_WATER_EFFECT := preload("res://shaders/title_water_effect.gdshader")

var press_start_label: Label
var blink_accum := 0.0
const BLINK_INTERVAL := 0.55
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


func _unhandled_input(event: InputEvent) -> void:
	var is_start := event.is_action_pressed("ui_accept")
	if not is_start and event is InputEventJoypadButton:
		is_start = (event as InputEventJoypadButton).button_index == 6 and event.pressed
	if is_start:
		get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")
