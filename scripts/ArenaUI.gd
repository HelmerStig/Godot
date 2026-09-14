extends Control
class_name ArenaUI

## Presenta lo stato dell'arena senza essere interrogata direttamente dal gameplay.

@onready var player1_health_bar: ProgressBar = $Player1Health
@onready var player2_health_bar: ProgressBar = $Player2Health
@onready var player1_name_label: Label = $Player1Name
@onready var player2_name_label: Label = $Player2Name
@onready var round_timer_label: Label = $RoundTimer
@onready var round_label: Label = $RoundLabel

const HEALTH_BAR_SHADOW := preload("res://assets/ui/bar/bar-01-shadow.png")
const HEALTH_BAR_GLOW := preload("res://assets/ui/bar/bar-02-glow.png")
const HEALTH_BAR_FILL := preload("res://assets/ui/bar/bar-03-fill.png")
const HEALTH_BAR_OUTLINE := preload("res://assets/ui/bar/bar-04-outline.png")
const HEALTH_ANIMATION_DURATION := 0.34
const HEALTH_BAR_SIZE := Vector2(350.0, 47.0)

var health_glows: Dictionary = {}
var health_fill_clips: Dictionary = {}
var health_fill_layers: Dictionary = {}
var health_fill_mirrored: Dictionary = {}
var health_tweens: Dictionary = {}
var health_initialized: Dictionary = {}


func _ready() -> void:
	_setup_health_bar(player1_health_bar)
	_setup_health_bar(player2_health_bar)
	_refresh_player_names()
	var arena: Node = owner
	if arena == null:
		push_error("ArenaUI deve appartenere a una MainArena")
		return

	for required_signal in [
		&"fighter_health_changed",
		&"round_time_changed",
		&"round_message_changed",
	]:
		if not arena.has_signal(required_signal):
			push_error("MainArena non espone il segnale richiesto: " + str(required_signal))
			return

	arena.connect(&"fighter_health_changed", _on_fighter_health_changed)
	arena.connect(&"round_time_changed", _on_round_time_changed)
	arena.connect(&"round_message_changed", _on_round_message_changed)


func _setup_health_bar(health_bar: ProgressBar) -> void:
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	health_bar.add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	var is_mirrored := health_bar == player2_health_bar

	var shadow := _make_health_layer("Shadow", HEALTH_BAR_SHADOW, true)
	shadow.flip_h = is_mirrored
	health_bar.add_child(shadow)

	var fill_clip := Control.new()
	fill_clip.name = "FillMask"
	fill_clip.clip_contents = true
	fill_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.add_child(fill_clip)
	var fill := _make_health_layer("Fill", HEALTH_BAR_FILL, false)
	fill_clip.add_child(fill)
	health_fill_clips[health_bar] = fill_clip
	health_fill_layers[health_bar] = fill
	health_fill_mirrored[health_bar] = is_mirrored

	var glow := _make_health_layer("DamageGlow", HEALTH_BAR_GLOW, true)
	glow.flip_h = is_mirrored
	glow.modulate.a = 0.0
	health_bar.add_child(glow)
	health_glows[health_bar] = glow

	var outline := _make_health_layer("Outline", HEALTH_BAR_OUTLINE, true)
	outline.flip_h = is_mirrored
	health_bar.add_child(outline)
	health_bar.value_changed.connect(_on_health_bar_value_changed.bind(health_bar))
	_update_health_fill(health_bar, health_bar.value)


func _make_health_layer(
	layer_name: String,
	texture: Texture2D,
	fit_parent_rect: bool
) -> TextureRect:
	var layer := TextureRect.new()
	layer.name = layer_name
	layer.texture = texture
	if fit_parent_rect:
		layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		layer.position = Vector2.ZERO
		layer.size = HEALTH_BAR_SIZE
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return layer


func _on_health_bar_value_changed(value: float, health_bar: ProgressBar) -> void:
	_update_health_fill(health_bar, value)


func _update_health_fill(health_bar: ProgressBar, percentage: float) -> void:
	var fill_clip := health_fill_clips.get(health_bar) as Control
	var fill := health_fill_layers.get(health_bar) as TextureRect
	if fill_clip == null or fill == null:
		return
	var ratio := clampf(percentage / 100.0, 0.0, 1.0)
	var filled_width := HEALTH_BAR_SIZE.x * ratio
	fill_clip.position = Vector2(
		HEALTH_BAR_SIZE.x - filled_width if health_fill_mirrored.get(health_bar, false) else 0.0,
		0.0
	)
	fill_clip.size = Vector2(filled_width, HEALTH_BAR_SIZE.y)
	fill.size = HEALTH_BAR_SIZE
	fill.flip_h = health_fill_mirrored.get(health_bar, false)
	fill.position = Vector2(-fill_clip.position.x, 0.0) if fill.flip_h else Vector2.ZERO


func _refresh_player_names() -> void:
	player1_name_label.text = CharacterSelection.get_label_for(CharacterSelection.player1_id).to_upper()
	player2_name_label.text = CharacterSelection.get_label_for(CharacterSelection.player2_id).to_upper()


func _on_fighter_health_changed(
	player_number: int,
	current_health: int,
	max_health: int
) -> void:
	var health_bar := player1_health_bar if player_number == 1 else player2_health_bar
	var target_percentage := _health_percentage(current_health, max_health)
	var previous_percentage := health_bar.value
	if not health_initialized.has(health_bar):
		health_initialized[health_bar] = true
		health_bar.value = target_percentage
		return

	var active_tween := health_tweens.get(health_bar) as Tween
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	var tween := create_tween()
	health_tweens[health_bar] = tween
	tween.tween_property(health_bar, "value", target_percentage, HEALTH_ANIMATION_DURATION).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	if target_percentage < previous_percentage:
		_play_damage_glow(health_bar)


func _play_damage_glow(health_bar: ProgressBar) -> void:
	var glow := health_glows.get(health_bar) as TextureRect
	if glow == null:
		return
	var tween := glow.create_tween()
	tween.kill()
	glow.modulate.a = 0.0
	tween.tween_property(glow, "modulate:a", 1.0, 0.045)
	tween.tween_property(glow, "modulate:a", 0.0, 0.22)


func _on_round_time_changed(seconds_remaining: int) -> void:
	round_timer_label.text = str(seconds_remaining)


func _on_round_message_changed(message: String, is_visible: bool) -> void:
	round_label.text = message
	round_label.visible = is_visible


func _health_percentage(current_health: int, max_health: int) -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health) * 100.0
