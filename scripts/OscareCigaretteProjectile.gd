extends Node2D
class_name OscareCigaretteProjectile

const SHEET := preload("res://assets/sprites/characters/oscare/siga_projectile.png")
const IMPACT_SOUND := preload("res://assets/sounds/sfx/crepitio.wav")
const IMPACT_COLOR := Color(1.0, 0.42, 0.06, 0.94)
const SPEEDS := {&"light": 520.0, &"medium": 720.0, &"heavy": 920.0}
const DAMAGE := 10
const MAX_LIFETIME := 3.0
const SPRITE_SCALE := Vector2(0.24, 0.24)
const HITBOX_SIZE := Vector2(26, 10)

var source_fighter: Fighter
var travel_direction := 1.0
var movement_speed := 520.0
var elapsed := 0.0
var has_hit := false
var sprite: AnimatedSprite2D
var sweep: ShapeCast2D


func setup(fighter: Fighter, facing_right: bool, strength: StringName = &"light") -> void:
	source_fighter = fighter
	travel_direction = 1.0 if facing_right else -1.0
	movement_speed = SPEEDS.get(strength, SPEEDS[&"light"])


func _ready() -> void:
	add_to_group("oscare_cigarette_projectile")
	z_index = 10
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.scale = SPRITE_SCALE
	sprite.flip_h = travel_direction < 0.0
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"fly")
	frames.set_animation_speed(&"fly", 60.0)
	frames.set_animation_loop(&"fly", true)
	for index in 25:
		var texture := AtlasTexture.new()
		texture.atlas = SHEET
		texture.region = Rect2((index % 5) * 512, (index / 5) * 512, 512, 512)
		frames.add_frame(&"fly", texture)
	sprite.sprite_frames = frames
	add_child(sprite)
	sprite.play(&"fly")
	sweep = ShapeCast2D.new()
	sweep.name = "CollisionSweep"
	var shape := RectangleShape2D.new()
	shape.size = HITBOX_SIZE
	sweep.shape = shape
	sweep.collision_mask = 4 # Hurtboxes only; smoke has no collision.
	sweep.collide_with_areas = true
	sweep.collide_with_bodies = false
	sweep.margin = 0.0
	add_child(sweep)
	if is_instance_valid(source_fighter):
		sweep.add_exception(source_fighter.get_node("Hurtbox"))


func _physics_process(delta: float) -> void:
	if has_hit:
		return
	if not is_instance_valid(source_fighter) or not source_fighter.controls_enabled:
		queue_free()
		return
	elapsed += delta
	if elapsed >= MAX_LIFETIME:
		queue_free()
		return
	var motion := Vector2(travel_direction * movement_speed * delta, 0)
	# Sweep the complete step: a fast, thin projectile must not skip a hurtbox
	# between two physics frames or damage several hurtboxes on one fighter.
	sweep.target_position = motion
	sweep.force_shapecast_update()
	for index in sweep.get_collision_count():
		var area := sweep.get_collider(index) as Area2D
		if area != null and _hit_area(area):
			return
	position += motion


func _hit_area(area: Area2D) -> bool:
	if has_hit or not area.is_in_group("hurtbox"):
		return false
	var target := area.get_parent() as Fighter
	if target == null or target == source_fighter:
		return false
	var crouched := target.get_crouch_progress() >= 0.5 or target.is_holding_low_guard()
	var height := AttackData.HitHeight.LOW if crouched else AttackData.HitHeight.MID
	var hurt_height := AttackData.HitHeight.LOW if crouched else AttackData.HitHeight.HIGH
	var result := target.combat.take_damage(
		DAMAGE, source_fighter, 0.3, 0.18, height, false, 0, 0, true, false, hurt_height, IMPACT_COLOR
	)
	if result == FighterCombat.DamageResult.IGNORED:
		return false
	has_hit = true
	if result in [FighterCombat.DamageResult.HIT, FighterCombat.DamageResult.KNOCKOUT]:
		_play_impact_sound()
	queue_free()
	return true


func _play_impact_sound() -> void:
	# The projectile disappears on contact, so the sound belongs to the arena.
	var audio := AudioStreamPlayer.new()
	audio.name = "CigaretteImpact"
	audio.stream = IMPACT_SOUND
	audio.set_meta(&"source_id", source_fighter.get_instance_id() if is_instance_valid(source_fighter) else 0)
	get_parent().add_child(audio)
	audio.add_to_group("oscare_cigarette_impact_audio")
	audio.finished.connect(audio.queue_free)
	audio.play()
