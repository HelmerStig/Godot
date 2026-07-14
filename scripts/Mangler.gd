extends CharacterBody2D
class_name Mangler

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
const JUMP_VELOCITY = -850.0
const GRAVITY = 1400.0
const GROUND_COLLISION_LAYER = 1
const FIGHTER_COLLISION_LAYER = 8
const ATTACK_HITBOXES = {
	"light_punch": {
		"size": Vector2(70.0, 35.0),
		"position": Vector2(35.0, -110.0),
	},
	"heavy_punch": {
		"size": Vector2(100.0, 45.0),
		"position": Vector2(55.0, -105.0),
	},
	"light_kick": {
		"size": Vector2(85.0, 35.0),
		"position": Vector2(47.5, -55.0),
	},
	"heavy_kick": {
		"size": Vector2(115.0, 45.0),
		"position": Vector2(72.5, -65.0),
	},
}

# === VARIABILI DI STATO ===
var current_state = State.IDLE
var is_facing_right = true
var is_player_controlled = true  # false per IA
var opponent: Mangler

# === VARIABILI DI COMBATTIMENTO ===
@export var character_data: CharacterData
@export var show_debug_boxes = true
@export_range(1, 2, 1) var player_number := 1
var max_health = 100
var current_health = 100
var is_blocking = false
var can_move = true
var is_attacking = false
var combo_counter = 0
var last_attack_time = 0.0
var current_attack_damage = 0
var action_generation = 0
var hit_targets: Array[Mangler] = []

# === LIMITI DELLO STAGE ===
var stage_left_limit = 0.0
var stage_right_limit = 1152.0

# === RIFERIMENTI ===
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var collision_shape = $CollisionShape2D
@onready var hitbox = $Hitbox if has_node("Hitbox") else null
@onready var hurtbox = $Hurtbox if has_node("Hurtbox") else null
@onready var hitbox_shape: CollisionShape2D = $Hitbox/HitboxShape if has_node("Hitbox/HitboxShape") else null


func _ready():
	# Inizializzazione
	apply_character_data()
	current_health = max_health
	add_to_group("fighters")
	if hitbox_shape and hitbox_shape.shape:
		# Ogni fighter deve poter cambiare la propria hitbox indipendentemente.
		hitbox_shape.shape = hitbox_shape.shape.duplicate()
	
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
	update_physical_collision()
	
	# Muovi il personaggio
	move_and_slide()
	
	# Applica limiti dello stage
	position.x = clamp(position.x, stage_left_limit, stage_right_limit)
	
	# Aggiorna direzione sprite
	update_facing_direction()


func handle_input():
	"""Gestisce un'unica azione per frame secondo una priorità esplicita."""
	if current_state in [State.ATTACKING, State.HIT, State.KNOCKED_DOWN]:
		return

	if current_state == State.BLOCKING:
		return

	# Tenere indietro prepara la guardia, ma permette ancora di arretrare.
	is_blocking = is_holding_back() and is_on_floor()

	if Input.is_action_just_pressed(get_input_action("light_punch")) and is_on_floor():
		perform_attack("light_punch", get_attack_damage("light_punch"), get_attack_duration("light_punch"))
		return
	elif Input.is_action_just_pressed(get_input_action("heavy_punch")) and is_on_floor():
		perform_attack("heavy_punch", get_attack_damage("heavy_punch"), get_attack_duration("heavy_punch"))
		return
	elif Input.is_action_just_pressed(get_input_action("light_kick")) and is_on_floor():
		perform_attack("light_kick", get_attack_damage("light_kick"), get_attack_duration("light_kick"))
		return
	elif Input.is_action_just_pressed(get_input_action("heavy_kick")) and is_on_floor():
		perform_attack("heavy_kick", get_attack_damage("heavy_kick"), get_attack_duration("heavy_kick"))
		return

	if Input.is_action_pressed(get_input_action("crouch")) and is_on_floor():
		current_state = State.CROUCHING
		velocity.x = 0
		return
	elif current_state == State.CROUCHING:
		current_state = State.IDLE

	if Input.is_action_just_pressed(get_input_action("jump")) and is_on_floor():
		velocity.y = character_data.jump_velocity
		current_state = State.JUMPING
		return

	var direction = Input.get_axis(get_input_action("move_left"), get_input_action("move_right"))
	var movement_speed = character_data.air_speed if current_state == State.JUMPING else character_data.walk_speed
	velocity.x = direction * movement_speed
	if is_on_floor():
		current_state = State.WALKING if direction != 0 else State.IDLE


func perform_attack(attack_name: String, damage: int, duration: float):
	"""Esegue un attacco"""
	if current_state in [State.IDLE, State.WALKING] and not is_attacking and is_on_floor():
		action_generation += 1
		var attack_generation = action_generation
		is_attacking = true
		is_blocking = false
		current_attack_damage = damage
		hit_targets.clear()
		configure_hitbox(attack_name)
		can_move = false
		current_state = State.ATTACKING
		velocity.x = 0
		
		# Abilita hitbox dopo un breve delay (startup frames)
		await get_tree().create_timer(duration * 0.3).timeout
		if attack_generation != action_generation:
			return
		enable_hitbox()
		
		print("Eseguendo attacco: " + attack_name + " (danno: " + str(damage) + ")")
		
		# Disabilita hitbox dopo i frame attivi
		await get_tree().create_timer(duration * 0.4).timeout
		if attack_generation != action_generation:
			return
		disable_hitbox()
		
		# Fine attacco (recovery frames)
		await get_tree().create_timer(duration * 0.3).timeout
		if attack_generation != action_generation:
			return
		is_attacking = false
		current_attack_damage = 0
		hit_targets.clear()
		can_move = true
		current_state = State.IDLE


func update_state():
	"""Aggiorna lo stato del personaggio in base alle condizioni"""
	if current_state in [State.ATTACKING, State.BLOCKING, State.HIT, State.KNOCKED_DOWN]:
		return
	
	# Se sta saltando
	if not is_on_floor():
		current_state = State.JUMPING
	elif current_state == State.JUMPING:
		current_state = State.IDLE
	
	# Se è a terra e non si sta muovendo
	elif is_on_floor() and velocity.x == 0 and current_state == State.WALKING:
		current_state = State.IDLE
	
	# Debug stato
	# print("Stato corrente: ", State.keys()[current_state])


func update_physical_collision():
	"""In aria attraversa gli altri fighter, ma continua a collidere col terreno."""
	var is_airborne = current_state == State.JUMPING or not is_on_floor()
	if is_airborne:
		collision_layer = 0
		collision_mask = GROUND_COLLISION_LAYER
	else:
		collision_layer = FIGHTER_COLLISION_LAYER
		collision_mask = GROUND_COLLISION_LAYER | FIGHTER_COLLISION_LAYER


func update_facing_direction():
	"""Mantiene il personaggio rivolto verso il proprio avversario."""
	if opponent == null or not is_instance_valid(opponent):
		return

	var horizontal_distance = opponent.global_position.x - global_position.x
	if is_zero_approx(horizontal_distance):
		return

	var should_face_right = horizontal_distance > 0.0
	if should_face_right != is_facing_right:
		flip_character()


func flip_character():
	"""Inverte la direzione del personaggio"""
	is_facing_right = !is_facing_right

	# Il corpo fisico resta invariato: si girano solo grafica e hitbox offensiva.
	if sprite:
		sprite.flip_h = not is_facing_right
	if hitbox:
		hitbox.scale.x = 1.0 if is_facing_right else -1.0


func is_holding_back() -> bool:
	"""Controlla se il giocatore tiene la direzione opposta all'avversario."""
	if opponent == null or not is_instance_valid(opponent):
		return false
	if opponent.global_position.x > global_position.x:
		return Input.is_action_pressed(get_input_action("move_left"))
	return Input.is_action_pressed(get_input_action("move_right"))


func get_input_action(action_name: String) -> StringName:
	"""Restituisce l'azione Input Map associata a questo giocatore."""
	return StringName("p%d_%s" % [player_number, action_name])


func is_attack_in_front(attacker: Mangler) -> bool:
	"""Verifica che l'attaccante si trovi sul lato verso cui guarda il fighter."""
	if attacker == null or not is_instance_valid(attacker):
		return false
	var attacker_is_on_right = attacker.global_position.x > global_position.x
	return attacker_is_on_right == is_facing_right


func take_damage(damage: int, attacker: Mangler):
	"""Riceve danno da un attacco"""
	if current_state == State.KNOCKED_DOWN:
		return
	var attack_was_blocked = (
		(is_blocking or current_state == State.BLOCKING)
		and is_holding_back()
		and is_attack_in_front(attacker)
		and is_on_floor()
	)
	if attack_was_blocked:
		# Se sta bloccando, riduce il danno
		damage = int(damage * 0.2)
		print("Attacco bloccato! Danno ridotto a: " + str(damage))
	
	current_health -= damage
	current_health = clamp(current_health, 0, max_health)
	
	print("Vita rimanente: " + str(current_health) + "/" + str(max_health))
	
	if current_health <= 0:
		die()
	elif attack_was_blocked:
		block_reaction()
	else:
		# Stato colpito
		hit_reaction()


func block_reaction():
	"""Entra brevemente in guardia solo dopo aver bloccato un colpo."""
	cancel_current_action()
	var block_generation = action_generation
	current_state = State.BLOCKING
	can_move = false
	velocity.x = 0

	await get_tree().create_timer(0.15).timeout
	if block_generation != action_generation or current_health <= 0:
		return
	can_move = true
	current_state = State.IDLE


func hit_reaction():
	"""Reazione quando viene colpito"""
	cancel_current_action()
	var hit_generation = action_generation
	current_state = State.HIT
	can_move = false
	velocity.x = 0
	
	# Torna allo stato normale dopo un breve stun
	await get_tree().create_timer(0.3).timeout
	if hit_generation != action_generation or current_health <= 0:
		return
	can_move = true
	current_state = State.IDLE


func die():
	"""Gestisce la morte del personaggio"""
	cancel_current_action()
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
		var target := area.get_parent() as Mangler
		if target != null and target != self and not hit_targets.has(target):
			hit_targets.append(target)
			target.take_damage(current_attack_damage, self)


func _on_hurtbox_area_entered(_area: Area2D):
	"""Chiamato quando la hurtbox viene colpita"""
	# Gestito dal metodo take_damage chiamato dall'avversario
	pass


func enable_hitbox():
	"""Abilita la hitbox durante un attacco"""
	if hitbox_shape:
		hitbox_shape.disabled = false


func disable_hitbox():
	"""Disabilita la hitbox"""
	if hitbox_shape:
		hitbox_shape.disabled = true


func configure_hitbox(attack_name: String):
	"""Configura dimensione e posizione dell'hitbox per l'attacco scelto."""
	if hitbox_shape == null or not ATTACK_HITBOXES.has(attack_name):
		return

	var hitbox_data: Dictionary = ATTACK_HITBOXES[attack_name]
	var attack_shape = hitbox_shape.shape as RectangleShape2D
	if attack_shape:
		attack_shape.size = hitbox_data["size"]
		hitbox_shape.position = hitbox_data["position"]


func reset_fighter(spawn_position: Vector2):
	"""Riporta il fighter a uno stato neutrale e invalida le azioni pendenti."""
	cancel_current_action()
	position = spawn_position
	velocity = Vector2.ZERO
	current_health = max_health
	current_state = State.IDLE
	is_blocking = false
	can_move = false


func cancel_current_action():
	action_generation += 1
	is_attacking = false
	is_blocking = false
	current_attack_damage = 0
	hit_targets.clear()
	disable_hitbox()


func apply_character_data():
	if character_data == null:
		character_data = CharacterData.create_default()
	max_health = character_data.max_health


func get_attack_damage(attack_name: String) -> int:
	match attack_name:
		"light_punch": return character_data.light_punch_damage
		"heavy_punch": return character_data.heavy_punch_damage
		"light_kick": return character_data.light_kick_damage
		"heavy_kick": return character_data.heavy_kick_damage
	return 0


func get_attack_duration(attack_name: String) -> float:
	match attack_name:
		"light_punch": return character_data.light_punch_duration
		"heavy_punch": return character_data.heavy_punch_duration
		"light_kick": return character_data.light_kick_duration
		"heavy_kick": return character_data.heavy_kick_duration
	return 0.0
