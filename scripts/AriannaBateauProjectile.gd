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
const RUN_SOUND := preload(
	"res://assets/sprites/characters/arianna/sound/corsa-bato.wav"
)
const ATTACK_SOUND := preload(
	"res://assets/sprites/characters/arianna/sound/abbaio-ringhio.wav"
)
const RUN_FRAME_COUNT := 49
const RUN_COLUMNS := 7
const ATTACK_FRAME_COUNT := 25
const ATTACK_COLUMNS := 5
const ATTACK_SOUND_FRAME := 8 # Zero-based: 0 corrisponde al fotogramma visibile 1.
const BACK_TO_RUN_FRAME_COUNT := 25
const BACK_TO_RUN_COLUMNS := 5
const CELL_SIZE := Vector2(512.0, 512.0)
const ANIMATION_FPS := 24.0
const MOVE_SPEED := 800.0
const ATTACK_TRIGGER_DISTANCE := 620.0
const ATTACK_CONTACT_DISTANCE := 70.0
const ATTACK_HIT_FRAME := 17
const DAMAGE_RATIO := 0.30
const HIT_STOP_DURATION := 0.07
const SCREEN_SHAKE_DISTANCE := 4.0
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
var run_dust: CPUParticles2D
var speed_trail: CPUParticles2D
var blue_magic_trail: CPUParticles2D
var run_audio_player: AudioStreamPlayer
var attack_audio_player: AudioStreamPlayer
var attack_sound_played := false


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
	_create_movement_effects()
	run_audio_player = _create_audio_player("RunAudio", RUN_SOUND, 0)
	attack_audio_player = _create_audio_player("AttackAudio", ATTACK_SOUND, -1.0)
	animated_sprite.play(&"run")
	run_audio_player.play()


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
	attack_sound_played = false
	animated_sprite.play(&"attack")
	_play_attack_sound_on_configured_frame()


func _create_audio_player(
	player_name: String,
	audio_stream: AudioStream,
	volume_db: float
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.stream = audio_stream
	player.volume_db = volume_db
	add_child(player)
	return player


func _on_frame_changed() -> void:
	_play_attack_sound_on_configured_frame()
	if current_state == State.ATTACKING and animated_sprite.frame % 3 == 0:
		_spawn_attack_afterimage()
	if (
		current_state == State.ATTACKING
		and animated_sprite.frame >= ATTACK_HIT_FRAME
		and not has_hit
	):
		_apply_bite()


func _play_attack_sound_on_configured_frame() -> void:
	if (
		current_state != State.ATTACKING
		or animated_sprite.animation != &"attack"
		or animated_sprite.frame < ATTACK_SOUND_FRAME
		or attack_sound_played
	):
		return
	attack_sound_played = true
	attack_audio_player.play()


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
	_spawn_bite_impact()
	_apply_hit_stop()
	_apply_screen_shake()


func _create_movement_effects() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	speed_trail = CPUParticles2D.new()
	speed_trail.name = "SpeedTrail"
	speed_trail.amount = 18
	speed_trail.lifetime = 0.24
	speed_trail.preprocess = 0.2
	speed_trail.position = Vector2(-travel_direction * 70.0, -65.0)
	speed_trail.direction = Vector2(-travel_direction, 0.0)
	speed_trail.spread = 8.0
	speed_trail.initial_velocity_min = 180.0
	speed_trail.initial_velocity_max = 330.0
	speed_trail.scale_amount_min = 0.5
	speed_trail.scale_amount_max = 1.5
	speed_trail.color = Color(0.72, 0.9, 1.0, 0.42)
	speed_trail.material = additive
	speed_trail.z_index = -2
	add_child(speed_trail)

	blue_magic_trail = CPUParticles2D.new()
	blue_magic_trail.name = "BlueMagicTrail"
	blue_magic_trail.amount = 58
	blue_magic_trail.lifetime = 0.38
	blue_magic_trail.preprocess = 0.28
	blue_magic_trail.position = Vector2(-travel_direction * 58.0, -52.0)
	blue_magic_trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	blue_magic_trail.emission_rect_extents = Vector2(18.0, 34.0)
	blue_magic_trail.direction = Vector2(-travel_direction, 0.0)
	blue_magic_trail.spread = 24.0
	blue_magic_trail.initial_velocity_min = 35.0
	blue_magic_trail.initial_velocity_max = 85.0
	blue_magic_trail.gravity = Vector2(0.0, -8.0)
	blue_magic_trail.scale_amount_min = 0.22
	blue_magic_trail.scale_amount_max = 0.58
	var blue_fade := Gradient.new()
	blue_fade.colors = PackedColorArray([
		Color(0.22, 0.68, 1.0, 0.82),
		Color(0.16, 0.48, 1.0, 0.0),
	])
	blue_magic_trail.color_ramp = blue_fade
	blue_magic_trail.texture = _create_blue_particle_texture()
	blue_magic_trail.material = additive
	blue_magic_trail.z_index = -3
	add_child(blue_magic_trail)

	run_dust = CPUParticles2D.new()
	run_dust.name = "RunDust"
	run_dust.amount = 14
	run_dust.lifetime = 0.32
	run_dust.preprocess = 0.18
	run_dust.position = Vector2(-travel_direction * 38.0, 72.0)
	run_dust.direction = Vector2(-travel_direction, -0.28).normalized()
	run_dust.spread = 34.0
	run_dust.initial_velocity_min = 45.0
	run_dust.initial_velocity_max = 120.0
	run_dust.gravity = Vector2(0.0, 130.0)
	run_dust.scale_amount_min = 0.8
	run_dust.scale_amount_max = 2.0
	run_dust.color = Color(0.72, 0.65, 0.54, 0.34)
	run_dust.z_index = -1
	add_child(run_dust)


func _create_blue_particle_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.9, 0.98, 1.0, 1.0),
		Color(0.12, 0.58, 1.0, 0.82),
		Color(0.08, 0.28, 1.0, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 18
	texture.height = 18
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _spawn_attack_afterimage() -> void:
	var texture := animated_sprite.sprite_frames.get_frame_texture(
		animated_sprite.animation, animated_sprite.frame
	)
	if texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.name = "BateauAfterimage"
	ghost.add_to_group("arianna_bateau_afterimage")
	ghost.texture = texture
	ghost.position = animated_sprite.position - Vector2(travel_direction * 100.0, 0.0)
	ghost.scale = animated_sprite.scale
	ghost.flip_h = animated_sprite.flip_h
	ghost.z_index = animated_sprite.z_index - 1
	ghost.modulate = Color(0.55, 0.82, 1.0, 0.28)
	add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.16)
	tween.tween_callback(ghost.queue_free)


func _spawn_bite_impact() -> Node2D:
	var impact := Node2D.new()
	impact.name = "BateauBiteImpact"
	impact.add_to_group("arianna_bateau_bite_impact")
	impact.z_index = 30
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(impact)
	impact.global_position = target_fighter.global_position + Vector2(0.0, -105.0)
	var sparks := CPUParticles2D.new()
	sparks.name = "BiteSparks"
	sparks.one_shot = true
	sparks.amount = 28
	sparks.lifetime = 0.28
	sparks.explosiveness = 0.92
	sparks.direction = Vector2(travel_direction, -0.15)
	sparks.spread = 145.0
	sparks.initial_velocity_min = 110.0
	sparks.initial_velocity_max = 310.0
	sparks.gravity = Vector2(0.0, 260.0)
	sparks.scale_amount_min = 1.2
	sparks.scale_amount_max = 3.2
	sparks.color = Color(1.0, 0.62, 0.12, 0.95)
	impact.add_child(sparks)
	var flash := Polygon2D.new()
	flash.name = "BiteFlash"
	flash.polygon = PackedVector2Array([
		Vector2(-34.0, 0.0), Vector2(-10.0, -10.0), Vector2(0.0, -42.0),
		Vector2(10.0, -10.0), Vector2(42.0, 0.0), Vector2(10.0, 10.0),
		Vector2(0.0, 42.0), Vector2(-10.0, 10.0),
	])
	flash.color = Color(1.0, 0.95, 0.72, 0.9)
	impact.add_child(flash)
	var tween := impact.create_tween()
	tween.tween_property(flash, "scale", Vector2(1.7, 1.7), 0.06)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.1)
	tween.tween_interval(0.3)
	tween.tween_callback(impact.queue_free)
	return impact


func _apply_hit_stop() -> void:
	set_physics_process(false)
	animated_sprite.pause()
	if is_instance_valid(target_fighter):
		target_fighter.animated_sprite.pause()
	await get_tree().create_timer(HIT_STOP_DURATION).timeout
	if is_instance_valid(self):
		set_physics_process(true)
		animated_sprite.play()
	if is_instance_valid(target_fighter):
		target_fighter.animated_sprite.play()


func _apply_screen_shake() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var original_offset := camera.offset
	var tween := camera.create_tween()
	tween.tween_property(camera, "offset", original_offset + Vector2(SCREEN_SHAKE_DISTANCE, -2.0), 0.035)
	tween.tween_property(camera, "offset", original_offset + Vector2(-3.0, 2.0), 0.035)
	tween.tween_property(camera, "offset", original_offset, 0.05)


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
