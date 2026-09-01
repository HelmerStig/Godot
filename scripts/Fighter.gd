extends CharacterBody2D
class_name Fighter

## Contratto runtime comune a tutti i combattenti.
##
## Mantiene identità, stato e riferimenti condivisi senza conoscere personaggi,
## mosse, atlas o proiettili specifici.

signal health_changed(current_health: int, max_health: int)
signal knocked_out
signal state_changed(previous_state: int, current_state: int)
signal attack_started(attack_name: StringName)
signal attack_finished

enum State {
	IDLE,
	WALKING,
	RUNNING,
	BACK_HOP_STARTUP,
	BACK_HOP,
	JUMP_STARTUP,
	JUMPING,
	CROUCHING,
	STANDING_UP,
	ATTACKING,
	BLOCKING,
	BLOCK_RECOVERY,
	HIT,
	SWEEP_KNOCKDOWN,
	KNOCKDOWN_RECOVERY,
	KNOCKED_DOWN
}

@export var character_data: CharacterData
@export var show_debug_boxes := true
@export_range(1, 2, 1) var player_number := 1

var current_state := State.IDLE
var is_facing_right := true
var is_player_controlled := true
var opponent: Fighter
var controls_enabled := true
var can_move := true
var input_buffer: FighterInputBuffer
var stage_left_limit := 0.0
var stage_right_limit := 1152.0
var shadow_ground_y := 0.0
var received_hit_height := AttackData.HitHeight.MID
var received_block_height := AttackData.HitHeight.MID
var block_started_crouched := false
var default_z_index := 0
var aerial_attack_used := false
var force_idle_until_landing := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var head_hurtbox: CollisionShape2D = $Hurtbox/HeadHurtbox
@onready var torso_hurtbox: CollisionShape2D = $Hurtbox/TorsoHurtbox
@onready var legs_hurtbox: CollisionShape2D = $Hurtbox/LegsHurtbox
@onready var combat: FighterCombat = $Combat
@onready var ground_shadow: Polygon2D = $GroundShadow


## API usata dai componenti condivisi. Le specializzazioni implementano animazioni
## e reazioni concrete senza costringere Fighter a conoscere un personaggio.
func change_state(_next_state: int) -> void:
	push_error("Fighter.change_state() deve essere implementato dalla specializzazione")


func get_input_action(_action_name: String) -> StringName:
	return StringName()


func is_holding_back() -> bool:
	return false


func is_holding_low_guard() -> bool:
	return false


func is_attack_in_front(_attacker: Fighter) -> bool:
	return false


func start_block_reaction(
	_hit_height: AttackData.HitHeight,
	_started_crouched: bool = false
) -> float:
	return 0.0


func start_block_recovery() -> float:
	return 0.0


func return_to_crouch_after_low_block() -> void:
	pass


func return_to_crouch_pose() -> void:
	pass


func start_hit_reaction(
	_hit_height: AttackData.HitHeight,
	_attacker: Fighter,
	_start_frame: int = 0,
	_apply_pushback: bool = true
) -> float:
	return 0.0


func start_airborne_hit_knockdown(_attacker: Fighter) -> void:
	pass


func hold_airborne_hit_landing_pose() -> void:
	pass


func start_sweep_knockdown(_attacker: Fighter) -> float:
	return 0.0


func get_sweep_grounded_hold_duration() -> float:
	return FighterCombat.SWEEP_GROUNDED_HOLD


func start_knockdown_recovery() -> float:
	return 0.0


func spawn_hit_effect(_world_position: Vector2, _facing_right: bool = true) -> void:
	pass


func restore_default_render_order() -> void:
	pass
