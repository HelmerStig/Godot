extends Node2D

const MATERIALIZE := preload("res://assets/sprites/characters/bue/tom_electric_materialize.png")
const RUN := preload("res://assets/sprites/characters/bue/tom_run_singing.png")
const SLAPS := preload("res://assets/sprites/characters/bue/tom_hat_slaps.png")
const MATERIALIZE_SOUND := preload("res://assets/sounds/sfx/scossa.wav")
const SINGING_SOUND := preload("res://assets/sounds/tom waits.mp3")
const HIT_SOUND := preload("res://assets/sounds/sfx/light-punch.wav")
const SONG_START := 25.0
const SPEED := 480.0
const DAMAGE := 5
const ART_SCALE := .85
const SLAP_FRAMES := [15,28,41] # Source 16,29,42: three fully extended hat strikes.
enum Phase { MATERIALIZING, APPROACHING, SLAPPING, EXITING }
var source_fighter: Fighter
var facing_right := true
var phase := Phase.MATERIALIZING
var sprite: AnimatedSprite2D
var sweep: ShapeCast2D
var target: Fighter
var strikes := 0
var elapsed := 0.0
var _pending_strikes := 0
var _target_generation := -1
var _slaps_finished := false
var materialize_audio: AudioStreamPlayer
var singing_audio: AudioStreamPlayer
var hit_sound_count := 0
var strike_frames: Array = SLAP_FRAMES

func _animation_specs() -> Array:
	return [[&"materialize",MATERIALIZE,30,60.0,false],[&"run",RUN,49,48.0,true],[&"slaps",SLAPS,49,60.0,false]]

func _song_stream() -> AudioStream:
	return SINGING_SOUND

func _song_start() -> float:
	return SONG_START

func _strike_frames() -> Array:
	return SLAP_FRAMES

func _sprite_y() -> float:
	return -158.0

func _exit_on_last_strike() -> bool:
	return true

func setup(fighter: Fighter, direction_right: bool) -> void:
	source_fighter = fighter
	facing_right = direction_right

func _ready() -> void:
	add_to_group("bue_singer_projectile")
	strike_frames = _strike_frames()
	materialize_audio = AudioStreamPlayer.new()
	materialize_audio.name = "MaterializationAudio"
	materialize_audio.stream = MATERIALIZE_SOUND
	materialize_audio.volume_db = -4
	add_child(materialize_audio)
	singing_audio = AudioStreamPlayer.new()
	singing_audio.name = "SingingAudio"
	singing_audio.stream = _song_stream()
	singing_audio.volume_db = -6
	add_child(singing_audio)
	z_index = 8
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.scale = Vector2.ONE * ART_SCALE
	sprite.position.y = _sprite_y()
	sprite.flip_h = not facing_right
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for spec in _animation_specs():
		frames.add_animation(spec[0])
		frames.set_animation_speed(spec[0],spec[3])
		frames.set_animation_loop(spec[0],spec[4])
		for index in int(spec[2]):
			var texture := AtlasTexture.new()
			texture.atlas = spec[1]
			texture.region = Rect2(index%7*512,index/7*512,512,512)
			frames.add_frame(spec[0],texture)
	sprite.sprite_frames = frames
	add_child(sprite)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	sweep = ShapeCast2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(70,150)
	sweep.shape = shape
	sweep.position = Vector2(30 if facing_right else -30,-150)
	sweep.collision_mask = 4
	sweep.collide_with_areas = true
	sweep.collide_with_bodies = false
	sweep.enabled = false
	sweep.margin = 0
	add_child(sweep)
	sweep.add_exception(source_fighter.get_node("Hurtbox"))
	sprite.play(&"materialize")

func _physics_process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	if not is_instance_valid(source_fighter) or not source_fighter.controls_enabled or source_fighter.combat.current_health <= 0:
		queue_free()
		return
	elapsed += delta
	if elapsed > 15.0:
		queue_free()
		return
	if phase == Phase.SLAPPING:
		_process_pending_strike()
		if _slaps_finished and _pending_strikes == 0:
			_start_exit()
		return
	if phase not in [Phase.APPROACHING,Phase.EXITING]:
		return
	var motion := Vector2(SPEED * delta * (1 if facing_right else -1),0)
	if phase == Phase.APPROACHING:
		sweep.target_position = motion
		sweep.force_shapecast_update()
		for index in sweep.get_collision_count():
			var area := sweep.get_collider(index) as Area2D
			if _try_contact(area):
				global_position += motion * sweep.get_closest_collision_unsafe_fraction() + Vector2(.5 if facing_right else -.5,0)
				return
	global_position += motion
	if phase == Phase.EXITING:
		# Stop the song when Tom has actually left the camera, not the whole stage.
		var screen_bounds := get_global_transform_with_canvas() * Rect2(-110,-340,220,390)
		if not get_viewport_rect().intersects(screen_bounds):
			queue_free()
			return
	# Stage limits describe the playable world; continue beyond them before freeing.
	if global_position.x < source_fighter.stage_left_limit - 450 or global_position.x > source_fighter.stage_right_limit + 450:
		queue_free()

func _try_contact(area: Area2D) -> bool:
	if phase != Phase.APPROACHING or area == null or not area.is_in_group("hurtbox"):
		return false
	var fighter := area.get_parent() as Fighter
	if fighter == null or fighter == source_fighter or fighter.combat.current_health <= 0 or fighter.current_state in [Fighter.State.KNOCKED_DOWN,Fighter.State.KNOCKDOWN_RECOVERY,Fighter.State.VICTORY]:
		return false
	target = fighter
	phase = Phase.SLAPPING
	sprite.play(&"slaps")
	return true

func _on_frame_changed() -> void:
	if phase != Phase.SLAPPING or is_queued_for_deletion():
		return
	# Catch crossed frames if rendering skips one at 60 FPS; each strike is queued once.
	while strikes + _pending_strikes < strike_frames.size() and sprite.frame >= strike_frames[strikes + _pending_strikes]:
		_pending_strikes += 1
	_process_pending_strike()

func _process_pending_strike() -> void:
	if is_queued_for_deletion():
		return
	if not is_instance_valid(source_fighter) or not source_fighter.controls_enabled or source_fighter.combat.current_health <= 0:
		queue_free()
		return
	if not is_instance_valid(target) or not target.controls_enabled or target.combat.current_health <= 0:
		_pending_strikes = 0
		_start_exit()
		return
	if _pending_strikes == 0:
		return
	# Slaps follow the visual frames, even if the previous hurt is still playing.
	# Waiting for HIT to finish leaves Tom stationary after the last hat swing.
	# An unrelated action still invalidates the sequence.
	if _target_generation >= 0:
		if target.combat.action_generation != _target_generation:
			_pending_strikes = 0
			_start_exit()
			return
	# Every slap still needs a real contact; it cannot damage a target that escaped.
	sweep.target_position = Vector2.ZERO
	sweep.force_shapecast_update()
	var overlaps := false
	for index in sweep.get_collision_count():
		var area := sweep.get_collider(index) as Area2D
		if area != null and area.get_parent() == target:
			overlaps = true
	if not overlaps:
		_pending_strikes = 0
		_start_exit()
		return
	_pending_strikes -= 1
	strikes += 1
	var crouched := target.get_crouch_progress() >= .5 or target.is_holding_low_guard()
	var height := AttackData.HitHeight.LOW if crouched else AttackData.HitHeight.HIGH
	var result := target.combat.take_damage(DAMAGE,source_fighter,.2,.22,height,false,0,0,false,false,height,Color.TRANSPARENT,true)
	if result in [FighterCombat.DamageResult.HIT,FighterCombat.DamageResult.KNOCKOUT]:
		_play_hit_audio()
	_target_generation = target.combat.action_generation if result == FighterCombat.DamageResult.HIT else -1
	if result in [FighterCombat.DamageResult.KNOCKOUT,FighterCombat.DamageResult.IGNORED]:
		_pending_strikes = 0
		_start_exit()
	elif strikes == strike_frames.size() and _exit_on_last_strike():
		# Resume forward travel on the third contact, without the stationary tail.
		_start_exit()

func _on_animation_finished() -> void:
	if phase == Phase.MATERIALIZING:
		materialize_audio.stop()
		phase = Phase.APPROACHING
		sprite.play(&"run")
		_start_running_audio()
	elif phase == Phase.SLAPPING:
		_slaps_finished = true
		if _pending_strikes == 0:
			_start_exit()

func _start_exit() -> void:
	phase = Phase.EXITING
	sprite.play(&"run")
	_start_running_audio()

func adopt_materialization_audio(audio: AudioStreamPlayer) -> void:
	# The same uninterrupted player starts on Bue and then follows Tom's lifetime.
	materialize_audio.queue_free()
	materialize_audio = audio
	materialize_audio.reparent(self)

func _start_running_audio() -> void:
	if not source_fighter.controls_enabled:
		singing_audio.stop()
		return
	if not singing_audio.playing:
		singing_audio.play(_song_start())

func _play_hit_audio() -> void:
	# Each contact is independent; allow a successful last hit to finish after KO.
	var audio := AudioStreamPlayer.new()
	audio.stream = HIT_SOUND
	audio.volume_db = -7
	audio.set_meta(&"source_id",source_fighter.get_instance_id())
	audio.add_to_group("bue_singer_hit_audio")
	get_parent().add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()
	hit_sound_count += 1
