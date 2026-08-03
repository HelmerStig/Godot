extends Node
class_name FighterCombat

## Gestisce il ciclo degli attacchi, le hitbox, i danni e le reazioni ai colpi.

signal health_changed(current_health: int, max_health: int)
signal knocked_out
signal attack_started(attack_name: StringName)
signal attack_finished

const DEFAULT_HITSTUN := 0.3
const DEFAULT_BLOCKSTUN := 0.15
const SWEEP_GROUNDED_HOLD := 0.35
const ATTACK_ANIMATION_FPS := 24.0
const CROUCHED_LIGHT_HITBOX_SIZE := Vector2(150.0, 35.0)
const CROUCHED_LIGHT_HITBOX_POSITION := Vector2(75.0, -110.0)
const CROUCHED_MEDIUM_HITBOX_SIZE := Vector2(165.0, 40.0)
const CROUCHED_MEDIUM_HITBOX_POSITION := Vector2(85.0, -108.0)
const CROUCHED_HEAVY_HITBOX_SIZE := Vector2(180.0, 170.0)
const CROUCHED_HEAVY_HITBOX_POSITION := Vector2(90.0, -155.0)
const CROUCHED_HEAVY_KICK_HITBOX_SIZE := Vector2(190.0, 45.0)
const CROUCHED_HEAVY_KICK_HITBOX_POSITION := Vector2(95.0, -42.0)
const CROUCHED_MEDIUM_KICK_HITBOX_SIZE := Vector2(165.0, 40.0)
const CROUCHED_MEDIUM_KICK_HITBOX_POSITION := Vector2(85.0, -48.0)
const CROUCHED_LIGHT_KICK_HITBOX_SIZE := Vector2(150.0, 35.0)
const CROUCHED_LIGHT_KICK_HITBOX_POSITION := Vector2(75.0, -45.0)
const JUMP_LIGHT_KICK_HITBOX_SIZE := Vector2(150.0, 45.0)
const JUMP_LIGHT_KICK_HITBOX_POSITION := Vector2(85.0, -105.0)

var fighter: Mangler
var character_data: CharacterData
var max_health := 100
var current_health := 100
var is_blocking := false
var is_attacking := false
var current_attack: AttackData
var current_attack_direction := FighterInputBuffer.Direction.NEUTRAL
var action_generation := 0
var hit_targets: Array[Mangler] = []
var light_punch_connected_targets: Array[Mangler] = []
var light_punch_followup_done := false
var medium_kick_followup_done := false
var is_crouched_light_punch := false
var crouched_punch_started_crouched := false
var is_crouched_medium_punch := false
var crouched_medium_punch_started_crouched := false
var is_crouched_heavy_punch := false
var crouched_heavy_punch_started_crouched := false
var is_crouched_heavy_kick := false
var is_crouched_medium_kick := false
var is_crouched_light_kick := false
var is_airborne_light_kick := false

@onready var hitbox: Area2D = get_parent().get_node("Hitbox")
@onready var hitbox_shape: CollisionShape2D = get_parent().get_node("Hitbox/HitboxShape")


func _ready() -> void:
	fighter = get_parent() as Mangler
	if hitbox_shape.shape:
		# Ogni fighter deve poter cambiare la propria hitbox indipendentemente.
		hitbox_shape.shape = hitbox_shape.shape.duplicate()
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	disable_hitbox()


func configure(data: CharacterData) -> void:
	character_data = data
	max_health = character_data.max_health
	current_health = max_health
	health_changed.emit(current_health, max_health)


func set_guarding(value: bool) -> void:
	is_blocking = value


func try_attack(
	attack_name: StringName,
	input_direction: int = FighterInputBuffer.Direction.NEUTRAL
) -> void:
	var wants_crouched_punch := (
		attack_name == &"light_punch"
		and input_direction in [
			FighterInputBuffer.Direction.DOWN,
			FighterInputBuffer.Direction.DOWN_FORWARD,
			FighterInputBuffer.Direction.DOWN_BACK,
		]
	)
	var wants_crouched_medium_punch := (
		attack_name == &"medium_punch"
		and input_direction in [
			FighterInputBuffer.Direction.DOWN,
			FighterInputBuffer.Direction.DOWN_FORWARD,
			FighterInputBuffer.Direction.DOWN_BACK,
		]
	)
	var wants_crouched_heavy_punch := (
		attack_name == &"heavy_punch"
		and input_direction in [
			FighterInputBuffer.Direction.DOWN,
			FighterInputBuffer.Direction.DOWN_FORWARD,
			FighterInputBuffer.Direction.DOWN_BACK,
		]
	)
	var wants_crouched_heavy_kick := (
		attack_name == &"heavy_kick"
		and input_direction in [
			FighterInputBuffer.Direction.DOWN,
			FighterInputBuffer.Direction.DOWN_FORWARD,
			FighterInputBuffer.Direction.DOWN_BACK,
		]
	)
	var wants_crouched_medium_kick := (
		attack_name == &"medium_kick"
		and input_direction in [
			FighterInputBuffer.Direction.DOWN,
			FighterInputBuffer.Direction.DOWN_FORWARD,
			FighterInputBuffer.Direction.DOWN_BACK,
		]
	)
	var wants_crouched_light_kick := (
		attack_name == &"light_kick"
		and input_direction in [
			FighterInputBuffer.Direction.DOWN,
			FighterInputBuffer.Direction.DOWN_FORWARD,
			FighterInputBuffer.Direction.DOWN_BACK,
		]
	)
	var starts_crouched := fighter.current_state == Mangler.State.CROUCHING
	var wants_airborne_light_kick := (
		attack_name == &"light_kick"
		and fighter.current_state == Mangler.State.JUMPING
		and not fighter.is_on_floor()
	)
	if fighter.current_state not in [Mangler.State.IDLE, Mangler.State.WALKING] and not wants_airborne_light_kick and not (
		(
			wants_crouched_punch
			or wants_crouched_medium_punch
			or wants_crouched_heavy_punch
			or wants_crouched_heavy_kick
			or wants_crouched_medium_kick
			or wants_crouched_light_kick
		)
		and starts_crouched
	):
		return
	if is_attacking or (not fighter.is_on_floor() and not wants_airborne_light_kick):
		return
	var attack := character_data.get_attack(attack_name)
	if attack == null or not attack.is_valid():
		push_warning("AttackData mancante o non valido: " + str(attack_name))
		return

	action_generation += 1
	var attack_generation := action_generation
	is_attacking = true
	is_blocking = false
	current_attack = attack
	current_attack_direction = input_direction
	is_crouched_light_punch = wants_crouched_punch
	crouched_punch_started_crouched = wants_crouched_punch and starts_crouched
	is_crouched_medium_punch = wants_crouched_medium_punch
	crouched_medium_punch_started_crouched = wants_crouched_medium_punch and starts_crouched
	is_crouched_heavy_punch = wants_crouched_heavy_punch
	crouched_heavy_punch_started_crouched = wants_crouched_heavy_punch and starts_crouched
	is_crouched_heavy_kick = wants_crouched_heavy_kick
	is_crouched_medium_kick = wants_crouched_medium_kick
	is_crouched_light_kick = wants_crouched_light_kick
	is_airborne_light_kick = wants_airborne_light_kick
	hit_targets.clear()
	light_punch_connected_targets.clear()
	light_punch_followup_done = false
	medium_kick_followup_done = false
	configure_hitbox(attack)
	var preserved_air_velocity := fighter.velocity
	fighter.change_state(Mangler.State.ATTACKING)
	if is_airborne_light_kick:
		fighter.velocity = preserved_air_velocity
	attack_started.emit(attack_name)
	var phase_durations := get_attack_phase_durations(attack)

	# Startup.
	await get_tree().create_timer(phase_durations.x).timeout
	if attack_generation != action_generation:
		return
	enable_hitbox()
	print("Eseguendo attacco: %s (danno: %d)" % [attack_name, attack.damage])

	# Frame attivi.
	await get_tree().create_timer(phase_durations.y).timeout
	if attack_generation != action_generation:
		return
	disable_hitbox()

	# Recovery.
	await get_tree().create_timer(phase_durations.z).timeout
	if attack_generation != action_generation:
		return
	if attack.attack_id in [&"light_punch", &"medium_punch", &"heavy_punch", &"light_kick", &"medium_kick", &"heavy_kick"]:
		while (
			attack_generation == action_generation
			and fighter.animated_sprite.animation in [
				&"light_punch_single",
				&"light_punch_double",
				&"crouched_punch",
				&"crouched_punch_crouched",
				&"medium_open_hand_slap",
				&"crouched_medium_punch",
				&"crouched_medium_punch_crouched",
				&"heavy_punch",
				&"crouched_power_punch",
				&"light_kick",
				&"medium_kick",
				&"heavy_kick",
				&"crouched_heavy_kick",
				&"crouched_medium_kick",
				&"crouched_light_kick",
				&"jump_light_kick",
			]
			and fighter.animated_sprite.is_playing()
		):
			await get_tree().process_frame
		if attack_generation != action_generation:
			return
	is_attacking = false
	current_attack = null
	hit_targets.clear()
	light_punch_connected_targets.clear()
	var should_return_to_crouch := (
		(
			is_crouched_light_punch
			or is_crouched_medium_punch
			or is_crouched_heavy_punch
			or is_crouched_heavy_kick
			or is_crouched_medium_kick
			or is_crouched_light_kick
		)
		and fighter.input_buffer != null
		and fighter.input_buffer.is_down_held()
	)
	var should_return_to_jump := is_airborne_light_kick and not fighter.is_on_floor()
	is_crouched_light_punch = false
	crouched_punch_started_crouched = false
	is_crouched_medium_punch = false
	crouched_medium_punch_started_crouched = false
	is_crouched_heavy_punch = false
	crouched_heavy_punch_started_crouched = false
	is_crouched_heavy_kick = false
	is_crouched_medium_kick = false
	is_crouched_light_kick = false
	is_airborne_light_kick = false
	if should_return_to_jump:
		fighter.change_state(Mangler.State.JUMPING)
	elif should_return_to_crouch:
		fighter.return_to_crouch_pose()
	else:
		fighter.change_state(Mangler.State.IDLE)
	attack_finished.emit()


func take_damage(
	damage: int,
	attacker: Mangler,
	hitstun: float = DEFAULT_HITSTUN,
	blockstun: float = DEFAULT_BLOCKSTUN,
	hit_height: AttackData.HitHeight = AttackData.HitHeight.MID,
	causes_knockdown: bool = false,
	hit_reaction_start_frame: int = 0,
	ko_start_frame: int = 0,
	apply_pushback: bool = true
) -> void:
	if fighter.current_state in [Mangler.State.KNOCKDOWN_RECOVERY, Mangler.State.KNOCKED_DOWN]:
		return

	var attack_was_blocked := (
		(is_blocking or fighter.current_state == Mangler.State.BLOCKING)
		and fighter.is_holding_back()
		and fighter.is_attack_in_front(attacker)
		and fighter.is_on_floor()
	)
	if attack_was_blocked:
		damage = 0
		print("Attacco bloccato! Nessun danno subito.")

	current_health = clampi(current_health - damage, 0, max_health)
	health_changed.emit(current_health, max_health)
	print("Vita rimanente: %d/%d" % [current_health, max_health])

	if current_health <= 0:
		die(ko_start_frame)
	elif attack_was_blocked:
		block_reaction(blockstun, hit_height)
	elif causes_knockdown:
		sweep_knockdown_reaction(attacker)
	else:
		if hit_height == AttackData.HitHeight.MID:
			hit_reaction_start_frame = 4
		hit_reaction(hitstun, hit_height, attacker, hit_reaction_start_frame, apply_pushback)


func block_reaction(duration: float, hit_height: AttackData.HitHeight) -> void:
	var started_crouched := fighter.current_state == Mangler.State.CROUCHING
	cancel_current_action()
	var block_generation := action_generation
	var animation_duration := fighter.start_block_reaction(hit_height, started_crouched)
	var reaction_duration := maxf(duration, animation_duration)

	await get_tree().create_timer(reaction_duration).timeout
	if block_generation != action_generation or current_health <= 0:
		return
	if hit_height == AttackData.HitHeight.LOW and fighter.is_holding_low_guard():
		fighter.return_to_crouch_after_low_block()
		return
	var recovery_duration := fighter.start_block_recovery()
	await get_tree().create_timer(recovery_duration).timeout
	if block_generation != action_generation or current_health <= 0:
		return
	fighter.change_state(Mangler.State.IDLE)


func hit_reaction(
	duration: float,
	hit_height: AttackData.HitHeight,
	attacker: Mangler,
	hit_reaction_start_frame: int = 0,
	apply_pushback: bool = true
) -> void:
	cancel_current_action()
	var hit_generation := action_generation
	var animation_duration := fighter.start_hit_reaction(
		hit_height,
		attacker,
		hit_reaction_start_frame,
		apply_pushback
	)
	var reaction_duration := maxf(duration, animation_duration)

	await get_tree().create_timer(reaction_duration).timeout
	if hit_generation != action_generation or current_health <= 0:
		return
	fighter.velocity.x = 0.0
	fighter.change_state(Mangler.State.IDLE)


func sweep_knockdown_reaction(attacker: Mangler) -> void:
	cancel_current_action()
	var knockdown_generation := action_generation
	var animation_duration := fighter.start_sweep_knockdown(attacker)

	await get_tree().create_timer(animation_duration + SWEEP_GROUNDED_HOLD).timeout
	if knockdown_generation != action_generation or current_health <= 0:
		return
	var recovery_duration := fighter.start_knockdown_recovery()
	await get_tree().create_timer(recovery_duration).timeout
	if knockdown_generation != action_generation or current_health <= 0:
		return
	fighter.change_state(Mangler.State.IDLE)


func die(start_frame: int = 0) -> void:
	cancel_current_action()
	fighter.change_state(Mangler.State.KNOCKED_DOWN)
	if fighter.animated_sprite.sprite_frames.has_animation(&"ko"):
		fighter.animated_sprite.play(&"ko")
		var final_frame := fighter.animated_sprite.sprite_frames.get_frame_count(&"ko") - 1
		fighter.animated_sprite.frame = clampi(start_frame, 0, final_frame)
	knocked_out.emit()
	print("KO!")


func reset() -> void:
	cancel_current_action()
	current_health = max_health
	health_changed.emit(current_health, max_health)


func cancel_current_action() -> void:
	action_generation += 1
	if fighter != null:
		fighter.restore_default_render_order()
	is_attacking = false
	is_blocking = false
	current_attack = null
	current_attack_direction = FighterInputBuffer.Direction.NEUTRAL
	is_crouched_light_punch = false
	crouched_punch_started_crouched = false
	is_crouched_medium_punch = false
	crouched_medium_punch_started_crouched = false
	is_crouched_heavy_punch = false
	crouched_heavy_punch_started_crouched = false
	is_crouched_heavy_kick = false
	is_crouched_medium_kick = false
	is_crouched_light_kick = false
	is_airborne_light_kick = false
	hit_targets.clear()
	light_punch_connected_targets.clear()
	light_punch_followup_done = false
	disable_hitbox()


func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)


func enable_hitbox() -> void:
	hitbox_shape.disabled = false


func disable_hitbox() -> void:
	if hitbox_shape:
		hitbox_shape.disabled = true


func configure_hitbox(attack: AttackData) -> void:
	var attack_shape := hitbox_shape.shape as RectangleShape2D
	if attack_shape:
		attack_shape.size = attack.hitbox_size
		hitbox_shape.position = attack.hitbox_position
		if is_crouched_light_punch:
			attack_shape.size = CROUCHED_LIGHT_HITBOX_SIZE
			hitbox_shape.position = CROUCHED_LIGHT_HITBOX_POSITION
		elif is_crouched_medium_punch:
			attack_shape.size = CROUCHED_MEDIUM_HITBOX_SIZE
			hitbox_shape.position = CROUCHED_MEDIUM_HITBOX_POSITION
		elif is_crouched_heavy_punch:
			attack_shape.size = CROUCHED_HEAVY_HITBOX_SIZE
			hitbox_shape.position = CROUCHED_HEAVY_HITBOX_POSITION
		elif is_crouched_heavy_kick:
			attack_shape.size = CROUCHED_HEAVY_KICK_HITBOX_SIZE
			hitbox_shape.position = CROUCHED_HEAVY_KICK_HITBOX_POSITION
		elif is_crouched_medium_kick:
			attack_shape.size = CROUCHED_MEDIUM_KICK_HITBOX_SIZE
			hitbox_shape.position = CROUCHED_MEDIUM_KICK_HITBOX_POSITION
		elif is_crouched_light_kick:
			attack_shape.size = CROUCHED_LIGHT_KICK_HITBOX_SIZE
			hitbox_shape.position = CROUCHED_LIGHT_KICK_HITBOX_POSITION
		elif is_airborne_light_kick:
			attack_shape.size = JUMP_LIGHT_KICK_HITBOX_SIZE
			hitbox_shape.position = JUMP_LIGHT_KICK_HITBOX_POSITION


func get_attack_phase_durations(attack: AttackData) -> Vector3:
	if attack.attack_id == &"medium_punch" and is_crouched_medium_punch:
		var startup_frames := 4.0 if crouched_medium_punch_started_crouched else 8.0
		return Vector3(startup_frames, 3.0, 5.0) / ATTACK_ANIMATION_FPS
	if attack.attack_id == &"heavy_punch" and is_crouched_heavy_punch:
		return Vector3(9.0, 2.0, 5.0) / ATTACK_ANIMATION_FPS
	if attack.attack_id == &"heavy_kick" and is_crouched_heavy_kick:
		return Vector3(3.0, 2.0, 12.0) / ATTACK_ANIMATION_FPS
	if attack.attack_id == &"medium_kick" and is_crouched_medium_kick:
		return Vector3(5.0, 3.0, 8.0) / ATTACK_ANIMATION_FPS
	if attack.attack_id == &"light_kick" and is_crouched_light_kick:
		return Vector3(5.0, 3.0, 8.0) / ATTACK_ANIMATION_FPS
	if attack.attack_id == &"light_kick" and is_airborne_light_kick:
		return Vector3(4.0, 2.0, 3.0) / ATTACK_ANIMATION_FPS
	return Vector3(attack.startup, attack.active, attack.recovery)


func get_hit_reaction_start_frame(attack: AttackData) -> int:
	if get_effective_hit_height(attack) == AttackData.HitHeight.MID:
		return 4
	return attack.hit_reaction_start_frame


func get_effective_hit_height(attack: AttackData) -> AttackData.HitHeight:
	if attack.attack_id == &"light_punch" and is_crouched_light_punch:
		return AttackData.HitHeight.MID
	if attack.attack_id == &"medium_punch" and is_crouched_medium_punch:
		return AttackData.HitHeight.MID
	if attack.attack_id == &"heavy_punch" and is_crouched_heavy_punch:
		return AttackData.HitHeight.LOW
	if attack.attack_id == &"heavy_kick" and is_crouched_heavy_kick:
		return AttackData.HitHeight.LOW
	if attack.attack_id == &"medium_kick" and is_crouched_medium_kick:
		return AttackData.HitHeight.MID
	if attack.attack_id == &"light_kick" and is_crouched_light_kick:
		return AttackData.HitHeight.MID
	if attack.attack_id == &"light_kick" and is_airborne_light_kick:
		return AttackData.HitHeight.HIGH
	return attack.hit_height


func perform_light_punch_followup() -> void:
	"""Al frame 8 riavvia la reazione dei bersagli colpiti dal primo pugno."""
	if light_punch_followup_done or not is_attacking or current_attack == null:
		return
	if current_attack.attack_id != &"light_punch":
		return

	light_punch_followup_done = true
	for target in light_punch_connected_targets.duplicate():
		if target == null or not is_instance_valid(target):
			continue
		target.combat.take_damage(
			current_attack.damage,
			fighter,
			current_attack.hitstun,
			current_attack.blockstun,
			current_attack.hit_height,
			current_attack.causes_knockdown,
			4,
			10,
			false
		)


func perform_medium_kick_followup() -> void:
	if medium_kick_followup_done or not is_attacking or current_attack == null:
		return
	if current_attack.attack_id != &"medium_kick":
		return

	medium_kick_followup_done = true
	for target in hit_targets.duplicate():
		if target == null or not is_instance_valid(target):
			continue
		target.combat.take_damage(
			int(current_attack.damage / 2),
			fighter,
			current_attack.hitstun,
			current_attack.blockstun,
			AttackData.HitHeight.MID,
			false,
			4
		)


func _on_hitbox_area_entered(area: Area2D) -> void:
	_apply_hit_to_area(area)


func _apply_hit_to_area(area: Area2D) -> void:
	if not area.is_in_group("hurtbox") or not is_attacking:
		return

	var target := area.get_parent() as Mangler
	if target == null or target == fighter or hit_targets.has(target) or current_attack == null:
		return
	hit_targets.append(target)
	if (
		current_attack.attack_id == &"light_punch"
		and not is_crouched_light_punch
		and not light_punch_connected_targets.has(target)
	):
		light_punch_connected_targets.append(target)
	var effective_hit_height := get_effective_hit_height(current_attack)
	var effective_reaction_frame := get_hit_reaction_start_frame(current_attack)
	var effective_damage := current_attack.damage
	var effective_knockdown := current_attack.causes_knockdown
	if current_attack.attack_id == &"heavy_kick" and is_crouched_heavy_kick:
		effective_knockdown = true
	if current_attack.attack_id == &"medium_kick" and not is_crouched_medium_kick:
		effective_damage = int(current_attack.damage / 2)
		effective_hit_height = (
			AttackData.HitHeight.MID
			if medium_kick_followup_done
			else AttackData.HitHeight.HIGH
		)
		effective_reaction_frame = 4 if medium_kick_followup_done else 0
		effective_knockdown = false
	target.combat.take_damage(
		effective_damage,
		fighter,
		current_attack.hitstun,
		current_attack.blockstun,
		effective_hit_height,
		effective_knockdown,
		effective_reaction_frame,
		0,
		not (current_attack.attack_id == &"light_punch" and not is_crouched_light_punch)
	)
