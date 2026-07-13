extends Node2D

## Script principale dell'arena di combattimento
## Gestisce il round, timer, UI e condizioni di vittoria

# === RIFERIMENTI AI FIGHTER ===
@onready var player1: CharacterBody2D = $Player1
@onready var player2: CharacterBody2D = $Player2

# === RIFERIMENTI UI ===
@onready var player1_health_bar = $CanvasLayer/UI/Player1Health
@onready var player2_health_bar = $CanvasLayer/UI/Player2Health
@onready var round_timer_label = $CanvasLayer/UI/RoundTimer
@onready var round_label = $CanvasLayer/UI/RoundLabel

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
	
	# Avvia il primo round
	await get_tree().create_timer(1.0).timeout
	start_round()


func _process(delta):
	if round_active and not match_over:
		# Aggiorna timer
		round_time -= delta
		round_timer_label.text = str(int(round_time))
		
		# Aggiorna barre vita
		update_health_bars()
		
		# Controlla fine round per tempo scaduto
		if round_time <= 0:
			end_round_timeout()
		
		# Controlla fine round per KO
		if player1.current_health <= 0:
			end_round_ko(2)
		elif player2.current_health <= 0:
			end_round_ko(1)


func start_round():
	"""Inizia un nuovo round"""
	round_active = false
	round_label.text = "ROUND " + str(current_round)
	round_label.visible = true
	
	# Reset posizioni
	player1.position = Vector2(300, 600)
	player2.position = Vector2(850, 600)
	
	# Reset vita
	player1.current_health = player1.max_health
	player2.current_health = player2.max_health
	
	# Reset stati
	player1.current_state = 0  # State.IDLE
	player2.current_state = 0  # State.IDLE
	player1.can_move = false
	player2.can_move = false
	
	# Countdown
	await get_tree().create_timer(1.0).timeout
	round_label.text = "FIGHT!"
	
	await get_tree().create_timer(1.0).timeout
	round_label.visible = false
	
	# Inizia il round
	round_active = true
	round_time = 99.0
	player1.can_move = true
	player2.can_move = true


func end_round_timeout():
	"""Fine round per tempo scaduto - vince chi ha più vita"""
	round_active = false
	
	if player1.current_health > player2.current_health:
		end_round_ko(1)
	elif player2.current_health > player1.current_health:
		end_round_ko(2)
	else:
		# Pareggio - nessun vincitore
		round_label.text = "DRAW"
		round_label.visible = true
		await get_tree().create_timer(2.0).timeout
		next_round()


func end_round_ko(winner: int):
	"""Fine round per KO"""
	round_active = false
	player1.can_move = false
	player2.can_move = false
	
	if winner == 1:
		player1_wins += 1
		round_label.text = "PLAYER 1 WINS!"
	else:
		player2_wins += 1
		round_label.text = "PLAYER 2 WINS!"
	
	round_label.visible = true
	
	# Controlla se qualcuno ha vinto il match
	if player1_wins >= 2:
		await get_tree().create_timer(2.0).timeout
		end_match(1)
	elif player2_wins >= 2:
		await get_tree().create_timer(2.0).timeout
		end_match(2)
	else:
		await get_tree().create_timer(3.0).timeout
		next_round()


func next_round():
	"""Prepara il round successivo"""
	current_round += 1
	if current_round <= max_rounds:
		start_round()
	else:
		# Fine match per numero round
		if player1_wins > player2_wins:
			end_match(1)
		elif player2_wins > player1_wins:
			end_match(2)
		else:
			round_label.text = "MATCH DRAW"
			round_label.visible = true


func end_match(winner: int):
	"""Fine del match"""
	match_over = true
	
	if winner == 1:
		round_label.text = "PLAYER 1 WINS THE MATCH!"
	else:
		round_label.text = "PLAYER 2 WINS THE MATCH!"
	
	round_label.visible = true
	
	# Opzione per ricominciare
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()


func update_health_bars():
	"""Aggiorna le barre della vita"""
	player1_health_bar.value = player1.get_health_percentage() * 100
	player2_health_bar.value = player2.get_health_percentage() * 100
