extends Node2D
class_name AriannaTullioProjectile

## Un gatto di Arianna entra fuori schermo, alterna casualmente corsa e salto,
## attacca tre volte e prosegue oltre il lato opposto dell'arena.

signal completed(cat: AriannaTullioProjectile)

enum State { APPROACHING, ATTACKING, FACE_JUMP, EXITING }

const RUN_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/cats/Tullio-run.png"
)
const JUMP_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/cats/Tullio-jump.png"
)
const ATTACK_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/cats/Tullio-attack.png"
)
const TILDA_RUN_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/cats/Tilda-run.png"
)
const TILDA_JUMP_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/cats/Tilda-jump.png"
)
const TILDA_ATTACK_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/cats/Tilda-attack.png"
)
const TELMA_RUN_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/cats/Telma-run.png"
)
const TELMA_JUMP_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/cats/Telma-jump.png"
)
const TELMA_ATTACK_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/cats/Telma-attack.png"
)
const RUN_FRAME_COUNT := 42
const RUN_COLUMNS := 7
const JUMP_FRAME_COUNT := 15
const JUMP_COLUMNS := 5
const ATTACK_FRAME_COUNT := 12
const ATTACK_COLUMNS := 5
const CELL_SIZE := Vector2(512.0, 512.0)
const ANIMATION_FPS := 24.0
const MOVE_SPEED := 680.0
const ATTACK_TRIGGER_DISTANCE := 150.0
const ATTACK_CONTACT_DISTANCE := 62.0
const ATTACK_HIT_FRAME := 8 # Zero-based: fotogramma visibile 9.
const ATTACK_LOOPS := 3
const DAMAGE_PER_HIT := 1
const FACE_JUMP_CHANCE := 0.30
const FACE_JUMP_TRIGGER_DISTANCE := 300.0
const FACE_JUMP_HIT_FRAME := 7 # Zero-based: fotogramma visibile 8.
const FACE_JUMP_DAMAGE := 2
const FACE_JUMP_FACE_OFFSET_Y := 0.0
const FACE_JUMP_HORIZONTAL_SPEED_MULTIPLIER := 1
const FACE_JUMP_AFTERIMAGE_INTERVAL := 2
const FACE_JUMP_AFTERIMAGE_LIFETIME := 0.16
const NORMAL_HIT_SHAKE_STRENGTH := 2.5
const NORMAL_HIT_SHAKE_DURATION := 0.08
const FACE_JUMP_SHAKE_STRENGTH := 7.0
const FACE_JUMP_SHAKE_DURATION := 0.18
const OFFSCREEN_MARGIN := 85.0
const SPRITE_SCALE := Vector2(0.41, 0.41)
const SPRITE_POSITION := Vector2(0.0, -22.0)

const CAT_PROFILES := {
	&"tullio": {
		"run": RUN_SHEET, "jump": JUMP_SHEET, "attack": ATTACK_SHEET,
		"run_frames": 42, "speed": 680.0,
	},
	&"tilda": {
		"run": TILDA_RUN_SHEET, "jump": TILDA_JUMP_SHEET, "attack": TILDA_ATTACK_SHEET,
		"run_frames": 42, "speed": 755.0,
	},
	&"telma": {
		"run": TELMA_RUN_SHEET, "jump": TELMA_JUMP_SHEET, "attack": TELMA_ATTACK_SHEET,
		"run_frames": 49, "speed": 625.0,
	},
}

var source_fighter: Fighter
var target_fighter: Fighter
var cat_id: StringName = &"tullio"
var move_speed := MOVE_SPEED
var run_sheet: Texture2D = RUN_SHEET
var jump_sheet: Texture2D = JUMP_SHEET
var attack_sheet: Texture2D = ATTACK_SHEET
var run_frame_count := RUN_FRAME_COUNT
var travel_direction := 1.0
var visible_left := 0.0
var visible_right := 1152.0
var current_state := State.APPROACHING
var attack_loops_completed := 0
var hit_applied_in_current_loop := false
var uses_face_jump_attack := false
var face_jump_hit_applied := false
var face_jump_ground_y := 0.0
var animated_sprite: AnimatedSprite2D
var random := RandomNumberGenerator.new()
var completion_emitted := false
var movement_particles: CPUParticles2D
var running_dust: CPUParticles2D
var face_jump_particles: CPUParticles2D
var face_jump_afterimage_spawn_count := 0


func setup(
	owner_fighter: Fighter,
	target: Fighter,
	selected_cat: StringName = &"tullio",
	speed_multiplier: float = 1.0
) -> void:
	source_fighter = owner_fighter
	target_fighter = target
	cat_id = selected_cat if CAT_PROFILES.has(selected_cat) else &"tullio"
	var profile: Dictionary = CAT_PROFILES[cat_id]
	run_sheet = profile["run"]
	jump_sheet = profile["jump"]
	attack_sheet = profile["attack"]
	run_frame_count = profile["run_frames"]
	move_speed = float(profile["speed"]) * speed_multiplier
	random.randomize()
	uses_face_jump_attack = random.randf() < FACE_JUMP_CHANCE
	travel_direction = 1.0 if owner_fighter.is_facing_right else -1.0
	visible_left = owner_fighter.stage_left_limit
	visible_right = owner_fighter.stage_right_limit


func _ready() -> void:
	add_to_group("arianna_cat_projectile")
	add_to_group("arianna_tullio_projectile") # Compatibilita con scene e test esistenti.
	name = String(cat_id).capitalize()
	random.randomize()
	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedSprite2D"
	animated_sprite.sprite_frames = _create_frames()
	animated_sprite.scale = SPRITE_SCALE
	animated_sprite.position = SPRITE_POSITION
	animated_sprite.flip_h = travel_direction < 0.0
	animated_sprite.animation_looped.connect(_on_animation_looped)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	add_child(animated_sprite)
	_create_movement_particles()
	_play_random_approach_animation()


func _create_movement_particles() -> void:
	movement_particles = CPUParticles2D.new()
	movement_particles.name = "MovementTrail"
	movement_particles.amount = 12
	movement_particles.lifetime = 0.24
	movement_particles.randomness = 0.55
	movement_particles.local_coords = false
	movement_particles.direction = Vector2(-travel_direction, 0.0)
	movement_particles.spread = 16.0
	movement_particles.gravity = Vector2.ZERO
	movement_particles.initial_velocity_min = 65.0
	movement_particles.initial_velocity_max = 125.0
	movement_particles.scale_amount_min = 1.0
	movement_particles.scale_amount_max = 2.4
	movement_particles.color = Color(1.0, 0.82, 0.36, 0.20)
	movement_particles.position = Vector2(-travel_direction * 32.0, -28.0)
	add_child(movement_particles)
	_create_running_dust()
	_create_face_jump_particles()


func _create_running_dust() -> void:
	running_dust = CPUParticles2D.new()
	running_dust.name = "RunningDust"
	running_dust.emitting = false
	running_dust.amount = 24
	running_dust.lifetime = 0.32
	running_dust.randomness = 0.65
	running_dust.local_coords = false
	running_dust.direction = Vector2(-travel_direction, -0.18)
	running_dust.spread = 28.0
	running_dust.gravity = Vector2(0.0, 120.0)
	running_dust.initial_velocity_min = 45.0
	running_dust.initial_velocity_max = 95.0
	running_dust.scale_amount_min = 0.18
	running_dust.scale_amount_max = 0.42
	running_dust.position = Vector2(-travel_direction * 24.0, -4.0)
	var dust_gradient := Gradient.new()
	dust_gradient.colors = PackedColorArray([
		Color(1.0, 0.94, 0.80, 0.88),
		Color(0.82, 0.76, 0.66, 0.0),
	])
	var dust_texture := GradientTexture2D.new()
	dust_texture.width = 10
	dust_texture.height = 10
	dust_texture.fill = GradientTexture2D.FILL_RADIAL
	dust_texture.fill_from = Vector2(0.5, 0.5)
	dust_texture.fill_to = Vector2(1.0, 0.5)
	dust_texture.gradient = dust_gradient
	running_dust.texture = dust_texture
	add_child(running_dust)


func _create_face_jump_particles() -> void:
	face_jump_particles = CPUParticles2D.new()
	face_jump_particles.name = "FaceJumpTrail"
	face_jump_particles.emitting = false
	face_jump_particles.amount = 18
	face_jump_particles.lifetime = 0.22
	face_jump_particles.randomness = 0.5
	face_jump_particles.local_coords = false
	face_jump_particles.direction = Vector2(-travel_direction, 0.15)
	face_jump_particles.spread = 24.0
	face_jump_particles.gravity = Vector2(0.0, 45.0)
	face_jump_particles.initial_velocity_min = 55.0
	face_jump_particles.initial_velocity_max = 110.0
	face_jump_particles.scale_amount_min = 0.22
	face_jump_particles.scale_amount_max = 0.48
	face_jump_particles.position = Vector2(-travel_direction * 28.0, -28.0)
	var particle_gradient := Gradient.new()
	particle_gradient.colors = PackedColorArray([
		Color(0.45, 0.88, 1.0, 0.72),
		Color(1.0, 0.82, 0.30, 0.0),
	])
	var particle_texture := GradientTexture2D.new()
	particle_texture.width = 12
	particle_texture.height = 12
	particle_texture.fill = GradientTexture2D.FILL_RADIAL
	particle_texture.fill_from = Vector2(0.5, 0.5)
	particle_texture.fill_to = Vector2(1.0, 0.5)
	particle_texture.gradient = particle_gradient
	face_jump_particles.texture = particle_texture
	add_child(face_jump_particles)


func _physics_process(delta: float) -> void:
	match current_state:
		State.APPROACHING:
			if is_instance_valid(target_fighter):
				var distance_to_target := (
					(target_fighter.global_position.x - global_position.x) * travel_direction
				)
				var trigger_distance := (
					FACE_JUMP_TRIGGER_DISTANCE if uses_face_jump_attack else ATTACK_TRIGGER_DISTANCE
				)
				if distance_to_target <= trigger_distance:
					if uses_face_jump_attack:
						_start_face_jump_attack()
					else:
						_start_attack()
					return
			_move_forward(delta)
		State.ATTACKING:
			_move_to_attack_contact(delta)
		State.FACE_JUMP:
			_move_forward(delta, FACE_JUMP_HORIZONTAL_SPEED_MULTIPLIER)
			_update_face_jump_height()
			if _is_fully_outside_opposite_side():
				_emit_completion()
				queue_free()
		State.EXITING:
			_move_forward(delta)
			if _is_fully_outside_opposite_side():
				_emit_completion()
				queue_free()


func _move_forward(delta: float, speed_multiplier: float = 1.0) -> void:
	position.x += travel_direction * move_speed * speed_multiplier * delta


func _move_to_attack_contact(delta: float) -> void:
	if not is_instance_valid(target_fighter):
		return
	var contact_x := target_fighter.global_position.x - travel_direction * ATTACK_CONTACT_DISTANCE
	var next_x := global_position.x + travel_direction * move_speed * delta
	global_position.x = minf(next_x, contact_x) if travel_direction > 0.0 else maxf(next_x, contact_x)


func _play_random_approach_animation() -> void:
	if current_state != State.APPROACHING:
		return
	var approach_animation: StringName = &"jump" if random.randf() < 0.5 else &"run"
	running_dust.emitting = approach_animation == &"run"
	animated_sprite.play(approach_animation)


func _start_attack() -> void:
	if current_state != State.APPROACHING:
		return
	current_state = State.ATTACKING
	attack_loops_completed = 0
	hit_applied_in_current_loop = false
	movement_particles.emitting = false
	running_dust.emitting = false
	animated_sprite.play(&"attack")


func _start_face_jump_attack() -> void:
	if current_state != State.APPROACHING:
		return
	current_state = State.FACE_JUMP
	face_jump_hit_applied = false
	face_jump_ground_y = global_position.y
	running_dust.emitting = false
	face_jump_particles.emitting = true
	animated_sprite.play(&"jump")
	animated_sprite.frame = 0
	_update_face_jump_height()


func _on_animation_looped() -> void:
	match current_state:
		State.APPROACHING:
			_play_random_approach_animation()
		State.ATTACKING:
			attack_loops_completed += 1
			if attack_loops_completed >= ATTACK_LOOPS:
				current_state = State.EXITING
				movement_particles.emitting = true
				running_dust.emitting = true
				animated_sprite.play(&"run")
			else:
				hit_applied_in_current_loop = false
		State.FACE_JUMP:
			global_position.y = face_jump_ground_y
			face_jump_particles.emitting = false
			current_state = State.EXITING
			running_dust.emitting = true
			animated_sprite.play(&"run")


func _on_frame_changed() -> void:
	if current_state == State.FACE_JUMP:
		_update_face_jump_height()
		if animated_sprite.frame % FACE_JUMP_AFTERIMAGE_INTERVAL == 1:
			_spawn_face_jump_afterimage()
	if (
		current_state == State.FACE_JUMP
		and animated_sprite.frame >= FACE_JUMP_HIT_FRAME
		and not face_jump_hit_applied
	):
		_apply_face_jump_hit()
	if (
		current_state == State.ATTACKING
		and animated_sprite.frame >= ATTACK_HIT_FRAME
		and not hit_applied_in_current_loop
	):
		_apply_cat_hit()


func _spawn_face_jump_afterimage() -> void:
	var current_texture := animated_sprite.sprite_frames.get_frame_texture(
		animated_sprite.animation,
		animated_sprite.frame
	)
	var scene_parent := get_parent()
	if current_texture == null or scene_parent == null:
		return
	var afterimage := Sprite2D.new()
	afterimage.name = "CatJumpAfterimage"
	afterimage.add_to_group("arianna_cat_jump_afterimage")
	afterimage.texture = current_texture
	afterimage.scale = animated_sprite.scale
	afterimage.flip_h = animated_sprite.flip_h
	afterimage.z_index = z_index - 1
	afterimage.modulate = Color(0.48, 0.86, 1.0, 0.24)
	scene_parent.add_child(afterimage)
	afterimage.global_position = animated_sprite.global_position - Vector2(travel_direction * 12.0, 0.0)
	face_jump_afterimage_spawn_count += 1
	var fade_tween := afterimage.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(afterimage, "modulate:a", 0.0, FACE_JUMP_AFTERIMAGE_LIFETIME)
	fade_tween.tween_property(
		afterimage,
		"global_position:x",
		afterimage.global_position.x - travel_direction * 16.0,
		FACE_JUMP_AFTERIMAGE_LIFETIME
	)
	fade_tween.chain().tween_callback(afterimage.queue_free)


func _update_face_jump_height() -> void:
	if current_state != State.FACE_JUMP or not is_instance_valid(target_fighter):
		return
	var face_y := (
		target_fighter.head_hurtbox.global_position.y + FACE_JUMP_FACE_OFFSET_Y
		if is_instance_valid(target_fighter.head_hurtbox)
		else target_fighter.global_position.y - 150.0
	)
	var frame := animated_sprite.frame
	if frame <= FACE_JUMP_HIT_FRAME:
		var rise_progress := float(frame) / float(maxi(1, FACE_JUMP_HIT_FRAME))
		global_position.y = lerpf(face_jump_ground_y, face_y, smoothstep(0.0, 1.0, rise_progress))
	else:
		var descent_frames := maxi(1, JUMP_FRAME_COUNT - 1 - FACE_JUMP_HIT_FRAME)
		var descent_progress := float(frame - FACE_JUMP_HIT_FRAME) / float(descent_frames)
		global_position.y = lerpf(face_y, face_jump_ground_y, smoothstep(0.0, 1.0, descent_progress))


func _apply_face_jump_hit() -> void:
	face_jump_hit_applied = true
	if not is_instance_valid(target_fighter) or not is_instance_valid(source_fighter):
		return
	target_fighter.combat.take_damage(
		FACE_JUMP_DAMAGE,
		source_fighter,
		0.28,
		0.16,
		AttackData.HitHeight.HIGH,
		false,
		0,
		0,
		false,
		true
	)
	_request_screen_shake(FACE_JUMP_SHAKE_STRENGTH, FACE_JUMP_SHAKE_DURATION)


func _apply_cat_hit() -> void:
	hit_applied_in_current_loop = true
	if not is_instance_valid(target_fighter) or not is_instance_valid(source_fighter):
		return
	global_position.x = (
		target_fighter.global_position.x - travel_direction * ATTACK_CONTACT_DISTANCE
	)
	target_fighter.combat.take_damage(
		DAMAGE_PER_HIT,
		source_fighter,
		0.28,
		0.16,
		AttackData.HitHeight.LOW,
		false,
		0,
		0,
		false,
		true
	)
	_request_screen_shake(NORMAL_HIT_SHAKE_STRENGTH, NORMAL_HIT_SHAKE_DURATION)


func _request_screen_shake(strength: float, duration: float) -> void:
	var active_camera := get_viewport().get_camera_2d()
	if active_camera == null:
		return
	var arena := active_camera.get_parent()
	if arena != null and arena.has_method("request_screen_shake"):
		arena.request_screen_shake(strength, duration)


func _exit_tree() -> void:
	_emit_completion()


func _emit_completion() -> void:
	if completion_emitted:
		return
	completion_emitted = true
	completed.emit(self)


func _is_fully_outside_opposite_side() -> bool:
	if travel_direction > 0.0:
		return global_position.x > visible_right + OFFSCREEN_MARGIN
	return global_position.x < visible_left - OFFSCREEN_MARGIN


func _create_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	_add_atlas_animation(frames, &"run", run_sheet, run_frame_count, RUN_COLUMNS)
	_add_atlas_animation(frames, &"jump", jump_sheet, JUMP_FRAME_COUNT, JUMP_COLUMNS)
	_add_atlas_animation(frames, &"attack", attack_sheet, ATTACK_FRAME_COUNT, ATTACK_COLUMNS)
	return frames


func _add_atlas_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	atlas: Texture2D,
	frame_count: int,
	columns: int
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, ANIMATION_FPS)
	frames.set_animation_loop(animation_name, true)
	for source_index in range(frame_count):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = atlas
		atlas_frame.region = Rect2(
			Vector2(float(source_index % columns), float(source_index / columns)) * CELL_SIZE,
			CELL_SIZE
		)
		frames.add_frame(animation_name, atlas_frame)


func cancel_for_round_reset() -> void:
	completion_emitted = true
	queue_free()
