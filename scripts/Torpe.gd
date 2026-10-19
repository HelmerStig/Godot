extends IdleRosterFighter
class_name Torpe

const BeerProjectile := preload("res://scripts/TorpeBeerBottleProjectile.gd")
const BEER_FRAMES := preload("res://assets/sprites/characters/torpe/special_1_beer_throw_64_frames.tres")
const BEER_ANIMATION := &"special_1_beer_throw"
const RELEASE_FRAME := 37 # Visual frame 38, native source frame 33: the hand opens.
const MOTION_WINDOW := 36
const BUTTON_WINDOW := 10
const WeldingSparks := preload("res://scripts/TorpeWeldingSparks.gd")
const WELDING_FRAMES := preload("res://assets/sprites/characters/torpe/special_2_welding_64_frames.tres")
const WELDING_ANIMATION := &"special_2_welding"
const WELDING_START_FRAME := 42 # Runtime frame 43, native frame 38: first welding arc.
const WELDING_END_FRAME := 63
const TORCH_FRAMES := [42,45,48,51,55,58,62,63]
const TORCH_POSITIONS := [Vector2(348,141),Vector2(347,136),Vector2(350,132),Vector2(352,134),Vector2(346,135),Vector2(350,133),Vector2(350,133),Vector2(347,139)]

var beer_special_active := false
var beer_spawned := false
var beer_strength: StringName = &"light"
var beer_facing_right := true
var welding_special_active := false
var welding_spawned := false
var welding_strength: StringName = &"light"
var welding_facing_right := true
var _welding_sparks: Node2D


func _ready() -> void:
	super._ready()
	var frames := animated_sprite.sprite_frames
	frames.add_animation(BEER_ANIMATION)
	frames.set_animation_speed(BEER_ANIMATION, 64.0)
	frames.set_animation_loop(BEER_ANIMATION, false)
	for index in BEER_FRAMES.get_frame_count(BEER_ANIMATION):
		var texture := BEER_FRAMES.get_frame_texture(BEER_ANIMATION, index) as AtlasTexture
		var local_texture := texture.duplicate() as AtlasTexture
		# Native frames 33/34 contain a flying bottle above the actor. Crop only
		# that transparent top strip, keeping a 512px virtual canvas and alignment.
		if index in [37, 38]:
			local_texture.region.position.y += 40
			local_texture.region.size.y -= 40
			local_texture.margin = Rect2(0, 40, 0, 40)
		frames.add_frame(BEER_ANIMATION, local_texture, BEER_FRAMES.get_frame_duration(BEER_ANIMATION, index))
	combat.attack_cancelled.connect(_clear_beer_special)
	frames.add_animation(WELDING_ANIMATION)
	frames.set_animation_speed(WELDING_ANIMATION, 60.0)
	frames.set_animation_loop(WELDING_ANIMATION, false)
	for index in WELDING_FRAMES.get_frame_count(WELDING_ANIMATION):
		frames.add_frame(WELDING_ANIMATION, WELDING_FRAMES.get_frame_texture(WELDING_ANIMATION,index), WELDING_FRAMES.get_frame_duration(WELDING_ANIMATION,index))
	combat.attack_cancelled.connect(_clear_welding_special)


func _try_start_character_special() -> bool:
	if (
		beer_special_active or welding_special_active or not controls_enabled or input_buffer == null
		or not is_on_floor() or (not can_move and current_state != State.STANDING_UP)
		or current_state not in [State.IDLE, State.WALKING, State.RUNNING, State.CROUCHING, State.STANDING_UP]
	):
		return false
	if input_buffer.get_current_direction() in [FighterInputBuffer.Direction.BACK, FighterInputBuffer.Direction.DOWN_BACK]:
		var back_motion := input_buffer.matches_recent_sequence([
			FighterInputBuffer.Direction.DOWN, FighterInputBuffer.Direction.DOWN_BACK, FighterInputBuffer.Direction.BACK,
		], MOTION_WINDOW)
		var back_diagonal := input_buffer.matches_recent_sequence([
			FighterInputBuffer.Direction.DOWN, FighterInputBuffer.Direction.DOWN_BACK,
		], MOTION_WINDOW)
		if back_motion or back_diagonal:
			for entry in [[&"heavy_punch", &"heavy"], [&"medium_punch", &"medium"], [&"light_punch", &"light"]]:
				if input_buffer.consume_attack(entry[0], BUTTON_WINDOW) in [FighterInputBuffer.Direction.BACK, FighterInputBuffer.Direction.DOWN_BACK]:
					input_buffer.clear()
					_start_welding_special(entry[1])
					return true
	if input_buffer.get_current_direction() not in [FighterInputBuffer.Direction.FORWARD, FighterInputBuffer.Direction.DOWN_FORWARD]:
		return false
	var full_motion := input_buffer.matches_recent_sequence([
		FighterInputBuffer.Direction.DOWN, FighterInputBuffer.Direction.DOWN_FORWARD, FighterInputBuffer.Direction.FORWARD,
	], MOTION_WINDOW)
	var diagonal_finish := input_buffer.matches_recent_sequence([
		FighterInputBuffer.Direction.DOWN, FighterInputBuffer.Direction.DOWN_FORWARD,
	], MOTION_WINDOW)
	if not full_motion and not diagonal_finish:
		return false
	for entry in [[&"heavy_punch", &"heavy"], [&"medium_punch", &"medium"], [&"light_punch", &"light"]]:
		if input_buffer.consume_attack(entry[0], BUTTON_WINDOW) in [FighterInputBuffer.Direction.FORWARD, FighterInputBuffer.Direction.DOWN_FORWARD]:
			input_buffer.clear()
			_start_beer_special(entry[1])
			return true
	return false


func _start_beer_special(strength: StringName = &"light") -> void:
	beer_special_active = true
	beer_spawned = false
	beer_strength = strength
	beer_facing_right = is_facing_right
	combat.set_guarding(false)
	combat.begin_animation_attack(BEER_ANIMATION)
	update_collision_profile()


func update_facing_direction() -> void:
	if not beer_special_active and not welding_special_active:
		super.update_facing_direction()


func change_state(next_state: int, force_victory_exit := false) -> void:
	if welding_special_active and next_state != State.ATTACKING:
		_clear_welding_special()
		if combat.is_attacking:
			combat.cancel_current_action()
	if beer_special_active and next_state != State.ATTACKING:
		_clear_beer_special()
		if combat.is_attacking:
			combat.cancel_current_action()
	super.change_state(next_state, force_victory_exit)


func _clear_beer_special() -> void:
	beer_special_active = false
	beer_spawned = false


func _on_animation_finished() -> void:
	if welding_special_active and animated_sprite.animation == WELDING_ANIMATION:
		_clear_welding_special(true)
		combat.finish_animation_attack()
		return
	if beer_special_active and animated_sprite.animation == BEER_ANIMATION:
		_clear_beer_special()
		combat.finish_animation_attack()
		return
	super._on_animation_finished()


func _on_animation_frame_changed() -> void:
	super._on_animation_frame_changed()
	if (
		welding_special_active and controls_enabled and combat.current_health > 0
		and current_state == State.ATTACKING and combat.is_attacking
		and animated_sprite.animation == WELDING_ANIMATION
		and animated_sprite.frame >= WELDING_START_FRAME and animated_sprite.frame <= WELDING_END_FRAME
	):
		if not welding_spawned:
			_spawn_welding_sparks()
		if is_instance_valid(_welding_sparks):
			_welding_sparks.sync_from_fighter()
	if (
		beer_special_active and not beer_spawned and controls_enabled
		and current_state == State.ATTACKING and combat.is_attacking and combat.current_health > 0
		and animated_sprite.animation == BEER_ANIMATION and animated_sprite.frame >= RELEASE_FRAME
	):
		_spawn_beer()


func _spawn_beer() -> Node2D:
	beer_spawned = true
	var projectile := BeerProjectile.new()
	projectile.setup(self, beer_facing_right, beer_strength)
	get_parent().add_child(projectile)
	var hand := Vector2(390, 62) - Vector2(256, 256)
	if animated_sprite.flip_h:
		hand.x = -hand.x
	projectile.global_position = animated_sprite.to_global(hand + animated_sprite.offset)
	projectile.global_position.x += (1.0 if beer_facing_right else -1.0) * projectile.visible_length * 0.45
	return projectile


func reset_fighter(spawn_position: Vector2) -> void:
	_clear_beer_special()
	_clear_welding_special()
	for group in ["torpe_beer_projectile", "torpe_beer_shatter", "torpe_welding_sparks"]:
		for effect in get_tree().get_nodes_in_group(group):
			if effect.source_fighter == self:
				effect.queue_free()
	for group in ["torpe_beer_break_audio", "torpe_beer_trail"]:
		for effect in get_tree().get_nodes_in_group(group):
			if effect.get_meta(&"source_id", 0) == get_instance_id():
				effect.queue_free()
	super.reset_fighter(spawn_position)


func _start_welding_special(strength: StringName = &"light") -> void:
	welding_special_active = true
	welding_spawned = false
	welding_strength = strength
	welding_facing_right = is_facing_right
	combat.set_guarding(false)
	combat.begin_animation_attack(WELDING_ANIMATION)
	update_collision_profile()


func _spawn_welding_sparks() -> Node2D:
	welding_spawned = true
	_welding_sparks = WeldingSparks.new()
	_welding_sparks.setup(self,welding_facing_right,welding_strength)
	get_parent().add_child(_welding_sparks)
	return _welding_sparks


func _clear_welding_special(allow_tail := false) -> void:
	welding_special_active = false
	welding_spawned = false
	if is_instance_valid(_welding_sparks):
		_welding_sparks.stop_emitting(not allow_tail)
	_welding_sparks = null


func get_welding_tip_global_position() -> Vector2:
	var point: Vector2 = TORCH_POSITIONS[-1]
	var frame := animated_sprite.frame
	if frame <= TORCH_FRAMES[0]:
		point = TORCH_POSITIONS[0]
	else:
		for index in range(1,TORCH_FRAMES.size()):
			if frame <= TORCH_FRAMES[index]:
				point = TORCH_POSITIONS[index-1].lerp(TORCH_POSITIONS[index],inverse_lerp(float(TORCH_FRAMES[index-1]),float(TORCH_FRAMES[index]),float(frame)))
				break
	point -= Vector2(256,256)
	if animated_sprite.flip_h:
		point.x = -point.x
	return animated_sprite.to_global(point + animated_sprite.offset)
