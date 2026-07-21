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
	if fighter.current_state not in [Mangler.State.IDLE, Mangler.State.WALKING]:
		return
	if is_attacking or not fighter.is_on_floor():
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
	hit_targets.clear()
	configure_hitbox(attack)
	fighter.change_state(Mangler.State.ATTACKING)
	attack_started.emit(attack_name)

	# Startup.
	await get_tree().create_timer(attack.startup).timeout
	if attack_generation != action_generation:
		return
	enable_hitbox()
	print("Eseguendo attacco: %s (danno: %d)" % [attack_name, attack.damage])

	# Frame attivi.
	await get_tree().create_timer(attack.active).timeout
	if attack_generation != action_generation:
		return
	disable_hitbox()

	# Recovery.
	await get_tree().create_timer(attack.recovery).timeout
	if attack_generation != action_generation:
		return
	is_attacking = false
	current_attack = null
	hit_targets.clear()
	fighter.change_state(Mangler.State.IDLE)
	attack_finished.emit()


func take_damage(
	damage: int,
	attacker: Mangler,
	hitstun: float = DEFAULT_HITSTUN,
	blockstun: float = DEFAULT_BLOCKSTUN,
	hit_height: AttackData.HitHeight = AttackData.HitHeight.MID,
	causes_knockdown: bool = false
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
		die()
	elif attack_was_blocked:
		block_reaction(blockstun)
	elif causes_knockdown:
		sweep_knockdown_reaction(attacker)
	else:
		hit_reaction(hitstun, hit_height, attacker)


func block_reaction(duration: float) -> void:
	cancel_current_action()
	var block_generation := action_generation
	fighter.change_state(Mangler.State.BLOCKING)

	await get_tree().create_timer(duration).timeout
	if block_generation != action_generation or current_health <= 0:
		return
	fighter.change_state(Mangler.State.IDLE)


func hit_reaction(
	duration: float,
	hit_height: AttackData.HitHeight,
	attacker: Mangler
) -> void:
	cancel_current_action()
	var hit_generation := action_generation
	var animation_duration := fighter.start_hit_reaction(hit_height, attacker)
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


func die() -> void:
	cancel_current_action()
	fighter.change_state(Mangler.State.KNOCKED_DOWN)
	knocked_out.emit()
	print("KO!")


func reset() -> void:
	cancel_current_action()
	current_health = max_health
	health_changed.emit(current_health, max_health)


func cancel_current_action() -> void:
	action_generation += 1
	is_attacking = false
	is_blocking = false
	current_attack = null
	current_attack_direction = FighterInputBuffer.Direction.NEUTRAL
	hit_targets.clear()
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


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hurtbox") or not is_attacking:
		return

	var target := area.get_parent() as Mangler
	if target == null or target == fighter or hit_targets.has(target) or current_attack == null:
		return
	hit_targets.append(target)
	target.combat.take_damage(
		current_attack.damage,
		fighter,
		current_attack.hitstun,
		current_attack.blockstun,
		current_attack.hit_height,
		current_attack.causes_knockdown
	)
