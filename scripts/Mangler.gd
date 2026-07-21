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

const GRAVITY := 1400.0
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
const SWEEP_PUSHBACK_SPEED := 240.0
const STANDING_COLLISION_SIZE := Vector2(150.0, 240.0)
const STANDING_COLLISION_POSITION := Vector2(0.0, -120.0)
const CROUCH_COLLISION_SIZE := Vector2(160.0, 175.0)
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
var light_punch_combo_queued := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var head_hurtbox: CollisionShape2D = $Hurtbox/HeadHurtbox
@onready var torso_hurtbox: CollisionShape2D = $Hurtbox/TorsoHurtbox
@onready var legs_hurtbox: CollisionShape2D = $Hurtbox/LegsHurtbox
@onready var combat: FighterCombat = $Combat
@onready var ground_shadow: Polygon2D = $GroundShadow


func _ready() -> void:
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
	combat.configure(character_data)
	add_to_group("fighters")
	update_animation()
	update_collision_profile()
	update_ground_shadow()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if current_state in [State.HIT, State.SWEEP_KNOCKDOWN]:
		velocity.x = move_toward(velocity.x, 0.0, HIT_PUSHBACK_DECELERATION * delta)

	# Il buffer continua a registrare durante startup, recovery e hit-stun.
	if is_player_controlled:
		input_buffer.update(is_facing_right)
	if is_player_controlled and controls_enabled and current_state == State.ATTACKING:
		try_queue_light_punch_combo()

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
		character_data.jump_velocity
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
			if animated_sprite.animation != block_animation or not animated_sprite.is_playing():
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
	"""Passa dal frame finale della parata al settimo frame fermo di crouch."""
	change_state(State.CROUCHING)
	if animated_sprite.sprite_frames.has_animation(&"crouch"):
		animated_sprite.play(&"crouch")
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(&"crouch") - 1
		animated_sprite.pause()
	update_collision_profile()


func return_to_crouch_pose() -> void:
	"""Ripristina e mantiene il settimo frame di crouch dopo un attacco basso."""
	change_state(State.CROUCHING)
	if animated_sprite.sprite_frames.has_animation(&"crouch"):
		animated_sprite.play(&"crouch")
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(&"crouch") - 1
		animated_sprite.pause()
	update_collision_profile()


func start_hit_reaction(
	hit_height: AttackData.HitHeight,
	attacker: Mangler,
	start_frame: int = 0
) -> float:
	"""Avvia da capo la reazione e applica un breve rinculo opposto all'attaccante."""
	received_hit_height = hit_height
	change_state(State.HIT)
	var hit_animation := get_hit_animation(hit_height)
	if animated_sprite.sprite_frames.has_animation(hit_animation):
		animated_sprite.play(hit_animation)
		var final_frame := animated_sprite.sprite_frames.get_frame_count(hit_animation) - 1
		animated_sprite.frame = clampi(start_frame, 0, final_frame)

	var push_direction := -1.0 if is_facing_right else 1.0
	if attacker != null and is_instance_valid(attacker):
		push_direction = signf(global_position.x - attacker.global_position.x)
		if is_zero_approx(push_direction):
			push_direction = -1.0 if is_facing_right else 1.0
	velocity.x = push_direction * HIT_PUSHBACK_SPEED
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


func try_queue_light_punch_combo() -> void:
	"""Converte il jab singolo nella combo se il secondo input arriva entro il sesto frame."""
	if light_punch_combo_queued or not combat.is_attacking or combat.current_attack == null:
		return
	if combat.current_attack.attack_id != &"light_punch":
		return
	if animated_sprite.animation != &"light_punch_single" or animated_sprite.frame > 5:
		return
	if input_buffer.consume_attack(&"light_punch", 1) == FighterInputBuffer.NO_DIRECTION:
		return

	light_punch_combo_queued = true
	var continuation_frame := animated_sprite.frame
	animated_sprite.play(&"light_punch_double")
	animated_sprite.frame = continuation_frame


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
	light_punch_combo_queued = false
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
	attack_started.emit(attack_name)


func _on_combat_attack_finished() -> void:
	light_punch_combo_queued = false
	attack_finished.emit()


func _on_animation_finished() -> void:
	if current_state == State.STANDING_UP and animated_sprite.animation == &"crouch":
		change_state(State.IDLE)
	elif current_state == State.BACK_HOP and animated_sprite.animation == &"dodge" and is_on_floor():
		change_state(State.IDLE)


func _on_animation_frame_changed() -> void:
	if (
		animated_sprite.animation == &"light_punch_double"
		and animated_sprite.frame >= 7
		and current_state == State.ATTACKING
	):
		combat.perform_light_punch_followup()
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
