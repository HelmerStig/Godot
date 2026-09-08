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

const GROUND_COLLISION_LAYER := 1
const FIGHTER_COLLISION_LAYER := 8
const SHADOW_MAX_HEIGHT := 800.0
const SHADOW_GROUND_ALPHA := 0.3
const SHADOW_AIR_ALPHA := 0.12
const SHADOW_AIR_SCALE := 0.58
const SHADOW_FLOOR_OFFSET_Y := 20.0
const RUN_DOUBLE_TAP_WINDOW_FRAMES := 15
const BACK_HOP_DOUBLE_TAP_WINDOW_FRAMES := 15
const ATTACK_FOREGROUND_Z_OFFSET := 1
const HIT_PUSHBACK_SPEED := 180.0
const SWEEP_PUSHBACK_SPEED := 240.0
const HURT_HIGH_EFFECT_OFFSET := Vector2(0.0, -220.0)
const HURT_MID_EFFECT_OFFSET := Vector2(0.0, -150.0)
const HURT_LOW_EFFECT_OFFSET := Vector2(0.0, -72.0)
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
	KNOCKED_DOWN,
	VICTORY
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
var last_forward_tap_frame := -RUN_DOUBLE_TAP_WINDOW_FRAMES - 1
var last_back_tap_frame := -BACK_HOP_DOUBLE_TAP_WINDOW_FRAMES - 1
var pending_jump_direction := 0.0
var pending_jump_horizontal_multiplier := 1.0
var attack_afterimage_spawn_count := 0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var head_hurtbox: CollisionShape2D = $Hurtbox/HeadHurtbox
@onready var torso_hurtbox: CollisionShape2D = $Hurtbox/TorsoHurtbox
@onready var legs_hurtbox: CollisionShape2D = $Hurtbox/LegsHurtbox
@onready var combat: FighterCombat = $Combat
@onready var ground_shadow: Polygon2D = $GroundShadow


func _ready() -> void:
	default_z_index = z_index
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


## API usata dai componenti condivisi. Le specializzazioni implementano animazioni
## e reazioni concrete senza costringere Fighter a conoscere un personaggio.
func change_state(next_state: int, force_victory_exit := false) -> void:
	if current_state == State.VICTORY and next_state != State.VICTORY and not force_victory_exit:
		return
	if current_state == next_state:
		update_animation()
		return
	var previous_state := current_state
	current_state = next_state
	match current_state:
		State.IDLE, State.WALKING, State.RUNNING, State.JUMPING, State.CROUCHING:
			can_move = true
		_:
			can_move = false
			velocity.x = 0.0
	update_animation()
	update_collision_profile()
	state_changed.emit(previous_state, current_state)


func get_input_action(action_name: String) -> StringName:
	if input_buffer != null:
		return input_buffer.get_action(action_name)
	return StringName("p%d_%s" % [player_number, action_name])


func is_holding_back() -> bool:
	return input_buffer != null and input_buffer.is_back_held()


func is_holding_low_guard() -> bool:
	return input_buffer != null and input_buffer.is_down_held() and input_buffer.is_back_held()


func is_attack_in_front(attacker: Fighter) -> bool:
	if attacker == null or not is_instance_valid(attacker):
		return false
	return (attacker.global_position.x > global_position.x) == is_facing_right


func start_block_reaction(
	hit_height: AttackData.HitHeight,
	started_crouched: bool = false
) -> float:
	received_block_height = hit_height
	block_started_crouched = started_crouched
	change_state(State.BLOCKING)
	var animation_name := get_block_animation(hit_height, started_crouched)
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	return get_animation_duration(animation_name)


func start_block_recovery() -> float:
	change_state(State.BLOCK_RECOVERY)
	var animation_name := get_block_recovery_animation(received_block_height)
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	return get_animation_duration(animation_name)


func return_to_crouch_after_low_block() -> void:
	return_to_crouch_pose()


func return_to_crouch_pose() -> void:
	change_state(State.CROUCHING)
	if animated_sprite.sprite_frames.has_animation(&"crouch"):
		animated_sprite.play(&"crouch")
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(&"crouch") - 1
		animated_sprite.pause()
	update_collision_profile()


func start_hit_reaction(
	hit_height: AttackData.HitHeight,
	attacker: Fighter,
	start_frame: int = 0,
	apply_pushback: bool = true
) -> float:
	received_hit_height = hit_height
	change_state(State.HIT)
	var animation_name := get_hit_animation(hit_height)
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
		animated_sprite.frame = clampi(
			start_frame, 0, animated_sprite.sprite_frames.get_frame_count(animation_name) - 1
		)
	spawn_hurt_blue_explosion(hit_height)
	if apply_pushback:
		var direction := -1.0 if is_facing_right else 1.0
		if is_instance_valid(attacker):
			direction = signf(global_position.x - attacker.global_position.x)
			if is_zero_approx(direction):
				direction = -1.0 if is_facing_right else 1.0
		velocity.x = direction * HIT_PUSHBACK_SPEED
	else:
		velocity.x = 0.0
	return get_animation_duration(animation_name, start_frame)


func spawn_hurt_blue_explosion(hit_height: AttackData.HitHeight) -> Node2D:
	var explosion := Node2D.new()
	explosion.name = "LowHurtBlueExplosion"
	explosion.add_to_group("hurt_blue_explosion")
	explosion.z_index = z_index + 4
	var parent_node: Node = get_tree().current_scene
	if parent_node == null:
		parent_node = get_tree().root
	parent_node.add_child(explosion)
	var offset := HURT_MID_EFFECT_OFFSET
	if hit_height == AttackData.HitHeight.HIGH:
		offset = HURT_HIGH_EFFECT_OFFSET
	elif hit_height == AttackData.HitHeight.LOW:
		offset = HURT_LOW_EFFECT_OFFSET
	explosion.global_position = global_position + offset
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var flash := Sprite2D.new()
	flash.name = "BlueFlash"
	flash.texture = create_hurt_blue_glow_texture()
	flash.scale = Vector2(0.32, 0.32)
	flash.material = material
	explosion.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector2(1.2, 1.2), 0.14)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.28)
	var sparks := CPUParticles2D.new()
	sparks.name = "BlueSparks"
	sparks.amount = 64
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.lifetime = 0.42
	sparks.spread = 180.0
	sparks.initial_velocity_min = 85.0
	sparks.initial_velocity_max = 285.0
	sparks.scale_amount_min = 1.3
	sparks.scale_amount_max = 3.8
	sparks.color = Color(0.24, 0.76, 1.0, 0.94)
	sparks.material = material
	explosion.add_child(sparks)
	sparks.emitting = true
	get_tree().create_timer(0.52).timeout.connect(explosion.queue_free)
	return explosion


func create_hurt_blue_glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.78, 0.96, 1.0, 0.98),
		Color(0.2, 0.7, 1.0, 0.58),
		Color(0.05, 0.3, 0.95, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.44, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 180
	texture.height = 180
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func start_airborne_hit_knockdown(attacker: Fighter) -> void:
	change_state(State.HIT)
	if animated_sprite.sprite_frames.has_animation(&"hurted_in_jump"):
		animated_sprite.play(&"hurted_in_jump")
	var direction := -1.0 if is_facing_right else 1.0
	if is_instance_valid(attacker):
		direction = signf(global_position.x - attacker.global_position.x)
	velocity.x = direction * HIT_PUSHBACK_SPEED


func hold_airborne_hit_landing_pose() -> void:
	velocity = Vector2.ZERO
	if animated_sprite.sprite_frames.has_animation(&"hurted_in_jump"):
		animated_sprite.play(&"hurted_in_jump")
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(&"hurted_in_jump") - 1
		animated_sprite.pause()


func start_sweep_knockdown(attacker: Fighter) -> float:
	change_state(State.SWEEP_KNOCKDOWN)
	if animated_sprite.sprite_frames.has_animation(&"sweep_knockdown"):
		animated_sprite.play(&"sweep_knockdown")
	var direction := -1.0 if is_facing_right else 1.0
	if is_instance_valid(attacker):
		direction = signf(global_position.x - attacker.global_position.x)
	velocity.x = direction * SWEEP_PUSHBACK_SPEED
	return get_animation_duration(&"sweep_knockdown")


func get_sweep_grounded_hold_duration() -> float:
	return FighterCombat.SWEEP_GROUNDED_HOLD


func start_knockdown_recovery() -> float:
	velocity.x = 0.0
	change_state(State.KNOCKDOWN_RECOVERY)
	if animated_sprite.sprite_frames.has_animation(&"knockdown_recovery"):
		animated_sprite.play(&"knockdown_recovery")
	return get_animation_duration(&"knockdown_recovery")


func spawn_hit_effect(_world_position: Vector2, _facing_right: bool = true) -> void:
	pass


func restore_default_render_order() -> void:
	z_index = default_z_index


func apply_character_data() -> void:
	if character_data == null:
		character_data = CharacterData.create_default()


func update_animation() -> void:
	if force_idle_until_landing:
		if animated_sprite.sprite_frames.has_animation(&"idle") and (animated_sprite.animation != &"idle" or not animated_sprite.is_playing()):
			animated_sprite.play(&"idle")
		return
	if current_state in [State.ATTACKING, State.VICTORY]:
		return
	if current_state == State.CROUCHING:
		if animated_sprite.sprite_frames.has_animation(&"crouch") and animated_sprite.animation != &"crouch":
			animated_sprite.play(&"crouch")
		return
	if current_state == State.STANDING_UP:
		if animated_sprite.sprite_frames.has_animation(&"crouch"):
			animated_sprite.play(&"crouch", -1.0)
		return
	if current_state == State.HIT:
		var hit_animation := get_hit_animation(received_hit_height)
		if animated_sprite.sprite_frames.has_animation(hit_animation) and (animated_sprite.animation != hit_animation or not animated_sprite.is_playing()):
			animated_sprite.play(hit_animation)
		return
	if current_state == State.BLOCKING:
		var block_animation := get_block_animation(received_block_height, block_started_crouched)
		if animated_sprite.sprite_frames.has_animation(block_animation) and animated_sprite.animation != block_animation:
			animated_sprite.play(block_animation)
		return
	if current_state == State.BLOCK_RECOVERY:
		var recovery_animation := get_block_recovery_animation(received_block_height)
		if animated_sprite.sprite_frames.has_animation(recovery_animation) and (animated_sprite.animation != recovery_animation or not animated_sprite.is_playing()):
			animated_sprite.play(recovery_animation)
		return
	if current_state == State.SWEEP_KNOCKDOWN:
		if animated_sprite.sprite_frames.has_animation(&"sweep_knockdown") and (animated_sprite.animation != &"sweep_knockdown" or not animated_sprite.is_playing()):
			animated_sprite.play(&"sweep_knockdown")
		return
	if current_state == State.KNOCKDOWN_RECOVERY:
		if animated_sprite.sprite_frames.has_animation(&"knockdown_recovery") and (animated_sprite.animation != &"knockdown_recovery" or not animated_sprite.is_playing()):
			animated_sprite.play(&"knockdown_recovery")
		return
	if current_state == State.KNOCKED_DOWN:
		if animated_sprite.sprite_frames.has_animation(&"ko") and animated_sprite.animation != &"ko":
			animated_sprite.play(&"ko")
		return
	var animation_name: StringName = &"idle"
	if current_state == State.WALKING:
		animation_name = &"backwalk" if is_moving_backward() else &"walk"
	elif current_state == State.RUNNING:
		animation_name = &"run"
	elif current_state in [State.JUMP_STARTUP, State.JUMPING]:
		animation_name = &"jump"
	if animated_sprite.sprite_frames.has_animation(animation_name):
		if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
			animated_sprite.play(animation_name)


func update_sprite_scale() -> void:
	pass


func start_jump(horizontal_direction: float) -> void:
	pending_jump_direction = horizontal_direction
	pending_jump_horizontal_multiplier = 1.0
	velocity = Vector2.ZERO
	change_state(State.JUMP_STARTUP)


func begin_jump_ascent() -> void:
	velocity = Vector2(
		pending_jump_direction * character_data.air_speed * pending_jump_horizontal_multiplier,
		character_data.jump_velocity
	)
	change_state(State.JUMPING)


func get_hit_animation(hit_height: AttackData.HitHeight) -> StringName:
	match hit_height:
		AttackData.HitHeight.HIGH:
			return &"hurt_high"
		AttackData.HitHeight.LOW:
			return &"hurt_low"
		_:
			return &"hurt_mid"


func get_block_animation(hit_height: AttackData.HitHeight, started_crouched := false) -> StringName:
	var animation_name: StringName
	match hit_height:
		AttackData.HitHeight.HIGH:
			animation_name = &"block_high"
		AttackData.HitHeight.LOW:
			animation_name = &"block_low_crouched" if started_crouched else &"block_low"
		_:
			animation_name = &"block_mid"
	return animation_name if animated_sprite.sprite_frames.has_animation(animation_name) else &"block_mid"


func get_block_recovery_animation(hit_height: AttackData.HitHeight) -> StringName:
	var animation_name: StringName
	match hit_height:
		AttackData.HitHeight.HIGH:
			animation_name = &"block_high_recovery"
		AttackData.HitHeight.LOW:
			animation_name = &"block_low_recovery"
		_:
			animation_name = &"block_mid_recovery"
	return animation_name


func get_animation_duration(animation_name: StringName, start_frame := 0) -> float:
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return 0.0
	var frames := animated_sprite.sprite_frames
	var speed := frames.get_animation_speed(animation_name)
	if speed <= 0.0:
		return 0.0
	var duration := 0.0
	for frame_index in range(clampi(start_frame, 0, frames.get_frame_count(animation_name) - 1), frames.get_frame_count(animation_name)):
		duration += frames.get_frame_duration(animation_name, frame_index) / speed
	return duration


func is_moving_backward() -> bool:
	return not is_zero_approx(velocity.x) and (velocity.x < 0.0 if is_facing_right else velocity.x > 0.0)


func update_state() -> void:
	if current_state in [State.BACK_HOP_STARTUP, State.JUMP_STARTUP, State.STANDING_UP, State.ATTACKING, State.BLOCKING, State.BLOCK_RECOVERY, State.HIT, State.SWEEP_KNOCKDOWN, State.KNOCKDOWN_RECOVERY, State.KNOCKED_DOWN, State.VICTORY]:
		return
	if not is_on_floor():
		change_state(State.JUMPING)
	elif current_state == State.JUMPING and velocity.y >= 0.0:
		velocity.x = 0.0
		change_state(State.IDLE)
	elif is_zero_approx(velocity.x) and current_state in [State.WALKING, State.RUNNING]:
		change_state(State.IDLE)


func update_physical_collision() -> void:
	var airborne := current_state == State.JUMPING or not is_on_floor() or current_state == State.BACK_HOP
	collision_layer = 0 if airborne else FIGHTER_COLLISION_LAYER
	collision_mask = GROUND_COLLISION_LAYER if airborne else GROUND_COLLISION_LAYER | FIGHTER_COLLISION_LAYER


func duplicate_collision_shapes() -> void:
	for shape_node in [collision_shape, head_hurtbox, torso_hurtbox, legs_hurtbox]:
		if shape_node.shape:
			shape_node.shape = shape_node.shape.duplicate()


func update_collision_profile() -> void:
	var ratio := get_crouch_progress()
	set_box_profile(collision_shape, STANDING_COLLISION_SIZE.lerp(CROUCH_COLLISION_SIZE, ratio), STANDING_COLLISION_POSITION.lerp(CROUCH_COLLISION_POSITION, ratio))
	set_box_profile(head_hurtbox, STANDING_HEAD_SIZE.lerp(CROUCH_HEAD_SIZE, ratio), STANDING_HEAD_POSITION.lerp(CROUCH_HEAD_POSITION, ratio))
	set_box_profile(torso_hurtbox, STANDING_TORSO_SIZE.lerp(CROUCH_TORSO_SIZE, ratio), STANDING_TORSO_POSITION.lerp(CROUCH_TORSO_POSITION, ratio))
	set_box_profile(legs_hurtbox, STANDING_LEGS_SIZE.lerp(CROUCH_LEGS_SIZE, ratio), STANDING_LEGS_POSITION.lerp(CROUCH_LEGS_POSITION, ratio))


func get_crouch_progress() -> float:
	if animated_sprite.animation.begins_with("crouched_"):
		return 1.0
	if current_state not in [State.CROUCHING, State.STANDING_UP] or animated_sprite.animation != &"crouch":
		return 0.0
	var final_frame := animated_sprite.sprite_frames.get_frame_count(&"crouch") - 1
	return clampf(float(animated_sprite.frame) / float(final_frame), 0.0, 1.0) if final_frame > 0 else 1.0


func set_box_profile(shape_node: CollisionShape2D, size: Vector2, box_position: Vector2) -> void:
	var rectangle := shape_node.shape as RectangleShape2D
	if rectangle:
		rectangle.size = size
		shape_node.position = box_position


func update_ground_shadow() -> void:
	if is_on_floor():
		shadow_ground_y = global_position.y
	var height := maxf(shadow_ground_y - global_position.y, 0.0)
	var ratio := clampf(height / SHADOW_MAX_HEIGHT, 0.0, 1.0)
	ground_shadow.global_position = Vector2(global_position.x, shadow_ground_y + SHADOW_FLOOR_OFFSET_Y)
	ground_shadow.scale = Vector2(lerpf(1.0, SHADOW_AIR_SCALE, ratio), lerpf(1.0, 0.72, ratio))
	ground_shadow.modulate.a = lerpf(SHADOW_GROUND_ALPHA, SHADOW_AIR_ALPHA, ratio)


func update_facing_direction() -> void:
	if not is_instance_valid(opponent):
		return
	var distance := opponent.global_position.x - global_position.x
	if not is_zero_approx(distance) and (distance > 0.0) != is_facing_right:
		flip_character()


func flip_character() -> void:
	is_facing_right = not is_facing_right
	animated_sprite.flip_h = not is_facing_right
	combat.hitbox.scale.x = 1.0 if is_facing_right else -1.0
	update_animation()
	update_sprite_scale()


func reset_fighter(spawn_position: Vector2) -> void:
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
	change_state(State.IDLE, true)
	can_move = true
	if input_buffer != null:
		input_buffer.clear()
	update_ground_shadow()


func bring_attacker_to_foreground() -> void:
	var opponent_z := opponent.z_index if is_instance_valid(opponent) else default_z_index
	z_index = maxi(default_z_index, opponent_z + ATTACK_FOREGROUND_Z_OFFSET)


func get_attack_motion_profile(_animation_name: StringName) -> Dictionary:
	return {}


func emit_attack_motion_effect() -> void:
	if current_state != State.ATTACKING:
		return
	var profile := get_attack_motion_profile(animated_sprite.animation)
	if profile.is_empty():
		return
	var last_frame := animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation) - 1
	if last_frame <= 0:
		return
	var start_frame := floori(float(last_frame) * float(profile["start_ratio"]))
	var end_frame := ceili(float(last_frame) * float(profile["end_ratio"]))
	if animated_sprite.frame >= start_frame and animated_sprite.frame <= end_frame:
		spawn_attack_motion_afterimage(profile)


func spawn_attack_motion_afterimage(profile: Dictionary) -> void:
	var texture := animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	if texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.name = "AttackAfterimage"
	ghost.add_to_group("attack_afterimage")
	ghost.texture = texture
	ghost.position = animated_sprite.position
	ghost.rotation = animated_sprite.rotation
	ghost.scale = animated_sprite.scale
	ghost.scale.x *= float(profile["stretch"])
	ghost.flip_h = animated_sprite.flip_h
	ghost.z_index = animated_sprite.z_index - 1
	var tint: Color = profile["tint"]
	ghost.modulate = Color(tint.r, tint.g, tint.b, float(profile["alpha"]))
	add_child(ghost)
	attack_afterimage_spawn_count += 1
	var direction := 1.0 if is_facing_right else -1.0
	var lifetime := float(profile["lifetime"])
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, lifetime)
	tween.parallel().tween_property(ghost, "position:x", ghost.position.x - direction * float(profile["offset"]), lifetime)
	tween.tween_callback(ghost.queue_free)


func _on_combat_health_changed(current_health: int, max_health: int) -> void:
	health_changed.emit(current_health, max_health)


func _on_combat_knocked_out() -> void:
	knocked_out.emit()


func _on_combat_attack_started(_attack_name: StringName) -> void:
	update_collision_profile()


func _on_combat_attack_finished() -> void:
	restore_default_render_order()
	attack_finished.emit()


func _on_animation_finished() -> void:
	pass


func _on_animation_frame_changed() -> void:
	emit_attack_motion_effect()
	if animated_sprite.animation == &"crouch":
		update_collision_profile()
