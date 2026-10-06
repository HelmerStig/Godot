extends "res://scripts/Fighter.gd"
class_name IdleRosterFighter

## Fighter iniziale con idle e camminata, in attesa del moveset completo.
## La scena resta compatibile con arena e MovementTest.

const IDLE_FPS := 18.0
const WALK_FPS := 24.0
const RUN_FPS := 24.0
const RUN_SPEED_MULTIPLIER := 2.0  # Stessa velocità di corsa di Arianna.
const JUMP_FPS := 24.0
const CROUCH_FPS := 24.0
const BLOCK_FPS := 24.0
const BLOCK_LOW_FPS := 48.0
const HURT_FPS := 48.0
const KO_FPS := 24.0
const KNOCKDOWN_FPS := 24.0
const SWEEP_GROUNDED_HOLD := 0.3
const GRAVITY := 3150.0
# Profilo di movimento iniziale uguale al back jump di Arianna.
const BACK_JUMP_DISTANCE := 80.0
const BACK_JUMP_DURATION := 0.5
const BACK_JUMP_TAKEOFF_FRAME := 4  # Frame visivo 5, indice 0-based.

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
@export var run_sheet: Texture2D
@export_range(1, 999, 1) var run_frame_count := 1
@export_range(1, 99, 1) var run_columns := 7
@export var run_cell_size := Vector2(512.0, 512.0)
@export var crouch_sheet: Texture2D
@export_range(1, 999, 1) var crouch_frame_count := 1
@export_range(1, 99, 1) var crouch_columns := 5
@export var crouch_cell_size := Vector2(512.0, 512.0)
@export var jump_sheet: Texture2D
@export var back_jump_sheet: Texture2D
@export var light_punch_sheet: Texture2D
@export var medium_punch_sheet: Texture2D
@export var medium_punch_frame_count := 1
@export var medium_punch_columns := 5
@export var medium_punch_fps := 48.0
## Zero significa che il foglio contiene già la recovery.
@export var medium_punch_reverse_fps := 48.0
@export var medium_punch_active_start_frame := 1
@export var medium_punch_active_end_frame := 1
@export var strong_punch_sheet: Texture2D
@export var strong_punch_frame_count := 1
@export var strong_punch_columns := 7
@export var strong_punch_fps := 30.0
@export var strong_punch_active_start_frame := 1
@export var strong_punch_active_end_frame := 1
@export_range(1, 7, 1) var light_punch_active_start_frame := 7
## Frame visivo (1-based) da cui parte l'animazione nel foglio.
@export_range(0, 999, 1) var jump_start_frame := 0
## Frame visivo (1-based) di stacco da terra: qui viene applicato l'impulso.
@export_range(0, 999, 1) var jump_takeoff_frame := 0
## Frame visivo (1-based) dopo il quale passare in idle al termine dell'animazione.
@export_range(0, 999, 1) var jump_idle_frame := 0
@export_range(1, 99, 1) var jump_columns := 7
@export var jump_cell_size := Vector2(512.0, 512.0)
@export var block_sheet: Texture2D
@export var block_medium_sheet: Texture2D
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
@export var hurt_medium_sheet: Texture2D
@export_range(1, 99, 1) var hurt_medium_frame_count := 11
@export_range(1, 99, 1) var hurt_medium_columns := 5
@export var hurt_medium_cell_size := Vector2(512.0, 512.0)
@export var hurt_low_sheet: Texture2D
@export var fall_sheet: Texture2D
@export var death_sheet: Texture2D
@export var sweep_knockdown_sheet: Texture2D
@export var knockdown_recovery_sheet: Texture2D
@export var knockdown_recovery_columns := 6
@export var idle_sprite_scale := Vector2(0.85, 0.85)
@export var idle_sprite_position := Vector2(0.0, -115.0)
## Per-character sprite size and ground alignment; overrides the defaults above.
@export var sprite_scale := Vector2(0.0, 0.0)
@export var sprite_position := Vector2(0.0, 0.0)

var _jump_startup := false
var _jump_takeoff_anim_idx := 0
var _jump_direction := 0.0
var _back_jump_active := false
var _back_jump_moving := false
var _back_jump_elapsed := 0.0
var _back_jump_start := Vector2.ZERO
var _back_jump_direction := -1.0
var _light_punch_hit_audio: AudioStreamPlayer
var _light_punch_whoosh_audio: AudioStreamPlayer
var _light_punch_hit_sound_played := false
var _medium_punch_whoosh_audio: AudioStreamPlayer
var _medium_punch_hit_sound_played := false
var _strong_punch_whoosh_audio: AudioStreamPlayer
var _strong_punch_hit_audio: AudioStreamPlayer
var _strong_punch_hit_sound_played := false


func _ready() -> void:
	_configure_animations()
	var data := CharacterData.create_default()
	data.character_name = String(fighter_id)
	data.display_name = fighter_display_name
	data.run_speed *= RUN_SPEED_MULTIPLIER
	character_data = data
	super._ready()
	_light_punch_hit_audio = AudioStreamPlayer.new()
	_light_punch_hit_audio.stream = preload("res://assets/sounds/sfx/light-punch.wav")
	_light_punch_hit_audio.volume_db = -7.0
	add_child(_light_punch_hit_audio)
	_light_punch_whoosh_audio = AudioStreamPlayer.new()
	_light_punch_whoosh_audio.stream = preload("res://sound-libraries/punch_short_whoosh_30.wav")
	_light_punch_whoosh_audio.volume_db = -4.0
	add_child(_light_punch_whoosh_audio)
	_medium_punch_whoosh_audio = AudioStreamPlayer.new()
	_medium_punch_whoosh_audio.stream = preload("res://assets/sounds/sfx/swosh.wav")
	_medium_punch_whoosh_audio.volume_db = -4.0
	add_child(_medium_punch_whoosh_audio)
	combat.attack_connected.connect(_on_medium_punch_connected)
	animated_sprite.frame_changed.connect(_update_medium_punch_hitbox)
	_strong_punch_whoosh_audio = AudioStreamPlayer.new()
	_strong_punch_whoosh_audio.stream = preload("res://assets/sounds/sfx/swosh.wav")
	_strong_punch_whoosh_audio.volume_db = -4.0
	add_child(_strong_punch_whoosh_audio)
	_strong_punch_hit_audio = AudioStreamPlayer.new()
	_strong_punch_hit_audio.stream = preload("res://assets/sounds/sfx/strong-punch.wav")
	_strong_punch_hit_audio.volume_db = -3.0
	add_child(_strong_punch_hit_audio)
	combat.attack_connected.connect(_on_strong_punch_connected)
	animated_sprite.frame_changed.connect(_update_strong_punch_hitbox)
	combat.attack_connected.connect(_on_light_punch_connected)
	animated_sprite.frame_changed.connect(_update_light_punch_hitbox)
	animated_sprite.play(&"idle")


func _physics_process(delta: float) -> void:
	if is_player_controlled and input_buffer != null:
		input_buffer.update(is_facing_right)
	if _back_jump_active:
		_process_back_jump(delta)
		return

	var on_floor := is_on_floor()
	if strong_punch_sheet != null and controls_enabled and can_move and on_floor and input_buffer != null and not input_buffer.is_down_held() and current_state in [State.IDLE, State.WALKING, State.RUNNING]:
		if input_buffer.consume_attack(&"heavy_punch") != FighterInputBuffer.NO_DIRECTION:
			_start_strong_punch()
	if medium_punch_sheet != null and controls_enabled and can_move and on_floor and input_buffer != null and not input_buffer.is_down_held() and current_state in [State.IDLE, State.WALKING, State.RUNNING]:
		if input_buffer.consume_attack(&"medium_punch") != FighterInputBuffer.NO_DIRECTION:
			_start_medium_punch()
	if light_punch_sheet != null and controls_enabled and can_move and on_floor and input_buffer != null and not input_buffer.is_down_held() and current_state in [State.IDLE, State.WALKING, State.RUNNING]:
		if input_buffer.consume_attack(&"light_punch") != FighterInputBuffer.NO_DIRECTION:
			_start_light_punch()
	combat.set_guarding(
		controls_enabled and on_floor and is_holding_back()
		and current_state in [State.IDLE, State.WALKING, State.CROUCHING, State.STANDING_UP, State.BLOCKING, State.BLOCK_RECOVERY]
	)
	var down_held := input_buffer != null and input_buffer.is_down_held()
	if (
		back_jump_sheet != null and controls_enabled and can_move and on_floor
		and current_state in [State.IDLE, State.WALKING]
		and input_buffer != null and input_buffer.is_back_just_pressed()
	):
		var frame := Engine.get_physics_frames()
		var previous_tap := last_back_tap_frame
		last_back_tap_frame = frame
		if frame - previous_tap <= BACK_HOP_DOUBLE_TAP_WINDOW_FRAMES:
			_start_back_jump()
			return
	if crouch_sheet != null and controls_enabled and on_floor:
		if down_held and current_state in [State.IDLE, State.WALKING, State.RUNNING]:
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
		and current_state in [State.IDLE, State.WALKING, State.RUNNING]
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
		and current_state in [State.IDLE, State.WALKING, State.RUNNING]
		and on_floor
		and input_buffer != null
	)
	var direction := input_buffer.get_horizontal_axis() if can_walk else 0.0
	if can_walk:
		if run_sheet != null and not down_held and input_buffer.is_forward_just_pressed():
			var current_frame := Engine.get_physics_frames()
			if current_frame > last_forward_tap_frame and current_frame - last_forward_tap_frame <= RUN_DOUBLE_TAP_WINDOW_FRAMES:
				change_state(State.RUNNING)
			last_forward_tap_frame = current_frame
		if current_state == State.RUNNING and not input_buffer.is_forward_held():
			change_state(State.WALKING if not is_zero_approx(direction) else State.IDLE)
		var movement_speed := character_data.run_speed if current_state == State.RUNNING else character_data.walk_speed
		velocity.x = direction * movement_speed
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

	if current_state in [State.IDLE, State.WALKING, State.RUNNING]:
		var next_state := State.IDLE
		if not is_zero_approx(velocity.x) and is_on_floor():
			next_state = State.RUNNING if current_state == State.RUNNING else State.WALKING
		if current_state != next_state:
			change_state(next_state)
		else:
			update_animation()

	# Esci dall'accovacciato quando il giocatore non tiene più giù.
	if current_state == State.CROUCHING and is_player_controlled and input_buffer != null:
		if not input_buffer.is_down_held():
			change_state(State.IDLE)


func change_state(next_state: int, force_victory_exit := false) -> void:
	if next_state != State.ATTACKING and is_instance_valid(_strong_punch_whoosh_audio):
		_strong_punch_whoosh_audio.stop()
	if next_state != State.ATTACKING and is_instance_valid(_medium_punch_whoosh_audio):
		_medium_punch_whoosh_audio.stop()
	var interrupted_back_jump := _back_jump_active and next_state not in [State.BACK_HOP_STARTUP, State.BACK_HOP]
	if interrupted_back_jump:
		_back_jump_active = false
		_back_jump_moving = false
		_back_jump_elapsed = 0.0
	# Solo per la parata ALTA: inserisce la recovery inversa prima di tornare in idle.
	if current_state == State.BLOCKING and next_state == State.IDLE \
			and received_block_height != AttackData.HitHeight.LOW:
		var recovery := get_block_recovery_animation(received_block_height)
		if animated_sprite.sprite_frames.has_animation(recovery):
			super.change_state(State.BLOCK_RECOVERY, force_victory_exit)
			return
	super.change_state(next_state, force_victory_exit)
	if interrupted_back_jump:
		update_physical_collision()
		update_collision_profile()


func update_animation() -> void:
	if _back_jump_active and current_state in [State.BACK_HOP_STARTUP, State.BACK_HOP]:
		return
	super.update_animation()


func _start_light_punch() -> void:
	var attack := character_data.get_attack(&"light_punch")
	if attack == null or light_punch_sheet == null:
		return
	_light_punch_hit_sound_played = false
	var punch_shape := RectangleShape2D.new()
	punch_shape.size = Vector2(160.0, 50.0)
	combat.hitbox_shape.shape = punch_shape
	combat.hitbox.scale.x = 1.0 if is_facing_right else -1.0
	combat.hitbox_shape.position = Vector2(85.0, -170.0)
	combat.hitbox_shape.rotation = 0.0
	combat.begin_animation_attack(&"light_punch", attack)
	_light_punch_whoosh_audio.play()
	animated_sprite.frame = 0
	_update_light_punch_hitbox()


func _start_medium_punch() -> void:
	var attack := character_data.get_attack(&"medium_punch")
	if attack == null or medium_punch_sheet == null:
		return
	_medium_punch_hit_sound_played = false
	var variant := AttackVariantData.new()
	variant.variant_id = &"roster_standing"
	variant.animation_name = &"medium_punch"
	variant.animation_fps = medium_punch_fps
	variant.hit_height = AttackData.HitHeight.HIGH
	variant.hit_reaction_start_frame = 0
	var punch_shape := RectangleShape2D.new()
	punch_shape.size = Vector2(190.0, 45.0)
	combat.hitbox_shape.shape = punch_shape
	combat.hitbox.scale.x = 1.0 if is_facing_right else -1.0
	# Il colpo alto incontra la testa in piedi e passa sopra la hurtbox crouched.
	combat.hitbox_shape.position = Vector2(100.0, -240.0)
	combat.hitbox_shape.rotation = 0.0
	combat.begin_animation_attack(&"medium_punch", attack, variant)
	animated_sprite.frame = 0
	_update_medium_punch_hitbox()
	_play_medium_punch_whoosh(combat.action_generation)


func _play_medium_punch_whoosh(generation: int) -> void:
	await get_tree().create_timer(0.2).timeout
	if generation == combat.action_generation and combat.is_attacking:
		_medium_punch_whoosh_audio.play()


func _update_medium_punch_hitbox() -> void:
	if current_state != State.ATTACKING or not combat.is_attacking:
		return
	if animated_sprite.animation == &"medium_punch" and animated_sprite.frame >= medium_punch_active_start_frame - 1 and animated_sprite.frame <= medium_punch_active_end_frame - 1:
		combat.enable_hitbox()
		combat.resolve_attack_overlap_immediately()
		combat.resolve_attack_overlap(combat.action_generation)
	elif animated_sprite.animation in [&"medium_punch", &"medium_punch_recovery"]:
		combat.disable_hitbox()


func _on_medium_punch_connected(attack_name: StringName, result: int) -> void:
	if attack_name == &"medium_punch" and result in [FighterCombat.DamageResult.HIT, FighterCombat.DamageResult.KNOCKOUT] and not _medium_punch_hit_sound_played:
		_medium_punch_hit_sound_played = true
		_light_punch_hit_audio.play()


func _start_strong_punch() -> void:
	var attack := character_data.get_attack(&"heavy_punch")
	if attack == null or strong_punch_sheet == null:
		return
	_strong_punch_hit_sound_played = false
	var variant := AttackVariantData.new()
	variant.variant_id = &"roster_standing"
	variant.animation_name = &"strong_punch"
	variant.animation_fps = strong_punch_fps
	variant.hit_height = AttackData.HitHeight.HIGH
	variant.causes_knockdown = false
	var punch_shape := RectangleShape2D.new()
	punch_shape.size = Vector2(190.0, 45.0)
	combat.hitbox_shape.shape = punch_shape
	combat.hitbox.scale.x = 1.0 if is_facing_right else -1.0
	combat.hitbox_shape.position = Vector2(100.0, -240.0)
	combat.hitbox_shape.rotation = 0.0
	combat.begin_animation_attack(&"strong_punch", attack, variant)
	animated_sprite.frame = 0
	_update_strong_punch_hitbox()
	_play_strong_punch_whoosh(combat.action_generation)


func get_strong_punch_whoosh_delay() -> float:
	# Delay di Arianna, anticipato se la finestra attiva comincia prima.
	return maxf(0.0, minf(0.5, float(strong_punch_active_start_frame - 1) / strong_punch_fps - 0.1))


func _play_strong_punch_whoosh(generation: int) -> void:
	await get_tree().create_timer(get_strong_punch_whoosh_delay()).timeout
	if generation == combat.action_generation and combat.is_attacking:
		_strong_punch_whoosh_audio.play()


func _update_strong_punch_hitbox() -> void:
	if current_state != State.ATTACKING or not combat.is_attacking or animated_sprite.animation != &"strong_punch":
		return
	if animated_sprite.frame >= strong_punch_active_start_frame - 1 and animated_sprite.frame <= strong_punch_active_end_frame - 1:
		combat.enable_hitbox()
		combat.resolve_attack_overlap_immediately()
		combat.resolve_attack_overlap(combat.action_generation)
	else:
		combat.disable_hitbox()


func _on_strong_punch_connected(attack_name: StringName, result: int) -> void:
	if attack_name == &"heavy_punch" and result in [FighterCombat.DamageResult.HIT, FighterCombat.DamageResult.KNOCKOUT] and not _strong_punch_hit_sound_played:
		_strong_punch_hit_sound_played = true
		_strong_punch_hit_audio.play()


func _update_light_punch_hitbox() -> void:
	if current_state != State.ATTACKING or animated_sprite.animation != &"light_punch" or not combat.is_attacking:
		return
	if animated_sprite.frame >= light_punch_active_start_frame - 1 and animated_sprite.frame <= 6:
		combat.enable_hitbox()
		combat.resolve_attack_overlap(combat.action_generation)
	else:
		combat.disable_hitbox()


func _on_light_punch_connected(attack_name: StringName, result: int) -> void:
	if attack_name == &"light_punch" and result in [FighterCombat.DamageResult.HIT, FighterCombat.DamageResult.KNOCKOUT] and not _light_punch_hit_sound_played:
		_light_punch_hit_sound_played = true
		_light_punch_hit_audio.play()


func _start_back_jump() -> void:
	_back_jump_active = true
	_back_jump_moving = false
	_back_jump_elapsed = 0.0
	_back_jump_start = position
	_back_jump_direction = -1.0 if is_facing_right else 1.0
	last_back_tap_frame = -BACK_HOP_DOUBLE_TAP_WINDOW_FRAMES - 1
	velocity = Vector2.ZERO
	combat.set_guarding(false)
	change_state(State.BACK_HOP_STARTUP)
	animated_sprite.play(&"back_jump")
	animated_sprite.frame = 0


func _process_back_jump(delta: float) -> void:
	if not _back_jump_moving and animated_sprite.frame >= BACK_JUMP_TAKEOFF_FRAME:
		_back_jump_moving = true
		change_state(State.BACK_HOP)
	if _back_jump_moving:
		_back_jump_elapsed = minf(_back_jump_elapsed + delta, BACK_JUMP_DURATION)
		var target_x := clampf(_back_jump_start.x + _back_jump_direction * BACK_JUMP_DISTANCE, stage_left_limit, stage_right_limit)
		position.x = lerpf(_back_jump_start.x, target_x, _back_jump_elapsed / BACK_JUMP_DURATION)
		position.y = _back_jump_start.y
		velocity = Vector2(_back_jump_direction * BACK_JUMP_DISTANCE / BACK_JUMP_DURATION if _back_jump_elapsed < BACK_JUMP_DURATION else 0.0, 0.0)
		collision_layer = 0
		collision_mask = GROUND_COLLISION_LAYER
	else:
		velocity = Vector2.ZERO
	update_ground_shadow()


func reset_fighter(spawn_position: Vector2) -> void:
	_back_jump_active = false
	_back_jump_moving = false
	_back_jump_elapsed = 0.0
	_jump_startup = false
	super.reset_fighter(spawn_position)
	update_physical_collision()


func start_hit_reaction(
	hit_height: AttackData.HitHeight,
	attacker: Fighter,
	start_frame: int = 0,
	apply_pushback: bool = true
) -> float:
	# Medium e low includono la posa iniziale e il ritorno completo.
	var full_sequence := (
		(hit_height == AttackData.HitHeight.MID and hurt_medium_sheet != null)
		or (hit_height == AttackData.HitHeight.LOW and hurt_low_sheet != null)
	)
	var effective_start := 0 if full_sequence else start_frame
	var duration := super.start_hit_reaction(hit_height, attacker, effective_start, apply_pushback)
	if hit_height == AttackData.HitHeight.MID and animated_sprite.sprite_frames.has_animation(&"hurt_mid_reverse"):
		duration += get_animation_duration(&"hurt_mid_reverse")
	if hit_height == AttackData.HitHeight.LOW and not hurt_started_crouched and animated_sprite.sprite_frames.has_animation(&"hurt_low_reverse"):
		duration += get_animation_duration(&"hurt_low_reverse")
	return duration


func start_block_reaction(height: AttackData.HitHeight, started_crouched := false) -> float:
	return super.start_block_reaction(height, started_crouched or is_holding_low_guard())


func get_block_animation(height: AttackData.HitHeight, crouched := false) -> StringName:
	if crouched:
		return &"block_low"
	if height == AttackData.HitHeight.MID and block_medium_sheet != null:
		return &"block_mid"
	return &"block_low" if height == AttackData.HitHeight.LOW else &"block_high"


func get_block_recovery_animation(height: AttackData.HitHeight) -> StringName:
	if block_started_crouched:
		return &"block_low_recovery"
	if height == AttackData.HitHeight.MID and block_medium_sheet != null:
		return &"block_mid_recovery"
	return &"block_low_recovery" if height == AttackData.HitHeight.LOW else &"block_high_recovery"


func play_ko_animation(_start_frame: int = 0) -> void:
	# Le death del roster mostrano sempre tutti i 49 frame, anche su colpi combo.
	super.play_ko_animation(0)


func get_sweep_grounded_hold_duration() -> float:
	return SWEEP_GROUNDED_HOLD


func _on_animation_finished() -> void:
	if current_state == State.ATTACKING and animated_sprite.animation == &"strong_punch":
		combat.finish_animation_attack()
		return
	if current_state == State.ATTACKING and animated_sprite.animation == &"medium_punch":
		combat.disable_hitbox()
		if medium_punch_reverse_fps > 0.0:
			animated_sprite.play(&"medium_punch_recovery")
		else:
			combat.finish_animation_attack()
		return
	if current_state == State.ATTACKING and animated_sprite.animation == &"medium_punch_recovery":
		combat.finish_animation_attack()
		return
	if current_state == State.ATTACKING and animated_sprite.animation == &"light_punch":
		combat.finish_animation_attack()
		return
	if _back_jump_active and animated_sprite.animation == &"back_jump":
		velocity = Vector2.ZERO
		change_state(State.IDLE)
		return
	if finish_crouched_hit_reaction(true):
		return
	if current_state == State.BLOCKING and animated_sprite.animation == &"block_mid":
		animated_sprite.frame = 5
		animated_sprite.pause()
		return
	if current_state == State.BLOCK_RECOVERY:
		if animated_sprite.animation == &"block_low_recovery":
			if input_buffer != null and input_buffer.is_down_held():
				return_to_crouch_pose()
			else:
				change_state(State.IDLE)
			return
		if animated_sprite.animation in [&"block_high_recovery", &"block_mid_recovery"]:
			change_state(State.IDLE)
			return
	if current_state == State.HIT:
		if animated_sprite.animation == &"hurt_low":
			animated_sprite.play(&"hurt_low_reverse")
			return
		if animated_sprite.animation == &"hurt_low_reverse":
			change_state(State.IDLE)
			return
		if animated_sprite.animation == &"hurt_mid" \
				and animated_sprite.sprite_frames.has_animation(&"hurt_mid_reverse"):
			animated_sprite.play(&"hurt_mid_reverse")
			return
		if animated_sprite.animation == &"hurt_mid_reverse":
			change_state(State.IDLE)
			return
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
	if strong_punch_sheet != null:
		_add_sheet_animation(frames, &"strong_punch", strong_punch_sheet, strong_punch_frame_count, strong_punch_columns, Vector2(512.0, 512.0), strong_punch_fps, false, 0, false)
	if medium_punch_sheet != null:
		_add_sheet_animation(frames, &"medium_punch", medium_punch_sheet, medium_punch_frame_count, medium_punch_columns, Vector2(512.0, 512.0), medium_punch_fps, false, 0, false)
		if medium_punch_reverse_fps > 0.0:
			_add_sheet_animation(frames, &"medium_punch_recovery", medium_punch_sheet, medium_punch_frame_count - 1, medium_punch_columns, Vector2(512.0, 512.0), medium_punch_reverse_fps, true, 0, false)
	if light_punch_sheet != null:
		_add_sheet_animation(frames, &"light_punch", light_punch_sheet, 7, 5, Vector2(512.0, 512.0), 24.0, false, 0, false)
		for source_index in range(5, -1, -1):
			var texture := AtlasTexture.new()
			texture.atlas = light_punch_sheet
			texture.region = Rect2(Vector2(source_index % 5, source_index / 5) * 512.0, Vector2(512.0, 512.0))
			frames.add_frame(&"light_punch", texture)
	_add_sheet_animation(frames, &"idle", idle_sheet, idle_frame_count, idle_columns, idle_cell_size, IDLE_FPS)
	if walk_sheet != null:
		_add_sheet_animation(frames, &"walk", walk_sheet, walk_frame_count, walk_columns, walk_cell_size, WALK_FPS)
		_add_sheet_animation(frames, &"backwalk", walk_sheet, walk_frame_count, walk_columns, walk_cell_size, WALK_FPS, true)
	if run_sheet != null:
		_add_sheet_animation(frames, &"run", run_sheet, run_frame_count, run_columns, run_cell_size, RUN_FPS)
	if back_jump_sheet != null:
		_add_sheet_animation(frames, &"back_jump", back_jump_sheet, 20, 5, Vector2(512.0, 512.0), 24.0, false, 0, false)
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
	if block_medium_sheet != null:
		_add_sheet_animation(frames, &"block_mid", block_medium_sheet, 6, 5, Vector2(512.0, 512.0), 24.0, false, 0, false)
		_add_sheet_animation(frames, &"block_mid_recovery", block_medium_sheet, 5, 5, Vector2(512.0, 512.0), 24.0, true, 0, false)
	if hurt_high_sheet != null:
		_add_sheet_animation(frames, &"hurt_high", hurt_high_sheet, hurt_high_frame_count, hurt_high_columns, hurt_high_cell_size, HURT_FPS, false, 0, false)
		if hurt_high_has_reverse and hurt_high_frame_count > 1:
			_add_sheet_animation(frames, &"hurt_high_reverse", hurt_high_sheet, hurt_high_frame_count - 1, hurt_high_columns, hurt_high_cell_size, HURT_FPS, true, 0, false)
	if hurt_medium_sheet != null:
		_add_sheet_animation(frames, &"hurt_mid", hurt_medium_sheet, hurt_medium_frame_count, hurt_medium_columns, hurt_medium_cell_size, HURT_FPS, false, 0, false)
		if hurt_medium_frame_count > 1:
			_add_sheet_animation(frames, &"hurt_mid_reverse", hurt_medium_sheet, hurt_medium_frame_count - 1, hurt_medium_columns, hurt_medium_cell_size, HURT_FPS, true, 0, false)
	if hurt_low_sheet != null:
		_add_sheet_animation(frames, &"hurt_low", hurt_low_sheet, 11, 5, Vector2(512.0, 512.0), HURT_FPS, false, 0, false)
		_add_sheet_animation(frames, &"hurt_low_reverse", hurt_low_sheet, 10, 5, Vector2(512.0, 512.0), HURT_FPS, true, 0, false)
	if death_sheet != null:
		_add_sheet_animation(frames, &"ko", death_sheet, 49, 7, Vector2(512.0, 512.0), KO_FPS, false, 0, false)
	if fall_sheet != null:
		_add_sheet_animation(frames, &"hurted_in_jump", fall_sheet, 20, 7, Vector2(512.0, 512.0), KNOCKDOWN_FPS, false, 0, false)
	if sweep_knockdown_sheet != null:
		_add_sheet_animation(frames, &"sweep_knockdown", sweep_knockdown_sheet, 42, 7, Vector2(512.0, 512.0), KNOCKDOWN_FPS, false, 0, false)
	if knockdown_recovery_sheet != null:
		_add_sheet_animation(frames, &"knockdown_recovery", knockdown_recovery_sheet, 17, knockdown_recovery_columns, Vector2(512.0, 512.0), KNOCKDOWN_FPS, false, 0, false)
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
