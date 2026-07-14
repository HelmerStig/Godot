extends Node2D

## Script principale dell'arena di combattimento
## Gestisce il round, timer, UI e condizioni di vittoria

# === RIFERIMENTI AI FIGHTER ===
@onready var player1: Mangler = $Player1
@onready var player2: Mangler = $Player2

# === RIFERIMENTI UI ===
@onready var player1_health_bar = $CanvasLayer/UI/Player1Health
@onready var player2_health_bar = $CanvasLayer/UI/Player2Health
@onready var round_timer_label = $CanvasLayer/UI/RoundTimer
@onready var round_label = $CanvasLayer/UI/RoundLabel
@onready var camera = $Camera2D

# === LIMITI DELLO STAGE ===
const STAGE_WIDTH = 2304.0
const STAGE_LEFT = 60.0
const STAGE_RIGHT = STAGE_WIDTH - 60.0
const FIGHTER_SPAWN_DISTANCE = 276.0
const FIGHTER_SCREEN_MARGIN = 70.0
const FLOOR_Y = 600.0

# === VARIABILI DI GIOCO ===
var round_time = 99.0  # Tempo del round in secondi
var current_round = 1
var max_rounds = 3
var player1_wins = 0
var player2_wins = 0
var round_active = false
var match_over = false
var round_generation = 0


func _ready():
	# Ogni fighter legge esclusivamente il proprio profilo di input.
	player1.player_number = 1
	player2.player_number = 2
	player1.is_player_controlled = true
	player2.is_player_controlled = true
	player1.can_move = false
	player2.can_move = false
	player1.opponent = player2
	player2.opponent = player1
	
	# Imposta limiti stage sui personaggi
	player1.stage_left_limit = STAGE_LEFT
	player1.stage_right_limit = STAGE_RIGHT
	player2.stage_left_limit = STAGE_LEFT
	player2.stage_right_limit = STAGE_RIGHT
	
	# Avvia il primo round
	await get_tree().create_timer(1.0).timeout
	start_round()


func _process(delta):
	# Aggiorna posizione camera per seguire il player
	update_camera_position()
	update_fighter_visible_limits()
	
	if round_active and not match_over:
		# Aggiorna timer
		round_time = maxf(round_time - delta, 0.0)
		round_timer_label.text = str(ceili(round_time))
		
		# Aggiorna barre vita
		update_health_bars()
		
		# Controlla fine round per tempo scaduto (disabilitato per training)
		# if round_time <= 0:
		# 	end_round_timeout()
		
		# In training il KO ferma l'azione, ma non avanza il match.
		if player1.current_health <= 0:
			end_round_ko(2)
		elif player2.current_health <= 0:
			end_round_ko(1)


func start_round():
	"""Inizia un nuovo round"""
	round_generation += 1
	var this_round_generation = round_generation
	round_active = false
	round_label.text = "TRAINING MODE"
	round_label.visible = true
	
	var stage_center = STAGE_WIDTH * 0.5
	# Ripristina prima i limiti assoluti: quelli visibili possono essere ristretti
	# dalla posizione della camera raggiunta nel tentativo precedente.
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
	update_health_bars()
	
	# Countdown
	await get_tree().create_timer(1.0).timeout
	if this_round_generation != round_generation:
		return
	round_label.text = "START!"
	
	await get_tree().create_timer(1.0).timeout
	if this_round_generation != round_generation:
		return
	round_label.visible = false
	
	# Inizia il round
	round_active = true
	round_time = 99.0
	player1.can_move = true
	player2.can_move = true


func end_round_timeout():
	"""Fine round per tempo scaduto - vince chi ha più vita"""
	# Disabilitato per training mode
	pass


func end_round_ko(_winner: int):
	"""Fine round per KO"""
	if not round_active:
		return
	round_active = false
	player1.can_move = false
	player2.can_move = false
	round_label.text = "PLAYER %d WINS - R TO RESET" % _winner
	round_label.visible = true


func next_round():
	"""Prepara il round successivo"""
	# Disabilitato per training mode
	pass


func update_camera_position():
	"""Aggiorna la posizione della camera per seguire i personaggi"""
	if player1 and player2:
		# Centra l'inquadratura tra i fighter rispettando i bordi dello stage.
		var target_x = (player1.position.x + player2.position.x) * 0.5
		var half_viewport = get_viewport_rect().size.x * 0.5
		var camera_min = half_viewport
		var camera_max = STAGE_WIDTH - half_viewport
		if camera_min > camera_max:
			target_x = (STAGE_LEFT + STAGE_RIGHT) * 0.5
		else:
			target_x = clamp(target_x, camera_min, camera_max)
		
		camera.position.x = target_x


func update_fighter_visible_limits():
	"""Impedisce ai fighter di oltrepassare i bordi visibili della camera."""
	var half_visible_width = get_viewport_rect().size.x * 0.5 / camera.zoom.x
	var camera_center_x = camera.get_screen_center_position().x
	var visible_left = maxf(STAGE_LEFT, camera_center_x - half_visible_width + FIGHTER_SCREEN_MARGIN)
	var visible_right = minf(STAGE_RIGHT, camera_center_x + half_visible_width - FIGHTER_SCREEN_MARGIN)

	# Su viewport eccezionalmente piccoli conserva almeno i limiti dello stage.
	if visible_left > visible_right:
		visible_left = STAGE_LEFT
		visible_right = STAGE_RIGHT

	player1.stage_left_limit = visible_left
	player1.stage_right_limit = visible_right
	player2.stage_left_limit = visible_left
	player2.stage_right_limit = visible_right


func end_match(_winner: int):
	"""Fine del match"""
	# Disabilitato per training mode
	pass


func update_health_bars():
	"""Aggiorna le barre della vita"""
	player1_health_bar.value = player1.get_health_percentage() * 100
	player2_health_bar.value = player2.get_health_percentage() * 100


func _unhandled_input(event):
	if event.is_action_pressed("reset_training"):
		start_round()
	elif event.is_action_pressed("toggle_debug_boxes"):
		var boxes_are_visible = not player1.show_debug_boxes
		player1.show_debug_boxes = boxes_are_visible
		player2.show_debug_boxes = boxes_are_visible
		player1.queue_redraw()
		player2.queue_redraw()
	elif event.is_action_pressed("toggle_slow_motion"):
		Engine.time_scale = 1.0 if Engine.time_scale < 1.0 else 0.15
