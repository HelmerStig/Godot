extends CharacterBody2D
class_name Fighter

## Script base per i personaggi del picchiaduro
## Gestisce movimento, stati, combattimento e fisica

# Enumerazione degli stati del personaggio
enum State {
	IDLE,
	WALKING,
	JUMPING,
	CROUCHING,
	ATTACKING,
	BLOCKING,
	HIT,
	KNOCKED_DOWN
}

# === COSTANTI DI MOVIMENTO ===
const WALK_SPEED = 200.0
const JUMP_VELOCITY = -450.0
const GRAVITY = 980.0

# === VARIABILI DI STATO ===
var current_state = State.IDLE
var is_facing_right = true
var is_player_controlled = true  # false per IA

# === VARIABILI DI COMBATTIMENTO ===
var max_health = 100
var current_health = 100
var is_blocking = false
var can_move = true
var is_attacking = false
var combo_counter = 0
var last_attack_time = 0.0

# === RIFERIMENTI ===
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var collision_shape = $CollisionShape2D
@onready var hitbox = $Hitbox if has_node("Hitbox") else null
@onready var hurtbox = $Hurtbox if has_node("Hurtbox") else null


func _ready():
	# Inizializzazione
	current_health = max_health
	add_to_group("fighters")
	
	# Connetti segnali hitbox/hurtbox
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)


func _physics_process(delta):
	# Applica gravità
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Gestione input e movimento
	if is_player_controlled and can_move:
		handle_input()
	
	# Aggiorna stato
	update_state()
	
	# Muovi il personaggio
	move_and_slide()
	
	# Aggiorna direzione sprite
	update_facing_direction()


func handle_input():
	"""Gestisce gli input del giocatore"""
	
	# Reset velocità orizzontale
	if is_on_floor() and current_state != State.ATTACKING:
		velocity.x = 0
	
	# Accovacciamento - controlla prima per priorità
	if Input.is_action_pressed("crouch") and is_on_floor() and current_state != State.ATTACKING:
		current_state = State.CROUCHING
		velocity.x = 0
		return  # Esce dalla funzione, ignora altri input
	
	# Se era accovacciato ma ha rilasciato il tasto, torna a IDLE
	if current_state == State.CROUCHING and not Input.is_action_pressed("crouch"):
		current_state = State.IDLE
	
	# Movimento orizzontale (funziona anche in aria durante il salto)
	if current_state in [State.IDLE, State.WALKING, State.JUMPING]:
		if Input.is_action_pressed("move_left"):
			velocity.x = -WALK_SPEED
			if is_on_floor():
				current_state = State.WALKING
		elif Input.is_action_pressed("move_right"):
			velocity.x = WALK_SPEED
			if is_on_floor():
				current_state = State.WALKING
		else:
			velocity.x = 0
			if is_on_floor() and current_state != State.JUMPING:
				current_state = State.IDLE
	
	# Salto
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		current_state = State.JUMPING
	
	# Blocco
	if Input.is_action_pressed("block") and current_state != State.CROUCHING:
		is_blocking = true
		current_state = State.BLOCKING
		velocity.x = 0
	else:
		is_blocking = false
	
	# Attacchi
	if Input.is_action_just_pressed("light_punch"):
		perform_attack("light_punch", 5, 0.3)
	elif Input.is_action_just_pressed("heavy_punch"):
		perform_attack("heavy_punch", 15, 0.6)
	elif Input.is_action_just_pressed("light_kick"):
		perform_attack("light_kick", 8, 0.4)
	elif Input.is_action_just_pressed("heavy_kick"):
		perform_attack("heavy_kick", 20, 0.7)


func perform_attack(attack_name: String, damage: int, duration: float):
	"""Esegue un attacco"""
	if not is_attacking and is_on_floor():
		is_attacking = true
		can_move = false
		current_state = State.ATTACKING
		velocity.x = 0
		
		# Abilita hitbox dopo un breve delay (startup frames)
		await get_tree().create_timer(duration * 0.3).timeout
		enable_hitbox()
		
		print("Eseguendo attacco: " + attack_name + " (danno: " + str(damage) + ")")
		
		# Disabilita hitbox dopo i frame attivi
		await get_tree().create_timer(duration * 0.4).timeout
		disable_hitbox()
		
		# Fine attacco (recovery frames)
		await get_tree().create_timer(duration * 0.3).timeout
		is_attacking = false
		can_move = true
		current_state = State.IDLE


func update_state():
	"""Aggiorna lo stato del personaggio in base alle condizioni"""
	
	# Se sta saltando
	if not is_on_floor() and current_state != State.HIT:
		if current_state != State.JUMPING:
			current_state = State.JUMPING
	
	# Se è a terra e non si sta muovendo
	elif is_on_floor() and velocity.x == 0 and current_state == State.WALKING:
		current_state = State.IDLE
	
	# Debug stato
	# print("Stato corrente: ", State.keys()[current_state])


func update_facing_direction():
	"""Aggiorna la direzione in cui guarda il personaggio"""
	if velocity.x > 0 and not is_facing_right:
		flip_character()
	elif velocity.x < 0 and is_facing_right:
		flip_character()


func flip_character():
	"""Inverte la direzione del personaggio"""
	is_facing_right = !is_facing_right
	
	# Usa scale.x per il flip (funziona con qualsiasi tipo di nodo)
	scale.x *= -1


func take_damage(damage: int, _attacker: Fighter):
	"""Riceve danno da un attacco"""
	if is_blocking:
		# Se sta bloccando, riduce il danno
		damage = int(damage * 0.2)
		print("Attacco bloccato! Danno ridotto a: " + str(damage))
	
	current_health -= damage
	current_health = clamp(current_health, 0, max_health)
	
	print("Vita rimanente: " + str(current_health) + "/" + str(max_health))
	
	if current_health <= 0:
		die()
	else:
		# Stato colpito
		hit_reaction()


func hit_reaction():
	"""Reazione quando viene colpito"""
	current_state = State.HIT
	can_move = false
	velocity.x = 0
	
	# Torna allo stato normale dopo un breve stun
	await get_tree().create_timer(0.3).timeout
	can_move = true
	current_state = State.IDLE


func die():
	"""Gestisce la morte del personaggio"""
	current_state = State.KNOCKED_DOWN
	can_move = false
	velocity.x = 0
	print("KO!")
	# TODO: Animazione KO e fine round


func get_health_percentage() -> float:
	"""Ritorna la percentuale di vita rimanente"""
	return float(current_health) / float(max_health)


func _on_hitbox_area_entered(area: Area2D):
	"""Chiamato quando la hitbox colpisce un'area"""
	# La hitbox colpisce la hurtbox dell'avversario
	if area.is_in_group("hurtbox") and is_attacking:
		var opponent = area.get_parent()
		if opponent != self and opponent is Fighter:
			# Infliggi danno in base all'attacco corrente
			var damage = 10  # Danno base, da calcolare in base all'attacco
			opponent.take_damage(damage, self)


func _on_hurtbox_area_entered(_area: Area2D):
	"""Chiamato quando la hurtbox viene colpita"""
	# Gestito dal metodo take_damage chiamato dall'avversario
	pass


func enable_hitbox():
	"""Abilita la hitbox durante un attacco"""
	if hitbox and hitbox.has_node("HitboxShape"):
		hitbox.get_node("HitboxShape").disabled = false


func disable_hitbox():
	"""Disabilita la hitbox"""
	if hitbox and hitbox.has_node("HitboxShape"):
		hitbox.get_node("HitboxShape").disabled = true
