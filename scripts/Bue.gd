extends IdleRosterFighter
class_name Bue

const SUMMON_SHEET := preload("res://assets/sprites/characters/bue/special_1_summon_lightning.png")
const SingerProjectile := preload("res://scripts/BueSingerProjectile.gd")
const SUMMON_ANIMATION := &"special_1_summon_lightning"
const SUMMON_FRAME := 9 # Frame 10, inclusive, user-facing numbering.
var summon_active := false
var summon_spawned := false
var summon_facing_right := true
var _summoned_singer
var _summon_audio: AudioStreamPlayer

func _ready() -> void:
	super._ready()
	_add_sheet_animation(animated_sprite.sprite_frames,SUMMON_ANIMATION,SUMMON_SHEET,30,7,Vector2(512,512),60.0,false,0,false)
	combat.attack_cancelled.connect(_clear_summon)

func _try_start_character_special() -> bool:
	if summon_active or is_instance_valid(_summoned_singer) or not controls_enabled or not is_on_floor() or (not can_move and current_state != State.STANDING_UP) or current_state not in [State.IDLE,State.WALKING,State.RUNNING,State.CROUCHING,State.STANDING_UP]:
		return false
	var buffer := input_buffer
	if buffer.get_current_direction() not in [FighterInputBuffer.Direction.FORWARD,FighterInputBuffer.Direction.DOWN_FORWARD]:
		return false
	if not buffer.matches_recent_sequence([FighterInputBuffer.Direction.DOWN,FighterInputBuffer.Direction.DOWN_FORWARD,FighterInputBuffer.Direction.FORWARD],36) and not buffer.matches_recent_sequence([FighterInputBuffer.Direction.DOWN,FighterInputBuffer.Direction.DOWN_FORWARD],36):
		return false
	for button in [&"heavy_punch",&"medium_punch",&"light_punch"]:
		if buffer.consume_attack(button,10) in [FighterInputBuffer.Direction.FORWARD,FighterInputBuffer.Direction.DOWN_FORWARD]:
			buffer.clear()
			_start_summon()
			return true
	return false

func _start_summon() -> void:
	if summon_active or is_instance_valid(_summoned_singer):
		return
	_summoned_singer = null
	summon_active = true
	summon_spawned = false
	summon_facing_right = is_facing_right
	combat.set_guarding(false)
	combat.begin_animation_attack(SUMMON_ANIMATION)
	if not is_instance_valid(_summon_audio):
		_summon_audio = AudioStreamPlayer.new()
		_summon_audio.name = "SummonElectricity"
		_summon_audio.stream = SingerProjectile.MATERIALIZE_SOUND
		_summon_audio.volume_db = -4
		add_child(_summon_audio)
	_summon_audio.play()
	update_collision_profile()

func _on_animation_frame_changed() -> void:
	super._on_animation_frame_changed()
	if summon_active and not summon_spawned and controls_enabled and combat.current_health > 0 and combat.is_attacking and current_state == State.ATTACKING and animated_sprite.animation == SUMMON_ANIMATION and animated_sprite.frame >= SUMMON_FRAME:
		_spawn_singer()

func _spawn_singer() -> Node2D:
	summon_spawned = true
	var singer := SingerProjectile.new()
	_summoned_singer = singer
	singer.setup(self,summon_facing_right)
	get_parent().add_child(singer)
	singer.adopt_materialization_audio(_summon_audio)
	singer.global_position = global_position + Vector2(170 if summon_facing_right else -170,26)
	return singer

func _on_animation_finished() -> void:
	if summon_active and animated_sprite.animation == SUMMON_ANIMATION:
		_clear_summon()
		combat.finish_animation_attack()
		return
	super._on_animation_finished()

func update_facing_direction() -> void:
	if not summon_active:
		super.update_facing_direction()

func change_state(next_state: int, force_victory_exit := false) -> void:
	if summon_active and next_state != State.ATTACKING:
		_clear_summon()
		if combat.is_attacking:
			combat.cancel_current_action()
	super.change_state(next_state,force_victory_exit)

func _clear_summon() -> void:
	if not is_instance_valid(_summoned_singer) and is_instance_valid(_summon_audio):
		_summon_audio.stop()
	summon_active = false
	summon_spawned = false

func reset_fighter(spawn_position: Vector2) -> void:
	_clear_summon()
	if is_instance_valid(_summon_audio):
		_summon_audio.stop()
	_summoned_singer = null
	for singer in get_tree().get_nodes_in_group("bue_singer_projectile"):
		if singer.source_fighter == self:
			singer.queue_free()
	for audio in get_tree().get_nodes_in_group("bue_singer_hit_audio"):
		if audio.get_meta(&"source_id",0) == get_instance_id():
			audio.queue_free()
	super.reset_fighter(spawn_position)
