extends Node2D
class_name TorpeBeerBottleProjectile

const Shatter := preload("res://scripts/TorpeBeerShatter.gd")
const TEXTURE := preload("res://assets/sprites/characters/torpe/beer_bottle.png")
const FLIGHT_SOUND := preload("res://assets/sounds/sfx/sibilo.wav")
const SOURCE_RECT := Rect2(320, 51, 389, 1400)
const SPEEDS := {&"light": 520.0, &"medium": 720.0, &"heavy": 920.0}
const SPINS := {&"light": 1.8, &"medium": 2.2, &"heavy": 2.6}
const GRAVITY := 600.0
const DAMAGE := 10

var source_fighter: Fighter
var velocity := Vector2.ZERO
var angular_velocity := 0.0
var visible_length := 73.44
var elapsed := 0.0
var has_hit := false
var sprite: Sprite2D
var sweep: ShapeCast2D
var flight_audio: AudioStreamPlayer
var trail: Line2D
var _trail_points: Array[Vector2] = []
var _trail_ages: Array[float] = []


func setup(fighter: Fighter, facing_right: bool, strength: StringName = &"light") -> void:
	source_fighter = fighter
	var direction := 1.0 if facing_right else -1.0
	visible_length = 81.6 * absf(fighter.animated_sprite.global_scale.y)
	velocity = Vector2(direction * float(SPEEDS.get(strength, 520.0)), -150)
	angular_velocity = direction * TAU * float(SPINS.get(strength, 1.8))
	rotation = direction * PI / 2.0


func _ready() -> void:
	add_to_group("torpe_beer_projectile")
	z_index = 10
	sprite = Sprite2D.new()
	var texture := AtlasTexture.new()
	texture.atlas = TEXTURE
	texture.region = SOURCE_RECT
	sprite.texture = texture
	sprite.scale = Vector2.ONE * visible_length / SOURCE_RECT.size.y
	add_child(sprite)
	sweep = ShapeCast2D.new()
	var shape := CapsuleShape2D.new()
	shape.height = visible_length * 0.94
	shape.radius = visible_length * SOURCE_RECT.size.x / SOURCE_RECT.size.y * 0.44
	sweep.shape = shape
	sweep.collision_mask = 5 # Ground and hurtboxes; never the fighter's pushbox.
	sweep.collide_with_areas = true
	sweep.collide_with_bodies = true
	sweep.margin = 0.0
	add_child(sweep)
	if is_instance_valid(source_fighter):
		sweep.add_exception(source_fighter.get_node("Hurtbox"))
	flight_audio = AudioStreamPlayer.new()
	flight_audio.name = "BeerFlightAudio"
	flight_audio.stream = FLIGHT_SOUND
	add_child(flight_audio)
	flight_audio.play()
	trail = Line2D.new()
	trail.name = "BeerTrail"
	trail.top_level = true
	trail.width = 5.0
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.antialiased = true
	trail.z_as_relative = false
	trail.z_index = 9
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1,.55,.13,0))
	gradient.set_color(1, Color(1,.82,.40,.6))
	trail.gradient = gradient
	trail.set_meta(&"source_id", source_fighter.get_instance_id() if is_instance_valid(source_fighter) else 0)
	add_child(trail)
	trail.global_transform = Transform2D.IDENTITY
	trail.add_to_group("torpe_beer_trail")


func _physics_process(delta: float) -> void:
	if has_hit:
		return
	if not is_instance_valid(source_fighter) or not source_fighter.controls_enabled:
		queue_free()
		return
	elapsed += delta
	if elapsed >= 3.0:
		queue_free()
		return
	var motion := velocity * delta + Vector2(0, GRAVITY * delta * delta * 0.5)
	velocity.y += GRAVITY * delta
	global_rotation += angular_velocity * delta
	# The cast rotates with the bottle; its local target must still describe
	# the same world-space flight, including at high spin and projectile speed.
	sweep.target_position = global_transform.basis_xform_inv(motion)
	sweep.force_shapecast_update()
	for index in sweep.get_collision_count():
		var collider := sweep.get_collider(index)
		if collider is Area2D:
			if not _hit_area(collider):
				continue
		elif not collider is StaticBody2D:
			continue
		var normal := sweep.get_collision_normal(index)
		var shape := sweep.shape as CapsuleShape2D
		var axis := Vector2.UP.rotated(global_rotation)
		var support := shape.radius + (shape.height * 0.5 - shape.radius) * absf(normal.dot(axis))
		if not normal.is_zero_approx():
			global_position = sweep.get_collision_point(index) + normal * (support + 2.0)
		_update_trail(delta, global_position)
		_shatter()
		return
	_update_trail(delta, global_position + motion)
	global_position += motion


func _update_trail(delta: float, next_position: Vector2) -> void:
	if _trail_points.is_empty():
		_trail_points.append(global_position)
		_trail_ages.append(0.0)
	for index in _trail_ages.size():
		_trail_ages[index] += delta
	while not _trail_ages.is_empty() and _trail_ages[0] > .12:
		_trail_ages.pop_front()
		_trail_points.pop_front()
	_trail_points.append(next_position)
	_trail_ages.append(0.0)
	trail.points = PackedVector2Array(_trail_points)


func _hit_area(area: Area2D) -> bool:
	if has_hit or not area.is_in_group("hurtbox"):
		return false
	var target := area.get_parent() as Fighter
	if target == null or target == source_fighter:
		return false
	var crouched := target.get_crouch_progress() >= 0.5 or target.is_holding_low_guard()
	var height := AttackData.HitHeight.LOW if crouched else AttackData.HitHeight.MID
	var hurt_height := AttackData.HitHeight.LOW if crouched else AttackData.HitHeight.HIGH
	var result := target.combat.take_damage(DAMAGE, source_fighter, 0.3, 0.18, height, false, 0, 0, true, false, hurt_height)
	return result != FighterCombat.DamageResult.IGNORED


func _shatter() -> void:
	if has_hit:
		return
	has_hit = true
	flight_audio.stop()
	# Let the world-space trail fade independently of the destroyed projectile.
	trail.reparent(get_parent(), true)
	var fade := trail.create_tween()
	fade.tween_property(trail, "modulate:a", 0.0, .14)
	fade.tween_callback(trail.queue_free)
	var effect := Shatter.new()
	effect.source_fighter = source_fighter
	effect.bottle_length = visible_length
	effect.bottle_rotation = global_rotation
	effect.incoming_velocity = velocity
	get_parent().add_child(effect)
	effect.global_position = global_position
	queue_free()
