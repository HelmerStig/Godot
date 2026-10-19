extends IdleRosterFighter
class_name Oscare

const CigaretteProjectile := preload("res://scripts/OscareCigaretteProjectile.gd")
const SmokeProjectile := preload("res://scripts/OscareSmokeBreathProjectile.gd")
const SMOKE_SHEET := preload("res://assets/sprites/characters/oscare/special_2_blow_candidate.png")
const SMOKE_ANIMATION := &"special_2_smoke_breath"
const MOUTH_FRAMES := [0,16,18,20,24,28,32,36,40,43,45,48]
const MOUTH_POSITIONS := [Vector2(284,120),Vector2(285,118),Vector2(289,123),Vector2(307,146),Vector2(333,161),Vector2(341,164),Vector2(342,164),Vector2(342,164),Vector2(336,159),Vector2(305,146),Vector2(293,130),Vector2(283,119)]
const LIGHT_CIGARETTE_SHEET := preload("res://assets/sprites/characters/oscare/special_1_light_cigarette_game.png")
const FLICK_SHEET := preload("res://assets/sprites/characters/oscare/special_1_cigarette_flick_game.png")
const LIGHT_ANIMATION := &"special_1_light_cigarette"
const FLICK_ANIMATION := &"special_1_cigarette_flick"
const SPECIAL_FPS := 60.0
const RELEASE_FRAME := 18 # Visual frame 19, first clean release pose.
const MOTION_WINDOW := 36 # 600 ms at the project's 60 Hz physics rate.
const BUTTON_WINDOW := 10
const IGNITION_SOUND := preload("res://assets/sounds/sfx/siga-accensione.wav")
const IGNITION_FRAME := 5 # Visual frame 6.
const SMOKE_SOUND := preload("res://assets/sounds/sfx/soffio.wav")

var cigarette_special_active := false
var cigarette_spawned := false
var cigarette_strength: StringName = &"light"
var cigarette_facing_right := true
var _ignition_audio: AudioStreamPlayer
var _ignition_sound_played := false
var smoke_special_active := false
var smoke_spawned := false
var smoke_facing_right := true
var _smoke_projectile: Node2D
var _smoke_audio: AudioStreamPlayer


func _ready() -> void:
	super._ready()
	var frames := animated_sprite.sprite_frames
	_add_sheet_animation(frames, LIGHT_ANIMATION, LIGHT_CIGARETTE_SHEET, 20, 7, Vector2(512,512), SPECIAL_FPS, false, 0, false)
	_add_sheet_animation(frames, FLICK_ANIMATION, FLICK_SHEET, 29, 7, Vector2(512,512), SPECIAL_FPS, false, 0, false)
	_add_sheet_animation(frames, SMOKE_ANIMATION, SMOKE_SHEET, 49, 7, Vector2(512,512), SPECIAL_FPS, false, 0, false)
	# Source frame 19 contains a baked flying cigarette. Repeat clean frame 20
	# at release instead, preserving the 29-frame duration and original artwork.
	frames.set_frame(FLICK_ANIMATION, RELEASE_FRAME, frames.get_frame_texture(FLICK_ANIMATION, RELEASE_FRAME + 1))
	combat.attack_cancelled.connect(_clear_cigarette_special)
	combat.attack_cancelled.connect(_clear_smoke_special)
	_ignition_audio = AudioStreamPlayer.new()
	_ignition_audio.name = "CigaretteIgnition"
	_ignition_audio.stream = IGNITION_SOUND
	add_child(_ignition_audio)
	_smoke_audio = AudioStreamPlayer.new()
	_smoke_audio.name = "SmokeBreathAudio"
	_smoke_audio.stream = SMOKE_SOUND
	add_child(_smoke_audio)


func _try_start_character_special() -> bool:
	if (
		cigarette_special_active or smoke_special_active or not controls_enabled
		or (not can_move and current_state != State.STANDING_UP)
		or not is_on_floor() or input_buffer == null
		or current_state not in [State.IDLE, State.WALKING, State.RUNNING, State.CROUCHING, State.STANDING_UP]
	):
		return false
	if input_buffer.get_current_direction() in [FighterInputBuffer.Direction.BACK, FighterInputBuffer.Direction.DOWN_BACK]:
		var back_motion := input_buffer.matches_recent_sequence([
			FighterInputBuffer.Direction.DOWN, FighterInputBuffer.Direction.DOWN_BACK,
			FighterInputBuffer.Direction.BACK,
		], MOTION_WINDOW)
		var back_diagonal := input_buffer.matches_recent_sequence([
			FighterInputBuffer.Direction.DOWN, FighterInputBuffer.Direction.DOWN_BACK,
		], MOTION_WINDOW)
		if back_motion or back_diagonal:
			for button in [&"heavy_punch", &"medium_punch", &"light_punch"]:
				if input_buffer.consume_attack(button, BUTTON_WINDOW) in [FighterInputBuffer.Direction.BACK, FighterInputBuffer.Direction.DOWN_BACK]:
					input_buffer.clear()
					_start_smoke_special()
					return true
	if input_buffer.get_current_direction() not in [FighterInputBuffer.Direction.FORWARD, FighterInputBuffer.Direction.DOWN_FORWARD]:
		return false
	var full_motion := input_buffer.matches_recent_sequence([
		FighterInputBuffer.Direction.DOWN, FighterInputBuffer.Direction.DOWN_FORWARD,
		FighterInputBuffer.Direction.FORWARD,
	], MOTION_WINDOW)
	var diagonal_finish := input_buffer.matches_recent_sequence([
		FighterInputBuffer.Direction.DOWN, FighterInputBuffer.Direction.DOWN_FORWARD,
	], MOTION_WINDOW)
	if not full_motion and not diagonal_finish:
		return false
	for entry in [[&"heavy_punch", &"heavy"], [&"medium_punch", &"medium"], [&"light_punch", &"light"]]:
		var direction := input_buffer.consume_attack(entry[0], BUTTON_WINDOW)
		if direction in [FighterInputBuffer.Direction.DOWN_FORWARD, FighterInputBuffer.Direction.FORWARD]:
			input_buffer.clear()
			_start_cigarette_special(entry[1])
			return true
	return false


func _start_cigarette_special(strength: StringName = &"light") -> void:
	_ignition_audio.stop()
	_ignition_sound_played = false
	cigarette_special_active = true
	cigarette_spawned = false
	cigarette_strength = strength
	cigarette_facing_right = is_facing_right
	combat.set_guarding(false)
	combat.begin_animation_attack(LIGHT_ANIMATION)
	update_collision_profile()


func update_facing_direction() -> void:
	# The projectile and the release hand keep the direction chosen at startup.
	if not cigarette_special_active and not smoke_special_active:
		super.update_facing_direction()


func change_state(next_state: int, force_victory_exit := false) -> void:
	if smoke_special_active and next_state != State.ATTACKING:
		_clear_smoke_special()
		if combat.is_attacking:
			combat.cancel_current_action()
	if cigarette_special_active and next_state != State.ATTACKING:
		_clear_cigarette_special()
		if combat.is_attacking:
			combat.cancel_current_action()
	super.change_state(next_state, force_victory_exit)


func _clear_cigarette_special(stop_ignition: bool = true) -> void:
	cigarette_special_active = false
	cigarette_spawned = false
	cigarette_strength = &"light"
	_ignition_sound_played = false
	if stop_ignition and is_instance_valid(_ignition_audio):
		_ignition_audio.stop()


func _on_animation_finished() -> void:
	if smoke_special_active and current_state == State.ATTACKING:
		if animated_sprite.animation == LIGHT_ANIMATION:
			animated_sprite.play(SMOKE_ANIMATION)
			return
		if animated_sprite.animation == SMOKE_ANIMATION:
			_clear_smoke_special(false)
			combat.finish_animation_attack()
			return
	if cigarette_special_active and current_state == State.ATTACKING:
		if animated_sprite.animation == LIGHT_ANIMATION:
			animated_sprite.play(FLICK_ANIMATION)
			return
		if animated_sprite.animation == FLICK_ANIMATION:
			# Let the one-second recording finish after the normal recovery.
			_clear_cigarette_special(false)
			combat.finish_animation_attack()
			return
	super._on_animation_finished()


func _on_animation_frame_changed() -> void:
	super._on_animation_frame_changed()
	if smoke_special_active and current_state == State.ATTACKING and combat.is_attacking and animated_sprite.animation == SMOKE_ANIMATION:
		if not smoke_spawned and animated_sprite.frame >= SmokeProjectile.START_FRAME and animated_sprite.frame < SmokeProjectile.START_FRAME + SmokeProjectile.FRAME_COUNT and controls_enabled:
			_spawn_smoke()
		if is_instance_valid(_smoke_projectile):
			_smoke_projectile.sync_from_fighter()
	if (
		(cigarette_special_active or smoke_special_active) and not _ignition_sound_played
		and current_state == State.ATTACKING and combat.is_attacking
		and controls_enabled and combat.current_health > 0
		and animated_sprite.animation == LIGHT_ANIMATION
		and animated_sprite.frame >= IGNITION_FRAME
	):
		_ignition_sound_played = true
		_ignition_audio.play()
	if (
		cigarette_special_active and not cigarette_spawned
		and current_state == State.ATTACKING and combat.is_attacking
		and controls_enabled and combat.current_health > 0
		and animated_sprite.animation == FLICK_ANIMATION
		and animated_sprite.frame >= RELEASE_FRAME
	):
		_spawn_cigarette()


func _spawn_cigarette() -> Node2D:
	cigarette_spawned = true
	var projectile := CigaretteProjectile.new()
	projectile.setup(self, cigarette_facing_right, cigarette_strength)
	get_parent().add_child(projectile)
	# Canvas-space fingertip in the clean release pose, transformed by the same
	# scale/offset/facing as the fighter sprite (also correct when facing left).
	var hand := Vector2(390, 142) - Vector2(256,256)
	if animated_sprite.flip_h:
		hand.x = -hand.x
	projectile.global_position = animated_sprite.to_global(hand + animated_sprite.offset)
	return projectile


func reset_fighter(spawn_position: Vector2) -> void:
	_clear_smoke_special()
	_clear_cigarette_special()
	for audio in get_tree().get_nodes_in_group("oscare_cigarette_impact_audio"):
		if audio.get_meta(&"source_id", 0) == get_instance_id():
			audio.queue_free()
	for projectile in get_tree().get_nodes_in_group("oscare_cigarette_projectile"):
		if projectile.source_fighter == self:
			projectile.queue_free()
	super.reset_fighter(spawn_position)


func _start_smoke_special() -> void:
	_clear_cigarette_special()
	_smoke_audio.stop()
	smoke_special_active = true
	smoke_spawned = false
	smoke_facing_right = is_facing_right
	combat.set_guarding(false)
	combat.begin_animation_attack(LIGHT_ANIMATION)
	update_collision_profile()


func _spawn_smoke() -> Node2D:
	smoke_spawned = true
	_smoke_projectile = SmokeProjectile.new()
	_smoke_projectile.setup(self, smoke_facing_right)
	get_parent().add_child(_smoke_projectile)
	_smoke_audio.play()
	return _smoke_projectile


func _clear_smoke_special(stop_audio: bool = true) -> void:
	if stop_audio:
		if is_instance_valid(_smoke_audio):
			_smoke_audio.stop()
		if smoke_special_active and is_instance_valid(_ignition_audio):
			_ignition_audio.stop()
	smoke_special_active = false
	smoke_spawned = false
	if is_instance_valid(_smoke_projectile):
		_smoke_projectile.queue_free()
	_smoke_projectile = null


func get_smoke_mouth_global_position() -> Vector2:
	var frame := animated_sprite.frame
	var point: Vector2 = MOUTH_POSITIONS[-1]
	for index in range(1, MOUTH_FRAMES.size()):
		if frame <= MOUTH_FRAMES[index]:
			var weight := inverse_lerp(float(MOUTH_FRAMES[index-1]), float(MOUTH_FRAMES[index]), float(frame))
			point = MOUTH_POSITIONS[index-1].lerp(MOUTH_POSITIONS[index], weight)
			break
	point -= Vector2(256,256)
	if animated_sprite.flip_h:
		point.x = -point.x
	return animated_sprite.to_global(point + animated_sprite.offset)
