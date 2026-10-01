extends Fighter
class_name IdleRosterFighter

## Fighter iniziale con idle e camminata, in attesa del moveset completo.
## La scena resta compatibile con arena e MovementTest.

const IDLE_FPS := 18.0
const WALK_FPS := 24.0
const JUMP_FPS := 24.0
const CROUCH_FPS := 24.0
const BLOCK_FPS := 24.0
const BLOCK_LOW_FPS := 48.0
const HURT_FPS := 24.0
const GRAVITY := 3150.0

@export var fighter_id: StringName
@export var fighter_display_name := "Fighter"
@export var idle_sheet: Texture2D
@export_range(1, 999, 1) var idle_frame_count := 1
@export_range(1, 99, 1) var idle_columns := 7
@export var idle_cell_size := Vector2(512.0, 512.0)
@export var walk_sheet: Texture2D
@export_range(1, 999, 1) var walk_frame_count := 49
@export_range(1, 99, 1) var walk_columns := 7
@export var walk_cell_size := Vector2(512.0, 512.0)
@export var crouch_sheet: Texture2D
@export_range(1, 999, 1) var crouch_frame_count := 1
@export_range(1, 99, 1) var crouch_columns := 5
@export var crouch_cell_size := Vector2(512.0, 512.0)
@export var jump_sheet: Texture2D
## Frame visivo (1-based) da cui parte l'animazione nel foglio.
@export_range(0, 999, 1) var jump_start_frame := 0
## Frame visivo (1-based) di stacco da terra: qui viene applicato l'impulso.
@export_range(0, 999, 1) var jump_takeoff_frame := 0
## Frame visivo (1-based) dopo il quale passare in idle al termine dell'animazione.
@export_range(0, 999, 1) var jump_idle_frame := 0
@export_range(1, 99, 1) var jump_columns := 7
@export var jump_cell_size := Vector2(512.0, 512.0)
@export var block_sheet: Texture2D
@export_range(1, 99, 1) var block_frame_count := 1
@export_range(1, 99, 1) var block_columns := 7
@export var block_cell_size := Vector2(512.0, 512.0)
@export var block_low_sheet: Texture2D
@export_range(1, 99, 1) var block_low_frame_count := 1
@export_range(1, 99, 1) var block_low_columns := 5
@export var block_low_cell_size := Vector2(512.0, 512.0)
@export var hurt_high_sheet: Texture2D
@export_range(1, 99, 1) var hurt_high_frame_count := 1
@export_range(1, 99, 1) var hurt_high_columns := 5
@export var hurt_high_cell_size := Vector2(512.0, 512.0)
## Se true, al termine dell'animazione la riproduce al contrario (senza l'ultimo frame) prima di tornare in idle.
@export var hurt_high_has_reverse := false
@export var idle_sprite_scale := Vector2(0.85, 0.85)
@export var idle_sprite_position := Vector2(0.0, -115.0)
## Per-character sprite size and ground alignment; overrides the defaults above.
@export var sprite_scale := Vector2(0.0, 0.0)
@export var sprite_position := Vector2(0.0, 0.0)

var _jump_startup := false
var _jump_takeoff_anim_idx := 0
var _jump_direction := 0.0


func _ready() -> void:
	_configure_animations()
	var data := CharacterData.create_default()
	data.character_name = String(fighter_id)
	data.display_name = fighter_display_name
	character_data = data
	super._ready()
	animated_sprite.play(&"idle")


func _physics_process(delta: float) -> void:
	if is_player_controlled and input_buffer != null:
		input_buffer.update(is_facing_right)

	var on_floor := is_on_floor()
	var down_held := input_buffer != null and input_buffer.is_down_held()
	if crouch_sheet != null and controls_enabled and on_floor:
		if down_held and current_state in [State.IDLE, State.WALKING]:
			change_state(State.CROUCHING)
		elif down_held and current_state == State.STANDING_UP:
			change_state(State.CROUCHING)
			animated_sprite.play(&"crouch", 1.0)
		elif not down_held and current_state == State.CROUCHING:
			change_state(State.STANDING_UP)

	# Pressione salto: avvia la fase di startup (anticipazione a terra).
	if (
		animated_sprite.sprite_frames.has_animation(&"jump")
		and controls_enabled
		and can_move
		and current_state in [State.IDLE, State.WALKING]
		and on_floor
		and input_buffer != null
		and Input.is_action_just_pressed(get_input_action("jump"))
	):
		_jump_startup = true
		_jump_direction = signf(input_buffer.get_horizontal_axis())
		_jump_takeoff_anim_idx = jump_takeoff_frame - jump_start_frame
		change_state(State.JUMP_STARTUP)

	# Startup: applica l'impulso al frame di stacco.
	if _jump_startup and current_state == State.JUMP_STARTUP:
		if animated_sprite.frame >= _jump_takeoff_anim_idx:
			_jump_startup = false
			velocity.y = character_data.jump_velocity * 1.5  # stessa altezza di Mangler (gravity 3150)
			velocity.x = _jump_direction * character_data.air_speed  # stessa distanza orizzontale di Arianna
			reset_airborne_combat_state()
			change_state(State.JUMPING)
			on_floor = false

	var can_walk := (
		controls_enabled
		and can_move
		and current_state in [State.IDLE, State.WALKING]
		and on_floor
		and input_buffer != null
	)
	var direction := input_buffer.get_horizontal_axis() if can_walk else 0.0
	if can_walk:
		velocity.x = direction * character_data.walk_speed
	elif current_state not in [State.JUMPING, State.JUMP_STARTUP]:
		velocity.x = 0.0
	# Durante JUMPING velocity.x è preservata (direzione del salto).
	if not on_floor:
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	update_physical_collision()
	move_and_slide()
	position.x = clampf(position.x, stage_left_limit, stage_right_limit)
	update_facing_direction()
	update_ground_shadow()

	# A terra dopo il salto: blocca il movimento e lascia che l'animazione
	# completi i frame di atterraggio; _on_animation_finished passerà in idle.
	if current_state == State.JUMPING and is_on_floor() and velocity.y >= 0.0:
		velocity.x = 0.0
		velocity.y = 0.0
		return

	if current_state in [State.IDLE, State.WALKING]:
		var next_state := State.WALKING if not is_zero_approx(velocity.x) and is_on_floor() else State.IDLE
		if current_state != next_state:
			change_state(next_state)
		else:
			update_animation()

	# Esci dall'accovacciato quando il giocatore non tiene più giù.
	if current_state == State.CROUCHING and is_player_controlled and input_buffer != null:
		if not input_buffer.is_down_held():
			change_state(State.IDLE)


func change_state(next_state: int, force_victory_exit := false) -> void:
	# Solo per la parata ALTA: inserisce la recovery inversa prima di tornare in idle.
	if current_state == State.BLOCKING and next_state == State.IDLE \
			and received_block_height != AttackData.HitHeight.LOW:
		var recovery := get_block_recovery_animation(received_block_height)
		if animated_sprite.sprite_frames.has_animation(recovery):
			super.change_state(State.BLOCK_RECOVERY, force_victory_exit)
			return
	super.change_state(next_state, force_victory_exit)


func get_block_animation(height: AttackData.HitHeight, _crouched := false) -> StringName:
	return &"block_low" if height == AttackData.HitHeight.LOW else &"block_high"


func get_block_recovery_animation(height: AttackData.HitHeight) -> StringName:
	return &"block_low_recovery" if height == AttackData.HitHeight.LOW else &"block_high_recovery"


func _on_animation_finished() -> void:
	if current_state == State.BLOCK_RECOVERY:
		if animated_sprite.animation == &"block_low_recovery":
			change_state(State.CROUCHING)
			return
		if animated_sprite.animation == &"block_high_recovery":
			change_state(State.IDLE)
			return
	if current_state == State.HIT:
		if animated_sprite.animation == &"hurt_high" \
				and animated_sprite.sprite_frames.has_animation(&"hurt_high_reverse"):
			animated_sprite.play(&"hurt_high_reverse")
			return
		if animated_sprite.animation in [&"hurt_high", &"hurt_high_reverse"]:
			change_state(State.IDLE)
			return
	if current_state == State.STANDING_UP and animated_sprite.animation == &"crouch":
		change_state(State.IDLE)
		return
	if current_state in [State.JUMP_STARTUP, State.JUMPING] and animated_sprite.animation == &"jump":
		_jump_startup = false
		change_state(State.IDLE)


func update_sprite_scale() -> void:
	var scale := sprite_scale if not sprite_scale.is_zero_approx() else idle_sprite_scale
	var pos := sprite_position if not sprite_position.is_zero_approx() else idle_sprite_position
	animated_sprite.scale = scale
	animated_sprite.position = pos


func _configure_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_sheet_animation(frames, &"idle", idle_sheet, idle_frame_count, idle_columns, idle_cell_size, IDLE_FPS)
	if walk_sheet != null:
		_add_sheet_animation(frames, &"walk", walk_sheet, walk_frame_count, walk_columns, walk_cell_size, WALK_FPS)
		_add_sheet_animation(frames, &"backwalk", walk_sheet, walk_frame_count, walk_columns, walk_cell_size, WALK_FPS, true)
	if crouch_sheet != null:
		_add_sheet_animation(frames, &"crouch", crouch_sheet, crouch_frame_count, crouch_columns, crouch_cell_size, CROUCH_FPS, false, 0, false)
	if jump_sheet != null and jump_idle_frame > jump_start_frame and jump_start_frame > 0:
		_add_sheet_animation(
			frames, &"jump", jump_sheet,
			jump_idle_frame - jump_start_frame,
			jump_columns, jump_cell_size, JUMP_FPS,
			false, jump_start_frame - 1, false
		)
	if block_sheet != null:
		_add_sheet_animation(frames, &"block_high", block_sheet, block_frame_count, block_columns, block_cell_size, BLOCK_FPS, false, 0, false)
		_add_sheet_animation(frames, &"block_high_recovery", block_sheet, block_frame_count, block_columns, block_cell_size, BLOCK_FPS, true, 0, false)
	if block_low_sheet != null:
		_add_sheet_animation(frames, &"block_low", block_low_sheet, block_low_frame_count, block_low_columns, block_low_cell_size, BLOCK_LOW_FPS, false, 0, false)
		_add_sheet_animation(frames, &"block_low_recovery", block_low_sheet, block_low_frame_count, block_low_columns, block_low_cell_size, BLOCK_LOW_FPS, true, 0, false)
	if hurt_high_sheet != null:
		_add_sheet_animation(frames, &"hurt_high", hurt_high_sheet, hurt_high_frame_count, hurt_high_columns, hurt_high_cell_size, HURT_FPS, false, 0, false)
		if hurt_high_has_reverse and hurt_high_frame_count > 1:
			_add_sheet_animation(frames, &"hurt_high_reverse", hurt_high_sheet, hurt_high_frame_count - 1, hurt_high_columns, hurt_high_cell_size, HURT_FPS, true, 0, false)
	animated_sprite.sprite_frames = frames
	animated_sprite.animation = &"idle"
	update_sprite_scale()


func _add_sheet_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	sheet: Texture2D,
	frame_count: int,
	columns: int,
	cell_size: Vector2,
	fps: float,
	reverse := false,
	src_start := 0,
	loop := true
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)
	for frame_index in frame_count:
		var source_index := src_start + (frame_count - 1 - frame_index if reverse else frame_index)
		var texture := AtlasTexture.new()
		texture.atlas = sheet
		texture.region = Rect2(
			float(source_index % columns) * cell_size.x,
			float(source_index / columns) * cell_size.y,
			cell_size.x,
			cell_size.y
		)
		frames.add_frame(animation_name, texture)
