extends IdleRosterFighter
class_name Mileto

const SHOULDER_SHEET := preload("res://assets/sprites/characters/mileto/special_1_shoulder.png")
const ShoulderAura := preload("res://scripts/MiletoShoulderAura.gd")
const SHOULDER_SOUND := preload("res://assets/sounds/sfx/scossa.wav")
const SHOULDER_HIT_SOUND := preload("res://assets/sounds/sfx/strong-punch.wav")
const GuitarProjectile := preload("res://scripts/MiletoGuitarProjectile.gd")
const GUITAR_WINDUP_SHEET := preload("res://assets/sprites/characters/mileto/Mileto-special_2_-_lightning_guitar_windup.png")
const GUITAR_THROW_SHEET := preload("res://assets/sprites/characters/mileto/special_2_guitar_throw.png")
const GUITAR_WINDUP_ANIMATION := &"special_2_guitar_windup"
const GUITAR_THROW_ANIMATION := &"special_2_guitar_throw"
const GUITAR_RELEASE_FRAME := 20 # Original frame 21 is the first empty-handed pose.
const GUITAR_MATERIALIZE_FRAME := 11 # Source frame 12: the first electric outline appears.
const GUITAR_MATERIALIZE_SOUND := preload("res://assets/sounds/sfx/chitarra-electricity.wav")
const SHOULDER_ANIMATION := &"special_1_shoulder"
const FRAME_COUNT := 40
const RUSH_FRAME := 12 # Source frame 13: shoulder is presented.
const HOLD_FRAME := 30 # Source frame 31, not the old padded candidate timeline.
const MOTION_WINDOW := 36
const BUTTON_WINDOW := 10
const SPEEDS := {&"light": 800.0, &"medium": 1100.0, &"heavy": 1400.0}
const COLORS := {&"light": Color(0.2,0.75,1.0), &"medium": Color(1.0,0.45,0.08), &"heavy": Color(1.0,0.12,0.08)}
const DAMAGE := 15

var shoulder_active := false
var shoulder_strength: StringName = &"light"
var shoulder_facing_right := true
var shoulder_connected := false
var _shoulder_cast: ShapeCast2D
var _shoulder_aura: Node2D
var _shoulder_audio: AudioStreamPlayer
var _shoulder_hit_audio: AudioStreamPlayer
var guitar_special_active := false
var guitar_spawned := false
var guitar_strength: StringName = &"light"
var guitar_facing_right := true
var _guitar_materialize_played := false
var _guitar_materialize_audio: AudioStreamPlayer


func _ready() -> void:
	super._ready()
	var frames := animated_sprite.sprite_frames
	_add_sheet_animation(frames, SHOULDER_ANIMATION, SHOULDER_SHEET, FRAME_COUNT, 8, Vector2(512,512), 48.0, false, 0, false)
	_add_sheet_animation(frames,GUITAR_WINDUP_ANIMATION,GUITAR_WINDUP_SHEET,45,8,Vector2(512,512),100.0,false,0,false)
	_add_sheet_animation(frames,GUITAR_THROW_ANIMATION,GUITAR_THROW_SHEET,23,8,Vector2(512,512),60.0,false,0,false)
	_shoulder_cast = ShapeCast2D.new()
	_shoulder_cast.name = "ShoulderContact"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(80,95)
	_shoulder_cast.shape = shape
	_shoulder_cast.collision_mask = 4
	_shoulder_cast.collide_with_areas = true
	_shoulder_cast.collide_with_bodies = false
	_shoulder_cast.enabled = false
	_shoulder_cast.max_results = 16
	add_child(_shoulder_cast)
	_shoulder_cast.add_exception($Hurtbox)
	_shoulder_audio = AudioStreamPlayer.new()
	_shoulder_audio.name = "ShoulderElectricity"
	_shoulder_audio.stream = SHOULDER_SOUND
	_shoulder_audio.volume_db = -4.0
	add_child(_shoulder_audio)
	_shoulder_hit_audio = AudioStreamPlayer.new()
	_shoulder_hit_audio.name = "ShoulderHeavyHit"
	_shoulder_hit_audio.stream = SHOULDER_HIT_SOUND
	_shoulder_hit_audio.volume_db = -3.0
	add_child(_shoulder_hit_audio)
	_guitar_materialize_audio = AudioStreamPlayer.new()
	_guitar_materialize_audio.name = "GuitarMaterialization"
	_guitar_materialize_audio.stream = GUITAR_MATERIALIZE_SOUND
	_guitar_materialize_audio.volume_db = -4.0
	add_child(_guitar_materialize_audio)
	combat.attack_cancelled.connect(_clear_shoulder)
	combat.attack_cancelled.connect(_clear_guitar_special)


func _try_start_character_special() -> bool:
	if shoulder_active or guitar_special_active or not controls_enabled or input_buffer == null or not is_on_floor():
		return false
	if (not can_move and current_state != State.STANDING_UP) or current_state not in [State.IDLE,State.WALKING,State.RUNNING,State.CROUCHING,State.STANDING_UP]:
		return false
	if input_buffer.get_current_direction() in [FighterInputBuffer.Direction.BACK,FighterInputBuffer.Direction.DOWN_BACK]:
		var back_motion := input_buffer.matches_recent_sequence([FighterInputBuffer.Direction.DOWN,FighterInputBuffer.Direction.DOWN_BACK,FighterInputBuffer.Direction.BACK],MOTION_WINDOW)
		var back_diagonal := input_buffer.matches_recent_sequence([FighterInputBuffer.Direction.DOWN,FighterInputBuffer.Direction.DOWN_BACK],MOTION_WINDOW)
		if back_motion or back_diagonal:
			for entry in [[&"heavy_punch",&"heavy"],[&"medium_punch",&"medium"],[&"light_punch",&"light"]]:
				if input_buffer.consume_attack(entry[0],BUTTON_WINDOW) in [FighterInputBuffer.Direction.BACK,FighterInputBuffer.Direction.DOWN_BACK]:
					input_buffer.clear()
					_start_guitar_special(entry[1])
					return true
	if input_buffer.get_current_direction() not in [FighterInputBuffer.Direction.FORWARD,FighterInputBuffer.Direction.DOWN_FORWARD]:
		return false
	var motion := input_buffer.matches_recent_sequence([FighterInputBuffer.Direction.DOWN,FighterInputBuffer.Direction.DOWN_FORWARD,FighterInputBuffer.Direction.FORWARD],MOTION_WINDOW)
	var diagonal := input_buffer.matches_recent_sequence([FighterInputBuffer.Direction.DOWN,FighterInputBuffer.Direction.DOWN_FORWARD],MOTION_WINDOW)
	if not motion and not diagonal:
		return false
	for entry in [[&"heavy_punch",&"heavy"],[&"medium_punch",&"medium"],[&"light_punch",&"light"]]:
		if input_buffer.consume_attack(entry[0],BUTTON_WINDOW) in [FighterInputBuffer.Direction.FORWARD,FighterInputBuffer.Direction.DOWN_FORWARD]:
			input_buffer.clear()
			_start_shoulder(entry[1])
			return true
	return false


func _start_shoulder(strength: StringName = &"light") -> void:
	shoulder_active = true
	shoulder_strength = strength
	shoulder_facing_right = is_facing_right
	shoulder_connected = false
	combat.set_guarding(false)
	combat.begin_animation_attack(SHOULDER_ANIMATION)
	_shoulder_audio.play()
	_shoulder_aura = ShoulderAura.new()
	_shoulder_aura.setup(self,COLORS[strength])
	get_parent().add_child(_shoulder_aura)
	update_collision_profile()


func _physics_process(delta: float) -> void:
	if not shoulder_active:
		super._physics_process(delta)
		return
	if not controls_enabled or combat.current_health <= 0 or current_state != State.ATTACKING or not combat.is_attacking:
		_clear_shoulder()
		combat.cancel_current_action()
		if current_state == State.ATTACKING:
			change_state(State.IDLE)
		return
	if is_player_controlled and input_buffer != null:
		input_buffer.update(shoulder_facing_right)
	var rushing := not shoulder_connected and animated_sprite.frame >= RUSH_FRAME
	var previous_position := global_position
	var direction := 1.0 if shoulder_facing_right else -1.0
	velocity.x = direction * float(SPEEDS[shoulder_strength]) if rushing else 0.0
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	update_physical_collision()
	move_and_slide()
	position.x = clampf(position.x,stage_left_limit,stage_right_limit)
	if rushing:
		# Sweep only the displacement allowed by stage/body collisions. This cannot
		# hit through a wall or beyond the stage boundary at high speed.
		_shoulder_cast.global_position = previous_position + Vector2(direction * 55,-195)
		_shoulder_cast.target_position = global_position - previous_position
		_shoulder_cast.force_shapecast_update()
		if _shoulder_cast.is_colliding():
			global_position = previous_position.lerp(global_position,_shoulder_cast.get_closest_collision_safe_fraction())
		for index in _shoulder_cast.get_collision_count():
			var area := _shoulder_cast.get_collider(index) as Area2D
			if _hit_shoulder_area(area):
				break
		if shoulder_active and not shoulder_connected and (is_on_wall() or position.x <= stage_left_limit or position.x >= stage_right_limit):
			_release_shoulder()
	update_ground_shadow()


func _hit_shoulder_area(area: Area2D) -> bool:
	if not shoulder_active or shoulder_connected or area == null or not area.is_in_group("hurtbox"):
		return false
	var target := area.get_parent() as Fighter
	if target == null or target == self:
		return false
	var crouched := target.get_crouch_progress() >= .5 or target.is_holding_low_guard()
	var height := AttackData.HitHeight.LOW if crouched else AttackData.HitHeight.MID
	var result := target.combat.take_damage(DAMAGE,self,.35,.2,height,false,0,0,true,false,-1,COLORS[shoulder_strength],true)
	if result == FighterCombat.DamageResult.IGNORED:
		return false
	if result in [FighterCombat.DamageResult.HIT,FighterCombat.DamageResult.KNOCKOUT]:
		_shoulder_hit_audio.play()
	# A KO may synchronously end the round and cancel this attack.
	if shoulder_active:
		_release_shoulder()
	return true


func _release_shoulder() -> void:
	if not shoulder_active or current_state != State.ATTACKING:
		return
	shoulder_connected = true
	velocity.x = 0.0
	animated_sprite.set_frame_and_progress(HOLD_FRAME + 1,0.0)
	animated_sprite.play(SHOULDER_ANIMATION)
	if is_instance_valid(_shoulder_aura):
		_shoulder_aura.stop_emitting()


func _on_animation_frame_changed() -> void:
	super._on_animation_frame_changed()
	if guitar_special_active and not _guitar_materialize_played and controls_enabled and combat.current_health > 0 and current_state == State.ATTACKING and combat.is_attacking and animated_sprite.animation == GUITAR_WINDUP_ANIMATION and animated_sprite.frame >= GUITAR_MATERIALIZE_FRAME:
		_guitar_materialize_played = true
		_guitar_materialize_audio.play()
	if guitar_special_active and not guitar_spawned and controls_enabled and combat.current_health > 0 and current_state == State.ATTACKING and combat.is_attacking and animated_sprite.animation == GUITAR_THROW_ANIMATION and animated_sprite.frame >= GUITAR_RELEASE_FRAME:
		_spawn_guitar()
	if shoulder_active and animated_sprite.animation == SHOULDER_ANIMATION and not shoulder_connected and animated_sprite.frame >= HOLD_FRAME:
		animated_sprite.set_frame_and_progress(HOLD_FRAME,0.0)
		animated_sprite.pause()


func _on_animation_finished() -> void:
	if guitar_special_active and animated_sprite.animation == GUITAR_WINDUP_ANIMATION:
		animated_sprite.play(GUITAR_THROW_ANIMATION)
		return
	if guitar_special_active and animated_sprite.animation == GUITAR_THROW_ANIMATION:
		_clear_guitar_special()
		combat.finish_animation_attack()
		return
	if shoulder_active and animated_sprite.animation == SHOULDER_ANIMATION:
		_clear_shoulder()
		combat.finish_animation_attack()
		return
	super._on_animation_finished()


func _clear_shoulder() -> void:
	if shoulder_active:
		velocity.x = 0.0
	shoulder_active = false
	if is_instance_valid(_shoulder_audio):
		_shoulder_audio.stop()
	if is_instance_valid(_shoulder_aura):
		_shoulder_aura.stop_emitting(true)
	_shoulder_aura = null


func update_facing_direction() -> void:
	if not shoulder_active and not guitar_special_active:
		super.update_facing_direction()


func change_state(next_state: int, force_victory_exit := false) -> void:
	if guitar_special_active and next_state != State.ATTACKING:
		_clear_guitar_special()
		if combat.is_attacking:
			combat.cancel_current_action()
	if shoulder_active and next_state != State.ATTACKING:
		_clear_shoulder()
		if combat.is_attacking:
			combat.cancel_current_action()
	super.change_state(next_state,force_victory_exit)


func reset_fighter(spawn_position: Vector2) -> void:
	_clear_shoulder()
	_clear_guitar_special()
	for group in ["mileto_guitar_projectile","mileto_guitar_explosion","mileto_guitar_trail","mileto_guitar_audio"]:
		for effect in get_tree().get_nodes_in_group(group):
			if effect.get_meta(&"source_id",0) == get_instance_id():
				effect.queue_free()
	if is_instance_valid(_shoulder_hit_audio):
		_shoulder_hit_audio.stop()
	for effect in get_tree().get_nodes_in_group("mileto_shoulder_aura"):
		if effect.source_fighter == self:
			effect.queue_free()
	super.reset_fighter(spawn_position)


func _start_guitar_special(strength: StringName = &"light") -> void:
	_guitar_materialize_played = false
	_guitar_materialize_audio.stop()
	guitar_special_active = true
	guitar_spawned = false
	guitar_strength = strength
	guitar_facing_right = is_facing_right
	combat.set_guarding(false)
	combat.begin_animation_attack(GUITAR_WINDUP_ANIMATION)
	update_collision_profile()


func _spawn_guitar() -> Node2D:
	guitar_spawned = true
	_guitar_materialize_audio.stop()
	var projectile := GuitarProjectile.new()
	projectile.setup(self,guitar_facing_right,guitar_strength)
	var point := Vector2(118 if guitar_facing_right else -118,-170)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + point
	return projectile


func _clear_guitar_special() -> void:
	guitar_special_active = false
	guitar_spawned = false
	if is_instance_valid(_guitar_materialize_audio):
		_guitar_materialize_audio.stop()
