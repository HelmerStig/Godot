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

const BASE_GRAVITY := 1400.0
const JUMP_SPEED_MULTIPLIER := 1.2
const LEGACY_SPRITE_SCALE := Vector2(0.7, 0.7)
const LEGACY_SPRITE_POSITION := Vector2(0.0, -120.0)
const REWORK_SPRITE_SCALE := Vector2(0.85, 0.85)
const REWORK_SPRITE_POSITION := Vector2(0.0, -115.0)
const GRAVITY := BASE_GRAVITY * JUMP_SPEED_MULTIPLIER * JUMP_SPEED_MULTIPLIER
const GROUND_COLLISION_LAYER := 1
const FIGHTER_COLLISION_LAYER := 8
const SHADOW_MAX_HEIGHT := 800.0
const SHADOW_GROUND_ALPHA := 0.3
const SHADOW_AIR_ALPHA := 0.12
const SHADOW_AIR_SCALE := 0.58
const SHADOW_FLOOR_OFFSET_Y := 20.0
const RUN_DOUBLE_TAP_WINDOW_FRAMES := 15
const RUN_JUMP_HORIZONTAL_MULTIPLIER := 1.35
const BACK_HOP_DOUBLE_TAP_WINDOW_FRAMES := 15
const BACK_HOP_HORIZONTAL_SPEED := 360.0
const BACK_HOP_VERTICAL_SPEED := -260.0
const BACK_HOP_TAKEOFF_FRAME := 12
const JUMP_TAKEOFF_FRAME := 5 # Indice zero-based: sesto frame visibile.
const HIT_PUSHBACK_SPEED := 180.0
const HIT_PUSHBACK_DECELERATION := 720.0
const ATTACK_FOREGROUND_Z_OFFSET := 1
const IDLE_SHEET := preload("res://assets/sprites/characters/mangler/01-mangler-idle.png")
const IDLE_FRAME_COUNT := 49
const IDLE_COLUMNS := 7
const IDLE_CELL_SIZE := Vector2(512.0, 512.0)
const WALK_SHEET := preload("res://assets/sprites/characters/mangler/02-walk.png")
const WALK_FRAME_COUNT := 48
const WALK_COLUMNS := 7
const WALK_CELL_SIZE := Vector2(512.0, 512.0)
const BACKWALK_SHEET := preload("res://assets/sprites/characters/mangler/03-back-walk.png")
const BACKWALK_FRAME_COUNT := 26
const BACKWALK_COLUMNS := 7
const BACKWALK_CELL_SIZE := Vector2(512.0, 512.0)
const RUN_SHEET := preload("res://assets/sprites/characters/mangler/05-run.png")
const RUN_FRAME_COUNT := 46
const RUN_COLUMNS := 7
const RUN_CELL_SIZE := Vector2(512.0, 512.0)
const HEAVY_PUNCH_HIGH_SHEET := preload(
	"res://assets/sprites/characters/mangler/moves/00-heavy_punch_high.png"
)
const HEAVY_PUNCH_HIGH_FRAME_COUNT := 49
const HEAVY_PUNCH_HIGH_COLUMNS := 7
const HEAVY_PUNCH_HIGH_CELL_SIZE := Vector2(512.0, 512.0)
const CROUCH_SHEET := preload("res://assets/sprites/characters/mangler/04-crouching.png")
const CROUCH_FRAME_COUNT := 25
const CROUCH_COLUMNS := 5
const CROUCH_CELL_SIZE := Vector2(512.0, 512.0)
const BLOCK_HIGH_SHEET := preload("res://assets/sprites/characters/mangler/06-block-high.png")
const BLOCK_HIGH_FRAME_COUNT := 22
const BLOCK_HIGH_COLUMNS := 5
const BLOCK_HIGH_CELL_SIZE := Vector2(512.0, 512.0)
const BLOCK_MID_SHEET := preload("res://assets/sprites/characters/mangler/07-block-middle.png")
const BLOCK_MID_FRAME_COUNT := 8
const BLOCK_MID_COLUMNS := 5
const BLOCK_MID_CELL_SIZE := Vector2(512.0, 512.0)
const BLOCK_LOW_SHEET := preload("res://assets/sprites/characters/mangler/08-block-low.png")
const BLOCK_LOW_FRAME_COUNT := 11
const BLOCK_LOW_COLUMNS := 5
const BLOCK_LOW_CELL_SIZE := Vector2(512.0, 512.0)
const CROUCHED_HEAVY_KICK_SHEET := preload(
	"res://assets/sprites/characters/mangler/test-spazzata.png"
)
const CROUCHED_HEAVY_KICK_SOURCE_START := 31 # Indice zero-based: fotogramma 32.
const CROUCHED_HEAVY_KICK_SOURCE_END := 47 # Indice zero-based: fotogramma 48.
const CROUCHED_HEAVY_KICK_COLUMNS := 8
const CROUCHED_HEAVY_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const SWEEP_AFTERIMAGE_START_FRAME := 2
const SWEEP_AFTERIMAGE_END_FRAME := 10
const SWEEP_AFTERIMAGE_LIFETIME := 0.14
const SWEEP_AFTERIMAGE_ALPHA := 0.28
const SWEEP_AFTERIMAGE_OFFSET := 8.0
const ATTACK_EFFECT_ANIMATIONS := [
	&"light_punch_single",
	&"crouched_punch",
	&"crouched_punch_crouched",
	&"medium_open_hand_slap",
	&"crouched_medium_punch",
	&"crouched_medium_punch_crouched",
	&"jump_medium_punch",
	&"jump_heavy_punch",
	&"heavy_punch",
	&"crouched_power_punch",
	&"light_kick",
	&"crouched_light_kick",
	&"jump_light_kick",
	&"medium_kick",
	&"crouched_medium_kick",
	&"jump_medium_kick",
	&"heavy_kick",
	&"crouched_heavy_kick",
	&"jump_heavy_kick",
]
const CROUCHED_MEDIUM_KICK_SHEET := preload(
	"res://assets/sprites/characters/mangler/medium-kick-low.png"
)
const CROUCHED_MEDIUM_KICK_FRAME_COUNT := 16
const CROUCHED_MEDIUM_KICK_COLUMNS := 4
const CROUCHED_MEDIUM_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const CROUCHED_LIGHT_KICK_SHEET := preload(
	"res://assets/sprites/characters/mangler/light_kick_low.png"
)
const CROUCHED_LIGHT_KICK_FRAME_COUNT := 16
const CROUCHED_LIGHT_KICK_COLUMNS := 4
const CROUCHED_LIGHT_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const JUMP_LIGHT_KICK_SHEET := preload(
	"res://assets/sprites/characters/mangler/jump-kick-light.png"
)
const JUMP_LIGHT_KICK_COLUMNS := 4
const JUMP_LIGHT_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const JUMP_LIGHT_KICK_SOURCE_SEQUENCE := [11, 12, 13, 14, 15, 14, 13, 12, 11]
const JUMP_HEAVY_KICK_SHEET := preload(
	"res://assets/sprites/characters/mangler/medium_jump_kick.png"
)
const JUMP_HEAVY_KICK_FRAME_COUNT := 16
const JUMP_HEAVY_KICK_COLUMNS := 4
const JUMP_HEAVY_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const JUMP_MEDIUM_KICK_SHEET := preload(
	"res://assets/sprites/characters/mangler/custom_jump_kick_2.png"
)
const JUMP_MEDIUM_KICK_FRAME_COUNT := 16
const JUMP_MEDIUM_KICK_COLUMNS := 4
const JUMP_MEDIUM_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const JUMP_MEDIUM_PUNCH_SHEET := preload(
	"res://assets/sprites/characters/mangler/medium-punch-jump.png"
)
const JUMP_MEDIUM_PUNCH_FRAME_COUNT := 16
const JUMP_MEDIUM_PUNCH_COLUMNS := 4
const JUMP_MEDIUM_PUNCH_CELL_SIZE := Vector2(512.0, 512.0)
const JUMP_HEAVY_PUNCH_SHEET := preload(
	"res://assets/sprites/characters/mangler/heavy_punch_jump.png"
)
const JUMP_HEAVY_PUNCH_FRAME_COUNT := 16
const JUMP_HEAVY_PUNCH_COLUMNS := 4
const JUMP_HEAVY_PUNCH_CELL_SIZE := Vector2(512.0, 512.0)
const MEDIUM_PUNCH_PREPARATION_SHEET := preload(
	"res://assets/sprites/characters/mangler/basic-moves/medium-punch/medium-punch-preparation.png"
)
const MEDIUM_PUNCH_PREPARATION_FRAME_COUNT := 10
const MEDIUM_PUNCH_HIT_SHEET := preload(
	"res://assets/sprites/characters/mangler/basic-moves/medium-punch/medium-punch-hit.png"
)
const MEDIUM_PUNCH_HIT_FRAME_COUNT := 16
const MEDIUM_PUNCH_TO_IDLE_SHEET := preload(
	"res://assets/sprites/characters/mangler/basic-moves/medium-punch/medium-punch-to-idle.png"
)
const MEDIUM_PUNCH_TO_IDLE_FRAME_COUNT := 16
const MEDIUM_PUNCH_COLUMNS := 4
const MEDIUM_PUNCH_CELL_SIZE := Vector2(512.0, 512.0)
const LIGHT_PUNCH_SHEET := preload(
	"res://assets/sprites/characters/mangler/basic-moves/light-punch/light-punch.png"
)
const LIGHT_PUNCH_FRAME_COUNT := 18
const LIGHT_PUNCH_COLUMNS := 5
const LIGHT_PUNCH_CELL_SIZE := Vector2(512.0, 512.0)
const LIGHT_KICK_SHEET := preload(
	"res://assets/sprites/characters/mangler/basic-moves/light-kick/light_kick.png"
)
const LIGHT_KICK_FRAME_COUNT := 25
const LIGHT_KICK_COLUMNS := 5
const LIGHT_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const STRONG_KICK_SHEET := preload(
	"res://assets/sprites/characters/mangler/basic-moves/strong-kick/strong-kick.png"
)
const STRONG_KICK_FRAME_COUNT := 49
const STRONG_KICK_COLUMNS := 7
const STRONG_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const MEDIUM_KICK_STANDING_SHEET := preload(
	"res://assets/sprites/characters/mangler/basic-moves/medium-kick/medium_kick.png"
)
const MEDIUM_KICK_STANDING_FRAME_COUNT := 42
const MEDIUM_KICK_STANDING_COLUMNS := 6
const MEDIUM_KICK_STANDING_CELL_SIZE := Vector2(512.0, 512.0)
const SWEEP_PUSHBACK_SPEED := 240.0
const STANDING_COLLISION_SIZE := Vector2(120.0, 240.0)
const STANDING_COLLISION_POSITION := Vector2(0.0, -120.0)
const CROUCH_COLLISION_SIZE := Vector2(130.0, 175.0)
const CROUCH_COLLISION_POSITION := Vector2(0.0, -87.5)
const STANDING_HEAD_SIZE := Vector2(55.0, 55.0)
const STANDING_HEAD_POSITION := Vector2(0.0, -252.5)
const CROUCH_HEAD_SIZE := Vector2(55.0, 50.0)
const CROUCH_HEAD_POSITION := Vector2(0.0, -190.0)
const STANDING_TORSO_SIZE := Vector2(115.0, 155.0)
const STANDING_TORSO_POSITION := Vector2(0.0, -166.0)
const CROUCH_TORSO_SIZE := Vector2(115.0, 105.0)
const CROUCH_TORSO_POSITION := Vector2(0.0, -126.0)
const STANDING_LEGS_SIZE := Vector2(100.0, 135.0)
const STANDING_LEGS_POSITION := Vector2(0.0, -67.5)
const CROUCH_LEGS_SIZE := Vector2(100.0, 100.0)
const CROUCH_LEGS_POSITION := Vector2(0.0, -50.0)
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
var shadow_ground_y := 0.0
var last_forward_tap_frame := -RUN_DOUBLE_TAP_WINDOW_FRAMES - 1
var last_back_tap_frame := -BACK_HOP_DOUBLE_TAP_WINDOW_FRAMES - 1
var pending_jump_direction := 0.0
var pending_jump_horizontal_multiplier := 1.0
var received_hit_height := AttackData.HitHeight.MID
var received_block_height := AttackData.HitHeight.MID
var block_started_crouched := false
var default_z_index := 0
var sweep_afterimage_spawn_count := 0
var attack_afterimage_spawn_count := 0
var aerial_attack_used := false
var force_idle_until_landing := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var head_hurtbox: CollisionShape2D = $Hurtbox/HeadHurtbox
@onready var torso_hurtbox: CollisionShape2D = $Hurtbox/TorsoHurtbox
@onready var legs_hurtbox: CollisionShape2D = $Hurtbox/LegsHurtbox
@onready var combat: FighterCombat = $Combat
@onready var ground_shadow: Polygon2D = $GroundShadow


func _ready() -> void:
	default_z_index = z_index
	configure_idle_frames()
	configure_walk_frames()
	configure_backwalk_frames()
	configure_run_frames()
	configure_heavy_punch_high_frames()
	configure_light_punch_frames()
	configure_crouch_frames()
	configure_block_high_frames()
	configure_block_mid_frames()
	configure_block_low_frames()
	configure_crouched_heavy_kick_frames()
	configure_standing_heavy_kick_frames()
	configure_crouched_medium_kick_frames()
	configure_standing_medium_kick_frames()
	configure_crouched_light_kick_frames()
	configure_standing_light_kick_frames()
	configure_jump_light_kick_frames()
	configure_jump_medium_kick_frames()
	configure_jump_heavy_kick_frames()
	configure_medium_punch_frames()
	configure_jump_medium_punch_frames()
	configure_jump_heavy_punch_frames()
	input_buffer = FighterInputBuffer.new(player_number)
	shadow_ground_y = global_position.y
	duplicate_collision_shapes()
	apply_character_data()
	combat.health_changed.connect(_on_combat_health_changed)
	combat.knocked_out.connect(_on_combat_knocked_out)
	combat.attack_started.connect(_on_combat_attack_started)
	combat.attack_finished.connect(_on_combat_attack_finished)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_animation_frame_changed)
	animated_sprite.animation_changed.connect(update_sprite_scale)
	combat.configure(character_data)
	add_to_group("fighters")
	update_animation()
	update_collision_profile()
	update_ground_shadow()


func configure_idle_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"idle"):
		frames.remove_animation(&"idle")
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 24.0)
	frames.set_animation_loop(&"idle", true)
	for source_index in range(IDLE_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = IDLE_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				(source_index % IDLE_COLUMNS) * IDLE_CELL_SIZE.x,
				(source_index / IDLE_COLUMNS) * IDLE_CELL_SIZE.y
			),
			IDLE_CELL_SIZE
		)
		frames.add_frame(&"idle", atlas_frame)


func configure_walk_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"walk"):
		frames.remove_animation(&"walk")
	frames.add_animation(&"walk")
	frames.set_animation_speed(&"walk", 24.0)
	frames.set_animation_loop(&"walk", true)
	for source_index in range(WALK_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = WALK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				(source_index % WALK_COLUMNS) * WALK_CELL_SIZE.x,
				(source_index / WALK_COLUMNS) * WALK_CELL_SIZE.y
			),
			WALK_CELL_SIZE
		)
		frames.add_frame(&"walk", atlas_frame)


func configure_backwalk_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"backwalk"):
		frames.remove_animation(&"backwalk")
	frames.add_animation(&"backwalk")
	frames.set_animation_speed(&"backwalk", 24.0)
	frames.set_animation_loop(&"backwalk", true)
	for source_index in range(BACKWALK_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = BACKWALK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				(source_index % BACKWALK_COLUMNS) * BACKWALK_CELL_SIZE.x,
				(source_index / BACKWALK_COLUMNS) * BACKWALK_CELL_SIZE.y
			),
			BACKWALK_CELL_SIZE
		)
		frames.add_frame(&"backwalk", atlas_frame)


func configure_run_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"run"):
		frames.remove_animation(&"run")
	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 24.0)
	frames.set_animation_loop(&"run", true)
	for source_index in range(RUN_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = RUN_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				(source_index % RUN_COLUMNS) * RUN_CELL_SIZE.x,
				(source_index / RUN_COLUMNS) * RUN_CELL_SIZE.y
			),
			RUN_CELL_SIZE
		)
		frames.add_frame(&"run", atlas_frame)


func configure_heavy_punch_high_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"heavy_punch"):
		frames.remove_animation(&"heavy_punch")
	frames.add_animation(&"heavy_punch")
	frames.set_animation_speed(&"heavy_punch", 48.0)
	frames.set_animation_loop(&"heavy_punch", false)
	for source_index in range(HEAVY_PUNCH_HIGH_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = HEAVY_PUNCH_HIGH_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				(source_index % HEAVY_PUNCH_HIGH_COLUMNS) * HEAVY_PUNCH_HIGH_CELL_SIZE.x,
				(source_index / HEAVY_PUNCH_HIGH_COLUMNS) * HEAVY_PUNCH_HIGH_CELL_SIZE.y
			),
			HEAVY_PUNCH_HIGH_CELL_SIZE
		)
		frames.add_frame(&"heavy_punch", atlas_frame)
	for source_index in range(40, 19, -1):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = HEAVY_PUNCH_HIGH_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				(source_index % HEAVY_PUNCH_HIGH_COLUMNS) * HEAVY_PUNCH_HIGH_CELL_SIZE.x,
				(source_index / HEAVY_PUNCH_HIGH_COLUMNS) * HEAVY_PUNCH_HIGH_CELL_SIZE.y
			),
			HEAVY_PUNCH_HIGH_CELL_SIZE
		)
		frames.add_frame(&"heavy_punch", atlas_frame)


func configure_crouch_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"crouch"):
		frames.remove_animation(&"crouch")
	frames.add_animation(&"crouch")
	frames.set_animation_speed(&"crouch", 48.0)
	frames.set_animation_loop(&"crouch", false)
	for source_index in range(CROUCH_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = CROUCH_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				(source_index % CROUCH_COLUMNS) * CROUCH_CELL_SIZE.x,
				(source_index / CROUCH_COLUMNS) * CROUCH_CELL_SIZE.y
			),
			CROUCH_CELL_SIZE
		)
		frames.add_frame(&"crouch", atlas_frame)


func configure_block_high_frames() -> void:
	var frames := animated_sprite.sprite_frames
	for animation_name in [&"block_high", &"block_high_recovery"]:
		if frames.has_animation(animation_name):
			frames.remove_animation(animation_name)
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 48.0)
		frames.set_animation_loop(animation_name, false)

	for source_index in range(8, BLOCK_HIGH_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = BLOCK_HIGH_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				(source_index % BLOCK_HIGH_COLUMNS) * BLOCK_HIGH_CELL_SIZE.x,
				(source_index / BLOCK_HIGH_COLUMNS) * BLOCK_HIGH_CELL_SIZE.y
			),
			BLOCK_HIGH_CELL_SIZE
		)
		frames.add_frame(&"block_high", atlas_frame)

	for source_index in range(BLOCK_HIGH_FRAME_COUNT - 2, -1, -1):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = BLOCK_HIGH_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				(source_index % BLOCK_HIGH_COLUMNS) * BLOCK_HIGH_CELL_SIZE.x,
				(source_index / BLOCK_HIGH_COLUMNS) * BLOCK_HIGH_CELL_SIZE.y
			),
			BLOCK_HIGH_CELL_SIZE
		)
		frames.add_frame(&"block_high_recovery", atlas_frame)


func configure_block_mid_frames() -> void:
	var frames := animated_sprite.sprite_frames
	for animation_name in [&"block_mid", &"block_mid_recovery"]:
		if frames.has_animation(animation_name):
			frames.remove_animation(animation_name)
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 24.0)
		frames.set_animation_loop(animation_name, false)

	for source_index in range(BLOCK_MID_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = BLOCK_MID_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				(source_index % BLOCK_MID_COLUMNS) * BLOCK_MID_CELL_SIZE.x,
				(source_index / BLOCK_MID_COLUMNS) * BLOCK_MID_CELL_SIZE.y
			),
			BLOCK_MID_CELL_SIZE
		)
		frames.add_frame(&"block_mid", atlas_frame)

	for source_index in range(BLOCK_MID_FRAME_COUNT - 2, -1, -1):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = BLOCK_MID_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				(source_index % BLOCK_MID_COLUMNS) * BLOCK_MID_CELL_SIZE.x,
				(source_index / BLOCK_MID_COLUMNS) * BLOCK_MID_CELL_SIZE.y
			),
			BLOCK_MID_CELL_SIZE
		)
		frames.add_frame(&"block_mid_recovery", atlas_frame)


func configure_block_low_frames() -> void:
	var frames := animated_sprite.sprite_frames
	for animation_name in [&"block_low", &"block_low_crouched", &"block_low_recovery"]:
		if frames.has_animation(animation_name):
			frames.remove_animation(animation_name)
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 24.0)
		frames.set_animation_loop(animation_name, false)

	for source_index in range(BLOCK_LOW_FRAME_COUNT):
		for animation_name in [&"block_low", &"block_low_crouched"]:
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = BLOCK_LOW_SHEET
			atlas_frame.region = Rect2(
				Vector2(
					(source_index % BLOCK_LOW_COLUMNS) * BLOCK_LOW_CELL_SIZE.x,
					(source_index / BLOCK_LOW_COLUMNS) * BLOCK_LOW_CELL_SIZE.y
				),
				BLOCK_LOW_CELL_SIZE
			)
			frames.add_frame(animation_name, atlas_frame)

	for source_index in range(BLOCK_LOW_FRAME_COUNT - 2, -1, -1):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = BLOCK_LOW_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				(source_index % BLOCK_LOW_COLUMNS) * BLOCK_LOW_CELL_SIZE.x,
				(source_index / BLOCK_LOW_COLUMNS) * BLOCK_LOW_CELL_SIZE.y
			),
			BLOCK_LOW_CELL_SIZE
		)
		frames.add_frame(&"block_low_recovery", atlas_frame)


func configure_standing_heavy_kick_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"heavy_kick"):
		frames.remove_animation(&"heavy_kick")
	frames.add_animation(&"heavy_kick")
	frames.set_animation_speed(&"heavy_kick", 48.0)
	frames.set_animation_loop(&"heavy_kick", false)
	# Avanzata: fotogrammi 21-48 (hitbox al 24); rovesciata: 47-21 (recovery).
	for source_index in range(21, STRONG_KICK_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = STRONG_KICK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % STRONG_KICK_COLUMNS),
				float(floori(float(source_index) / STRONG_KICK_COLUMNS))
			) * STRONG_KICK_CELL_SIZE,
			STRONG_KICK_CELL_SIZE
		)
		frames.add_frame(&"heavy_kick", atlas_frame)
	for source_index in range(STRONG_KICK_FRAME_COUNT - 2, 20, -1):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = STRONG_KICK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % STRONG_KICK_COLUMNS),
				float(floori(float(source_index) / STRONG_KICK_COLUMNS))
			) * STRONG_KICK_CELL_SIZE,
			STRONG_KICK_CELL_SIZE
		)
		frames.add_frame(&"heavy_kick", atlas_frame)


func configure_crouched_heavy_kick_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"crouched_heavy_kick"):
		frames.remove_animation(&"crouched_heavy_kick")
	frames.add_animation(&"crouched_heavy_kick")
	frames.set_animation_speed(&"crouched_heavy_kick", 24.0)
	frames.set_animation_loop(&"crouched_heavy_kick", false)
	for source_index in range(
		CROUCHED_HEAVY_KICK_SOURCE_START,
		CROUCHED_HEAVY_KICK_SOURCE_END + 1
	):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = CROUCHED_HEAVY_KICK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % CROUCHED_HEAVY_KICK_COLUMNS),
				float(floori(float(source_index) / CROUCHED_HEAVY_KICK_COLUMNS))
			) * CROUCHED_HEAVY_KICK_CELL_SIZE,
			CROUCHED_HEAVY_KICK_CELL_SIZE
		)
		frames.add_frame(&"crouched_heavy_kick", atlas_frame)


func configure_standing_medium_kick_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"medium_kick"):
		frames.remove_animation(&"medium_kick")
	frames.add_animation(&"medium_kick")
	frames.set_animation_speed(&"medium_kick", 48.0)
	frames.set_animation_loop(&"medium_kick", false)
	# Avanzata: fotogrammi 14-41 (hitbox ai pos. 26-27); rovesciata: 40-14 (recovery).
	for source_index in range(14, MEDIUM_KICK_STANDING_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = MEDIUM_KICK_STANDING_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % MEDIUM_KICK_STANDING_COLUMNS),
				float(floori(float(source_index) / MEDIUM_KICK_STANDING_COLUMNS))
			) * MEDIUM_KICK_STANDING_CELL_SIZE,
			MEDIUM_KICK_STANDING_CELL_SIZE
		)
		frames.add_frame(&"medium_kick", atlas_frame)
	for source_index in range(MEDIUM_KICK_STANDING_FRAME_COUNT - 2, 13, -1):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = MEDIUM_KICK_STANDING_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % MEDIUM_KICK_STANDING_COLUMNS),
				float(floori(float(source_index) / MEDIUM_KICK_STANDING_COLUMNS))
			) * MEDIUM_KICK_STANDING_CELL_SIZE,
			MEDIUM_KICK_STANDING_CELL_SIZE
		)
		frames.add_frame(&"medium_kick", atlas_frame)


func configure_crouched_medium_kick_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"crouched_medium_kick"):
		frames.remove_animation(&"crouched_medium_kick")
	frames.add_animation(&"crouched_medium_kick")
	frames.set_animation_speed(&"crouched_medium_kick", 24.0)
	frames.set_animation_loop(&"crouched_medium_kick", false)
	for source_index in range(CROUCHED_MEDIUM_KICK_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = CROUCHED_MEDIUM_KICK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % CROUCHED_MEDIUM_KICK_COLUMNS),
				float(floori(float(source_index) / CROUCHED_MEDIUM_KICK_COLUMNS))
			) * CROUCHED_MEDIUM_KICK_CELL_SIZE,
			CROUCHED_MEDIUM_KICK_CELL_SIZE
		)
		frames.add_frame(&"crouched_medium_kick", atlas_frame)


func configure_standing_light_kick_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"light_kick"):
		frames.remove_animation(&"light_kick")
	frames.add_animation(&"light_kick")
	frames.set_animation_speed(&"light_kick", 48.0)
	frames.set_animation_loop(&"light_kick", false)
	# Avanzata: fotogrammi 10-24 (startup + impatto al 24); rovesciata: 23-10 (recovery).
	for source_index in range(10, LIGHT_KICK_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = LIGHT_KICK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % LIGHT_KICK_COLUMNS),
				float(floori(float(source_index) / LIGHT_KICK_COLUMNS))
			) * LIGHT_KICK_CELL_SIZE,
			LIGHT_KICK_CELL_SIZE
		)
		frames.add_frame(&"light_kick", atlas_frame)
	for source_index in range(LIGHT_KICK_FRAME_COUNT - 2, 9, -1):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = LIGHT_KICK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % LIGHT_KICK_COLUMNS),
				float(floori(float(source_index) / LIGHT_KICK_COLUMNS))
			) * LIGHT_KICK_CELL_SIZE,
			LIGHT_KICK_CELL_SIZE
		)
		frames.add_frame(&"light_kick", atlas_frame)


func configure_crouched_light_kick_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"crouched_light_kick"):
		frames.remove_animation(&"crouched_light_kick")
	frames.add_animation(&"crouched_light_kick")
	frames.set_animation_speed(&"crouched_light_kick", 24.0)
	frames.set_animation_loop(&"crouched_light_kick", false)
	for source_index in range(CROUCHED_LIGHT_KICK_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = CROUCHED_LIGHT_KICK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % CROUCHED_LIGHT_KICK_COLUMNS),
				float(floori(float(source_index) / CROUCHED_LIGHT_KICK_COLUMNS))
			) * CROUCHED_LIGHT_KICK_CELL_SIZE,
			CROUCHED_LIGHT_KICK_CELL_SIZE
		)
		frames.add_frame(&"crouched_light_kick", atlas_frame)


func configure_jump_light_kick_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"jump_light_kick"):
		frames.remove_animation(&"jump_light_kick")
	frames.add_animation(&"jump_light_kick")
	frames.set_animation_speed(&"jump_light_kick", 24.0)
	frames.set_animation_loop(&"jump_light_kick", false)
	for source_index in JUMP_LIGHT_KICK_SOURCE_SEQUENCE:
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = JUMP_LIGHT_KICK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % JUMP_LIGHT_KICK_COLUMNS),
				float(floori(float(source_index) / JUMP_LIGHT_KICK_COLUMNS))
			) * JUMP_LIGHT_KICK_CELL_SIZE,
			JUMP_LIGHT_KICK_CELL_SIZE
		)
		frames.add_frame(&"jump_light_kick", atlas_frame)


func configure_jump_heavy_kick_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"jump_heavy_kick"):
		frames.remove_animation(&"jump_heavy_kick")
	frames.add_animation(&"jump_heavy_kick")
	frames.set_animation_speed(&"jump_heavy_kick", 30.0)
	frames.set_animation_loop(&"jump_heavy_kick", false)
	for source_index in range(JUMP_HEAVY_KICK_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = JUMP_HEAVY_KICK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % JUMP_HEAVY_KICK_COLUMNS),
				float(floori(float(source_index) / JUMP_HEAVY_KICK_COLUMNS))
			) * JUMP_HEAVY_KICK_CELL_SIZE,
			JUMP_HEAVY_KICK_CELL_SIZE
		)
		frames.add_frame(&"jump_heavy_kick", atlas_frame)


func configure_jump_medium_kick_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"jump_medium_kick"):
		frames.remove_animation(&"jump_medium_kick")
	frames.add_animation(&"jump_medium_kick")
	frames.set_animation_speed(&"jump_medium_kick", 30.0)
	frames.set_animation_loop(&"jump_medium_kick", false)
	for source_index in range(JUMP_MEDIUM_KICK_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = JUMP_MEDIUM_KICK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % JUMP_MEDIUM_KICK_COLUMNS),
				float(floori(float(source_index) / JUMP_MEDIUM_KICK_COLUMNS))
			) * JUMP_MEDIUM_KICK_CELL_SIZE,
			JUMP_MEDIUM_KICK_CELL_SIZE
		)
		frames.add_frame(&"jump_medium_kick", atlas_frame)


func configure_light_punch_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"light_punch_single"):
		frames.remove_animation(&"light_punch_single")
	frames.add_animation(&"light_punch_single")
	frames.set_animation_speed(&"light_punch_single", 48.0)
	frames.set_animation_loop(&"light_punch_single", false)
	for source_index in range(LIGHT_PUNCH_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = LIGHT_PUNCH_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % LIGHT_PUNCH_COLUMNS),
				float(floori(float(source_index) / LIGHT_PUNCH_COLUMNS))
			) * LIGHT_PUNCH_CELL_SIZE,
			LIGHT_PUNCH_CELL_SIZE
		)
		frames.add_frame(&"light_punch_single", atlas_frame)


func configure_medium_punch_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"medium_open_hand_slap"):
		frames.remove_animation(&"medium_open_hand_slap")
	frames.add_animation(&"medium_open_hand_slap")
	frames.set_animation_speed(&"medium_open_hand_slap", 48.0)
	frames.set_animation_loop(&"medium_open_hand_slap", false)
	
	# Add preparation frames (10 frames)
	for source_index in range(MEDIUM_PUNCH_PREPARATION_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = MEDIUM_PUNCH_PREPARATION_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % MEDIUM_PUNCH_COLUMNS),
				float(floori(float(source_index) / float(MEDIUM_PUNCH_COLUMNS)))
			) * MEDIUM_PUNCH_CELL_SIZE,
			MEDIUM_PUNCH_CELL_SIZE
		)
		frames.add_frame(&"medium_open_hand_slap", atlas_frame)
	
	# Add hit frames (16 frames)
	for source_index in range(MEDIUM_PUNCH_HIT_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = MEDIUM_PUNCH_HIT_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % MEDIUM_PUNCH_COLUMNS),
				float(floori(float(source_index) / float(MEDIUM_PUNCH_COLUMNS)))
			) * MEDIUM_PUNCH_CELL_SIZE,
			MEDIUM_PUNCH_CELL_SIZE
		)
		frames.add_frame(&"medium_open_hand_slap", atlas_frame)
	
	# Add to-idle frames (16 frames)
	for source_index in range(MEDIUM_PUNCH_TO_IDLE_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = MEDIUM_PUNCH_TO_IDLE_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % MEDIUM_PUNCH_COLUMNS),
				float(floori(float(source_index) / float(MEDIUM_PUNCH_COLUMNS)))
			) * MEDIUM_PUNCH_CELL_SIZE,
			MEDIUM_PUNCH_CELL_SIZE
		)
		frames.add_frame(&"medium_open_hand_slap", atlas_frame)


func configure_jump_medium_punch_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"jump_medium_punch"):
		frames.remove_animation(&"jump_medium_punch")
	frames.add_animation(&"jump_medium_punch")
	frames.set_animation_speed(&"jump_medium_punch", 24.0)
	frames.set_animation_loop(&"jump_medium_punch", false)
	for source_index in range(JUMP_MEDIUM_PUNCH_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = JUMP_MEDIUM_PUNCH_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % JUMP_MEDIUM_PUNCH_COLUMNS),
				float(floori(float(source_index) / JUMP_MEDIUM_PUNCH_COLUMNS))
			) * JUMP_MEDIUM_PUNCH_CELL_SIZE,
			JUMP_MEDIUM_PUNCH_CELL_SIZE
		)
		frames.add_frame(&"jump_medium_punch", atlas_frame)


func configure_jump_heavy_punch_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"jump_heavy_punch"):
		frames.remove_animation(&"jump_heavy_punch")
	frames.add_animation(&"jump_heavy_punch")
	frames.set_animation_speed(&"jump_heavy_punch", 24.0)
	frames.set_animation_loop(&"jump_heavy_punch", false)
	for source_index in range(JUMP_HEAVY_PUNCH_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = JUMP_HEAVY_PUNCH_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % JUMP_HEAVY_PUNCH_COLUMNS),
				float(floori(float(source_index) / JUMP_HEAVY_PUNCH_COLUMNS))
			) * JUMP_HEAVY_PUNCH_CELL_SIZE,
			JUMP_HEAVY_PUNCH_CELL_SIZE
		)
		frames.add_frame(&"jump_heavy_punch", atlas_frame)


func _physics_process(delta: float) -> void:
	if force_idle_until_landing and is_on_floor():
		force_idle_until_landing = false
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if current_state in [State.HIT, State.SWEEP_KNOCKDOWN]:
		velocity.x = move_toward(velocity.x, 0.0, HIT_PUSHBACK_DECELERATION * delta)

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
	update_ground_shadow()


func handle_input() -> void:
	"""Gestisce un'unica azione per frame secondo una priorità esplicita."""
	if current_state in [
		State.BACK_HOP_STARTUP,
		State.BACK_HOP,
		State.JUMP_STARTUP,
		State.STANDING_UP,
		State.ATTACKING,
		State.BLOCKING,
		State.BLOCK_RECOVERY,
		State.HIT,
		State.SWEEP_KNOCKDOWN,
		State.KNOCKDOWN_RECOVERY,
		State.KNOCKED_DOWN,
	]:
		return
	# Come nei fighting game classici, l'arco viene deciso allo stacco:
	# nessun cambio di direzione è consentito durante il volo.
	if current_state == State.JUMPING:
		for aerial_attack_name in [
			&"heavy_punch", &"medium_punch", &"heavy_kick", &"medium_kick", &"light_kick"
		]:
			var aerial_attack_direction := input_buffer.consume_attack(aerial_attack_name)
			if aerial_attack_direction != FighterInputBuffer.NO_DIRECTION:
				combat.try_attack(aerial_attack_name, aerial_attack_direction)
				break
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
		change_state(State.STANDING_UP)
		return

	if Input.is_action_just_pressed(get_input_action("jump")) and is_on_floor():
		start_jump(input_buffer.get_horizontal_axis())
		return

	var direction := input_buffer.get_horizontal_axis()
	if is_on_floor() and input_buffer.is_back_just_pressed():
		var current_frame := Engine.get_physics_frames()
		if current_frame - last_back_tap_frame <= BACK_HOP_DOUBLE_TAP_WINDOW_FRAMES:
			start_back_hop(direction)
			last_back_tap_frame = -BACK_HOP_DOUBLE_TAP_WINDOW_FRAMES - 1
			return
		last_back_tap_frame = current_frame

	if is_on_floor() and input_buffer.is_forward_just_pressed():
		var current_frame := Engine.get_physics_frames()
		if current_frame - last_forward_tap_frame <= RUN_DOUBLE_TAP_WINDOW_FRAMES:
			change_state(State.RUNNING)
		last_forward_tap_frame = current_frame

	if current_state == State.RUNNING and not input_buffer.is_forward_held():
		change_state(State.WALKING if direction != 0.0 else State.IDLE)

	var movement_speed := (
		character_data.run_speed if current_state == State.RUNNING
		else character_data.walk_speed
	)
	velocity.x = direction * movement_speed
	if is_on_floor() and current_state != State.RUNNING:
		change_state(State.WALKING if direction != 0 else State.IDLE)


func start_back_hop(horizontal_direction: float) -> void:
	"""Avvia la preparazione visiva del balzo nella direzione opposta all'avversario."""
	var back_direction := signf(horizontal_direction)
	if is_zero_approx(back_direction):
		back_direction = -1.0 if is_facing_right else 1.0
	combat.set_guarding(false)
	pending_jump_direction = back_direction
	velocity = Vector2.ZERO
	change_state(State.BACK_HOP_STARTUP)
	if not animated_sprite.sprite_frames.has_animation(&"dodge"):
		begin_back_hop()


func begin_back_hop() -> void:
	"""Applica l'impulso quando dodge raggiunge il primo frame sospeso."""
	if current_state != State.BACK_HOP_STARTUP:
		return
	velocity = Vector2(
		pending_jump_direction * BACK_HOP_HORIZONTAL_SPEED,
		BACK_HOP_VERTICAL_SPEED
	)
	change_state(State.BACK_HOP)


func start_jump(horizontal_direction: float) -> void:
	"""Riproduce la preparazione e memorizza la direzione scelta allo stacco."""
	aerial_attack_used = false
	force_idle_until_landing = false
	pending_jump_direction = signf(horizontal_direction)
	pending_jump_horizontal_multiplier = (
		RUN_JUMP_HORIZONTAL_MULTIPLIER if current_state == State.RUNNING else 1.0
	)
	velocity = Vector2.ZERO
	change_state(State.JUMP_STARTUP)
	if not animated_sprite.sprite_frames.has_animation(&"jump"):
		begin_jump_ascent()


func begin_jump_ascent() -> void:
	"""Applica l'impulso al primo frame in cui entrambi i piedi lasciano il terreno."""
	if current_state != State.JUMP_STARTUP:
		return
	velocity = Vector2(
		pending_jump_direction * character_data.air_speed * pending_jump_horizontal_multiplier,
		character_data.jump_velocity * JUMP_SPEED_MULTIPLIER
	)
	change_state(State.JUMPING)


func change_state(next_state: int) -> void:
	"""Centralizza gli effetti collaterali di ogni transizione di stato."""
	if current_state == next_state:
		update_animation()
		return

	var previous_state := current_state
	current_state = next_state
	match current_state:
		State.IDLE, State.WALKING, State.RUNNING, State.JUMPING:
			can_move = true
		State.BACK_HOP_STARTUP, State.BACK_HOP:
			can_move = false
			if current_state == State.BACK_HOP_STARTUP:
				velocity = Vector2.ZERO
		State.JUMP_STARTUP:
			can_move = false
			velocity = Vector2.ZERO
		State.CROUCHING:
			can_move = true
			velocity.x = 0.0
		State.STANDING_UP, State.ATTACKING, State.BLOCKING, State.BLOCK_RECOVERY, State.HIT, State.SWEEP_KNOCKDOWN, State.KNOCKDOWN_RECOVERY, State.KNOCKED_DOWN:
			can_move = false
			velocity.x = 0.0
	update_animation()
	update_collision_profile()
	state_changed.emit(previous_state, current_state)


func update_animation() -> void:
	"""Riproduce l'animazione associata allo stato, senza riavviarla ogni frame."""
	if force_idle_until_landing:
		if animated_sprite.animation != &"idle" or not animated_sprite.is_playing():
			animated_sprite.play(&"idle")
		return
	# L'animazione di attacco è gestita da _on_combat_attack_started; non interrompere.
	if current_state == State.ATTACKING:
		return
	if current_state == State.CROUCHING:
		if (
			animated_sprite.sprite_frames.has_animation(&"crouch")
			and animated_sprite.animation != &"crouch"
		):
			animated_sprite.play(&"crouch")
		return

	if current_state == State.STANDING_UP:
		if animated_sprite.sprite_frames.has_animation(&"crouch"):
			animated_sprite.play(&"crouch", -1.0)
		return

	if current_state == State.BACK_HOP and animated_sprite.animation == &"dodge":
		return

	if current_state in [State.BACK_HOP_STARTUP, State.BACK_HOP]:
		var back_hop_animation: StringName = &"dodge" if (
			animated_sprite.sprite_frames.has_animation(&"dodge")
		) else &"backwalk"
		if animated_sprite.animation != back_hop_animation or not animated_sprite.is_playing():
			animated_sprite.play(back_hop_animation)
		return

	# JUMP_STARTUP e JUMPING sono due fasi fisiche della stessa animazione.
	# Al momento dello stacco deve continuare dal frame corrente, senza play().
	if current_state == State.JUMPING and animated_sprite.animation == &"jump":
		return

	if current_state == State.HIT:
		var hit_animation := get_hit_animation(received_hit_height)
		if animated_sprite.sprite_frames.has_animation(hit_animation):
			if animated_sprite.animation != hit_animation or not animated_sprite.is_playing():
				animated_sprite.play(hit_animation)
			return

	if current_state == State.BLOCKING:
		var block_animation := get_block_animation(received_block_height, block_started_crouched)
		if animated_sprite.sprite_frames.has_animation(block_animation):
			# Una parata conclusa deve mantenere la posa finale, non ricominciare da capo.
			if animated_sprite.animation != block_animation:
				animated_sprite.play(block_animation)
			return

	if current_state == State.BLOCK_RECOVERY:
		var recovery_animation := get_block_recovery_animation(received_block_height)
		if animated_sprite.sprite_frames.has_animation(recovery_animation):
			if animated_sprite.animation != recovery_animation or not animated_sprite.is_playing():
				animated_sprite.play(recovery_animation)
			return

	if current_state == State.SWEEP_KNOCKDOWN:
		if animated_sprite.sprite_frames.has_animation(&"sweep_knockdown"):
			if animated_sprite.animation != &"sweep_knockdown" or not animated_sprite.is_playing():
				animated_sprite.play(&"sweep_knockdown")
			return

	if current_state == State.KNOCKDOWN_RECOVERY:
		if animated_sprite.sprite_frames.has_animation(&"knockdown_recovery"):
			if animated_sprite.animation != &"knockdown_recovery" or not animated_sprite.is_playing():
				animated_sprite.play(&"knockdown_recovery")
			return

	if current_state == State.KNOCKED_DOWN:
		if animated_sprite.sprite_frames.has_animation(&"ko"):
			# Non riavviare il KO quando ha raggiunto la posa finale a terra.
			if animated_sprite.animation != &"ko":
				animated_sprite.play(&"ko")
			return

	var next_animation: StringName = &"idle"
	if current_state == State.WALKING:
		next_animation = &"backwalk" if is_moving_backward() else &"walk"
	elif current_state == State.RUNNING:
		next_animation = &"run"
	elif (
		current_state in [State.JUMP_STARTUP, State.JUMPING]
		and animated_sprite.sprite_frames.has_animation(&"jump")
	):
		next_animation = &"jump"
	if (
		animated_sprite.sprite_frames.has_animation(next_animation)
		and (animated_sprite.animation != next_animation or not animated_sprite.is_playing())
	):
		animated_sprite.play(next_animation)


func update_sprite_scale() -> void:
	"""Ingrandisce soltanto le animazioni già convertite al nuovo formato grafico."""
	var uses_reworked_art := animated_sprite.animation in [
		&"idle", &"light_punch_single", &"light_kick", &"medium_kick", &"heavy_kick", &"medium_open_hand_slap", &"heavy_punch", &"crouch", &"jump", &"block_high",
		&"block_high_recovery", &"block_mid", &"block_mid_recovery", &"block_low",
		&"block_low_crouched", &"block_low_recovery"
	]
	animated_sprite.scale = REWORK_SPRITE_SCALE if uses_reworked_art else LEGACY_SPRITE_SCALE
	animated_sprite.position = (
		REWORK_SPRITE_POSITION if uses_reworked_art else LEGACY_SPRITE_POSITION
	)


func get_hit_animation(hit_height: AttackData.HitHeight) -> StringName:
	match hit_height:
		AttackData.HitHeight.HIGH:
			return &"hurt_high"
		AttackData.HitHeight.LOW:
			return &"hurt_low"
		_:
			return &"hurt_mid"


func get_block_animation(
	block_height: AttackData.HitHeight,
	started_crouched: bool = false
) -> StringName:
	var animation_name: StringName
	match block_height:
		AttackData.HitHeight.HIGH:
			animation_name = &"block_high"
		AttackData.HitHeight.LOW:
			animation_name = &"block_low_crouched" if started_crouched else &"block_low"
		_:
			animation_name = &"block_mid"
	if animated_sprite.sprite_frames.has_animation(animation_name):
		return animation_name
	return &"block_mid"


func get_block_recovery_animation(block_height: AttackData.HitHeight) -> StringName:
	var animation_name: StringName
	match block_height:
		AttackData.HitHeight.HIGH:
			animation_name = &"block_high_recovery"
		AttackData.HitHeight.LOW:
			animation_name = &"block_low_recovery"
		_:
			animation_name = &"block_mid_recovery"
	if animated_sprite.sprite_frames.has_animation(animation_name):
		return animation_name
	return &"block_mid_recovery"


func start_block_reaction(
	block_height: AttackData.HitHeight,
	started_crouched: bool = false
) -> float:
	received_block_height = block_height
	block_started_crouched = started_crouched
	change_state(State.BLOCKING)
	var block_animation := get_block_animation(block_height, started_crouched)
	if animated_sprite.sprite_frames.has_animation(block_animation):
		animated_sprite.play(block_animation)
	return get_animation_duration(block_animation)


func start_block_recovery() -> float:
	change_state(State.BLOCK_RECOVERY)
	var recovery_animation := get_block_recovery_animation(received_block_height)
	if animated_sprite.sprite_frames.has_animation(recovery_animation):
		animated_sprite.play(recovery_animation)
	return get_animation_duration(recovery_animation)


func is_holding_low_guard() -> bool:
	return (
		input_buffer != null
		and input_buffer.is_down_held()
		and input_buffer.is_back_held()
	)


func return_to_crouch_after_low_block() -> void:
	"""Passa dal frame finale della parata alla posa finale del crouch."""
	change_state(State.CROUCHING)
	if animated_sprite.sprite_frames.has_animation(&"crouch"):
		animated_sprite.play(&"crouch")
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(&"crouch") - 1
		animated_sprite.pause()
	update_collision_profile()


func return_to_crouch_pose() -> void:
	"""Ripristina e mantiene la posa finale del crouch dopo un attacco basso."""
	change_state(State.CROUCHING)
	if animated_sprite.sprite_frames.has_animation(&"crouch"):
		animated_sprite.play(&"crouch")
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(&"crouch") - 1
		animated_sprite.pause()
	update_collision_profile()


func start_hit_reaction(
	hit_height: AttackData.HitHeight,
	attacker: Mangler,
	start_frame: int = 0,
	apply_pushback: bool = true
) -> float:
	"""Avvia da capo la reazione e applica un breve rinculo opposto all'attaccante."""
	received_hit_height = hit_height
	change_state(State.HIT)
	var hit_animation := get_hit_animation(hit_height)
	if animated_sprite.sprite_frames.has_animation(hit_animation):
		animated_sprite.play(hit_animation)
		var final_frame := animated_sprite.sprite_frames.get_frame_count(hit_animation) - 1
		animated_sprite.frame = clampi(start_frame, 0, final_frame)

	if apply_pushback:
		var push_direction := -1.0 if is_facing_right else 1.0
		if attacker != null and is_instance_valid(attacker):
			push_direction = signf(global_position.x - attacker.global_position.x)
			if is_zero_approx(push_direction):
				push_direction = -1.0 if is_facing_right else 1.0
		velocity.x = push_direction * HIT_PUSHBACK_SPEED
	else:
		velocity.x = 0.0
	return get_animation_duration(hit_animation, start_frame)


func start_sweep_knockdown(attacker: Mangler) -> float:
	"""Avvia la caduta da spazzata e applica un rinculo più deciso."""
	change_state(State.SWEEP_KNOCKDOWN)
	if animated_sprite.sprite_frames.has_animation(&"sweep_knockdown"):
		animated_sprite.play(&"sweep_knockdown")

	var push_direction := -1.0 if is_facing_right else 1.0
	if attacker != null and is_instance_valid(attacker):
		push_direction = signf(global_position.x - attacker.global_position.x)
		if is_zero_approx(push_direction):
			push_direction = -1.0 if is_facing_right else 1.0
	velocity.x = push_direction * SWEEP_PUSHBACK_SPEED
	return get_animation_duration(&"sweep_knockdown")


func start_knockdown_recovery() -> float:
	"""Avvia la rialzata non interrompibile dalla posa finale della spazzata."""
	velocity.x = 0.0
	change_state(State.KNOCKDOWN_RECOVERY)
	if animated_sprite.sprite_frames.has_animation(&"knockdown_recovery"):
		animated_sprite.play(&"knockdown_recovery")
	return get_animation_duration(&"knockdown_recovery")


func get_animation_duration(animation_name: StringName, start_frame: int = 0) -> float:
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return 0.0
	var frames := animated_sprite.sprite_frames
	var speed := frames.get_animation_speed(animation_name)
	if speed <= 0.0:
		return 0.0
	var duration := 0.0
	var first_frame := clampi(start_frame, 0, frames.get_frame_count(animation_name) - 1)
	for frame_index in range(first_frame, frames.get_frame_count(animation_name)):
		duration += frames.get_frame_duration(animation_name, frame_index) / speed
	return duration


func is_moving_backward() -> bool:
	if is_zero_approx(velocity.x):
		return false
	return velocity.x < 0.0 if is_facing_right else velocity.x > 0.0


func update_state() -> void:
	if current_state == State.BACK_HOP_STARTUP:
		return
	if current_state == State.BACK_HOP:
		if is_on_floor() and velocity.y >= 0.0:
			velocity = Vector2.ZERO
			if not animated_sprite.is_playing():
				change_state(State.IDLE)
		return
	if current_state == State.JUMP_STARTUP:
		return
	if current_state in [
		State.STANDING_UP,
		State.ATTACKING,
		State.BLOCKING,
		State.BLOCK_RECOVERY,
		State.HIT,
		State.SWEEP_KNOCKDOWN,
		State.KNOCKDOWN_RECOVERY,
		State.KNOCKED_DOWN,
	]:
		return

	if not is_on_floor():
		change_state(State.JUMPING)
	elif current_state == State.JUMPING and velocity.y >= 0.0:
		velocity.x = 0.0
		change_state(State.IDLE)
	elif is_zero_approx(velocity.x) and current_state in [State.WALKING, State.RUNNING]:
		change_state(State.IDLE)


func update_physical_collision() -> void:
	"""In aria attraversa gli altri fighter, ma continua a collidere col terreno."""
	var is_airborne := (
		current_state == State.JUMPING
		or not is_on_floor()
		or (current_state == State.BACK_HOP and velocity.y < 0.0)
	)
	if is_airborne:
		collision_layer = 0
		collision_mask = GROUND_COLLISION_LAYER
	else:
		collision_layer = FIGHTER_COLLISION_LAYER
		collision_mask = GROUND_COLLISION_LAYER | FIGHTER_COLLISION_LAYER


func duplicate_collision_shapes() -> void:
	"""Rende le forme modificabili per fighter senza alterare l'altro giocatore."""
	for shape_node in [collision_shape, head_hurtbox, torso_hurtbox, legs_hurtbox]:
		if shape_node.shape:
			shape_node.shape = shape_node.shape.duplicate()


func update_collision_profile() -> void:
	"""Interpola pushbox e hurtbox seguendo i frame della transizione crouch."""
	var crouch_ratio := get_crouch_progress()
	set_box_profile(
		collision_shape,
		STANDING_COLLISION_SIZE.lerp(CROUCH_COLLISION_SIZE, crouch_ratio),
		STANDING_COLLISION_POSITION.lerp(CROUCH_COLLISION_POSITION, crouch_ratio)
	)
	set_box_profile(
		head_hurtbox,
		STANDING_HEAD_SIZE.lerp(CROUCH_HEAD_SIZE, crouch_ratio),
		STANDING_HEAD_POSITION.lerp(CROUCH_HEAD_POSITION, crouch_ratio)
	)
	set_box_profile(
		torso_hurtbox,
		STANDING_TORSO_SIZE.lerp(CROUCH_TORSO_SIZE, crouch_ratio),
		STANDING_TORSO_POSITION.lerp(CROUCH_TORSO_POSITION, crouch_ratio)
	)
	set_box_profile(
		legs_hurtbox,
		STANDING_LEGS_SIZE.lerp(CROUCH_LEGS_SIZE, crouch_ratio),
		STANDING_LEGS_POSITION.lerp(CROUCH_LEGS_POSITION, crouch_ratio)
	)


func get_crouch_progress() -> float:
	if current_state not in [State.CROUCHING, State.STANDING_UP]:
		return 0.0
	if animated_sprite.animation != &"crouch":
		return 0.0
	var final_frame := animated_sprite.sprite_frames.get_frame_count(&"crouch") - 1
	if final_frame <= 0:
		return 1.0
	return clampf(float(animated_sprite.frame) / float(final_frame), 0.0, 1.0)


func set_box_profile(shape_node: CollisionShape2D, size: Vector2, box_position: Vector2) -> void:
	var rectangle := shape_node.shape as RectangleShape2D
	if rectangle:
		rectangle.size = size
		shape_node.position = box_position


func update_ground_shadow() -> void:
	"""Mantiene l'ombra sul pavimento e la attenua in base all'altezza."""
	if is_on_floor():
		shadow_ground_y = global_position.y

	var height_above_ground := maxf(shadow_ground_y - global_position.y, 0.0)
	var air_ratio := clampf(height_above_ground / SHADOW_MAX_HEIGHT, 0.0, 1.0)
	var shadow_scale := lerpf(1.0, SHADOW_AIR_SCALE, air_ratio)
	ground_shadow.global_position = Vector2(
		global_position.x,
		shadow_ground_y + SHADOW_FLOOR_OFFSET_Y
	)
	ground_shadow.scale = Vector2(shadow_scale, lerpf(1.0, 0.72, air_ratio))
	ground_shadow.modulate.a = lerpf(SHADOW_GROUND_ALPHA, SHADOW_AIR_ALPHA, air_ratio)


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
	update_animation()


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
	clear_attack_afterimages()
	aerial_attack_used = false
	force_idle_until_landing = false
	position = spawn_position
	velocity = Vector2.ZERO
	shadow_ground_y = spawn_position.y
	last_forward_tap_frame = -RUN_DOUBLE_TAP_WINDOW_FRAMES - 1
	last_back_tap_frame = -BACK_HOP_DOUBLE_TAP_WINDOW_FRAMES - 1
	pending_jump_direction = 0.0
	pending_jump_horizontal_multiplier = 1.0
	combat.reset()
	change_state(State.IDLE)
	can_move = true
	if input_buffer != null:
		input_buffer.clear()
	update_ground_shadow()


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
	bring_player_one_to_foreground()
	if attack_name == &"light_punch" and combat.is_crouched_light_punch:
		var crouched_animation := (
			&"crouched_punch_crouched"
			if combat.crouched_punch_started_crouched
			else &"crouched_punch"
		)
		if animated_sprite.sprite_frames.has_animation(crouched_animation):
			animated_sprite.play(crouched_animation)
	elif attack_name == &"light_punch" and animated_sprite.sprite_frames.has_animation(&"light_punch_single"):
		animated_sprite.play(&"light_punch_single")
	elif attack_name == &"medium_punch" and combat.is_airborne_medium_punch:
		animated_sprite.play(&"jump_medium_punch")
	elif attack_name == &"heavy_punch" and combat.is_airborne_heavy_punch:
		animated_sprite.play(&"jump_heavy_punch")
	elif attack_name == &"medium_punch" and combat.is_crouched_medium_punch:
		var crouched_medium_animation := (
			&"crouched_medium_punch_crouched"
			if combat.crouched_medium_punch_started_crouched
			else &"crouched_medium_punch"
		)
		if animated_sprite.sprite_frames.has_animation(crouched_medium_animation):
			animated_sprite.play(crouched_medium_animation)
	elif attack_name == &"medium_punch" and animated_sprite.sprite_frames.has_animation(&"medium_open_hand_slap"):
		animated_sprite.play(&"medium_open_hand_slap")
	elif attack_name == &"heavy_punch" and combat.is_crouched_heavy_punch:
		if animated_sprite.sprite_frames.has_animation(&"crouched_power_punch"):
			animated_sprite.play(&"crouched_power_punch")
	elif attack_name == &"heavy_punch" and animated_sprite.sprite_frames.has_animation(&"heavy_punch"):
		animated_sprite.play(&"heavy_punch")
	elif attack_name == &"light_kick" and combat.is_airborne_light_kick:
		animated_sprite.play(&"jump_light_kick")
	elif attack_name == &"heavy_kick" and combat.is_airborne_heavy_kick:
		animated_sprite.play(&"jump_heavy_kick")
	elif attack_name == &"medium_kick" and combat.is_airborne_medium_kick:
		animated_sprite.play(&"jump_medium_kick")
	elif attack_name == &"light_kick" and combat.is_crouched_light_kick:
		animated_sprite.play(&"crouched_light_kick")
	elif attack_name == &"light_kick" and animated_sprite.sprite_frames.has_animation(&"light_kick"):
		animated_sprite.play(&"light_kick")
	elif attack_name == &"medium_kick" and animated_sprite.sprite_frames.has_animation(&"medium_kick"):
		if combat.is_crouched_medium_kick:
			animated_sprite.play(&"crouched_medium_kick")
		else:
			animated_sprite.play(&"medium_kick")
	elif (
		attack_name == &"heavy_kick"
		and combat.is_crouched_heavy_kick
		and animated_sprite.sprite_frames.has_animation(&"crouched_heavy_kick")
	):
		animated_sprite.play(&"crouched_heavy_kick")
	elif attack_name == &"heavy_kick" and animated_sprite.sprite_frames.has_animation(&"heavy_kick"):
		animated_sprite.play(&"heavy_kick")
	attack_started.emit(attack_name)


func _on_combat_attack_finished() -> void:
	restore_default_render_order()
	attack_finished.emit()


func bring_player_one_to_foreground() -> void:
	if player_number != 1:
		return
	var opponent_z := opponent.z_index if is_instance_valid(opponent) else default_z_index
	z_index = maxi(default_z_index, opponent_z + ATTACK_FOREGROUND_Z_OFFSET)


func restore_default_render_order() -> void:
	if player_number == 1:
		z_index = default_z_index


func get_attack_motion_profile(animation_name: StringName) -> Dictionary:
	if animation_name == &"crouched_heavy_kick":
		return {
			"start_ratio": 0.12,
			"end_ratio": 0.63,
			"tint": Color(0.82, 0.9, 1.0),
			"alpha": SWEEP_AFTERIMAGE_ALPHA,
			"lifetime": SWEEP_AFTERIMAGE_LIFETIME,
			"offset": SWEEP_AFTERIMAGE_OFFSET,
			"stretch": 1.04,
		}
	if animation_name in [
		&"jump_light_kick", &"jump_medium_kick", &"jump_heavy_kick", &"jump_medium_punch",
		&"jump_heavy_punch"
	]:
		return {
			"start_ratio": 0.18,
			"end_ratio": 0.78,
			"tint": Color(0.72, 0.88, 1.0),
			"alpha": 0.24,
			"lifetime": 0.13,
			"offset": 7.0,
			"stretch": 1.03,
		}
	if animation_name in [
		&"heavy_punch", &"crouched_power_punch", &"heavy_kick"
	]:
		return {
			"start_ratio": 0.28,
			"end_ratio": 0.78,
			"tint": Color(1.0, 0.78, 0.55),
			"alpha": 0.3,
			"lifetime": 0.16,
			"offset": 10.0,
			"stretch": 1.06,
		}
	if animation_name in [
		&"medium_open_hand_slap",
		&"crouched_medium_punch",
		&"crouched_medium_punch_crouched",
		&"light_kick",
		&"medium_kick",
		&"crouched_medium_kick",
	]:
		return {
			"start_ratio": 0.24,
			"end_ratio": 0.72,
			"tint": Color(0.86, 0.92, 1.0),
			"alpha": 0.22,
			"lifetime": 0.12,
			"offset": 6.0,
			"stretch": 1.025,
		}
	if animation_name in [
		&"light_punch_single",
		&"light_punch_double",
		&"crouched_punch",
		&"crouched_punch_crouched",
		&"crouched_light_kick",
	]:
		return {
			"start_ratio": 0.2,
			"end_ratio": 0.62,
			"tint": Color.WHITE,
			"alpha": 0.16,
			"lifetime": 0.09,
			"offset": 4.0,
			"stretch": 1.01,
		}
	return {}


func has_attack_motion_effect(animation_name: StringName) -> bool:
	return not get_attack_motion_profile(animation_name).is_empty()


func emit_attack_motion_effect() -> void:
	if current_state != State.ATTACKING:
		return
	var profile := get_attack_motion_profile(animated_sprite.animation)
	if profile.is_empty():
		return
	var frame_count := animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation)
	if frame_count <= 1:
		return
	var last_frame := frame_count - 1
	var effect_start := floori(float(last_frame) * float(profile["start_ratio"]))
	var effect_end := ceili(float(last_frame) * float(profile["end_ratio"]))
	if animated_sprite.frame >= effect_start and animated_sprite.frame <= effect_end:
		spawn_attack_motion_afterimage(profile)


func spawn_attack_motion_afterimage(profile: Dictionary) -> void:
	var frame_texture := animated_sprite.sprite_frames.get_frame_texture(
		animated_sprite.animation, animated_sprite.frame
	)
	if frame_texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.name = "AttackAfterimage"
	ghost.add_to_group("attack_afterimage")
	if animated_sprite.animation == &"crouched_heavy_kick":
		ghost.add_to_group("sweep_afterimage")
	ghost.texture = frame_texture
	ghost.centered = animated_sprite.centered
	ghost.offset = animated_sprite.offset
	ghost.position = animated_sprite.position
	ghost.rotation = animated_sprite.rotation
	ghost.scale = animated_sprite.scale
	ghost.scale.x *= float(profile["stretch"])
	ghost.flip_h = animated_sprite.flip_h
	ghost.flip_v = animated_sprite.flip_v
	ghost.texture_filter = animated_sprite.texture_filter
	ghost.z_index = animated_sprite.z_index - 1
	var tint: Color = profile["tint"]
	ghost.modulate = Color(tint.r, tint.g, tint.b, float(profile["alpha"]))
	add_child(ghost)
	attack_afterimage_spawn_count += 1
	if animated_sprite.animation == &"crouched_heavy_kick":
		sweep_afterimage_spawn_count += 1
	var trail_direction := 1.0 if is_facing_right else -1.0
	var tween := ghost.create_tween()
	var lifetime := float(profile["lifetime"])
	tween.tween_property(ghost, "modulate:a", 0.0, lifetime)
	tween.parallel().tween_property(
		ghost,
		"position:x",
		ghost.position.x - trail_direction * float(profile["offset"]),
		lifetime
	)
	tween.tween_callback(ghost.queue_free)


func spawn_sweep_motion_afterimage() -> void:
	spawn_attack_motion_afterimage(get_attack_motion_profile(&"crouched_heavy_kick"))


func clear_attack_afterimages() -> void:
	for child in get_children():
		if child.is_in_group("attack_afterimage"):
			child.queue_free()


func _on_animation_finished() -> void:
	if current_state == State.STANDING_UP and animated_sprite.animation == &"crouch":
		change_state(State.IDLE)
	elif current_state == State.BACK_HOP and animated_sprite.animation == &"dodge" and is_on_floor():
		change_state(State.IDLE)


func _on_animation_frame_changed() -> void:
	emit_attack_motion_effect()
	if (
		animated_sprite.animation == &"medium_kick"
		and animated_sprite.frame >= 28
		and current_state == State.ATTACKING
	):
		combat.perform_medium_kick_followup()
	elif animated_sprite.animation == &"crouch":
		update_collision_profile()
	elif (
		animated_sprite.animation == &"dodge"
		and current_state == State.BACK_HOP_STARTUP
		and animated_sprite.frame >= BACK_HOP_TAKEOFF_FRAME
	):
		begin_back_hop()
	elif (
		animated_sprite.animation == &"jump"
		and current_state == State.JUMP_STARTUP
		and animated_sprite.frame >= JUMP_TAKEOFF_FRAME
	):
		begin_jump_ascent()
