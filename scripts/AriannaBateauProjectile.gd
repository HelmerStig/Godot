extends Node2D
class_name AriannaBateauProjectile

## Proiettile cinematografico di Arianna: attraversa l'arena senza collisioni fisiche.

enum State {
	RUNNING,
	ATTACKING,
	BACK_TO_RUN,
	EXITING,
}

const RUN_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/Bateau-run.png"
)
const ATTACK_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/Bateau-jump_attack.png"
)
const BACK_TO_RUN_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/Bateau-back_to_run.png"
)
const RUN_FRAME_COUNT := 49
const RUN_COLUMNS := 7
const ATTACK_FRAME_COUNT := 25
const ATTACK_COLUMNS := 5
const BACK_TO_RUN_FRAME_COUNT := 25
const BACK_TO_RUN_COLUMNS := 5
const CELL_SIZE := Vector2(512.0, 512.0)
const ANIMATION_FPS := 24.0
const MOVE_SPEED := 760.0
const ATTACK_TRIGGER_DISTANCE := 620.0
const ATTACK_CONTACT_DISTANCE := 70.0
const ATTACK_HIT_FRAME := 17
const DAMAGE_RATIO := 0.30
const OFFSCREEN_MARGIN := 190.0
const SPRITE_SCALE := Vector2(0.72, 0.72)
const SPRITE_POSITION := Vector2(0.0, -70.0)

var source_fighter: Fighter
var target_fighter: Fighter
var travel_direction := 1.0
var visible_left := 0.0
var visible_right := 1152.0
var current_state := State.RUNNING
var animated_sprite: AnimatedSprite2D
var has_hit := false


func setup(owner_fighter: Fighter, target: Fighter) -> void:
	source_fighter = owner_fighter
	target_fighter = target
	travel_direction = 1.0 if owner_fighter.is_facing_right else -1.0
	visible_left = owner_fighter.stage_left_limit
	visible_right = owner_fighter.stage_right_limit


func _ready() -> void:
	add_to_group("arianna_bateau_projectile")
	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedSprite2D"
	animated_sprite.sprite_frames = _create_frames()
	animated_sprite.scale = SPRITE_SCALE
	animated_sprite.position = SPRITE_POSITION
	animated_sprite.flip_h = travel_direction < 0.0
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	add_child(animated_sprite)
	animated_sprite.play(&"run")


func _physics_process(delta: float) -> void:
	match current_state:
		State.RUNNING:
			if is_instance_valid(target_fighter):
				var distance_to_target := (
					(target_fighter.global_position.x - global_position.x) * travel_direction
				)
				if distance_to_target <= ATTACK_TRIGGER_DISTANCE:
					_start_attack()
					return
			_move_forward(delta)
		State.ATTACKING:
			_move_attack_toward_target(delta)
		State.BACK_TO_RUN:
			_move_forward(delta)
		State.EXITING:
			_move_forward(delta)
			if _is_fully_outside_opposite_side():
				queue_free()


func _move_forward(delta: float) -> void:
	position.x += travel_direction * MOVE_SPEED * delta


func _move_attack_toward_target(delta: float) -> void:
	if has_hit:
		_move_forward(delta)
		return
	if not is_instance_valid(target_fighter):
		return
	var contact_x := target_fighter.global_position.x - travel_direction * ATTACK_CONTACT_DISTANCE
	var next_x := global_position.x + travel_direction * MOVE_SPEED * delta
	global_position.x = minf(next_x, contact_x) if travel_direction > 0.0 else maxf(next_x, contact_x)


func _start_attack() -> void:
	if current_state != State.RUNNING:
		return
	current_state = State.ATTACKING
	animated_sprite.play(&"attack")


func _on_frame_changed() -> void:
	if (
		current_state == State.ATTACKING
		and animated_sprite.frame >= ATTACK_HIT_FRAME
		and not has_hit
	):
		_apply_bite()


func _apply_bite() -> void:
	if not is_instance_valid(target_fighter) or not is_instance_valid(source_fighter):
		return
	has_hit = true
	global_position.x = (
		target_fighter.global_position.x - travel_direction * ATTACK_CONTACT_DISTANCE
	)
	var damage := roundi(float(target_fighter.combat.max_health) * DAMAGE_RATIO)
	target_fighter.combat.take_damage(
		damage,
		source_fighter,
		0.32,
		0.18,
		AttackData.HitHeight.HIGH,
		false,
		0,
		0,
		false,
		true
	)


func _on_animation_finished() -> void:
	match current_state:
		State.ATTACKING:
			current_state = State.BACK_TO_RUN
			animated_sprite.play(&"back_to_run")
		State.BACK_TO_RUN:
			current_state = State.EXITING
			animated_sprite.play(&"run")


func _is_fully_outside_opposite_side() -> bool:
	if travel_direction > 0.0:
		return global_position.x > visible_right + OFFSCREEN_MARGIN
	return global_position.x < visible_left - OFFSCREEN_MARGIN


func _create_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	_add_atlas_animation(frames, &"run", RUN_SHEET, RUN_FRAME_COUNT, RUN_COLUMNS, true)
	_add_atlas_animation(
		frames, &"attack", ATTACK_SHEET, ATTACK_FRAME_COUNT, ATTACK_COLUMNS, false
	)
	_add_atlas_animation(
		frames,
		&"back_to_run",
		BACK_TO_RUN_SHEET,
		BACK_TO_RUN_FRAME_COUNT,
		BACK_TO_RUN_COLUMNS,
		false
	)
	return frames


func _add_atlas_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	atlas: Texture2D,
	frame_count: int,
	columns: int,
	looped: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, ANIMATION_FPS)
	frames.set_animation_loop(animation_name, looped)
	for source_index in range(frame_count):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = atlas
		atlas_frame.region = Rect2(
			Vector2(float(source_index % columns), float(source_index / columns)) * CELL_SIZE,
			CELL_SIZE
		)
		frames.add_frame(animation_name, atlas_frame)
