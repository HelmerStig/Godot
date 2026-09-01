extends Node2D
class_name MainArena

## Coordina training e fighter; la UI osserva esclusivamente questi segnali.

signal fighter_health_changed(player_number: int, current_health: int, max_health: int)
signal round_time_changed(seconds_remaining: int)
signal round_message_changed(message: String, is_visible: bool)
signal round_started
signal round_ended(winner: int)

@onready var player1: Fighter = $Player1
@onready var player2: Fighter = $Player2
@onready var camera: Camera2D = $Camera2D

const STAGE_WIDTH := 2304.0
const STAGE_LEFT := 60.0
const STAGE_RIGHT := STAGE_WIDTH - 60.0
const FIGHTER_SPAWN_DISTANCE := 276.0
const FIGHTER_SCREEN_MARGIN := 70.0
const FLOOR_Y := 600.0
const ROUND_DURATION := 99.0

var round_time := ROUND_DURATION
var current_round := 1
var max_rounds := 3
var player1_wins := 0
var player2_wins := 0
var round_active := false
var match_over := false
var round_generation := 0
var displayed_round_seconds := -1


func _ready() -> void:
	player1.player_number = 1
	player2.player_number = 2
	player1.is_player_controlled = true
	player2.is_player_controlled = true
	player1.controls_enabled = false
	player2.controls_enabled = false
	player1.opponent = player2
	player2.opponent = player1
	player1.health_changed.connect(_on_fighter_health_changed.bind(1))
	player2.health_changed.connect(_on_fighter_health_changed.bind(2))
	player1.knocked_out.connect(_on_fighter_knocked_out.bind(2))
	player2.knocked_out.connect(_on_fighter_knocked_out.bind(1))

	player1.stage_left_limit = STAGE_LEFT
	player1.stage_right_limit = STAGE_RIGHT
	player2.stage_left_limit = STAGE_LEFT
	player2.stage_right_limit = STAGE_RIGHT

	_publish_initial_state()
	await get_tree().create_timer(1.0).timeout
	start_round()


func _process(delta: float) -> void:
	update_camera_position()
	update_fighter_visible_limits()

	if round_active and not match_over:
		round_time = maxf(round_time - delta, 0.0)
		_publish_round_time()
		# Il timeout resta disabilitato in training mode.


func start_round() -> void:
	"""Ripristina il training e avvia il countdown."""
	round_generation += 1
	var this_round_generation := round_generation
	round_active = false
	player1.controls_enabled = false
	player2.controls_enabled = false
	round_time = ROUND_DURATION
	displayed_round_seconds = -1
	round_message_changed.emit("TRAINING MODE", true)
	_publish_round_time()

	var stage_center := STAGE_WIDTH * 0.5
	player1.stage_left_limit = STAGE_LEFT
	player1.stage_right_limit = STAGE_RIGHT
	player2.stage_left_limit = STAGE_LEFT
	player2.stage_right_limit = STAGE_RIGHT
	player1.reset_fighter(Vector2(stage_center - FIGHTER_SPAWN_DISTANCE, FLOOR_Y))
	player2.reset_fighter(Vector2(stage_center + FIGHTER_SPAWN_DISTANCE, FLOOR_Y))
	camera.position.x = stage_center
	camera.reset_smoothing()
	if not player1.is_facing_right:
		player1.flip_character()
	if player2.is_facing_right:
		player2.flip_character()

	await get_tree().create_timer(1.0).timeout
	if this_round_generation != round_generation:
		return
	round_message_changed.emit("START!", true)

	await get_tree().create_timer(1.0).timeout
	if this_round_generation != round_generation:
		return
	round_message_changed.emit("", false)
	round_active = true
	player1.controls_enabled = true
	player2.controls_enabled = true
	round_started.emit()


func end_round_timeout() -> void:
	# Disabilitato per training mode.
	pass


func end_round_ko(winner: int) -> void:
	if not round_active:
		return
	round_active = false
	player1.controls_enabled = false
	player2.controls_enabled = false
	player1.velocity = Vector2.ZERO
	player2.velocity = Vector2.ZERO
	round_message_changed.emit("PLAYER %d WINS - R TO RESET" % winner, true)
	round_ended.emit(winner)


func next_round() -> void:
	# Disabilitato per training mode.
	pass


func update_camera_position() -> void:
	if player1 and player2:
		var target_x := (player1.position.x + player2.position.x) * 0.5
		var half_viewport := get_viewport_rect().size.x * 0.5
		var camera_min := half_viewport
		var camera_max := STAGE_WIDTH - half_viewport
		if camera_min > camera_max:
			target_x = (STAGE_LEFT + STAGE_RIGHT) * 0.5
		else:
			target_x = clampf(target_x, camera_min, camera_max)
		camera.position.x = target_x


func update_fighter_visible_limits() -> void:
	var half_visible_width := get_viewport_rect().size.x * 0.5 / camera.zoom.x
	var camera_center_x := camera.get_screen_center_position().x
	var visible_left := maxf(
		STAGE_LEFT,
		camera_center_x - half_visible_width + FIGHTER_SCREEN_MARGIN
	)
	var visible_right := minf(
		STAGE_RIGHT,
		camera_center_x + half_visible_width - FIGHTER_SCREEN_MARGIN
	)

	if visible_left > visible_right:
		visible_left = STAGE_LEFT
		visible_right = STAGE_RIGHT

	player1.stage_left_limit = visible_left
	player1.stage_right_limit = visible_right
	player2.stage_left_limit = visible_left
	player2.stage_right_limit = visible_right


func end_match(_winner: int) -> void:
	# Disabilitato per training mode.
	pass


func _publish_initial_state() -> void:
	fighter_health_changed.emit(1, player1.combat.current_health, player1.combat.max_health)
	fighter_health_changed.emit(2, player2.combat.current_health, player2.combat.max_health)
	round_message_changed.emit("TRAINING MODE", true)
	_publish_round_time()


func _publish_round_time() -> void:
	var seconds_remaining := ceili(round_time)
	if seconds_remaining == displayed_round_seconds:
		return
	displayed_round_seconds = seconds_remaining
	round_time_changed.emit(seconds_remaining)


func _on_fighter_health_changed(
	current_health: int,
	max_health: int,
	player_number: int
) -> void:
	fighter_health_changed.emit(player_number, current_health, max_health)


func _on_fighter_knocked_out(winner: int) -> void:
	end_round_ko(winner)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_training"):
		start_round()
	elif event.is_action_pressed("toggle_debug_boxes"):
		var boxes_are_visible := not player1.show_debug_boxes
		player1.show_debug_boxes = boxes_are_visible
		player2.show_debug_boxes = boxes_are_visible
		player1.queue_redraw()
		player2.queue_redraw()
	elif event.is_action_pressed("toggle_slow_motion"):
		Engine.time_scale = 1.0 if Engine.time_scale < 1.0 else 0.15
