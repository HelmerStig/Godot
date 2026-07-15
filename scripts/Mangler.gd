extends CharacterBody2D
class_name Mangler

## Corpo e coordinatore del fighter: input, movimento, stato e orientamento.

signal health_changed(current_health: int, max_health: int)
signal knocked_out
signal state_changed(previous_state: int, current_state: int)
signal attack_started(attack_name: StringName)
signal attack_finished

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

const GRAVITY := 1400.0
const GROUND_COLLISION_LAYER := 1
const FIGHTER_COLLISION_LAYER := 8
const ATTACK_PRIORITY := [
	&"light_punch",
	&"medium_punch",
	&"heavy_punch",
	&"light_kick",
	&"medium_kick",
	&"heavy_kick",
]

@export var character_data: CharacterData
@export var show_debug_boxes := true
@export_range(1, 2, 1) var player_number := 1

var current_state := State.IDLE
var is_facing_right := true
var is_player_controlled := true
var opponent: Mangler
var controls_enabled := true
var can_move := true
var input_buffer: FighterInputBuffer
var stage_left_limit := 0.0
var stage_right_limit := 1152.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var combat: FighterCombat = $Combat


func _ready() -> void:
	input_buffer = FighterInputBuffer.new(player_number)
	apply_character_data()
	combat.health_changed.connect(_on_combat_health_changed)
	combat.knocked_out.connect(_on_combat_knocked_out)
	combat.attack_started.connect(_on_combat_attack_started)
	combat.attack_finished.connect(_on_combat_attack_finished)
	combat.configure(character_data)
	add_to_group("fighters")
	update_animation()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Il buffer continua a registrare durante startup, recovery e hit-stun.
	if is_player_controlled:
		input_buffer.update(is_facing_right)

	if is_player_controlled and controls_enabled and can_move:
		handle_input()

	update_state()
	update_physical_collision()
	move_and_slide()
	position.x = clampf(position.x, stage_left_limit, stage_right_limit)
	update_facing_direction()


func handle_input() -> void:
	"""Gestisce un'unica azione per frame secondo una priorità esplicita."""
	if current_state in [State.ATTACKING, State.BLOCKING, State.HIT, State.KNOCKED_DOWN]:
		return

	# Tenere indietro prepara la guardia, ma permette ancora di arretrare.
	combat.set_guarding(is_holding_back() and is_on_floor())

	if is_on_floor():
		for attack_name in ATTACK_PRIORITY:
			var attack_direction := input_buffer.consume_attack(attack_name)
			if attack_direction != FighterInputBuffer.NO_DIRECTION:
				combat.try_attack(attack_name, attack_direction)
				return

	if input_buffer.is_down_held() and is_on_floor():
		change_state(State.CROUCHING)
		return
	elif current_state == State.CROUCHING:
		change_state(State.IDLE)

	if Input.is_action_just_pressed(get_input_action("jump")) and is_on_floor():
		velocity.y = character_data.jump_velocity
		change_state(State.JUMPING)
		return

	var direction := input_buffer.get_horizontal_axis()
	var movement_speed := (
		character_data.air_speed if current_state == State.JUMPING
		else character_data.walk_speed
	)
	velocity.x = direction * movement_speed
	if is_on_floor():
		change_state(State.WALKING if direction != 0 else State.IDLE)


func change_state(next_state: int) -> void:
	"""Centralizza gli effetti collaterali di ogni transizione di stato."""
	if current_state == next_state:
		return

	var previous_state := current_state
	current_state = next_state
	match current_state:
		State.IDLE, State.WALKING, State.JUMPING:
			can_move = true
		State.CROUCHING:
			can_move = true
			velocity.x = 0.0
		State.ATTACKING, State.BLOCKING, State.HIT, State.KNOCKED_DOWN:
			can_move = false
			velocity.x = 0.0
	update_animation()
	state_changed.emit(previous_state, current_state)


func update_animation() -> void:
	"""Riproduce l'animazione associata allo stato, senza riavviarla ogni frame."""
	var next_animation: StringName = &"walk" if current_state == State.WALKING else &"idle"
	if animated_sprite.sprite_frames.has_animation(next_animation):
		animated_sprite.play(next_animation)


func update_state() -> void:
	if current_state in [State.ATTACKING, State.BLOCKING, State.HIT, State.KNOCKED_DOWN]:
		return

	if not is_on_floor():
		change_state(State.JUMPING)
	elif current_state == State.JUMPING:
		change_state(State.IDLE)
	elif is_zero_approx(velocity.x) and current_state == State.WALKING:
		change_state(State.IDLE)


func update_physical_collision() -> void:
	"""In aria attraversa gli altri fighter, ma continua a collidere col terreno."""
	var is_airborne := current_state == State.JUMPING or not is_on_floor()
	if is_airborne:
		collision_layer = 0
		collision_mask = GROUND_COLLISION_LAYER
	else:
		collision_layer = FIGHTER_COLLISION_LAYER
		collision_mask = GROUND_COLLISION_LAYER | FIGHTER_COLLISION_LAYER


func update_facing_direction() -> void:
	if opponent == null or not is_instance_valid(opponent):
		return

	var horizontal_distance := opponent.global_position.x - global_position.x
	if is_zero_approx(horizontal_distance):
		return

	var should_face_right := horizontal_distance > 0.0
	if should_face_right != is_facing_right:
		flip_character()


func flip_character() -> void:
	is_facing_right = not is_facing_right
	animated_sprite.flip_h = not is_facing_right
	combat.hitbox.scale.x = 1.0 if is_facing_right else -1.0


func is_holding_back() -> bool:
	if opponent == null or not is_instance_valid(opponent) or input_buffer == null:
		return false
	return input_buffer.is_back_held()


func get_input_action(action_name: String) -> StringName:
	if input_buffer != null:
		return input_buffer.get_action(action_name)
	return StringName("p%d_%s" % [player_number, action_name])


func is_attack_in_front(attacker: Mangler) -> bool:
	if attacker == null or not is_instance_valid(attacker):
		return false
	var attacker_is_on_right := attacker.global_position.x > global_position.x
	return attacker_is_on_right == is_facing_right


func reset_fighter(spawn_position: Vector2) -> void:
	position = spawn_position
	velocity = Vector2.ZERO
	combat.reset()
	change_state(State.IDLE)
	can_move = true
	if input_buffer != null:
		input_buffer.clear()


func get_health_percentage() -> float:
	return combat.get_health_percentage()


func apply_character_data() -> void:
	if character_data == null:
		character_data = CharacterData.create_default()


func _on_combat_health_changed(current_health: int, max_health: int) -> void:
	health_changed.emit(current_health, max_health)


func _on_combat_knocked_out() -> void:
	knocked_out.emit()


func _on_combat_attack_started(attack_name: StringName) -> void:
	attack_started.emit(attack_name)


func _on_combat_attack_finished() -> void:
	attack_finished.emit()
