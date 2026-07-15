extends Node
class_name FighterCombat

## Gestisce il ciclo degli attacchi, le hitbox, i danni e le reazioni ai colpi.

signal health_changed(current_health: int, max_health: int)
signal knocked_out
signal attack_started(attack_name: StringName)
signal attack_finished

const ATTACK_HITBOXES := {
	&"light_punch": {
		"size": Vector2(70.0, 35.0),
		"position": Vector2(35.0, -110.0),
	},
	&"medium_punch": {
		"size": Vector2(85.0, 40.0),
		"position": Vector2(45.0, -108.0),
	},
	&"heavy_punch": {
		"size": Vector2(100.0, 45.0),
		"position": Vector2(55.0, -105.0),
	},
	&"light_kick": {
		"size": Vector2(85.0, 35.0),
		"position": Vector2(47.5, -55.0),
	},
	&"medium_kick": {
		"size": Vector2(100.0, 40.0),
		"position": Vector2(60.0, -60.0),
	},
	&"heavy_kick": {
		"size": Vector2(115.0, 45.0),
		"position": Vector2(72.5, -65.0),
	},
}

var fighter: Mangler
var character_data: CharacterData
var max_health := 100
var current_health := 100
var is_blocking := false
var is_attacking := false
var current_attack_damage := 0
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

	action_generation += 1
	var attack_generation := action_generation
	var damage := get_attack_damage(attack_name)
	var duration := get_attack_duration(attack_name)
	is_attacking = true
	is_blocking = false
	current_attack_damage = damage
	current_attack_direction = input_direction
	hit_targets.clear()
	configure_hitbox(attack_name)
	fighter.change_state(Mangler.State.ATTACKING)
	attack_started.emit(attack_name)

	# Startup.
	await get_tree().create_timer(duration * 0.3).timeout
	if attack_generation != action_generation:
		return
	enable_hitbox()
	print("Eseguendo attacco: %s (danno: %d)" % [attack_name, damage])

	# Frame attivi.
	await get_tree().create_timer(duration * 0.4).timeout
	if attack_generation != action_generation:
		return
	disable_hitbox()

	# Recovery.
	await get_tree().create_timer(duration * 0.3).timeout
	if attack_generation != action_generation:
		return
	is_attacking = false
	current_attack_damage = 0
	hit_targets.clear()
	fighter.change_state(Mangler.State.IDLE)
	attack_finished.emit()


func take_damage(damage: int, attacker: Mangler) -> void:
	if fighter.current_state == Mangler.State.KNOCKED_DOWN:
		return

	var attack_was_blocked := (
		(is_blocking or fighter.current_state == Mangler.State.BLOCKING)
		and fighter.is_holding_back()
		and fighter.is_attack_in_front(attacker)
		and fighter.is_on_floor()
	)
	if attack_was_blocked:
		damage = int(damage * 0.2)
		print("Attacco bloccato! Danno ridotto a: " + str(damage))

	current_health = clampi(current_health - damage, 0, max_health)
	health_changed.emit(current_health, max_health)
	print("Vita rimanente: %d/%d" % [current_health, max_health])

	if current_health <= 0:
		die()
	elif attack_was_blocked:
		block_reaction()
	else:
		hit_reaction()


func block_reaction() -> void:
	cancel_current_action()
	var block_generation := action_generation
	fighter.change_state(Mangler.State.BLOCKING)

	await get_tree().create_timer(0.15).timeout
	if block_generation != action_generation or current_health <= 0:
		return
	fighter.change_state(Mangler.State.IDLE)


func hit_reaction() -> void:
	cancel_current_action()
	var hit_generation := action_generation
	fighter.change_state(Mangler.State.HIT)

	await get_tree().create_timer(0.3).timeout
	if hit_generation != action_generation or current_health <= 0:
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
	current_attack_damage = 0
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


func configure_hitbox(attack_name: StringName) -> void:
	if not ATTACK_HITBOXES.has(attack_name):
		return

	var hitbox_data: Dictionary = ATTACK_HITBOXES[attack_name]
	var attack_shape := hitbox_shape.shape as RectangleShape2D
	if attack_shape:
		attack_shape.size = hitbox_data["size"]
		hitbox_shape.position = hitbox_data["position"]


func get_attack_damage(attack_name: StringName) -> int:
	match attack_name:
		&"light_punch": return character_data.light_punch_damage
		&"medium_punch": return character_data.medium_punch_damage
		&"heavy_punch": return character_data.heavy_punch_damage
		&"light_kick": return character_data.light_kick_damage
		&"medium_kick": return character_data.medium_kick_damage
		&"heavy_kick": return character_data.heavy_kick_damage
	return 0


func get_attack_duration(attack_name: StringName) -> float:
	match attack_name:
		&"light_punch": return character_data.light_punch_duration
		&"medium_punch": return character_data.medium_punch_duration
		&"heavy_punch": return character_data.heavy_punch_duration
		&"light_kick": return character_data.light_kick_duration
		&"medium_kick": return character_data.medium_kick_duration
		&"heavy_kick": return character_data.heavy_kick_duration
	return 0.0


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hurtbox") or not is_attacking:
		return

	var target := area.get_parent() as Mangler
	if target == null or target == fighter or hit_targets.has(target):
		return
	hit_targets.append(target)
	target.combat.take_damage(current_attack_damage, fighter)
