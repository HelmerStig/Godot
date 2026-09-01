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
const JUMP_KICK_ANIMATION_FPS := 30.0
const AIRBORNE_ATTACK_GROUND_CANCEL_HEIGHT := 40.0
# Alias pubblici temporanei: la suite storica li usa ancora in fase di compilazione.
# Il runtime non li legge più; la fonte effettiva è AttackVariantData.
const CROUCHED_LIGHT_HITBOX_SIZE := Vector2(150.0, 35.0)
const CROUCHED_LIGHT_HITBOX_POSITION := Vector2(75.0, -110.0)
const STANDING_LIGHT_PUNCH_HITBOX_SIZE := Vector2(205.0, 35.0)
const STANDING_LIGHT_PUNCH_HITBOX_POSITION := Vector2(52.5, -210.0)
const STANDING_LIGHT_PUNCH_ACTIVE_FRAME := 11
const CROUCHED_LIGHT_PUNCH_ACTIVE_FRAME := 10
const CROUCHED_MEDIUM_PUNCH_ACTIVE_FRAME := 11
const CROUCHED_HEAVY_PUNCH_ACTIVE_FRAME := 8
const STANDING_LIGHT_KICK_ACTIVE_FRAME := 14
const STANDING_HEAVY_KICK_ACTIVE_FRAME := 24
const STANDING_HEAVY_KICK_HITBOX_SIZE := Vector2(165.0, 45.0)
const STANDING_HEAVY_KICK_HITBOX_POSITION := Vector2(97.5, -65.0)
const STANDING_MEDIUM_KICK_ACTIVE_FRAME := 26
const STANDING_MEDIUM_PUNCH_ACTIVE_FRAME := 17
const CROUCHED_MEDIUM_HITBOX_SIZE := Vector2(195.0, 40.0)
const CROUCHED_MEDIUM_HITBOX_POSITION := Vector2(100.0, -108.0)
const CROUCHED_HEAVY_KICK_HITBOX_SIZE := Vector2(190.0, 45.0)
const CROUCHED_HEAVY_KICK_HITBOX_POSITION := Vector2(95.0, -42.0)
const CROUCHED_MEDIUM_KICK_HITBOX_SIZE := Vector2(195.0, 40.0)
const CROUCHED_MEDIUM_KICK_HITBOX_POSITION := Vector2(100.0, -48.0)
const CROUCHED_LIGHT_KICK_HITBOX_SIZE := Vector2(190.0, 35.0)
const CROUCHED_LIGHT_KICK_HITBOX_POSITION := Vector2(95.0, -45.0)
const JUMP_LIGHT_KICK_HITBOX_SIZE := Vector2(150.0, 45.0)
const JUMP_LIGHT_KICK_HITBOX_POSITION := Vector2(85.0, -105.0)
const JUMP_HEAVY_KICK_HITBOX_SIZE := Vector2(220.0, 65.0)
const JUMP_HEAVY_KICK_HITBOX_POSITION := Vector2(125.0, -60.0)
const JUMP_MEDIUM_KICK_HITBOX_SIZE := Vector2(150.0, 45.0)
const JUMP_MEDIUM_KICK_HITBOX_POSITION := Vector2(85.0, -105.0)
const STANDING_HEAVY_PUNCH_HITBOX_SIZE := Vector2(225.0, 45.0)
const STANDING_HEAVY_PUNCH_HITBOX_POSITION := Vector2(117.5, -105.0)
const CROUCHED_HEAVY_LAUNCH_VERTICAL := 800.0
const CROUCHED_HEAVY_LAUNCH_HORIZONTAL := 200.0

var fighter: Fighter
var character_data: CharacterData
var max_health := 100
var current_health := 100
var is_blocking := false
var is_attacking := false
var current_attack: AttackData
var current_variant: Resource
var current_attack_direction := FighterInputBuffer.Direction.NEUTRAL
var action_generation := 0
var hit_targets: Array[Fighter] = []
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
var is_airborne_heavy_kick := false
var is_airborne_medium_kick := false
var is_airborne_medium_punch := false
var is_airborne_heavy_punch := false
var is_airborne_light_punch := false
var is_special_720_punch := false
var is_special_sonic_boom := false

@onready var hitbox: Area2D = get_parent().get_node("Hitbox")
@onready var hitbox_shape: CollisionShape2D = get_parent().get_node("Hitbox/HitboxShape")


func _ready() -> void:
	fighter = get_parent() as Fighter
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
	var starts_crouched := fighter.current_state == Fighter.State.CROUCHING
	var wants_special_720_punch := attack_name == &"special_720_punch"
	var wants_special_sonic_boom := attack_name == &"special_sonic_boom"
	var wants_airborne_light_punch := (
		attack_name == &"light_punch"
		and fighter.current_state == Fighter.State.JUMPING
		and not fighter.is_on_floor()
		and not fighter.aerial_attack_used
	)
	var wants_airborne_medium_punch := (
		attack_name == &"medium_punch"
		and fighter.current_state == Fighter.State.JUMPING
		and not fighter.is_on_floor()
		and not fighter.aerial_attack_used
	)
	var wants_airborne_heavy_punch := (
		attack_name == &"heavy_punch"
		and fighter.current_state == Fighter.State.JUMPING
		and not fighter.is_on_floor()
		and not fighter.aerial_attack_used
	)
	var wants_airborne_light_kick := (
		attack_name == &"light_kick"
		and fighter.current_state == Fighter.State.JUMPING
		and not fighter.is_on_floor()
		and not fighter.aerial_attack_used
	)
	var wants_airborne_heavy_kick := (
		attack_name == &"heavy_kick"
		and fighter.current_state == Fighter.State.JUMPING
		and not fighter.is_on_floor()
		and not fighter.aerial_attack_used
	)
	var wants_airborne_medium_kick := (
		attack_name == &"medium_kick"
		and fighter.current_state == Fighter.State.JUMPING
		and not fighter.is_on_floor()
		and not fighter.aerial_attack_used
	)
	var wants_airborne_kick := (
		wants_airborne_light_kick
		or wants_airborne_medium_kick
		or wants_airborne_heavy_kick
	)
	var wants_airborne_attack := (
		wants_airborne_kick
		or wants_airborne_light_punch
		or wants_airborne_medium_punch
		or wants_airborne_heavy_punch
	)
	if (
		fighter.current_state == Fighter.State.JUMPING
		and not fighter.is_on_floor()
		and fighter.aerial_attack_used
	):
		return
	if fighter.current_state not in [Fighter.State.IDLE, Fighter.State.WALKING] and not wants_airborne_attack and not (
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
	if is_attacking or (not fighter.is_on_floor() and not wants_airborne_attack):
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
	is_crouched_light_punch = wants_crouched_punch and not wants_airborne_light_punch
	crouched_punch_started_crouched = wants_crouched_punch and starts_crouched
	is_crouched_medium_punch = wants_crouched_medium_punch and not wants_airborne_medium_punch
	crouched_medium_punch_started_crouched = wants_crouched_medium_punch and starts_crouched
	is_crouched_heavy_punch = wants_crouched_heavy_punch and not wants_airborne_heavy_punch
	crouched_heavy_punch_started_crouched = wants_crouched_heavy_punch and starts_crouched
	is_crouched_heavy_kick = wants_crouched_heavy_kick
	is_crouched_medium_kick = wants_crouched_medium_kick
	is_crouched_light_kick = wants_crouched_light_kick
	is_airborne_light_kick = wants_airborne_light_kick
	is_airborne_heavy_kick = wants_airborne_heavy_kick
	is_airborne_medium_kick = wants_airborne_medium_kick
	is_airborne_medium_punch = wants_airborne_medium_punch
	is_airborne_heavy_punch = wants_airborne_heavy_punch
	is_airborne_light_punch = wants_airborne_light_punch
	is_special_720_punch = wants_special_720_punch
	is_special_sonic_boom = wants_special_sonic_boom
	current_variant = attack.get_variant(get_current_variant_id())
	if wants_airborne_attack:
		fighter.aerial_attack_used = true
	hit_targets.clear()
	medium_kick_followup_done = false
	configure_hitbox(attack)
	var preserved_air_velocity := fighter.velocity
	fighter.change_state(Fighter.State.ATTACKING)
	if (
		is_airborne_light_kick
		or is_airborne_medium_kick
		or is_airborne_heavy_kick
		or is_airborne_medium_punch
		or is_airborne_heavy_punch
		or is_airborne_light_punch
	):
		fighter.velocity = preserved_air_velocity
	attack_started.emit(attack_name)
	var phase_durations := get_attack_phase_durations(attack)

	# Startup.
	if attack.attack_id == &"medium_punch" and not is_crouched_medium_punch and not is_airborne_medium_punch:
		await wait_for_standing_medium_punch_active_frame(attack_generation)
	else:
		await get_tree().create_timer(phase_durations.x).timeout
	if attack_generation != action_generation:
		return
	if not is_special_sonic_boom:
		enable_hitbox()
	print("Eseguendo attacco: %s (danno: %d)" % [attack_name, attack.damage])

	var canceled_near_ground := false
	if is_airborne_light_punch or is_airborne_medium_punch:
		canceled_near_ground = await hold_jump_attack_until_release(
			attack_name, attack_generation, 14, 15
		)
		if attack_generation != action_generation:
			return
	elif is_airborne_light_kick or is_airborne_medium_kick or is_airborne_heavy_kick:
		canceled_near_ground = await hold_jump_attack_until_release(
			attack_name, attack_generation, 19, 20
		)
		if attack_generation != action_generation:
			return
	elif is_special_720_punch:
		await perform_special_720_multi_hit(phase_durations.y, attack_generation)
		if attack_generation != action_generation:
			return
	else:
		# Frame attivi.
		await get_tree().create_timer(phase_durations.y).timeout
		if attack_generation != action_generation:
			return
	if (
		not is_airborne_light_punch
		and not is_airborne_medium_punch
		and not is_airborne_light_kick
		and not is_airborne_medium_kick
		and not is_airborne_heavy_kick
		and wants_airborne_attack
		and is_attack_button_held(attack_name)
	):
		canceled_near_ground = await hold_airborne_attack_until_release(
			attack_name, attack_generation
		)
		if attack_generation != action_generation:
			return
	disable_hitbox()

	# Recovery.
	if not canceled_near_ground:
		await get_tree().create_timer(phase_durations.z).timeout
		if attack_generation != action_generation:
			return
	if attack.attack_id in [&"light_punch", &"medium_punch", &"heavy_punch", &"light_kick", &"medium_kick", &"heavy_kick", &"special_720_punch", &"special_sonic_boom"]:
		while (
			attack_generation == action_generation
			and fighter.animated_sprite.animation in [
				&"light_punch_single",
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
				&"jump_light_punch",
				&"jump_heavy_kick",
				&"jump_medium_kick",
				&"jump_medium_punch",
				&"jump_heavy_punch",
				&"special_720_punch",
				&"special_sonic_boom",
			]
			and fighter.animated_sprite.is_playing()
		):
			await get_tree().process_frame
		if attack_generation != action_generation:
			return
	is_attacking = false
	current_attack = null
	current_variant = null
	hit_targets.clear()
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
	var should_return_to_jump := (
		(
			is_airborne_light_kick
			or is_airborne_medium_kick
			or is_airborne_heavy_kick
			or is_airborne_medium_punch
			or is_airborne_heavy_punch
			or is_airborne_light_punch
		)
		and not fighter.is_on_floor()
	)
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
	is_airborne_heavy_kick = false
	is_airborne_medium_kick = false
	is_airborne_medium_punch = false
	is_airborne_heavy_punch = false
	is_airborne_light_punch = false
	is_special_720_punch = false
	is_special_sonic_boom = false
	if canceled_near_ground and fighter.is_on_floor():
		fighter.change_state(Fighter.State.IDLE)
	elif canceled_near_ground:
		fighter.force_idle_until_landing = true
		fighter.change_state(Fighter.State.JUMPING)
	elif should_return_to_jump:
		fighter.change_state(Fighter.State.JUMPING)
	elif should_return_to_crouch:
		fighter.return_to_crouch_pose()
	else:
		fighter.change_state(Fighter.State.IDLE)
	attack_finished.emit()


func take_damage(
	damage: int,
	attacker: Fighter,
	hitstun: float = DEFAULT_HITSTUN,
	blockstun: float = DEFAULT_BLOCKSTUN,
	hit_height: AttackData.HitHeight = AttackData.HitHeight.MID,
	causes_knockdown: bool = false,
	hit_reaction_start_frame: int = 0,
	ko_start_frame: int = 0,
	apply_pushback: bool = true
) -> void:
	if fighter.current_state in [Fighter.State.KNOCKDOWN_RECOVERY, Fighter.State.KNOCKED_DOWN]:
		return
	var was_airborne := not fighter.is_on_floor()

	var attack_was_blocked := (
		(is_blocking or fighter.current_state == Fighter.State.BLOCKING)
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
		block_reaction(blockstun, hit_height, attacker)
	elif causes_knockdown:
		sweep_knockdown_reaction(attacker)
	elif was_airborne:
		airborne_knockdown_reaction(attacker)
	else:
		if hit_height == AttackData.HitHeight.MID:
			hit_reaction_start_frame = 4
		hit_reaction(hitstun, hit_height, attacker, hit_reaction_start_frame, apply_pushback)


func block_reaction(
	duration: float,
	hit_height: AttackData.HitHeight,
	attacker: Fighter = null
) -> void:
	var started_crouched := fighter.current_state == Fighter.State.CROUCHING
	cancel_current_action()
	var block_generation := action_generation
	var animation_duration := fighter.start_block_reaction(hit_height, started_crouched)
	var reaction_duration := maxf(duration, animation_duration)

	await get_tree().create_timer(reaction_duration).timeout
	if block_generation != action_generation or current_health <= 0:
		return
	while (
		attacker != null
		and is_instance_valid(attacker)
		and attacker.combat != null
		and attacker.combat.is_attacking
	):
		var frame_count := fighter.animated_sprite.sprite_frames.get_frame_count(
			fighter.animated_sprite.animation
		)
		if frame_count > 0:
			fighter.animated_sprite.frame = frame_count - 1
			fighter.animated_sprite.pause()
		await get_tree().process_frame
		if block_generation != action_generation or current_health <= 0:
			return
	if hit_height == AttackData.HitHeight.LOW and fighter.is_holding_low_guard():
		fighter.return_to_crouch_after_low_block()
		return
	var recovery_duration := fighter.start_block_recovery()
	await get_tree().create_timer(recovery_duration).timeout
	if block_generation != action_generation or current_health <= 0:
		return
	fighter.change_state(Fighter.State.IDLE)


func hit_reaction(
	duration: float,
	hit_height: AttackData.HitHeight,
	attacker: Fighter,
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
	fighter.change_state(Fighter.State.IDLE)


func airborne_knockdown_reaction(attacker: Fighter) -> void:
	cancel_current_action()
	var knockdown_generation := action_generation
	fighter.start_airborne_hit_knockdown(attacker)
	while not fighter.is_on_floor():
		await get_tree().physics_frame
		if knockdown_generation != action_generation or current_health <= 0:
			return
	fighter.hold_airborne_hit_landing_pose()
	await get_tree().create_timer(1.0).timeout
	if knockdown_generation != action_generation or current_health <= 0:
		return
	var recovery_duration := fighter.start_knockdown_recovery()
	await get_tree().create_timer(recovery_duration).timeout
	if knockdown_generation != action_generation or current_health <= 0:
		return
	fighter.change_state(Fighter.State.IDLE)


func sweep_knockdown_reaction(attacker: Fighter) -> void:
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
	fighter.change_state(Fighter.State.IDLE)


func die(start_frame: int = 0) -> void:
	cancel_current_action()
	fighter.change_state(Fighter.State.KNOCKED_DOWN)
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
	current_variant = null
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
	is_airborne_heavy_kick = false
	is_airborne_medium_kick = false
	is_airborne_medium_punch = false
	is_airborne_heavy_punch = false
	is_airborne_light_punch = false
	is_special_720_punch = false
	is_special_sonic_boom = false
	hit_targets.clear()
	disable_hitbox(true)


func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)


func enable_hitbox() -> void:
	if hitbox_shape:
		hitbox_shape.disabled = false


func perform_special_720_multi_hit(active_duration: float, attack_generation: int) -> void:
	"""Genera tre impatti separati se l'avversario resta nella zona delle braccia."""
	var pulse_interval := active_duration / 3.0
	for pulse_index in range(3):
		if attack_generation != action_generation:
			return
		hit_targets.clear()
		await get_tree().physics_frame
		for area in hitbox.get_overlapping_areas():
			_apply_hit_to_area(area)
		await get_tree().create_timer(pulse_interval).timeout


func wait_for_standing_medium_punch_active_frame(attack_generation: int) -> void:
	var active_frame: int = (
		current_variant.active_animation_frame
		if current_variant != null
		else 0
	)
	while (
		attack_generation == action_generation
		and fighter.animated_sprite.animation == &"medium_open_hand_slap"
		and fighter.animated_sprite.frame < active_frame
	):
		await get_tree().process_frame


func disable_hitbox(deferred: bool = false) -> void:
	if hitbox_shape:
		if deferred:
			hitbox_shape.set_deferred("disabled", true)
		else:
			hitbox_shape.disabled = true


func is_attack_button_held(attack_name: StringName) -> bool:
	if not fighter.is_player_controlled:
		return false
	return Input.is_action_pressed(fighter.get_input_action(String(attack_name)))


func hold_airborne_attack_until_release(
	attack_name: StringName,
	attack_generation: int
) -> bool:
	"""Mantiene posa finale e hitbox dell'attacco aereo finché il tasto resta premuto."""
	while (
		attack_generation == action_generation
		and fighter.animated_sprite.is_playing()
		and is_attack_button_held(attack_name)
		and not should_cancel_airborne_attack_for_landing()
	):
		await get_tree().process_frame
	if attack_generation != action_generation:
		return false
	if should_cancel_airborne_attack_for_landing():
		return true
	if not is_attack_button_held(attack_name):
		return false

	var animation_name := fighter.animated_sprite.animation
	var frame_count := fighter.animated_sprite.sprite_frames.get_frame_count(animation_name)
	if frame_count > 0:
		fighter.animated_sprite.frame = frame_count - 1
		fighter.animated_sprite.pause()
	while (
		attack_generation == action_generation
		and is_attack_button_held(attack_name)
		and not should_cancel_airborne_attack_for_landing()
	):
		await get_tree().process_frame
	return should_cancel_airborne_attack_for_landing()


func hold_jump_attack_until_release(
	attack_name: StringName,
	attack_generation: int,
	hold_animation_frame: int,
	release_animation_frame: int
) -> bool:
	## Mantiene la posa d'impatto e riparte dal primo frame della recovery inversa.
	var sprite := fighter.animated_sprite
	while (
		attack_generation == action_generation
		and sprite.frame < hold_animation_frame
		and not fighter.is_on_floor()
	):
		await get_tree().process_frame
	if attack_generation != action_generation:
		return false
	if fighter.is_on_floor():
		return true
	sprite.frame = hold_animation_frame
	sprite.pause()
	# Il colpo resta attivo almeno per un frame anche se il tasto era già stato rilasciato.
	await get_tree().process_frame
	while (
		attack_generation == action_generation
		and is_attack_button_held(attack_name)
		and not fighter.is_on_floor()
	):
		await get_tree().process_frame
	if attack_generation != action_generation:
		return false
	if fighter.is_on_floor():
		return true
	disable_hitbox()
	sprite.frame = release_animation_frame
	sprite.play(current_variant.animation_name)
	return false


func should_cancel_airborne_attack_for_landing() -> bool:
	if fighter.is_on_floor():
		return true
	var height_above_ground := maxf(
		fighter.shadow_ground_y - fighter.global_position.y,
		0.0
	)
	return fighter.velocity.y >= 0.0 and height_above_ground <= AIRBORNE_ATTACK_GROUND_CANCEL_HEIGHT


func configure_hitbox(attack: AttackData) -> void:
	var attack_shape := hitbox_shape.shape as RectangleShape2D
	if attack_shape:
		if current_variant != null:
			attack_shape.size = current_variant.hitbox_size
			hitbox_shape.position = current_variant.hitbox_position
			hitbox_shape.rotation_degrees = current_variant.hitbox_rotation_degrees
			return
		attack_shape.size = attack.hitbox_size
		hitbox_shape.position = attack.hitbox_position
		hitbox_shape.rotation = 0.0


func get_attack_phase_durations(attack: AttackData) -> Vector3:
	if current_variant != null:
		return current_variant.get_phase_durations()
	return Vector3(attack.startup, attack.active, attack.recovery)


func get_hit_reaction_start_frame(attack: AttackData) -> int:
	if current_variant != null and current_variant.hit_reaction_start_frame > 0:
		return current_variant.hit_reaction_start_frame
	if get_effective_hit_height(attack) == AttackData.HitHeight.MID:
		return 4
	return attack.hit_reaction_start_frame


func get_effective_hit_height(attack: AttackData) -> AttackData.HitHeight:
	if current_variant != null:
		return current_variant.hit_height
	return attack.hit_height


func get_current_variant_id() -> StringName:
	if (
		is_airborne_light_punch or is_airborne_light_kick
		or is_airborne_medium_kick or is_airborne_heavy_kick
		or is_airborne_medium_punch or is_airborne_heavy_punch
	):
		return &"airborne"
	if crouched_punch_started_crouched or crouched_medium_punch_started_crouched:
		return &"crouched_held"
	if (
		is_crouched_light_punch or is_crouched_medium_punch or is_crouched_heavy_punch
		or is_crouched_light_kick or is_crouched_medium_kick or is_crouched_heavy_kick
	):
		return &"crouched"
	return &"standing"


func _target_will_block(target: Fighter) -> bool:
	return (
		(target.combat.is_blocking or target.current_state == Fighter.State.BLOCKING)
		and target.is_holding_back()
		and target.is_attack_in_front(fighter)
		and target.is_on_floor()
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
	# La speciale usa tre impulsi temporizzati, evitando un quarto colpo dal segnale enter.
	if is_special_720_punch:
		return
	_apply_hit_to_area(area)


func _apply_hit_to_area(area: Area2D) -> void:
	if not area.is_in_group("hurtbox") or not is_attacking:
		return

	var target := area.get_parent() as Fighter
	if target == null or target == fighter or hit_targets.has(target) or current_attack == null:
		return
	hit_targets.append(target)
	if (
		current_attack.attack_id == &"light_punch"
		and not is_crouched_light_punch
		and not _target_will_block(target)
	):
		fighter.spawn_hit_effect(target.global_position + Vector2(0.0, -220.0), fighter.is_facing_right)
	var effective_hit_height := get_effective_hit_height(current_attack)
	var effective_reaction_frame := get_hit_reaction_start_frame(current_attack)
	var effective_damage := current_attack.damage
	var effective_knockdown: bool = (
		current_variant.causes_knockdown
		if current_variant != null
		else current_attack.causes_knockdown
	)
	if (
		current_attack.attack_id == &"medium_kick"
		and not is_crouched_medium_kick
		and not is_airborne_medium_kick
		and not (
			current_variant != null
			and current_variant.variant_id in [&"arianna_standing", &"arianna_low"]
		)
	):
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
		not is_special_720_punch
	)
	if current_attack.attack_id == &"heavy_punch" and is_crouched_heavy_punch:
		# Launch: l'avversario vola in alto 100px e indietro 50px.
		var launch_dir := 1.0 if fighter.is_facing_right else -1.0
		target.velocity.y = -CROUCHED_HEAVY_LAUNCH_VERTICAL
		target.velocity.x = launch_dir * CROUCHED_HEAVY_LAUNCH_HORIZONTAL
