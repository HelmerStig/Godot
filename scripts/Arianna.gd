extends Mangler
class_name Arianna

## Arianna rispetta il contratto Fighter e riusa temporaneamente da Mangler
## l'implementazione di movimento e reazioni, personalizzando moveset e atlas.
## finché non verranno integrate le sue mosse.

const AnimationCatalog := preload("res://scripts/AriannaAnimationCatalog.gd")
const BateauProjectile := preload("res://scripts/AriannaBateauProjectile.gd")

const ARIANNA_IDLE_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/idle.png"
)
const ARIANNA_IDLE_FRAME_COUNT := 24
const ARIANNA_IDLE_COLUMNS := 7
const ARIANNA_IDLE_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_WALK_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/01-walk.png"
)
const ARIANNA_WALK_FRAME_COUNT := 48
const ARIANNA_WALK_COLUMNS := 7
const ARIANNA_WALK_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_RUN_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/run.png"
)
const ARIANNA_RUN_FRAME_COUNT := 48
const ARIANNA_RUN_COLUMNS := 7
const ARIANNA_RUN_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_RUN_SPEED_MULTIPLIER := 2.0
const ARIANNA_BACK_JUMP_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/back-jump.png"
)
const ARIANNA_BACK_JUMP_COLUMNS := 7
const ARIANNA_BACK_JUMP_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_BACK_JUMP_SOURCE_START := 27
const ARIANNA_BACK_JUMP_SOURCE_END := 48
const ARIANNA_BACK_JUMP_FRAME_COUNT := (
	ARIANNA_BACK_JUMP_SOURCE_END - ARIANNA_BACK_JUMP_SOURCE_START + 1
)
const ARIANNA_BACK_JUMP_DISTANCE := 80.0
const ARIANNA_BACK_JUMP_DURATION := 0.5
const ARIANNA_BACK_JUMP_SPEED := ARIANNA_BACK_JUMP_DISTANCE / ARIANNA_BACK_JUMP_DURATION
const ARIANNA_CROUCH_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/crouched.png"
)
const ARIANNA_CROUCH_FRAME_COUNT := 19
const ARIANNA_CROUCH_COLUMNS := 5
const ARIANNA_CROUCH_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_GUARD_HIGH_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/guard_high.png"
)
const ARIANNA_GUARD_HIGH_FRAME_COUNT := 16
const ARIANNA_GUARD_HIGH_COLUMNS := 4
const ARIANNA_GUARD_HIGH_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_GUARD_MIDDLE_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/guard_middle.png"
)
const ARIANNA_GUARD_MIDDLE_FRAME_COUNT := 13
const ARIANNA_GUARD_MIDDLE_COLUMNS := 4
const ARIANNA_GUARD_MIDDLE_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_GUARD_LOW_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/guard_low.png"
)
const ARIANNA_GUARD_LOW_FRAME_COUNT := 16
const ARIANNA_GUARD_LOW_COLUMNS := 4
const ARIANNA_GUARD_LOW_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_LIGHT_PUNCH_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/light-punch/light-punch.png"
)
const ARIANNA_LIGHT_PUNCH_FRAME_COUNT := 12
const ARIANNA_LIGHT_PUNCH_LAST_PLAYED_FRAME := 9
const ARIANNA_LIGHT_PUNCH_COLUMNS := 7
const ARIANNA_LIGHT_PUNCH_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_LIGHT_PUNCH_ACTIVE_START_FRAME := 6
const ARIANNA_LIGHT_PUNCH_ACTIVE_END_FRAME := 8
const ARIANNA_LIGHT_PUNCH_HITBOX_SIZE := Vector2(160.0, 50.0)
const ARIANNA_LIGHT_PUNCH_HITBOX_POSITION := Vector2(85.0, -170.0)
const ARIANNA_JUMP_LIGHT_PUNCH_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/light-punch/jump_light_punch.png"
)
const ARIANNA_JUMP_LIGHT_PUNCH_SOURCE_FRAME_COUNT := 19
const ARIANNA_JUMP_LIGHT_PUNCH_SOURCE_START := 13
const ARIANNA_JUMP_LIGHT_PUNCH_COLUMNS := 7
const ARIANNA_JUMP_LIGHT_PUNCH_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_JUMP_LIGHT_PUNCH_HOLD_FRAMES := 7
const ARIANNA_JUMP_LIGHT_PUNCH_ACTIVE_START_FRAME := 5
const ARIANNA_JUMP_LIGHT_PUNCH_ACTIVE_END_FRAME := 11
const ARIANNA_JUMP_LIGHT_PUNCH_RESUME_JUMP_FRAME := 31
const ARIANNA_JUMP_LIGHT_PUNCH_HITBOX_SIZE := Vector2(170.0, 55.0)
const ARIANNA_JUMP_LIGHT_PUNCH_HITBOX_POSITION := Vector2(90.0, -125.0)
const ARIANNA_JUMP_LIGHT_PUNCH_SPRITE_SCALE := Vector2(0.78, 0.78)
const ARIANNA_JUMP_MEDIUM_PUNCH_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/medium-punch/jump_medium_punch.png"
)
const ARIANNA_JUMP_MEDIUM_PUNCH_SOURCE_START := 4
const ARIANNA_JUMP_MEDIUM_PUNCH_SOURCE_END := 24
const ARIANNA_JUMP_MEDIUM_PUNCH_COLUMNS := 5
const ARIANNA_JUMP_MEDIUM_PUNCH_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_JUMP_MEDIUM_PUNCH_ACTIVE_START_FRAME := 15
const ARIANNA_JUMP_MEDIUM_PUNCH_ACTIVE_END_FRAME := 20
const ARIANNA_JUMP_MEDIUM_PUNCH_RESUME_JUMP_FRAME := 28
const ARIANNA_JUMP_MEDIUM_PUNCH_HITBOX_SIZE := Vector2(200.0, 48.0)
const ARIANNA_JUMP_MEDIUM_PUNCH_HITBOX_POSITION := Vector2(105.0, -145.0)
const ARIANNA_JUMP_MEDIUM_PUNCH_SPRITE_SCALE := Vector2(0.78, 0.78)
const ARIANNA_JUMP_STRONG_PUNCH_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/strong-punch/strong_jump_punch.png"
)
const ARIANNA_JUMP_STRONG_PUNCH_FRAME_COUNT := 27
const ARIANNA_JUMP_STRONG_PUNCH_COLUMNS := 7
const ARIANNA_JUMP_STRONG_PUNCH_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_JUMP_STRONG_PUNCH_ACTIVE_START_FRAME := 14
const ARIANNA_JUMP_STRONG_PUNCH_ACTIVE_END_FRAME := 20
const ARIANNA_JUMP_STRONG_PUNCH_RESUME_JUMP_FRAME := 39
const ARIANNA_JUMP_STRONG_PUNCH_HITBOX_SIZE := Vector2(210.0, 70.0)
const ARIANNA_JUMP_STRONG_PUNCH_HITBOX_POSITION := Vector2(105.0, -105.0)
const ARIANNA_JUMP_STRONG_PUNCH_HITBOX_ROTATION := deg_to_rad(18.0)
const ARIANNA_JUMP_STRONG_PUNCH_SPRITE_SCALE := Vector2(0.78, 0.78)
const ARIANNA_JUMP_LIGHT_KICK_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/light-kick/light_kick_jump.png"
)
const ARIANNA_JUMP_LIGHT_KICK_SOURCE_FRAME_COUNT := 15
const ARIANNA_JUMP_LIGHT_KICK_COLUMNS := 7
const ARIANNA_JUMP_LIGHT_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_JUMP_LIGHT_KICK_ACTIVE_START_FRAME := 8
const ARIANNA_JUMP_LIGHT_KICK_ACTIVE_END_FRAME := 14
const ARIANNA_JUMP_LIGHT_KICK_RESUME_JUMP_FRAME := 39
const ARIANNA_JUMP_LIGHT_KICK_HITBOX_SIZE := Vector2(170.0, 55.0)
const ARIANNA_JUMP_LIGHT_KICK_HITBOX_POSITION := Vector2(95.0, -55.0)
const ARIANNA_JUMP_LIGHT_KICK_HITBOX_ROTATION := deg_to_rad(12.0)
const ARIANNA_JUMP_LIGHT_KICK_SPRITE_SCALE := Vector2(0.78, 0.78)
const ARIANNA_JUMP_MEDIUM_KICK_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/medium-kick/medium_kick_jump.png"
)
const ARIANNA_JUMP_MEDIUM_KICK_SOURCE_FRAME_COUNT := 35
const ARIANNA_JUMP_MEDIUM_KICK_RECOVERY_END_SOURCE_FRAME := 21
const ARIANNA_JUMP_MEDIUM_KICK_COLUMNS := 7
const ARIANNA_JUMP_MEDIUM_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_JUMP_MEDIUM_KICK_ACTIVE_START_FRAME := 27
const ARIANNA_JUMP_MEDIUM_KICK_ACTIVE_END_FRAME := 47
const ARIANNA_JUMP_MEDIUM_KICK_RESUME_JUMP_FRAME := 29
const ARIANNA_JUMP_MEDIUM_KICK_HITBOX_SIZE := Vector2(170.0, 55.0)
const ARIANNA_JUMP_MEDIUM_KICK_HITBOX_POSITION := Vector2(125.0, -145.0)
const ARIANNA_JUMP_MEDIUM_KICK_HITBOX_ROTATION := deg_to_rad(12.0)
const ARIANNA_JUMP_MEDIUM_KICK_SPRITE_SCALE := Vector2(0.78, 0.78)
const ARIANNA_JUMP_STRONG_KICK_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/strong-kick/strong_kick_jump_2.png"
)
const ARIANNA_JUMP_STRONG_KICK_FRAME_COUNT := 30
const ARIANNA_JUMP_STRONG_KICK_COLUMNS := 7
const ARIANNA_JUMP_STRONG_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_JUMP_STRONG_KICK_ACTIVE_START_FRAME := 14
const ARIANNA_JUMP_STRONG_KICK_ACTIVE_END_FRAME := 18
const ARIANNA_JUMP_STRONG_KICK_RESUME_JUMP_FRAME := 34
const ARIANNA_JUMP_STRONG_KICK_HITBOX_SIZE := Vector2(220.0, 65.0)
const ARIANNA_JUMP_STRONG_KICK_HITBOX_POSITION := Vector2(125.0, -60.0)
const ARIANNA_JUMP_STRONG_KICK_HITBOX_ROTATION := deg_to_rad(10.0)
const ARIANNA_JUMP_STRONG_KICK_SPRITE_SCALE := Vector2(0.78, 0.78)
const ARIANNA_BASEBALL_SPECIAL_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/baseball_special.png"
)
const ARIANNA_BASEBALL_SPECIAL_FRAME_COUNT := 49
const ARIANNA_BASEBALL_SPECIAL_COLUMNS := 7
const ARIANNA_BASEBALL_SPECIAL_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_BASEBALL_TORNADO_SPAWN_FRAME := 23
const ARIANNA_BASEBALL_TORNADO_SPAWN_OFFSET := Vector2(175.0, -80.0)
const ARIANNA_WHISTLE_SPECIAL_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/whistles.png"
)
const ARIANNA_WHISTLE_SOUND := preload(
	"res://assets/sprites/characters/arianna/sound/fischio.wav"
)
const ARIANNA_WHISTLE_SPECIAL_FRAME_COUNT := 24
const ARIANNA_WHISTLE_SPECIAL_COLUMNS := 5
const ARIANNA_WHISTLE_SPECIAL_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_WHISTLE_MOTION_WINDOW_FRAMES := 72
const ARIANNA_WHISTLE_CHORD_WINDOW_FRAMES := 6
const ARIANNA_WHISTLE_AIR_START_FRAME := 5 # Zero-based: fotogramma visibile 6.
const ARIANNA_WHISTLE_SOUND_FRAME := 5 # Zero-based: fotogramma visibile 6.
const ARIANNA_WHISTLE_AIR_END_FRAME := 19 # Zero-based: fotogramma visibile 20.
const ARIANNA_WHISTLE_AIR_MOUTH_OFFSET := Vector2(64.0, -238.0)
const ARIANNA_HURT_MEDIUM_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/hurt_medium.png"
)
const ARIANNA_HURT_MEDIUM_SOURCE_FRAME_COUNT := 8
const ARIANNA_HURT_MEDIUM_COLUMNS := 5
const ARIANNA_HURT_MEDIUM_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_HURT_MEDIUM_PUSHBACK_MULTIPLIER := 0.45
const ARIANNA_HURT_HIGH_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/hurt_high.png"
)
const ARIANNA_HURT_HIGH_FRAME_COUNT := 7
const ARIANNA_HURT_HIGH_COLUMNS := 5
const ARIANNA_HURT_HIGH_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_SWEEP_KNOCKDOWN_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/sweep_knockdown.png"
)
const ARIANNA_SWEEP_KNOCKDOWN_FRAME_COUNT := 25
const ARIANNA_SWEEP_KNOCKDOWN_COLUMNS := 5
const ARIANNA_SWEEP_KNOCKDOWN_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_KNOCKDOWN_RECOVERY_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/knockdown_recovery.png"
)
const ARIANNA_KNOCKDOWN_RECOVERY_FRAME_COUNT := 25
const ARIANNA_KNOCKDOWN_RECOVERY_COLUMNS := 5
const ARIANNA_KNOCKDOWN_RECOVERY_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_KO_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/ko.png"
)
const ARIANNA_KO_FRAME_COUNT := 25
const ARIANNA_KO_COLUMNS := 5
const ARIANNA_KO_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_HURT_LOW_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/hurt_low.png"
)
const ARIANNA_HURT_LOW_FRAME_COUNT := 6
const ARIANNA_HURT_LOW_COLUMNS := 5
const ARIANNA_HURT_LOW_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_LOW_LIGHT_PUNCH_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/light-punch/ligth-punch-low.png"
)
const ARIANNA_LOW_LIGHT_PUNCH_FRAME_COUNT := 25
const ARIANNA_LOW_LIGHT_PUNCH_LAST_PLAYED_FRAME := 15
const ARIANNA_LOW_LIGHT_PUNCH_COLUMNS := 5
const ARIANNA_LOW_LIGHT_PUNCH_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_LOW_LIGHT_PUNCH_ACTIVE_START_FRAME := 11
const ARIANNA_LOW_LIGHT_PUNCH_ACTIVE_END_FRAME := 14
const ARIANNA_LOW_LIGHT_PUNCH_HITBOX_SIZE := Vector2(165.0, 45.0)
const ARIANNA_LOW_LIGHT_PUNCH_HITBOX_POSITION := Vector2(87.5, -115.0)
const ARIANNA_MEDIUM_PUNCH_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/medium-punch/medium-punch.png"
)
const ARIANNA_MEDIUM_PUNCH_FRAME_COUNT := 25
const ARIANNA_MEDIUM_PUNCH_COLUMNS := 5
const ARIANNA_MEDIUM_PUNCH_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_MEDIUM_PUNCH_ACTIVE_START_FRAME := 20
const ARIANNA_MEDIUM_PUNCH_ACTIVE_END_FRAME := 24
const ARIANNA_MEDIUM_PUNCH_HITBOX_SIZE := Vector2(190.0, 45.0)
const ARIANNA_MEDIUM_PUNCH_HITBOX_POSITION := Vector2(100.0, -195.0)
const ARIANNA_LOW_MEDIUM_PUNCH_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/medium-punch/medium-punch-low.png"
)
const ARIANNA_LOW_MEDIUM_PUNCH_FRAME_COUNT := 12
const ARIANNA_LOW_MEDIUM_PUNCH_COLUMNS := 5
const ARIANNA_LOW_MEDIUM_PUNCH_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_LOW_MEDIUM_PUNCH_ACTIVE_START_FRAME := 9
const ARIANNA_LOW_MEDIUM_PUNCH_ACTIVE_END_FRAME := 11
const ARIANNA_LOW_MEDIUM_PUNCH_HITBOX_SIZE := Vector2(200.0, 48.0)
const ARIANNA_LOW_MEDIUM_PUNCH_HITBOX_POSITION := Vector2(105.0, -120.0)
const ARIANNA_STRONG_PUNCH_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/strong-punch/strong-punch.png"
)
const ARIANNA_STRONG_PUNCH_FRAME_COUNT := 49
const ARIANNA_STRONG_PUNCH_COLUMNS := 7
const ARIANNA_STRONG_PUNCH_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_STRONG_PUNCH_ACTIVE_START_FRAME := 22
const ARIANNA_STRONG_PUNCH_ACTIVE_END_FRAME := 27
const ARIANNA_STRONG_PUNCH_HITBOX_SIZE := Vector2(110.0, 65.0)
const ARIANNA_STRONG_PUNCH_HITBOX_POSITION := Vector2(100.0, -180.0)
const ARIANNA_CROUCHED_STRONG_PUNCH_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/strong-punch/strong-punch-crouched.png"
)
const ARIANNA_CROUCHED_STRONG_PUNCH_SOURCE_FRAME_COUNT := 49
const ARIANNA_CROUCHED_STRONG_PUNCH_COLUMNS := 7
const ARIANNA_CROUCHED_STRONG_PUNCH_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_CROUCHED_STRONG_PUNCH_SKIP_START := 21
const ARIANNA_CROUCHED_STRONG_PUNCH_SKIP_END := 34
const ARIANNA_CROUCHED_STRONG_PUNCH_FRAME_COUNT := 35
const ARIANNA_CROUCHED_STRONG_PUNCH_ACTIVE_START_FRAME := 7
const ARIANNA_CROUCHED_STRONG_PUNCH_ACTIVE_END_FRAME := 20
const ARIANNA_CROUCHED_STRONG_PUNCH_HITBOX_SIZE := Vector2(190.0, 100.0)
const ARIANNA_CROUCHED_STRONG_PUNCH_HITBOX_POSITION := Vector2(100.0, -165.0)
const ARIANNA_LIGHT_KICK_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/light-kick/light_kick.png"
)
const ARIANNA_LIGHT_KICK_COLUMNS := 5
const ARIANNA_LIGHT_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_LIGHT_KICK_SOURCE_START := 10
const ARIANNA_LIGHT_KICK_SOURCE_END := 22
const ARIANNA_LIGHT_KICK_ACTIVE_START_FRAME := 9
const ARIANNA_LIGHT_KICK_ACTIVE_END_FRAME := 12
const ARIANNA_LIGHT_KICK_HITBOX_SIZE := Vector2(165.0, 55.0)
const ARIANNA_LIGHT_KICK_HITBOX_POSITION := Vector2(110.0, -105.0)
const ARIANNA_LOW_LIGHT_KICK_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/light-kick/light_kick_low.png"
)
const ARIANNA_LOW_LIGHT_KICK_FRAME_COUNT := 21
const ARIANNA_LOW_LIGHT_KICK_COLUMNS := 7
const ARIANNA_LOW_LIGHT_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_LOW_LIGHT_KICK_ACTIVE_START_FRAME := 17
const ARIANNA_LOW_LIGHT_KICK_ACTIVE_END_FRAME := 20
const ARIANNA_LOW_LIGHT_KICK_HITBOX_SIZE := Vector2(210.0, 45.0)
const ARIANNA_LOW_LIGHT_KICK_HITBOX_POSITION := Vector2(110.0, -80.0)
const ARIANNA_MEDIUM_KICK_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/medium-kick/medium_kick.png"
)
const ARIANNA_MEDIUM_KICK_COLUMNS := 7
const ARIANNA_MEDIUM_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_MEDIUM_KICK_SOURCE_START := 7
const ARIANNA_MEDIUM_KICK_SOURCE_END := 27
const ARIANNA_MEDIUM_KICK_ACTIVE_START_FRAME := 17
const ARIANNA_MEDIUM_KICK_ACTIVE_END_FRAME := 20
const ARIANNA_MEDIUM_KICK_HITBOX_SIZE := Vector2(210.0, 55.0)
const ARIANNA_MEDIUM_KICK_HITBOX_POSITION := Vector2(110.0, -155.0)
const ARIANNA_LOW_MEDIUM_KICK_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/medium-kick/medium_kick_low.png"
)
const ARIANNA_LOW_MEDIUM_KICK_COLUMNS := 7
const ARIANNA_LOW_MEDIUM_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_LOW_MEDIUM_KICK_SOURCE_START := 7
const ARIANNA_LOW_MEDIUM_KICK_SOURCE_END := 20
const ARIANNA_LOW_MEDIUM_KICK_ACTIVE_START_FRAME := 10
const ARIANNA_LOW_MEDIUM_KICK_ACTIVE_END_FRAME := 13
const ARIANNA_LOW_MEDIUM_KICK_HITBOX_SIZE := Vector2(140.0, 45.0)
const ARIANNA_LOW_MEDIUM_KICK_HITBOX_POSITION := Vector2(115.0, -80.0)
const ARIANNA_STRONG_KICK_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/strong-kick/strong-kick.png"
)
const ARIANNA_STRONG_KICK_SOURCE_FRAME_COUNT := 36
const ARIANNA_STRONG_KICK_COLUMNS := 6
const ARIANNA_STRONG_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_STRONG_KICK_ACTIVE_START_FRAME := 14
const ARIANNA_STRONG_KICK_ACTIVE_END_FRAME := 20
const ARIANNA_STRONG_KICK_HITBOX_SIZE := Vector2(220.0, 70.0)
const ARIANNA_STRONG_KICK_HITBOX_POSITION := Vector2(115.0, -150.0)
const ARIANNA_LOW_STRONG_KICK_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/strong-kick/strong-kick-low.png"
)
const ARIANNA_LOW_STRONG_KICK_FRAME_COUNT := 49
const ARIANNA_LOW_STRONG_KICK_COLUMNS := 7
const ARIANNA_LOW_STRONG_KICK_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_LOW_STRONG_KICK_ACTIVE_START_FRAME := 14
const ARIANNA_LOW_STRONG_KICK_ACTIVE_END_FRAME := 34
const ARIANNA_LOW_STRONG_KICK_HITBOX_SIZE := Vector2(250.0, 60.0)
const ARIANNA_LOW_STRONG_KICK_HITBOX_POSITION := Vector2(125.0, -65.0)
const ARIANNA_JUMP_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/custom_jump.png"
)
const ARIANNA_JUMP_FRAME_COUNT := 49
const ARIANNA_JUMP_COLUMNS := 7
const ARIANNA_JUMP_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_JUMP_FPS := 32.0
const ARIANNA_JUMP_TAKEOFF_FRAME := 9 # Zero-based: 9 = fotogramma visibile 10.
const ARIANNA_JUMP_GRAVITY := 1800.0
const ARIANNA_AIR_COLLISION_SIZE := Vector2(120.0, 90.0)
# Il bordo inferiore resta a y=0 come nella collisione standing: cambiando
# profilo a stacco/atterraggio l'origine del fighter non scende né risale.
const ARIANNA_AIR_COLLISION_POSITION := Vector2(0.0, -45.0)
const ARIANNA_SPRITE_SCALE := Vector2(0.85, 0.85)
const ARIANNA_SPRITE_POSITION := Vector2(0.0, -120.0)

var light_punch_active := false
var jump_light_punch_active := false
var jump_medium_punch_active := false
var jump_strong_punch_active := false
var jump_light_kick_active := false
var jump_medium_kick_active := false
var jump_strong_kick_active := false
var baseball_special_active := false
var baseball_tornado_spawned := false
var baseball_special_strength: StringName = &"light"
var whistle_special_active := false
var whistle_frozen_target: Fighter
var whistle_target_controls_enabled := true
var whistle_target_can_move := true
var whistle_air_effect: CPUParticles2D
var whistle_audio_player: AudioStreamPlayer
var whistle_sound_played := false
var low_light_punch_active := false
var medium_punch_active := false
var low_medium_punch_active := false
var strong_punch_active := false
var crouched_strong_punch_active := false
var light_kick_active := false
var low_light_kick_active := false
var medium_kick_active := false
var low_medium_kick_active := false
var strong_kick_active := false
var low_strong_kick_active := false
var jump_facing_locked := false
var jump_rotation_finished := false
var jump_takeoff_armed := false
var jump_started_left_of_opponent := true
var run_direction := 1.0
var back_jump_active := false
var back_jump_start_x := 0.0
var back_jump_start_y := 0.0
var back_jump_direction := -1.0
var back_jump_elapsed := 0.0


func _ready() -> void:
	# La scena ereditata punta allo SpriteFrames di Mangler: duplicarlo evita che
	# Player 2 sovrascriva l'atlante idle di Arianna durante il proprio _ready().
	animated_sprite.sprite_frames = animated_sprite.sprite_frames.duplicate(true)
	super._ready()
	AnimationCatalog.new(self).configure_all()
	whistle_audio_player = AudioStreamPlayer.new()
	whistle_audio_player.name = "WhistleAudio"
	whistle_audio_player.stream = ARIANNA_WHISTLE_SOUND
	whistle_audio_player.volume_db = -2.0
	add_child(whistle_audio_player)
	_activate_idle()
	call_deferred("_activate_idle")


func _physics_process(_delta: float) -> void:
	if is_player_controlled:
		input_buffer.update(is_facing_right)
	if current_state == State.HIT:
		if not is_on_floor():
			velocity.y += ARIANNA_JUMP_GRAVITY * _delta
		elif velocity.y > 0.0:
			velocity.y = 0.0
		update_physical_collision()
		update_collision_profile()
		move_and_slide()
		position.x = clampf(position.x, stage_left_limit, stage_right_limit)
		update_facing_direction()
		update_ground_shadow()
		return
	if current_state in [
		State.SWEEP_KNOCKDOWN,
		State.KNOCKDOWN_RECOVERY,
		State.KNOCKED_DOWN,
	]:
		# Questi stati sono guidati da FighterCombat: la locomozione non deve
		# sovrascriverli con IDLE al frame fisico successivo all'impatto.
		velocity = Vector2.ZERO
		update_animation()
		update_physical_collision()
		update_collision_profile()
		move_and_slide()
		position.x = clampf(position.x, stage_left_limit, stage_right_limit)
		update_facing_direction()
		update_ground_shadow()
		return
	var opponent_is_attacking := (
		is_instance_valid(opponent)
		and opponent.combat != null
		and opponent.combat.is_attacking
	)
	if not back_jump_active and not is_on_floor():
		velocity.y += ARIANNA_JUMP_GRAVITY * _delta
	if back_jump_active:
		back_jump_elapsed = minf(back_jump_elapsed + _delta, ARIANNA_BACK_JUMP_DURATION)
		var movement_progress := back_jump_elapsed / ARIANNA_BACK_JUMP_DURATION
		var target_x := clampf(
			back_jump_start_x + back_jump_direction * ARIANNA_BACK_JUMP_DISTANCE,
			stage_left_limit,
			stage_right_limit
		)
		position.x = lerpf(back_jump_start_x, target_x, movement_progress)
		position.y = back_jump_start_y
		velocity.x = (
			back_jump_direction * ARIANNA_BACK_JUMP_SPEED
			if movement_progress < 1.0
			else 0.0
		)
		velocity.y = 0.0
		collision_layer = 0
		collision_mask = GROUND_COLLISION_LAYER
		if movement_progress >= 1.0:
			_finish_back_jump()
			update_ground_shadow()
			return
		update_facing_direction()
		update_ground_shadow()
		return
	if (
		jump_light_punch_active
		or jump_medium_punch_active
		or jump_strong_punch_active
		or jump_light_kick_active
		or jump_medium_kick_active
		or jump_strong_kick_active
	):
		update_physical_collision()
		update_collision_profile()
		move_and_slide()
		position.x = clampf(position.x, stage_left_limit, stage_right_limit)
		if is_on_floor():
			if jump_strong_kick_active:
				_finish_jump_strong_kick(true)
			elif jump_medium_kick_active:
				_finish_jump_medium_kick(true)
			elif jump_light_kick_active:
				_finish_jump_light_kick(true)
			elif jump_strong_punch_active:
				_finish_jump_strong_punch(true)
			elif jump_medium_punch_active:
				_finish_jump_medium_punch(true)
			else:
				_finish_jump_light_punch(true)
		else:
			update_facing_direction()
		update_ground_shadow()
		return
	if (
		whistle_special_active
		or baseball_special_active
		or light_punch_active
		or medium_punch_active
		or low_medium_punch_active
		or strong_punch_active
		or crouched_strong_punch_active
		or light_kick_active
		or medium_kick_active
		or strong_kick_active
	):
		velocity = Vector2.ZERO
		current_state = State.ATTACKING
		move_and_slide()
		position.x = clampf(position.x, stage_left_limit, stage_right_limit)
		update_facing_direction()
		update_ground_shadow()
		return
	if (
		controls_enabled
		and can_move
		and input_buffer != null
		and is_on_floor()
	):
		if _try_start_whistle_special():
			return
		if _try_start_baseball_special():
			return
	if controls_enabled and can_move and input_buffer != null and is_on_floor():
		var strong_kick_direction := input_buffer.consume_attack(&"heavy_kick")
		if strong_kick_direction != FighterInputBuffer.NO_DIRECTION:
			if input_buffer.is_down_held() or strong_kick_direction == FighterInputBuffer.Direction.DOWN:
				_start_low_strong_kick()
			else:
				_start_strong_kick()
			return
	if (
		controls_enabled
		and can_move
		and input_buffer != null
		and is_on_floor()
		and current_state not in [State.JUMP_STARTUP, State.JUMPING]
	):
		var medium_kick_direction := input_buffer.consume_attack(&"medium_kick")
		if medium_kick_direction != FighterInputBuffer.NO_DIRECTION:
			if input_buffer.is_down_held() or medium_kick_direction == FighterInputBuffer.Direction.DOWN:
				_start_low_medium_kick()
			else:
				_start_medium_kick()
			return
	if (
		controls_enabled
		and can_move
		and input_buffer != null
		and is_on_floor()
		and current_state not in [State.JUMP_STARTUP, State.JUMPING]
	):
		var light_kick_direction := input_buffer.consume_attack(&"light_kick")
		if light_kick_direction != FighterInputBuffer.NO_DIRECTION:
			if input_buffer.is_down_held() or light_kick_direction == FighterInputBuffer.Direction.DOWN:
				_start_low_light_kick()
			else:
				_start_light_kick()
			return
	if (
		controls_enabled
		and can_move
		and input_buffer != null
		and is_on_floor()
		and current_state not in [State.JUMP_STARTUP, State.JUMPING]
	):
		var strong_direction := input_buffer.consume_attack(&"heavy_punch")
		if strong_direction != FighterInputBuffer.NO_DIRECTION:
			if input_buffer.is_down_held() or strong_direction == FighterInputBuffer.Direction.DOWN:
				_start_crouched_strong_punch()
			else:
				_start_strong_punch()
			return
	if (
		controls_enabled
		and can_move
		and input_buffer != null
		and is_on_floor()
		and current_state not in [State.JUMP_STARTUP, State.JUMPING]
	):
		var medium_direction := input_buffer.consume_attack(&"medium_punch")
		if medium_direction != FighterInputBuffer.NO_DIRECTION:
			if input_buffer.is_down_held() or medium_direction == FighterInputBuffer.Direction.DOWN:
				_start_low_medium_punch()
			else:
				_start_medium_punch()
			return
	if current_state not in [State.BLOCKING, State.BLOCK_RECOVERY]:
		# Come Mangler, indietro prepara logicamente la parata prima dell'impatto;
		# l'animazione high viene però mostrata soltanto ad attacco già attivo.
		combat.set_guarding(
			controls_enabled
			and can_move
			and is_on_floor()
			and input_buffer.is_back_held()
		)
	if current_state in [State.BLOCKING, State.BLOCK_RECOVERY]:
		if input_buffer.is_back_just_pressed() and is_on_floor():
			var guard_back_tap_frame := Engine.get_physics_frames()
			if guard_back_tap_frame - last_back_tap_frame <= BACK_HOP_DOUBLE_TAP_WINDOW_FRAMES:
				combat.set_guarding(false)
				_start_back_jump()
				return
			last_back_tap_frame = guard_back_tap_frame
		if (
			current_state == State.BLOCKING
			and (not input_buffer.is_back_held() or not opponent_is_attacking)
		):
			combat.set_guarding(false)
			_start_guard_recovery()
		velocity = Vector2.ZERO
		update_physical_collision()
		update_collision_profile()
		move_and_slide()
		update_facing_direction()
		update_ground_shadow()
		return
	var light_punch_direction := FighterInputBuffer.NO_DIRECTION
	if (
		controls_enabled
		and can_move
		and input_buffer != null
		and is_on_floor()
		and current_state not in [State.JUMP_STARTUP, State.JUMPING]
	):
		light_punch_direction = input_buffer.consume_attack(&"light_punch")
		if light_punch_direction != FighterInputBuffer.NO_DIRECTION:
			if input_buffer.is_down_held() or light_punch_direction == FighterInputBuffer.Direction.DOWN:
				_start_low_light_punch()
			else:
				_start_light_punch()
			return
	var horizontal_axis := input_buffer.get_horizontal_axis() if input_buffer != null else 0.0
	if (
		controls_enabled
		and can_move
		and is_on_floor()
		and Input.is_action_just_pressed(get_input_action("jump"))
	):
		start_jump(horizontal_axis)
	if current_state in [State.JUMP_STARTUP, State.JUMPING]:
		var jump_strong_kick_direction := input_buffer.consume_attack(&"heavy_kick")
		if (
			current_state == State.JUMPING
			and jump_strong_kick_direction != FighterInputBuffer.NO_DIRECTION
			and not aerial_attack_used
		):
			_start_jump_strong_kick()
			return
		var jump_medium_kick_direction := input_buffer.consume_attack(&"medium_kick")
		if (
			current_state == State.JUMPING
			and jump_medium_kick_direction != FighterInputBuffer.NO_DIRECTION
			and not aerial_attack_used
		):
			_start_jump_medium_kick()
			return
		var jump_light_kick_direction := input_buffer.consume_attack(&"light_kick")
		if (
			current_state == State.JUMPING
			and jump_light_kick_direction != FighterInputBuffer.NO_DIRECTION
			and not aerial_attack_used
		):
			_start_jump_light_kick()
			return
		var jump_strong_punch_direction := input_buffer.consume_attack(&"heavy_punch")
		if (
			current_state == State.JUMPING
			and jump_strong_punch_direction != FighterInputBuffer.NO_DIRECTION
			and not aerial_attack_used
		):
			_start_jump_strong_punch()
			return
		var jump_medium_punch_direction := input_buffer.consume_attack(&"medium_punch")
		if (
			current_state == State.JUMPING
			and jump_medium_punch_direction != FighterInputBuffer.NO_DIRECTION
			and not aerial_attack_used
		):
			_start_jump_medium_punch()
			return
		var jump_light_punch_direction := input_buffer.consume_attack(&"light_punch")
		if (
			current_state == State.JUMPING
			and jump_light_punch_direction != FighterInputBuffer.NO_DIRECTION
			and not aerial_attack_used
		):
			_start_jump_light_punch()
			return
		update_physical_collision()
		update_collision_profile()
		var was_jumping := current_state in [State.JUMP_STARTUP, State.JUMPING]
		move_and_slide()
		position.x = clampf(position.x, stage_left_limit, stage_right_limit)
		update_state()
		update_physical_collision()
		update_collision_profile()
		if was_jumping and current_state not in [State.JUMP_STARTUP, State.JUMPING]:
			jump_rotation_finished = true
		_update_jump_facing()
		update_ground_shadow()
		return
	if (
		input_buffer.is_down_held()
		and input_buffer.is_back_held()
		and is_on_floor()
		and opponent_is_attacking
		and _get_incoming_guard_height() == AttackData.HitHeight.LOW
	):
		_start_guard_for_incoming_attack()
		return
	if input_buffer.is_down_held() and is_on_floor():
		if current_state != State.CROUCHING:
			change_state(State.CROUCHING)
		velocity = Vector2.ZERO
		update_physical_collision()
		update_collision_profile()
		move_and_slide()
		update_facing_direction()
		update_ground_shadow()
		return
	if current_state == State.CROUCHING:
		_start_crouch_recovery()
	if current_state == State.STANDING_UP and animated_sprite.animation == &"arianna_crouch_recovery":
		velocity = Vector2.ZERO
		update_physical_collision()
		update_collision_profile()
		move_and_slide()
		update_facing_direction()
		update_ground_shadow()
		return
	if is_on_floor() and input_buffer.is_back_just_pressed():
		var current_frame := Engine.get_physics_frames()
		if current_frame - last_back_tap_frame <= BACK_HOP_DOUBLE_TAP_WINDOW_FRAMES:
			_start_back_jump()
		last_back_tap_frame = current_frame
	if back_jump_active:
		return
	if (
		controls_enabled
		and can_move
		and is_on_floor()
		and input_buffer.is_back_held()
		and opponent_is_attacking
	):
		_start_guard_for_incoming_attack()
		return
	if is_on_floor() and input_buffer.is_forward_just_pressed():
		var current_frame := Engine.get_physics_frames()
		if current_frame - last_forward_tap_frame <= RUN_DOUBLE_TAP_WINDOW_FRAMES:
			_start_run()
		last_forward_tap_frame = current_frame
	if current_state == State.RUNNING:
		velocity.x = (
			run_direction * character_data.run_speed * ARIANNA_RUN_SPEED_MULTIPLIER
		)
		if is_on_floor():
			velocity.y = 0.0
		update_physical_collision()
		update_collision_profile()
		move_and_slide()
		position.x = clampf(position.x, stage_left_limit, stage_right_limit)
		var reached_stage_edge := (
			(run_direction < 0.0 and is_equal_approx(position.x, stage_left_limit))
			or (run_direction > 0.0 and is_equal_approx(position.x, stage_right_limit))
		)
		if _has_run_collision() or reached_stage_edge:
			velocity = Vector2.ZERO
			change_state(State.IDLE)
		else:
			if animated_sprite.animation != &"run" or not animated_sprite.is_playing():
				animated_sprite.play(&"run")
		update_facing_direction()
		update_ground_shadow()
		return
	var walking_forward := controls_enabled and can_move and is_forward_input(horizontal_axis)
	var walking_backward := controls_enabled and can_move and is_backward_input(horizontal_axis)
	var is_walking := walking_forward or walking_backward
	velocity.x = (
		signf(horizontal_axis) * character_data.walk_speed
		if is_walking
		else 0.0
	)
	# Finché Godot non conferma il contatto, conserva la piccola velocità di
	# gravità necessaria a registrare il pavimento tramite move_and_slide().
	if is_on_floor():
		velocity.y = 0.0
	current_state = State.WALKING if is_walking else State.IDLE
	update_physical_collision()
	update_collision_profile()
	move_and_slide()
	position.x = clampf(position.x, stage_left_limit, stage_right_limit)
	var desired_animation: StringName = (
		&"walk" if walking_forward else (&"backwalk" if walking_backward else &"idle")
	)
	if animated_sprite.animation != desired_animation or not animated_sprite.is_playing():
		animated_sprite.play(desired_animation)
	update_facing_direction()
	update_ground_shadow()


func _activate_idle() -> void:
	animated_sprite.position = ARIANNA_SPRITE_POSITION
	animated_sprite.scale = ARIANNA_SPRITE_SCALE
	animated_sprite.play(&"idle")


func update_sprite_scale() -> void:
	animated_sprite.scale = (
		ARIANNA_JUMP_LIGHT_PUNCH_SPRITE_SCALE
		if animated_sprite.animation == &"arianna_jump_light_punch"
		else (
			ARIANNA_JUMP_MEDIUM_PUNCH_SPRITE_SCALE
			if animated_sprite.animation == &"arianna_jump_medium_punch"
			else (
				ARIANNA_JUMP_STRONG_PUNCH_SPRITE_SCALE
				if animated_sprite.animation == &"arianna_jump_strong_punch"
				else (
					ARIANNA_JUMP_LIGHT_KICK_SPRITE_SCALE
					if animated_sprite.animation == &"arianna_jump_light_kick"
					else (
						ARIANNA_JUMP_MEDIUM_KICK_SPRITE_SCALE
						if animated_sprite.animation == &"arianna_jump_medium_kick"
						else (
							ARIANNA_JUMP_STRONG_KICK_SPRITE_SCALE
							if animated_sprite.animation == &"arianna_jump_strong_kick"
							else ARIANNA_SPRITE_SCALE
						)
					)
				)
			)
		)
	)
	animated_sprite.position = ARIANNA_SPRITE_POSITION
	grab_front_sprite.scale = ARIANNA_SPRITE_SCALE
	grab_front_sprite.position = ARIANNA_SPRITE_POSITION


## Lo slicing degli atlas è gestito da AriannaAnimationCatalog.


func start_hit_reaction(
	hit_height: AttackData.HitHeight,
	attacker: Fighter,
	start_frame: int = 0,
	apply_pushback: bool = true
) -> float:
	if hit_height in [
		AttackData.HitHeight.LOW,
		AttackData.HitHeight.MID,
		AttackData.HitHeight.HIGH,
	]:
		# Le reazioni custom di Arianna riproducono sempre la sequenza completa.
		start_frame = 0
	var reaction_duration := super.start_hit_reaction(
		hit_height, attacker, start_frame, apply_pushback
	)
	if hit_height == AttackData.HitHeight.MID and apply_pushback:
		velocity.x *= ARIANNA_HURT_MEDIUM_PUSHBACK_MULTIPLIER
	return reaction_duration


func get_sweep_grounded_hold_duration() -> float:
	# Il foglio termina già nella posa a terra: la recovery parte subito dopo.
	return 0.0


func begin_jump_ascent() -> void:
	if (
		current_state != State.JUMP_STARTUP
		or not jump_takeoff_armed
		or animated_sprite.frame < ARIANNA_JUMP_TAKEOFF_FRAME
	):
		return
	velocity = Vector2(
		pending_jump_direction * character_data.air_speed * pending_jump_horizontal_multiplier,
		character_data.jump_velocity
	)
	change_state(State.JUMPING)


func start_jump(horizontal_direction: float) -> void:
	jump_facing_locked = true
	jump_rotation_finished = false
	jump_takeoff_armed = false
	if is_instance_valid(opponent):
		jump_started_left_of_opponent = global_position.x < opponent.global_position.x
	super.start_jump(horizontal_direction)
	animated_sprite.frame = 0
	jump_takeoff_armed = true


func update_animation() -> void:
	if (
		current_state == State.JUMPING
		and animated_sprite.animation == &"jump"
		and (
			animated_sprite.frame == ARIANNA_JUMP_FRAME_COUNT - 1
			and not animated_sprite.is_playing()
		)
	):
		return
	super.update_animation()


func _start_run() -> void:
	run_direction = 1.0 if is_facing_right else -1.0
	velocity = Vector2(
		run_direction * character_data.run_speed * ARIANNA_RUN_SPEED_MULTIPLIER,
		0.0
	)
	change_state(State.RUNNING)


func _start_back_jump() -> void:
	back_jump_active = true
	back_jump_start_x = position.x
	back_jump_start_y = position.y
	back_jump_elapsed = 0.0
	back_jump_direction = -1.0 if is_facing_right else 1.0
	velocity = Vector2(
		back_jump_direction * ARIANNA_BACK_JUMP_SPEED,
		0.0
	)
	change_state(State.BACK_HOP)
	animated_sprite.play(&"arianna_back_jump")


func _finish_back_jump() -> void:
	position.x = clampf(
		back_jump_start_x + back_jump_direction * ARIANNA_BACK_JUMP_DISTANCE,
		stage_left_limit,
		stage_right_limit
	)
	position.y = back_jump_start_y
	back_jump_active = false
	back_jump_elapsed = 0.0
	velocity = Vector2.ZERO
	update_physical_collision()
	update_collision_profile()
	change_state(State.IDLE)


func _start_crouch_recovery() -> void:
	var previous_state := current_state
	current_state = State.STANDING_UP
	can_move = false
	velocity = Vector2.ZERO
	animated_sprite.play(&"arianna_crouch_recovery")
	update_collision_profile()
	state_changed.emit(previous_state, current_state)


func _start_guard_for_incoming_attack() -> void:
	received_block_height = _get_incoming_guard_height()
	block_started_crouched = input_buffer.is_down_held()
	combat.set_guarding(true)
	change_state(State.BLOCKING)


func _get_incoming_guard_height() -> AttackData.HitHeight:
	if (
		is_instance_valid(opponent)
		and opponent.combat != null
		and opponent.combat.current_attack != null
	):
		return opponent.combat.get_effective_hit_height(opponent.combat.current_attack)
	return AttackData.HitHeight.HIGH


func _start_guard_recovery() -> void:
	change_state(State.BLOCK_RECOVERY)


func get_crouch_progress() -> float:
	if animated_sprite.animation == &"arianna_crouch_recovery":
		var final_frame := animated_sprite.sprite_frames.get_frame_count(
			&"arianna_crouch_recovery"
		) - 1
		if final_frame <= 0:
			return 0.0
		return 1.0 - clampf(float(animated_sprite.frame) / float(final_frame), 0.0, 1.0)
	return super.get_crouch_progress()


func _has_run_collision() -> bool:
	for collision_index in range(get_slide_collision_count()):
		var collision := get_slide_collision(collision_index)
		if collision.get_collider() is Fighter or absf(collision.get_normal().x) > 0.5:
			return true
	return false


func _update_jump_facing() -> void:
	if not jump_facing_locked or not jump_rotation_finished:
		return
	if not is_instance_valid(opponent):
		jump_facing_locked = false
		return
	var has_crossed_opponent := (
		global_position.x > opponent.global_position.x
		if jump_started_left_of_opponent
		else global_position.x < opponent.global_position.x
	)
	if has_crossed_opponent:
		update_facing_direction()
	if current_state not in [State.JUMP_STARTUP, State.JUMPING] or has_crossed_opponent:
		jump_facing_locked = false


func update_collision_profile() -> void:
	# `is_on_floor()` è false nei primissimi frame di caricamento, prima che
	# CharacterBody2D abbia eseguito move_and_slide(). Usarlo qui ridurrebbe la
	# pushbox già in idle e lascerebbe Arianna sospesa sopra il pavimento.
	var is_airborne := (
		current_state == State.JUMPING
		or jump_light_punch_active
		or jump_medium_punch_active
		or jump_strong_punch_active
		or jump_light_kick_active
		or jump_medium_kick_active
		or jump_strong_kick_active
	)
	if is_airborne:
		set_box_profile(
			collision_shape,
			ARIANNA_AIR_COLLISION_SIZE,
			ARIANNA_AIR_COLLISION_POSITION
		)
		return
	super.update_collision_profile()


func _start_baseball_special(strength: StringName = &"light") -> void:
	baseball_special_active = true
	baseball_tornado_spawned = false
	baseball_special_strength = strength
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.disable_hitbox()
	combat.is_attacking = true
	combat.current_attack = null
	combat.current_variant = null
	combat.hit_targets.clear()
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_baseball_special")


func _try_start_whistle_special() -> bool:
	var has_complete_half_circle := input_buffer.matches_recent_sequence([
		FighterInputBuffer.Direction.BACK,
		FighterInputBuffer.Direction.DOWN_BACK,
		FighterInputBuffer.Direction.DOWN,
		FighterInputBuffer.Direction.DOWN_FORWARD,
		FighterInputBuffer.Direction.FORWARD,
	], ARIANNA_WHISTLE_MOTION_WINDOW_FRAMES)
	var has_diagonal_finish := input_buffer.matches_recent_sequence([
		FighterInputBuffer.Direction.BACK,
		FighterInputBuffer.Direction.DOWN_BACK,
		FighterInputBuffer.Direction.DOWN,
		FighterInputBuffer.Direction.DOWN_FORWARD,
	], ARIANNA_WHISTLE_MOTION_WINDOW_FRAMES)
	var has_lenient_start := input_buffer.matches_recent_sequence([
		FighterInputBuffer.Direction.DOWN_BACK,
		FighterInputBuffer.Direction.DOWN,
		FighterInputBuffer.Direction.DOWN_FORWARD,
		FighterInputBuffer.Direction.FORWARD,
	], ARIANNA_WHISTLE_MOTION_WINDOW_FRAMES)
	if not has_complete_half_circle and not has_diagonal_finish and not has_lenient_start:
		return false
	var chord_direction := input_buffer.consume_attack_chord([
		&"light_kick", &"medium_kick"
	], FighterInputBuffer.DEFAULT_ATTACK_BUFFER_FRAMES, ARIANNA_WHISTLE_CHORD_WINDOW_FRAMES)
	if chord_direction not in [
		FighterInputBuffer.Direction.DOWN_FORWARD,
		FighterInputBuffer.Direction.FORWARD,
	]:
		return false
	input_buffer.clear()
	_start_whistle_special()
	return true


func _start_whistle_special() -> void:
	_stop_whistle_air_effect(true)
	whistle_sound_played = false
	if is_instance_valid(whistle_audio_player):
		whistle_audio_player.stop()
	whistle_special_active = true
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.disable_hitbox()
	combat.is_attacking = true
	combat.current_attack = null
	combat.current_variant = null
	combat.hit_targets.clear()
	bring_attacker_to_foreground()
	_hold_whistle_opponent_idle()
	animated_sprite.play(&"arianna_whistle_special")


func _hold_whistle_opponent_idle() -> void:
	whistle_frozen_target = null
	if not is_instance_valid(opponent) or opponent.combat == null:
		return
	var opponent_is_guarding := (
		opponent.combat.is_blocking
		or opponent.current_state in [State.BLOCKING, State.BLOCK_RECOVERY]
	)
	if opponent_is_guarding:
		return
	whistle_frozen_target = opponent
	whistle_target_controls_enabled = opponent.controls_enabled
	whistle_target_can_move = opponent.can_move
	opponent.combat.cancel_current_action()
	opponent.controls_enabled = false
	opponent.change_state(State.IDLE)
	opponent.can_move = false
	opponent.velocity = Vector2.ZERO


func _finish_whistle_special() -> void:
	var whistle_completed := (
		animated_sprite.animation == &"arianna_whistle_special"
		and animated_sprite.frame >= ARIANNA_WHISTLE_SPECIAL_FRAME_COUNT - 1
	)
	_stop_whistle_air_effect()
	combat.disable_hitbox()
	combat.is_attacking = false
	combat.current_attack = null
	combat.current_variant = null
	combat.hit_targets.clear()
	restore_default_render_order()
	whistle_special_active = false
	velocity = Vector2.ZERO
	if is_instance_valid(whistle_frozen_target):
		whistle_frozen_target.change_state(State.IDLE)
		whistle_frozen_target.controls_enabled = whistle_target_controls_enabled
		whistle_frozen_target.can_move = whistle_target_can_move
	whistle_frozen_target = null
	if whistle_completed:
		_spawn_bateau_projectile()
	change_state(State.IDLE)


func _spawn_bateau_projectile() -> AriannaBateauProjectile:
	if not is_instance_valid(opponent):
		return null
	var bateau := BateauProjectile.new() as AriannaBateauProjectile
	bateau.setup(self, opponent)
	var projectile_parent: Node = get_tree().current_scene
	if projectile_parent == null:
		projectile_parent = get_tree().root
	projectile_parent.add_child(bateau)
	var spawn_x := (
		stage_left_limit - AriannaBateauProjectile.OFFSCREEN_MARGIN
		if bateau.travel_direction > 0.0
		else stage_right_limit + AriannaBateauProjectile.OFFSCREEN_MARGIN
	)
	bateau.global_position = Vector2(spawn_x, global_position.y)
	return bateau


func _start_whistle_air_effect() -> CPUParticles2D:
	if is_instance_valid(whistle_air_effect):
		return whistle_air_effect
	var facing_sign := 1.0 if is_facing_right else -1.0
	var air := CPUParticles2D.new()
	air.name = "WhistleAir"
	air.add_to_group("arianna_whistle_air")
	air.position = Vector2(
		ARIANNA_WHISTLE_AIR_MOUTH_OFFSET.x * facing_sign,
		ARIANNA_WHISTLE_AIR_MOUTH_OFFSET.y
	)
	air.amount = 14
	air.lifetime = 0.32
	air.preprocess = 0.08
	air.direction = Vector2(facing_sign, -0.02).normalized()
	air.spread = 7.0
	air.gravity = Vector2.ZERO
	air.initial_velocity_min = 82.0
	air.initial_velocity_max = 132.0
	air.scale_amount_min = 0.42
	air.scale_amount_max = 1.15
	air.color = Color(0.86, 0.95, 1.0, 0.30)
	air.texture = _create_whistle_air_texture()
	air.z_index = animated_sprite.z_index + 2
	add_child(air)
	air.emitting = true
	whistle_air_effect = air
	return air


func _stop_whistle_air_effect(immediate: bool = false) -> void:
	if not is_instance_valid(whistle_air_effect):
		whistle_air_effect = null
		return
	var air := whistle_air_effect
	whistle_air_effect = null
	air.emitting = false
	if immediate or not is_inside_tree():
		air.queue_free()
	else:
		get_tree().create_timer(air.lifetime).timeout.connect(air.queue_free)


func _create_whistle_air_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.94, 0.99, 1.0, 0.42),
		Color(0.68, 0.88, 1.0, 0.16),
		Color(0.46, 0.72, 1.0, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.48, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 38
	texture.height = 9
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.35, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _try_start_baseball_special() -> bool:
	var has_complete_quarter_circle := input_buffer.matches_recent_sequence([
		FighterInputBuffer.Direction.DOWN,
		FighterInputBuffer.Direction.DOWN_FORWARD,
		FighterInputBuffer.Direction.FORWARD,
	])
	var has_diagonal_finish := input_buffer.matches_recent_sequence([
		FighterInputBuffer.Direction.DOWN,
		FighterInputBuffer.Direction.DOWN_FORWARD,
	])
	if not has_complete_quarter_circle and not has_diagonal_finish:
		return false
	var selected_strength: StringName = &""
	for attack_entry in [
		[&"heavy_punch", &"heavy"],
		[&"medium_punch", &"medium"],
		[&"light_punch", &"light"],
	]:
		var attack_direction := input_buffer.consume_attack(attack_entry[0])
		if attack_direction in [
			FighterInputBuffer.Direction.DOWN_FORWARD,
			FighterInputBuffer.Direction.FORWARD,
		]:
			selected_strength = attack_entry[1]
			break
	if selected_strength == &"":
		return false
	input_buffer.clear()
	_start_baseball_special(selected_strength)
	return true


func _finish_baseball_special() -> void:
	combat.disable_hitbox()
	combat.is_attacking = false
	combat.current_attack = null
	combat.current_variant = null
	combat.hit_targets.clear()
	restore_default_render_order()
	baseball_special_active = false
	baseball_tornado_spawned = false
	baseball_special_strength = &"light"
	velocity = Vector2.ZERO
	change_state(State.IDLE)


func _spawn_baseball_tornado() -> AriannaTornadoProjectile:
	var tornado := AriannaTornadoProjectile.new()
	tornado.setup(self, is_facing_right, baseball_special_strength)
	var projectile_parent: Node = get_tree().current_scene
	if projectile_parent == null:
		projectile_parent = get_tree().root
	projectile_parent.add_child(tornado)
	var facing_sign := 1.0 if is_facing_right else -1.0
	tornado.global_position = global_position + Vector2(
		ARIANNA_BASEBALL_TORNADO_SPAWN_OFFSET.x * facing_sign,
		ARIANNA_BASEBALL_TORNADO_SPAWN_OFFSET.y
	)
	baseball_tornado_spawned = true
	return tornado


func _start_light_punch() -> void:
	var attack := character_data.get_attack(&"light_punch")
	if attack == null:
		return
	light_punch_active = true
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.is_attacking = true
	combat.current_attack = attack
	combat.current_variant = null
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_LIGHT_PUNCH_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_LIGHT_PUNCH_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_light_punch")


func _start_jump_light_punch() -> void:
	var attack := character_data.get_attack(&"light_punch")
	if attack == null:
		return
	jump_light_punch_active = true
	aerial_attack_used = true
	current_state = State.ATTACKING
	combat.action_generation += 1
	combat.is_attacking = true
	combat.is_airborne_light_punch = true
	combat.current_attack = attack
	combat.current_variant = null
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_JUMP_LIGHT_PUNCH_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_JUMP_LIGHT_PUNCH_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_jump_light_punch")
	animated_sprite.scale = ARIANNA_JUMP_LIGHT_PUNCH_SPRITE_SCALE


func _resolve_jump_light_punch_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not jump_light_punch_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _finish_jump_light_punch(landed: bool) -> void:
	combat.disable_hitbox()
	combat.is_attacking = false
	combat.is_airborne_light_punch = false
	combat.current_attack = null
	combat.current_variant = null
	combat.hit_targets.clear()
	restore_default_render_order()
	jump_light_punch_active = false
	animated_sprite.scale = ARIANNA_SPRITE_SCALE
	if landed or is_on_floor():
		velocity = Vector2.ZERO
		change_state(State.IDLE)
		return
	change_state(State.JUMPING)
	animated_sprite.play(&"jump")
	animated_sprite.frame = ARIANNA_JUMP_LIGHT_PUNCH_RESUME_JUMP_FRAME


func _start_jump_medium_punch() -> void:
	var attack := character_data.get_attack(&"medium_punch")
	if attack == null:
		return
	jump_medium_punch_active = true
	aerial_attack_used = true
	current_state = State.ATTACKING
	combat.action_generation += 1
	combat.is_attacking = true
	combat.is_airborne_medium_punch = true
	combat.current_attack = attack
	combat.current_variant = null
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_JUMP_MEDIUM_PUNCH_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_JUMP_MEDIUM_PUNCH_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.scale = ARIANNA_JUMP_MEDIUM_PUNCH_SPRITE_SCALE
	animated_sprite.play(&"arianna_jump_medium_punch")


func _resolve_jump_medium_punch_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not jump_medium_punch_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _finish_jump_medium_punch(landed: bool) -> void:
	combat.disable_hitbox()
	combat.is_attacking = false
	combat.is_airborne_medium_punch = false
	combat.current_attack = null
	combat.current_variant = null
	combat.hit_targets.clear()
	restore_default_render_order()
	jump_medium_punch_active = false
	animated_sprite.scale = ARIANNA_SPRITE_SCALE
	if landed or is_on_floor():
		velocity = Vector2.ZERO
		change_state(State.IDLE)
		return
	change_state(State.JUMPING)
	animated_sprite.play(&"jump")
	animated_sprite.frame = ARIANNA_JUMP_MEDIUM_PUNCH_RESUME_JUMP_FRAME


func _start_jump_strong_punch() -> void:
	var attack := character_data.get_attack(&"heavy_punch")
	if attack == null:
		return
	jump_strong_punch_active = true
	aerial_attack_used = true
	current_state = State.ATTACKING
	combat.action_generation += 1
	combat.is_attacking = true
	combat.is_airborne_heavy_punch = true
	combat.current_attack = attack
	combat.current_variant = null
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_JUMP_STRONG_PUNCH_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_JUMP_STRONG_PUNCH_HITBOX_POSITION
	combat.hitbox_shape.rotation = ARIANNA_JUMP_STRONG_PUNCH_HITBOX_ROTATION
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_jump_strong_punch")


func _resolve_jump_strong_punch_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not jump_strong_punch_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _finish_jump_strong_punch(landed: bool) -> void:
	combat.disable_hitbox()
	combat.is_attacking = false
	combat.is_airborne_heavy_punch = false
	combat.current_attack = null
	combat.current_variant = null
	combat.hit_targets.clear()
	restore_default_render_order()
	jump_strong_punch_active = false
	animated_sprite.scale = ARIANNA_SPRITE_SCALE
	combat.hitbox_shape.rotation = 0.0
	if landed or is_on_floor():
		velocity = Vector2.ZERO
		change_state(State.IDLE)
		return
	change_state(State.JUMPING)
	animated_sprite.play(&"jump")
	animated_sprite.frame = ARIANNA_JUMP_STRONG_PUNCH_RESUME_JUMP_FRAME


func _start_jump_light_kick() -> void:
	var attack := character_data.get_attack(&"light_kick")
	if attack == null:
		return
	jump_light_kick_active = true
	aerial_attack_used = true
	current_state = State.ATTACKING
	combat.action_generation += 1
	combat.is_attacking = true
	combat.is_airborne_light_kick = true
	combat.current_attack = attack
	var middle_variant := AttackVariantData.new()
	middle_variant.variant_id = &"arianna_airborne"
	middle_variant.animation_name = &"arianna_jump_light_kick"
	middle_variant.hit_height = AttackData.HitHeight.MID
	combat.current_variant = middle_variant
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_JUMP_LIGHT_KICK_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_JUMP_LIGHT_KICK_HITBOX_POSITION
	combat.hitbox_shape.rotation = ARIANNA_JUMP_LIGHT_KICK_HITBOX_ROTATION
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_jump_light_kick")


func _resolve_jump_light_kick_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not jump_light_kick_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _finish_jump_light_kick(landed: bool) -> void:
	combat.disable_hitbox()
	combat.is_attacking = false
	combat.is_airborne_light_kick = false
	combat.current_attack = null
	combat.current_variant = null
	combat.hit_targets.clear()
	restore_default_render_order()
	jump_light_kick_active = false
	animated_sprite.scale = ARIANNA_SPRITE_SCALE
	combat.hitbox_shape.rotation = 0.0
	if landed or is_on_floor():
		velocity = Vector2.ZERO
		change_state(State.IDLE)
		return
	change_state(State.JUMPING)
	animated_sprite.play(&"jump")
	animated_sprite.frame = ARIANNA_JUMP_LIGHT_KICK_RESUME_JUMP_FRAME


func _start_jump_medium_kick() -> void:
	var attack := character_data.get_attack(&"medium_kick")
	if attack == null:
		return
	jump_medium_kick_active = true
	aerial_attack_used = true
	current_state = State.ATTACKING
	combat.action_generation += 1
	combat.is_attacking = true
	combat.is_airborne_medium_kick = true
	combat.current_attack = attack
	var high_variant := AttackVariantData.new()
	high_variant.variant_id = &"arianna_airborne"
	high_variant.animation_name = &"arianna_jump_medium_kick"
	high_variant.hit_height = AttackData.HitHeight.HIGH
	combat.current_variant = high_variant
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_JUMP_MEDIUM_KICK_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_JUMP_MEDIUM_KICK_HITBOX_POSITION
	combat.hitbox_shape.rotation = ARIANNA_JUMP_MEDIUM_KICK_HITBOX_ROTATION
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_jump_medium_kick")
	animated_sprite.scale = ARIANNA_JUMP_MEDIUM_KICK_SPRITE_SCALE


func _resolve_jump_medium_kick_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not jump_medium_kick_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _finish_jump_medium_kick(landed: bool) -> void:
	combat.disable_hitbox()
	combat.is_attacking = false
	combat.is_airborne_medium_kick = false
	combat.current_attack = null
	combat.current_variant = null
	combat.hit_targets.clear()
	restore_default_render_order()
	jump_medium_kick_active = false
	animated_sprite.scale = ARIANNA_SPRITE_SCALE
	combat.hitbox_shape.rotation = 0.0
	if landed or is_on_floor():
		velocity = Vector2.ZERO
		change_state(State.IDLE)
		return
	change_state(State.JUMPING)
	animated_sprite.play(&"jump")
	animated_sprite.frame = ARIANNA_JUMP_MEDIUM_KICK_RESUME_JUMP_FRAME


func _start_jump_strong_kick() -> void:
	var attack := character_data.get_attack(&"heavy_kick")
	if attack == null:
		return
	jump_strong_kick_active = true
	aerial_attack_used = true
	current_state = State.ATTACKING
	combat.action_generation += 1
	combat.is_attacking = true
	combat.is_airborne_heavy_kick = true
	combat.current_attack = attack
	var high_variant := AttackVariantData.new()
	high_variant.variant_id = &"arianna_airborne"
	high_variant.animation_name = &"arianna_jump_strong_kick"
	high_variant.hit_height = AttackData.HitHeight.HIGH
	combat.current_variant = high_variant
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_JUMP_STRONG_KICK_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_JUMP_STRONG_KICK_HITBOX_POSITION
	combat.hitbox_shape.rotation = ARIANNA_JUMP_STRONG_KICK_HITBOX_ROTATION
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_jump_strong_kick")
	animated_sprite.scale = ARIANNA_JUMP_STRONG_KICK_SPRITE_SCALE


func _resolve_jump_strong_kick_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not jump_strong_kick_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _finish_jump_strong_kick(landed: bool) -> void:
	combat.disable_hitbox()
	combat.is_attacking = false
	combat.is_airborne_heavy_kick = false
	combat.current_attack = null
	combat.current_variant = null
	combat.hit_targets.clear()
	restore_default_render_order()
	jump_strong_kick_active = false
	animated_sprite.scale = ARIANNA_SPRITE_SCALE
	combat.hitbox_shape.rotation = 0.0
	if landed or is_on_floor():
		velocity = Vector2.ZERO
		change_state(State.IDLE)
		return
	change_state(State.JUMPING)
	animated_sprite.play(&"jump")
	animated_sprite.frame = ARIANNA_JUMP_STRONG_KICK_RESUME_JUMP_FRAME


func _start_low_light_punch() -> void:
	var attack := character_data.get_attack(&"light_punch")
	if attack == null:
		return
	light_punch_active = true
	low_light_punch_active = true
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.is_attacking = true
	combat.is_crouched_light_punch = false
	combat.current_attack = attack
	var middle_variant := AttackVariantData.new()
	middle_variant.variant_id = &"arianna_low"
	middle_variant.animation_name = &"arianna_low_light_punch"
	middle_variant.hit_height = AttackData.HitHeight.MID
	combat.current_variant = middle_variant
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_LOW_LIGHT_PUNCH_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_LOW_LIGHT_PUNCH_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_low_light_punch")


func _resolve_low_light_punch_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not low_light_punch_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _start_medium_punch() -> void:
	var attack := character_data.get_attack(&"medium_punch")
	if attack == null:
		return
	medium_punch_active = true
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.is_attacking = true
	combat.current_attack = attack
	combat.current_variant = null
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_MEDIUM_PUNCH_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_MEDIUM_PUNCH_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_medium_punch")


func _resolve_medium_punch_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not medium_punch_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _start_low_medium_punch() -> void:
	var attack := character_data.get_attack(&"medium_punch")
	if attack == null:
		return
	low_medium_punch_active = true
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.is_attacking = true
	combat.current_attack = attack
	var middle_variant := AttackVariantData.new()
	middle_variant.variant_id = &"arianna_low"
	middle_variant.animation_name = &"arianna_low_medium_punch"
	middle_variant.hit_height = AttackData.HitHeight.MID
	combat.current_variant = middle_variant
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_LOW_MEDIUM_PUNCH_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_LOW_MEDIUM_PUNCH_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_low_medium_punch")


func _resolve_low_medium_punch_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not low_medium_punch_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _start_strong_punch() -> void:
	var attack := character_data.get_attack(&"heavy_punch")
	if attack == null:
		return
	strong_punch_active = true
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.is_attacking = true
	combat.current_attack = attack
	var high_variant := AttackVariantData.new()
	high_variant.variant_id = &"arianna_standing"
	high_variant.animation_name = &"arianna_strong_punch"
	high_variant.hit_height = AttackData.HitHeight.HIGH
	combat.current_variant = high_variant
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_STRONG_PUNCH_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_STRONG_PUNCH_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_strong_punch")


func _resolve_strong_punch_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not strong_punch_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _start_crouched_strong_punch() -> void:
	var attack := character_data.get_attack(&"heavy_punch")
	if attack == null:
		return
	crouched_strong_punch_active = true
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.is_attacking = true
	combat.current_attack = attack
	var high_variant := AttackVariantData.new()
	high_variant.variant_id = &"arianna_crouched"
	high_variant.animation_name = &"arianna_crouched_strong_punch"
	high_variant.hit_height = AttackData.HitHeight.HIGH
	combat.current_variant = high_variant
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_CROUCHED_STRONG_PUNCH_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_CROUCHED_STRONG_PUNCH_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_crouched_strong_punch")


func _start_light_kick() -> void:
	var attack := character_data.get_attack(&"light_kick")
	if attack == null:
		return
	light_kick_active = true
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.is_attacking = true
	combat.current_attack = attack
	var middle_variant := AttackVariantData.new()
	middle_variant.variant_id = &"arianna_standing"
	middle_variant.animation_name = &"arianna_light_kick"
	middle_variant.hit_height = AttackData.HitHeight.MID
	combat.current_variant = middle_variant
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_LIGHT_KICK_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_LIGHT_KICK_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_light_kick")


func _resolve_light_kick_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not light_kick_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _start_low_light_kick() -> void:
	var attack := character_data.get_attack(&"light_kick")
	if attack == null:
		return
	light_kick_active = true
	low_light_kick_active = true
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.is_attacking = true
	combat.current_attack = attack
	var low_variant := AttackVariantData.new()
	low_variant.variant_id = &"arianna_low"
	low_variant.animation_name = &"arianna_low_light_kick"
	low_variant.hit_height = AttackData.HitHeight.LOW
	combat.current_variant = low_variant
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_LOW_LIGHT_KICK_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_LOW_LIGHT_KICK_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_low_light_kick")


func _resolve_low_light_kick_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not low_light_kick_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _start_medium_kick() -> void:
	var attack := character_data.get_attack(&"medium_kick")
	if attack == null:
		return
	medium_kick_active = true
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.is_attacking = true
	combat.current_attack = attack
	var middle_variant := AttackVariantData.new()
	middle_variant.variant_id = &"arianna_standing"
	middle_variant.animation_name = &"arianna_medium_kick"
	middle_variant.hit_height = AttackData.HitHeight.MID
	combat.current_variant = middle_variant
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_MEDIUM_KICK_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_MEDIUM_KICK_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_medium_kick")


func _resolve_medium_kick_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not medium_kick_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _start_low_medium_kick() -> void:
	var attack := character_data.get_attack(&"medium_kick")
	if attack == null:
		return
	medium_kick_active = true
	low_medium_kick_active = true
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.is_attacking = true
	combat.current_attack = attack
	var low_variant := AttackVariantData.new()
	low_variant.variant_id = &"arianna_low"
	low_variant.animation_name = &"arianna_low_medium_kick"
	low_variant.hit_height = AttackData.HitHeight.LOW
	combat.current_variant = low_variant
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_LOW_MEDIUM_KICK_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_LOW_MEDIUM_KICK_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_low_medium_kick")


func _resolve_low_medium_kick_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if attack_generation != combat.action_generation or not low_medium_kick_active or not combat.is_attacking:
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _start_strong_kick() -> void:
	var attack := character_data.get_attack(&"heavy_kick")
	if attack == null:
		return
	strong_kick_active = true
	low_strong_kick_active = false
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.is_attacking = true
	combat.current_attack = attack
	var middle_variant := AttackVariantData.new()
	middle_variant.variant_id = &"arianna_standing"
	middle_variant.animation_name = &"arianna_strong_kick"
	middle_variant.hit_height = AttackData.HitHeight.HIGH
	combat.current_variant = middle_variant
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_STRONG_KICK_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_STRONG_KICK_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_strong_kick")


func _start_low_strong_kick() -> void:
	var attack := character_data.get_attack(&"heavy_kick")
	if attack == null:
		return
	strong_kick_active = true
	low_strong_kick_active = true
	current_state = State.ATTACKING
	velocity = Vector2.ZERO
	combat.action_generation += 1
	combat.is_attacking = true
	combat.current_attack = attack
	var low_variant := AttackVariantData.new()
	low_variant.variant_id = &"arianna_low"
	low_variant.animation_name = &"arianna_low_strong_kick"
	low_variant.hit_height = AttackData.HitHeight.LOW
	low_variant.causes_knockdown = true
	combat.current_variant = low_variant
	combat.hit_targets.clear()
	var attack_shape := combat.hitbox_shape.shape as RectangleShape2D
	attack_shape.size = ARIANNA_LOW_STRONG_KICK_HITBOX_SIZE
	combat.hitbox_shape.position = ARIANNA_LOW_STRONG_KICK_HITBOX_POSITION
	combat.hitbox_shape.rotation = 0.0
	bring_attacker_to_foreground()
	animated_sprite.play(&"arianna_low_strong_kick")


func _resolve_strong_kick_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if attack_generation != combat.action_generation or not strong_kick_active or not combat.is_attacking:
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _resolve_crouched_strong_punch_overlap(attack_generation: int) -> void:
	await get_tree().physics_frame
	if (
		attack_generation != combat.action_generation
		or not crouched_strong_punch_active
		or not combat.is_attacking
	):
		return
	for area in combat.hitbox.get_overlapping_areas():
		combat._apply_hit_to_area(area)


func _on_animation_finished() -> void:
	if animated_sprite.animation == &"arianna_whistle_special":
		_finish_whistle_special()
	elif animated_sprite.animation == &"arianna_baseball_special":
		_finish_baseball_special()
	elif animated_sprite.animation == &"arianna_jump_light_punch":
		_finish_jump_light_punch(false)
	elif animated_sprite.animation == &"arianna_jump_medium_punch":
		_finish_jump_medium_punch(false)
	elif animated_sprite.animation == &"arianna_jump_strong_punch":
		_finish_jump_strong_punch(false)
	elif animated_sprite.animation == &"arianna_jump_light_kick":
		_finish_jump_light_kick(false)
	elif animated_sprite.animation == &"arianna_jump_medium_kick":
		_finish_jump_medium_kick(false)
	elif animated_sprite.animation == &"arianna_jump_strong_kick":
		_finish_jump_strong_kick(false)
	elif animated_sprite.animation == &"arianna_light_punch":
		combat.disable_hitbox()
		animated_sprite.play(&"arianna_light_punch_recovery")
	elif animated_sprite.animation == &"arianna_light_punch_recovery":
		combat.disable_hitbox()
		combat.is_attacking = false
		combat.current_attack = null
		combat.current_variant = null
		combat.hit_targets.clear()
		restore_default_render_order()
		light_punch_active = false
		current_state = State.IDLE
		animated_sprite.play(&"idle")
	elif animated_sprite.animation == &"arianna_low_light_punch":
		combat.disable_hitbox()
		animated_sprite.play(&"arianna_low_light_punch_recovery")
	elif animated_sprite.animation == &"arianna_low_light_punch_recovery":
		combat.disable_hitbox()
		combat.is_attacking = false
		combat.current_attack = null
		combat.current_variant = null
		combat.hit_targets.clear()
		restore_default_render_order()
		light_punch_active = false
		low_light_punch_active = false
		if input_buffer != null and input_buffer.is_down_held():
			change_state(State.CROUCHING)
			animated_sprite.frame = ARIANNA_CROUCH_FRAME_COUNT - 1
			animated_sprite.pause()
		else:
			change_state(State.IDLE)
	elif animated_sprite.animation == &"arianna_medium_punch":
		combat.disable_hitbox()
		animated_sprite.play(&"arianna_medium_punch_recovery")
	elif animated_sprite.animation == &"arianna_medium_punch_recovery":
		combat.disable_hitbox()
		combat.is_attacking = false
		combat.current_attack = null
		combat.current_variant = null
		combat.hit_targets.clear()
		restore_default_render_order()
		medium_punch_active = false
		change_state(State.IDLE)
	elif animated_sprite.animation == &"arianna_low_medium_punch":
		combat.disable_hitbox()
		animated_sprite.play(&"arianna_low_medium_punch_recovery")
	elif animated_sprite.animation == &"arianna_low_medium_punch_recovery":
		combat.disable_hitbox()
		combat.is_attacking = false
		combat.current_attack = null
		combat.current_variant = null
		combat.hit_targets.clear()
		restore_default_render_order()
		low_medium_punch_active = false
		if input_buffer != null and input_buffer.is_down_held():
			change_state(State.CROUCHING)
			animated_sprite.frame = ARIANNA_CROUCH_FRAME_COUNT - 1
			animated_sprite.pause()
		else:
			change_state(State.IDLE)
	elif animated_sprite.animation == &"arianna_strong_punch":
		combat.disable_hitbox()
		combat.is_attacking = false
		combat.current_attack = null
		combat.current_variant = null
		combat.hit_targets.clear()
		restore_default_render_order()
		strong_punch_active = false
		change_state(State.IDLE)
	elif animated_sprite.animation == &"arianna_crouched_strong_punch":
		combat.disable_hitbox()
		combat.is_attacking = false
		combat.current_attack = null
		combat.current_variant = null
		combat.hit_targets.clear()
		restore_default_render_order()
		crouched_strong_punch_active = false
		if input_buffer != null and input_buffer.is_down_held():
			change_state(State.CROUCHING)
			animated_sprite.frame = ARIANNA_CROUCH_FRAME_COUNT - 1
			animated_sprite.pause()
		else:
			change_state(State.IDLE)
	elif animated_sprite.animation == &"arianna_light_kick":
		combat.disable_hitbox()
		animated_sprite.play(&"arianna_light_kick_recovery")
	elif animated_sprite.animation == &"arianna_light_kick_recovery":
		combat.disable_hitbox()
		combat.is_attacking = false
		combat.current_attack = null
		combat.current_variant = null
		combat.hit_targets.clear()
		restore_default_render_order()
		light_kick_active = false
		change_state(State.IDLE)
	elif animated_sprite.animation == &"arianna_low_light_kick":
		combat.disable_hitbox()
		animated_sprite.play(&"arianna_low_light_kick_recovery")
	elif animated_sprite.animation == &"arianna_low_light_kick_recovery":
		combat.disable_hitbox()
		combat.is_attacking = false
		combat.current_attack = null
		combat.current_variant = null
		combat.hit_targets.clear()
		restore_default_render_order()
		light_kick_active = false
		low_light_kick_active = false
		if input_buffer != null and input_buffer.is_down_held():
			change_state(State.CROUCHING)
			animated_sprite.frame = ARIANNA_CROUCH_FRAME_COUNT - 1
			animated_sprite.pause()
		else:
			change_state(State.IDLE)
	elif animated_sprite.animation == &"arianna_medium_kick":
		combat.disable_hitbox()
		animated_sprite.play(&"arianna_medium_kick_recovery")
	elif animated_sprite.animation == &"arianna_medium_kick_recovery":
		combat.disable_hitbox()
		combat.is_attacking = false
		combat.current_attack = null
		combat.current_variant = null
		combat.hit_targets.clear()
		restore_default_render_order()
		medium_kick_active = false
		change_state(State.IDLE)
	elif animated_sprite.animation == &"arianna_low_medium_kick":
		combat.disable_hitbox()
		animated_sprite.play(&"arianna_low_medium_kick_recovery")
	elif animated_sprite.animation == &"arianna_low_medium_kick_recovery":
		combat.disable_hitbox()
		combat.is_attacking = false
		combat.current_attack = null
		combat.current_variant = null
		combat.hit_targets.clear()
		restore_default_render_order()
		medium_kick_active = false
		low_medium_kick_active = false
		if input_buffer != null and input_buffer.is_down_held():
			change_state(State.CROUCHING)
			animated_sprite.frame = ARIANNA_CROUCH_FRAME_COUNT - 1
			animated_sprite.pause()
		else:
			change_state(State.IDLE)
	elif animated_sprite.animation == &"arianna_strong_kick":
		combat.disable_hitbox()
		combat.is_attacking = false
		combat.current_attack = null
		combat.current_variant = null
		combat.hit_targets.clear()
		restore_default_render_order()
		strong_kick_active = false
		low_strong_kick_active = false
		change_state(State.IDLE)
	elif animated_sprite.animation == &"arianna_low_strong_kick":
		combat.disable_hitbox()
		combat.is_attacking = false
		combat.current_attack = null
		combat.current_variant = null
		combat.hit_targets.clear()
		restore_default_render_order()
		strong_kick_active = false
		low_strong_kick_active = false
		if input_buffer != null and input_buffer.is_down_held():
			change_state(State.CROUCHING)
			animated_sprite.frame = ARIANNA_CROUCH_FRAME_COUNT - 1
			animated_sprite.pause()
		else:
			change_state(State.IDLE)
	elif animated_sprite.animation == &"jump":
		jump_rotation_finished = true
		_update_jump_facing()
	elif animated_sprite.animation == &"arianna_back_jump":
		# Il moto Godot dura più dei 22 frame: conclusa la sequenza visiva,
		# tornare subito in idle mentre il timer completa lo spostamento.
		change_state(State.IDLE)
	elif animated_sprite.animation == &"arianna_crouch_recovery":
		change_state(State.IDLE)
	elif animated_sprite.animation in [
		&"block_high_recovery", &"block_mid_recovery", &"block_low_recovery"
	]:
		combat.set_guarding(false)
		change_state(State.IDLE)
	else:
		super._on_animation_finished()


func _on_animation_frame_changed() -> void:
	if animated_sprite.animation == &"arianna_whistle_special":
		if animated_sprite.frame == ARIANNA_WHISTLE_SOUND_FRAME and not whistle_sound_played:
			whistle_sound_played = true
			whistle_audio_player.play()
		if animated_sprite.frame in range(
			ARIANNA_WHISTLE_AIR_START_FRAME,
			ARIANNA_WHISTLE_AIR_END_FRAME + 1
		):
			_start_whistle_air_effect()
		else:
			_stop_whistle_air_effect()
	if animated_sprite.animation == &"arianna_baseball_special":
		if (
			animated_sprite.frame == ARIANNA_BASEBALL_TORNADO_SPAWN_FRAME
			and not baseball_tornado_spawned
		):
			_spawn_baseball_tornado()
		return
	if (
		current_state == State.JUMP_STARTUP
		and jump_takeoff_armed
		and animated_sprite.animation == &"jump"
		and animated_sprite.frame >= ARIANNA_JUMP_TAKEOFF_FRAME
	):
		begin_jump_ascent()
	super._on_animation_frame_changed()
	if animated_sprite.animation == &"arianna_jump_light_punch":
		if animated_sprite.frame == ARIANNA_JUMP_LIGHT_PUNCH_ACTIVE_START_FRAME:
			combat.enable_hitbox()
			_resolve_jump_light_punch_overlap(combat.action_generation)
		elif animated_sprite.frame > ARIANNA_JUMP_LIGHT_PUNCH_ACTIVE_END_FRAME:
			combat.disable_hitbox()
		return
	if animated_sprite.animation == &"arianna_jump_medium_punch":
		if animated_sprite.frame == ARIANNA_JUMP_MEDIUM_PUNCH_ACTIVE_START_FRAME:
			combat.enable_hitbox()
			_resolve_jump_medium_punch_overlap(combat.action_generation)
		elif animated_sprite.frame > ARIANNA_JUMP_MEDIUM_PUNCH_ACTIVE_END_FRAME:
			combat.disable_hitbox()
		return
	if animated_sprite.animation == &"arianna_jump_strong_punch":
		if animated_sprite.frame == ARIANNA_JUMP_STRONG_PUNCH_ACTIVE_START_FRAME:
			combat.enable_hitbox()
			_resolve_jump_strong_punch_overlap(combat.action_generation)
		elif animated_sprite.frame > ARIANNA_JUMP_STRONG_PUNCH_ACTIVE_END_FRAME:
			combat.disable_hitbox()
		return
	if animated_sprite.animation == &"arianna_jump_light_kick":
		if animated_sprite.frame == ARIANNA_JUMP_LIGHT_KICK_ACTIVE_START_FRAME:
			combat.enable_hitbox()
			_resolve_jump_light_kick_overlap(combat.action_generation)
		elif animated_sprite.frame > ARIANNA_JUMP_LIGHT_KICK_ACTIVE_END_FRAME:
			combat.disable_hitbox()
		return
	if animated_sprite.animation == &"arianna_jump_medium_kick":
		if animated_sprite.frame == ARIANNA_JUMP_MEDIUM_KICK_ACTIVE_START_FRAME:
			combat.enable_hitbox()
			_resolve_jump_medium_kick_overlap(combat.action_generation)
		elif animated_sprite.frame > ARIANNA_JUMP_MEDIUM_KICK_ACTIVE_END_FRAME:
			combat.disable_hitbox()
		return
	if animated_sprite.animation == &"arianna_jump_strong_kick":
		if animated_sprite.frame == ARIANNA_JUMP_STRONG_KICK_ACTIVE_START_FRAME:
			combat.enable_hitbox()
			_resolve_jump_strong_kick_overlap(combat.action_generation)
		elif animated_sprite.frame > ARIANNA_JUMP_STRONG_KICK_ACTIVE_END_FRAME:
			combat.disable_hitbox()
		return
	if (
		animated_sprite.animation == &"jump"
		and animated_sprite.frame == ARIANNA_JUMP_FRAME_COUNT - 1
	):
		jump_rotation_finished = true
		_update_jump_facing()
	if animated_sprite.animation != &"arianna_light_punch":
		if animated_sprite.animation == &"arianna_low_strong_kick":
			if animated_sprite.frame == ARIANNA_LOW_STRONG_KICK_ACTIVE_START_FRAME:
				combat.enable_hitbox()
				_resolve_strong_kick_overlap(combat.action_generation)
			elif animated_sprite.frame > ARIANNA_LOW_STRONG_KICK_ACTIVE_END_FRAME:
				combat.disable_hitbox()
			return
		if animated_sprite.animation == &"arianna_strong_kick":
			if animated_sprite.frame == ARIANNA_STRONG_KICK_ACTIVE_START_FRAME:
				combat.enable_hitbox()
				_resolve_strong_kick_overlap(combat.action_generation)
			elif animated_sprite.frame > ARIANNA_STRONG_KICK_ACTIVE_END_FRAME:
				combat.disable_hitbox()
			return
		if animated_sprite.animation == &"arianna_low_medium_kick":
			if animated_sprite.frame == ARIANNA_LOW_MEDIUM_KICK_ACTIVE_START_FRAME:
				combat.enable_hitbox()
				_resolve_low_medium_kick_overlap(combat.action_generation)
			elif animated_sprite.frame > ARIANNA_LOW_MEDIUM_KICK_ACTIVE_END_FRAME:
				combat.disable_hitbox()
			return
		if animated_sprite.animation == &"arianna_medium_kick":
			if animated_sprite.frame == ARIANNA_MEDIUM_KICK_ACTIVE_START_FRAME:
				combat.enable_hitbox()
				_resolve_medium_kick_overlap(combat.action_generation)
			elif animated_sprite.frame > ARIANNA_MEDIUM_KICK_ACTIVE_END_FRAME:
				combat.disable_hitbox()
			return
		if animated_sprite.animation == &"arianna_low_light_kick":
			if animated_sprite.frame == ARIANNA_LOW_LIGHT_KICK_ACTIVE_START_FRAME:
				combat.enable_hitbox()
				_resolve_low_light_kick_overlap(combat.action_generation)
			elif animated_sprite.frame > ARIANNA_LOW_LIGHT_KICK_ACTIVE_END_FRAME:
				combat.disable_hitbox()
			return
		if animated_sprite.animation == &"arianna_light_kick":
			if animated_sprite.frame == ARIANNA_LIGHT_KICK_ACTIVE_START_FRAME:
				combat.enable_hitbox()
				_resolve_light_kick_overlap(combat.action_generation)
			elif animated_sprite.frame > ARIANNA_LIGHT_KICK_ACTIVE_END_FRAME:
				combat.disable_hitbox()
			return
		if animated_sprite.animation == &"arianna_crouched_strong_punch":
			if animated_sprite.frame == ARIANNA_CROUCHED_STRONG_PUNCH_ACTIVE_START_FRAME:
				combat.enable_hitbox()
				_resolve_crouched_strong_punch_overlap(combat.action_generation)
			elif animated_sprite.frame > ARIANNA_CROUCHED_STRONG_PUNCH_ACTIVE_END_FRAME:
				combat.disable_hitbox()
			return
		if animated_sprite.animation == &"arianna_strong_punch":
			if animated_sprite.frame == ARIANNA_STRONG_PUNCH_ACTIVE_START_FRAME:
				combat.enable_hitbox()
				_resolve_strong_punch_overlap(combat.action_generation)
			elif animated_sprite.frame > ARIANNA_STRONG_PUNCH_ACTIVE_END_FRAME:
				combat.disable_hitbox()
			return
		if animated_sprite.animation == &"arianna_low_medium_punch":
			if animated_sprite.frame == ARIANNA_LOW_MEDIUM_PUNCH_ACTIVE_START_FRAME:
				combat.enable_hitbox()
				_resolve_low_medium_punch_overlap(combat.action_generation)
			elif animated_sprite.frame > ARIANNA_LOW_MEDIUM_PUNCH_ACTIVE_END_FRAME:
				combat.disable_hitbox()
			return
		if animated_sprite.animation == &"arianna_medium_punch":
			if animated_sprite.frame == ARIANNA_MEDIUM_PUNCH_ACTIVE_START_FRAME:
				combat.enable_hitbox()
				_resolve_medium_punch_overlap(combat.action_generation)
			elif animated_sprite.frame > ARIANNA_MEDIUM_PUNCH_ACTIVE_END_FRAME:
				combat.disable_hitbox()
			return
		if animated_sprite.animation != &"arianna_low_light_punch":
			return
		if animated_sprite.frame == ARIANNA_LOW_LIGHT_PUNCH_ACTIVE_START_FRAME:
			combat.enable_hitbox()
			_resolve_low_light_punch_overlap(combat.action_generation)
		elif animated_sprite.frame > ARIANNA_LOW_LIGHT_PUNCH_ACTIVE_END_FRAME:
			combat.disable_hitbox()
		return
	if animated_sprite.frame == ARIANNA_LIGHT_PUNCH_ACTIVE_START_FRAME:
		combat.enable_hitbox()
	elif animated_sprite.frame > ARIANNA_LIGHT_PUNCH_ACTIVE_END_FRAME:
		combat.disable_hitbox()


func is_forward_input(horizontal_axis: float) -> bool:
	return horizontal_axis > 0.0 if is_facing_right else horizontal_axis < 0.0


func is_backward_input(horizontal_axis: float) -> bool:
	return horizontal_axis < 0.0 if is_facing_right else horizontal_axis > 0.0


func handle_input() -> void:
	# Arianna resta in idle finché non dispone del proprio moveset.
	velocity.x = 0.0
