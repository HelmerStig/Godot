extends Node2D

## Script principale dell'arena di combattimento
## Gestisce il round, timer, UI e condizioni di vittoria

# === RIFERIMENTI AI FIGHTER ===
@onready var player1: CharacterBody2D = $Player1
# @onready var player2: CharacterBody2D = $Player2  # Temporaneamente disabilitato

# === RIFERIMENTI UI ===
@onready var player1_health_bar = $CanvasLayer/UI/Player1Health
# @onready var player2_health_bar = $CanvasLayer/UI/Player2Health  # Temporaneamente disabilitato
@onready var round_timer_label = $CanvasLayer/UI/RoundTimer
@onready var round_label = $CanvasLayer/UI/RoundLabel
@onready var camera = $Camera2D

# === LIMITI DELLO STAGE ===
const STAGE_LEFT = 100.0
const STAGE_RIGHT = 1052.0

# === VARIABILI DI GIOCO ===
var round_time = 99.0  # Tempo del round in secondi
var current_round = 1
var max_rounds = 3
var player1_wins = 0
var player2_wins = 0
var round_active = false
var match_over = false


func _ready():
	# Imposta Player2 come non controllato dal giocatore (per ora)
	# player2.is_player_controlled = false  # Per IA futura
	
	# Imposta limiti stage sui personaggi
	player1.stage_left_limit = STAGE_LEFT
	player1.stage_right_limit = STAGE_RIGHT
	
	# Avvia il primo round
	await get_tree().create_timer(1.0).timeout
	start_round()


func _process(delta):
	# Aggiorna posizione camera per seguire il player
	update_camera_position()
	
	if round_active and not match_over:
		# Aggiorna timer
		round_time -= delta
		round_timer_label.text = str(int(round_time))
		
		# Aggiorna barre vita
		update_health_bars()
		
		# Controlla fine round per tempo scaduto (disabilitato per training)
		# if round_time <= 0:
		# 	end_round_timeout()
		
		# Controlla fine round per KO (solo player1 per ora)
		if player1.current_health <= 0:
			round_label.text = "KNOCKED OUT!"
			round_label.visible = true


func start_round():
	"""Inizia un nuovo round"""
	round_active = false
	round_label.text = "TRAINING MODE"
	round_label.visible = true
	
	# Reset posizione
	player1.position = Vector2(300, 600)
	
	# Reset vita
	player1.current_health = player1.max_health
	
	# Reset stato
	player1.current_state = 0  # State.IDLE
	player1.can_move = false
	
	# Countdown
	await get_tree().create_timer(1.0).timeout
	round_label.text = "START!"
	
	await get_tree().create_timer(1.0).timeout
	round_label.visible = false
	
	# Inizia il round
	round_active = true
	round_time = 99.0
	player1.can_move = true


func end_round_timeout():
	"""Fine round per tempo scaduto - vince chi ha più vita"""
	# Disabilitato per training mode
	pass


func end_round_ko(_winner: int):
	"""Fine round per KO"""
	# Disabilitato per training mode
	pass


func next_round():
	"""Prepara il round successivo"""
	# Disabilitato per training mode
	pass


func update_camera_position():
	"""Aggiorna la posizione della camera per seguire i personaggi"""
	if player1:
		# Per ora segue solo player1, in futuro centrerà tra player1 e player2
		var target_x = player1.position.x
		
		# Clamp la camera dentro i limiti dello stage
		target_x = clamp(target_x, STAGE_LEFT + 576, STAGE_RIGHT - 576)
		
		camera.position.x = target_x


func end_match(_winner: int):
	"""Fine del match"""
	# Disabilitato per training mode
	pass


func update_health_bars():
	"""Aggiorna le barre della vita"""
	player1_health_bar.value = player1.get_health_percentage() * 100
	# player2_health_bar.value = player2.get_health_percentage() * 100  # Temporaneamente disabilitato
