extends Node2D

const SHEET := preload("res://assets/sprites/characters/mileto/guitar-projectile.png")
const Explosion := preload("res://scripts/MiletoGuitarExplosion.gd")
const THROW_SOUND := preload("res://assets/sounds/sfx/boomerang.wav")
const HIT_SOUND := preload("res://sound-libraries/body_hit_large_76.wav")
const SPEEDS := {&"light":600.0,&"medium":800.0,&"heavy":1000.0}
const DAMAGE := 15
const MAX_LIFETIME := 3.0
const SPRITE_SCALE := 2.0
const TINT := Color(.25,.75,1.0,.95)
# Opaque envelopes for each 256px cell, not the full transparent canvas.
const BOUNDS := [Rect2(63,95,118,44),Rect2(63,95,118,44),Rect2(63,95,116,44),Rect2(63,96,115,43),Rect2(63,96,114,43),Rect2(65,97,111,42),Rect2(67,94,108,45),Rect2(72,98,103,42),Rect2(78,98,92,42),Rect2(88,94,70,47),Rect2(98,97,55,44),Rect2(107,98,40,44),Rect2(107,97,37,50),Rect2(119,98,32,49),Rect2(107,97,51,49),Rect2(103,94,64,51),Rect2(96,94,75,49),Rect2(87,96,89,46),Rect2(81,94,98,47),Rect2(75,95,106,45),Rect2(71,95,111,44),Rect2(68,95,114,44),Rect2(66,95,116,44),Rect2(64,95,116,44),Rect2(63,95,118,44)]

var source_fighter: Fighter
var travel_direction := 1.0
var movement_speed := 600.0
var elapsed := 0.0
var has_hit := false
var sprite: AnimatedSprite2D
var sweep: ShapeCast2D
var trails: Array[Line2D] = []
var _points: Array[Vector2] = []
var _ages: Array[float] = []
var _throw_audio: AudioStreamPlayer


func setup(fighter: Fighter, facing_right: bool, strength: StringName = &"light") -> void:
	source_fighter = fighter
	travel_direction = 1.0 if facing_right else -1.0
	movement_speed = SPEEDS.get(strength,600.0)
	set_meta(&"source_id",fighter.get_instance_id())


func _ready() -> void:
	add_to_group("mileto_guitar_projectile")
	z_index = 10
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.scale = Vector2.ONE * SPRITE_SCALE
	sprite.offset = Vector2(6,8)
	sprite.flip_h = travel_direction < 0
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"fly")
	frames.set_animation_speed(&"fly",100.0)
	frames.set_animation_loop(&"fly",true)
	for index in 25:
		var texture := AtlasTexture.new()
		texture.atlas = SHEET
		texture.region = Rect2(index%5*256,index/5*256,256,256)
		frames.add_frame(&"fly",texture)
	sprite.sprite_frames = frames
	add_child(sprite)
	sweep = ShapeCast2D.new()
	sweep.name = "CollisionSweep"
	sweep.shape = RectangleShape2D.new()
	sweep.collision_mask = 4
	sweep.collide_with_areas = true
	sweep.collide_with_bodies = false
	sweep.margin = 0.0
	sweep.enabled = false
	add_child(sweep)
	sweep.add_exception(source_fighter.get_node("Hurtbox"))
	sprite.frame_changed.connect(_sync_collision)
	_sync_collision()
	sprite.play(&"fly")
	for width in [18.0,4.0]:
		var trail := Line2D.new()
		trail.name = "GuitarTrail"
		trail.top_level = true
		trail.width = width
		trail.antialiased = true
		trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		trail.end_cap_mode = Line2D.LINE_CAP_ROUND
		trail.z_as_relative = false
		trail.z_index = 9
		var gradient := Gradient.new()
		gradient.set_color(0,Color(TINT,0))
		gradient.set_color(1,Color(TINT,.25 if width > 4 else .9))
		trail.gradient = gradient
		trail.set_meta(&"source_id",source_fighter.get_instance_id())
		trail.add_to_group("mileto_guitar_trail")
		add_child(trail)
		trail.global_transform = Transform2D.IDENTITY
		trails.append(trail)
	_throw_audio = _play_sound(THROW_SOUND, &"mileto_guitar_throw_audio", -4.0)


func _sync_collision() -> void:
	var bounds: Rect2 = BOUNDS[sprite.frame]
	(sweep.shape as RectangleShape2D).size = bounds.size * SPRITE_SCALE * .85
	var center := (bounds.get_center() - Vector2(128,128) + sprite.offset) * SPRITE_SCALE
	center.x *= travel_direction
	sweep.position = center


func _physics_process(delta: float) -> void:
	if has_hit or is_queued_for_deletion():
		return
	if not is_instance_valid(source_fighter) or not source_fighter.controls_enabled:
		queue_free()
		return
	elapsed += delta
	if elapsed >= MAX_LIFETIME:
		queue_free()
		return
	var motion := Vector2(travel_direction * movement_speed * delta,0)
	sweep.target_position = motion
	sweep.force_shapecast_update()
	for index in sweep.get_collision_count():
		var area := sweep.get_collider(index) as Area2D
		var point := sweep.get_collision_point(index)
		if point.is_zero_approx():
			point = global_position + motion * sweep.get_closest_collision_safe_fraction()
		if area != null and _hit_area(area,point):
			return
	_update_trail(delta,global_position + motion)
	global_position += motion


func _update_trail(delta: float, next_position: Vector2) -> void:
	if _points.is_empty():
		_points.append(global_position)
		_ages.append(0.0)
	for index in _ages.size():
		_ages[index] += delta
	while not _ages.is_empty() and _ages[0] > .16:
		_ages.pop_front()
		_points.pop_front()
	_points.append(next_position)
	_ages.append(0.0)
	for trail in trails:
		trail.points = PackedVector2Array(_points)


func _hit_area(area: Area2D, point := Vector2.INF) -> bool:
	if has_hit or is_queued_for_deletion() or not area.is_in_group("hurtbox") or not source_fighter.controls_enabled:
		return false
	var target := area.get_parent() as Fighter
	if target == null or target == source_fighter:
		return false
	var crouched := target.get_crouch_progress() >= .5 or target.is_holding_low_guard()
	var height := AttackData.HitHeight.LOW if crouched else AttackData.HitHeight.MID
	var hurt := AttackData.HitHeight.LOW if crouched else AttackData.HitHeight.HIGH
	var result := target.combat.take_damage(DAMAGE,source_fighter,.35,.2,height,false,0,0,true,false,hurt,TINT,true)
	if result == FighterCombat.DamageResult.IGNORED:
		return false
	if is_instance_valid(_throw_audio):
		_throw_audio.stop()
		_throw_audio.queue_free()
	if result in [FighterCombat.DamageResult.HIT, FighterCombat.DamageResult.KNOCKOUT]:
		_play_sound(HIT_SOUND, &"mileto_guitar_hit_audio", -5.0)
	has_hit = true
	var impact := Explosion.new()
	impact.set_meta(&"source_id",source_fighter.get_instance_id())
	get_parent().add_child(impact)
	impact.global_position = global_position if point == Vector2.INF else point
	for trail in trails:
		trail.reparent(get_parent(),true)
		var fade := trail.create_tween()
		fade.tween_property(trail,"modulate:a",0.0,.18)
		fade.tween_callback(trail.queue_free)
	queue_free()
	return true


func _play_sound(stream: AudioStream, group: StringName, volume: float) -> AudioStreamPlayer:
	# Arena ownership lets the impact finish after the projectile disappears.
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume
	audio.set_meta(&"source_id", source_fighter.get_instance_id())
	audio.add_to_group("mileto_guitar_audio")
	audio.add_to_group(group)
	get_parent().add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()
	return audio
