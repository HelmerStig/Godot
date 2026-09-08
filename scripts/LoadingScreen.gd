extends Control

const ARENA_SCENE := "res://scenes/MainArena.tscn"
const DOT_INTERVAL := 0.45
const MAX_DOTS := 3

var dot_accum := 0.0
var dot_count := 0
var loading_label: Label
var loading_done := false


func _ready() -> void:
	_build_ui()
	ResourceLoader.load_threaded_request(ARENA_SCENE)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.09, 1)
	add_child(bg)

	var placeholder := Panel.new()
	placeholder.set_anchor(SIDE_LEFT, 0.1)
	placeholder.set_anchor(SIDE_RIGHT, 0.9)
	placeholder.set_anchor(SIDE_TOP, 0.15)
	placeholder.set_anchor(SIDE_BOTTOM, 0.75)
	add_child(placeholder)

	var placeholder_lbl := Label.new()
	placeholder_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	placeholder_lbl.text = "[STAGE BACKGROUND]"
	placeholder_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder_lbl.add_theme_font_size_override("font_size", 28)
	placeholder.add_child(placeholder_lbl)

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
