extends Node2D
class_name TorpeWeldingSparks

const SOUND := preload("res://assets/sounds/sfx/saldatore.wav")
const Reactions := preload("res://scripts/FighterCombatReactions.gd")
const DAMAGE := {&"light": 10, &"medium": 15, &"heavy": 20}
const RATES := {&"light": 600.0, &"medium": 1000.0, &"heavy": 1400.0}
const PARTICLE_AMOUNTS := {&"light": 60, &"medium": 100, &"heavy": 140}
const COLORS := [Color(.15,.60,1), Color(1,.12,.08), Color(1,.85,.10)]
const REACH := 300.0
const SPEED := 1040.0
const GRAVITY := 850.0
const LIFETIME := REACH / SPEED

var source_fighter: Fighter
var facing_right := true
var damage := 10
var emission_rate := 600.0
var particle_amount := 60
var emitting := true
var emitter_position := Vector2.ZERO
var sparks: Array[Dictionary] = []
var hit_targets: Array[Fighter] = []
var audio: AudioStreamPlayer
var emitted_count := 0
var _emission_accumulator := 0.0
var particle_emitters: Array[CPUParticles2D] = []
var _tail_remaining := 0.0
var elapsed := 0.0
var _hurt_generations: Dictionary = {}
var _next_hurt_cycle: Dictionary = {}


func setup(fighter: Fighter, direction_right: bool, strength: StringName = &"light") -> void:
	source_fighter = fighter
	facing_right = direction_right
	damage = DAMAGE.get(strength,10)
	emission_rate = RATES.get(strength,600.0)
	particle_amount = PARTICLE_AMOUNTS.get(strength,60)


func _ready() -> void:
	add_to_group("torpe_welding_sparks")
	z_index = 10
	audio = AudioStreamPlayer.new()
	audio.name = "WeldingAudio"
	var recording := SOUND.duplicate() as AudioStreamWAV
	recording.loop_end = int(recording.get_length() * recording.mix_rate)
	recording.loop_mode = AudioStreamWAV.LOOP_FORWARD
	audio.stream = recording
	add_child(audio)
	sync_from_fighter()
	if emitting:
		_create_particle_emitters()
		audio.play()
		_emit_spark()


func _create_particle_emitters() -> void:
	var texture := GradientTexture2D.new()
	texture.width = 16
	texture.height = 16
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(.5,.5)
	texture.fill_to = Vector2(.5,0)
	var radial := Gradient.new()
	radial.set_color(0,Color.WHITE)
	radial.set_color(1,Color(1,1,1,0))
	texture.gradient = radial
	var fade := Gradient.new()
	fade.set_color(0,Color.WHITE)
	fade.set_color(1,Color(1,1,1,0))
	for index in COLORS.size():
		var particles := CPUParticles2D.new()
		particles.name = ["BlueParticles","RedParticles","YellowParticles"][index]
		particles.emitting = false
		particles.amount = particle_amount
		particles.lifetime = LIFETIME
		particles.local_coords = false
		particles.direction = Vector2(1 if facing_right else -1,0)
		particles.spread = 6
		particles.gravity = Vector2(0,GRAVITY)
		particles.initial_velocity_min = 860
		particles.initial_velocity_max = SPEED
		particles.scale_amount_min = .12
		particles.scale_amount_max = .26
		particles.color = COLORS[index]
		particles.color_ramp = fade
		particles.texture = texture
		add_child(particles)
		particles.global_position = emitter_position
		particles.emitting = true
		particle_emitters.append(particles)


func sync_from_fighter() -> void:
	if not is_instance_valid(source_fighter) or not source_fighter.controls_enabled or source_fighter.combat.current_health <= 0:
		stop_emitting(true)
		return
	if not emitting:
		return
	if (
		source_fighter.get("welding_special_active") != true
		or source_fighter.current_state != Fighter.State.ATTACKING or not source_fighter.combat.is_attacking
		or source_fighter.animated_sprite.animation != &"special_2_welding"
		or source_fighter.animated_sprite.frame < 42 or source_fighter.animated_sprite.frame > 63
	):
		stop_emitting()
		return
	emitter_position = source_fighter.call(&"get_welding_tip_global_position")
	for particles in particle_emitters:
		particles.global_position = emitter_position


func stop_emitting(discard_sparks := false) -> void:
	if emitting:
		_tail_remaining = LIFETIME
	emitting = false
	for particles in particle_emitters:
		particles.emitting = false
	if is_instance_valid(audio):
		audio.stop()
	if discard_sparks:
		sparks.clear()
		queue_free()


func _emit_spark() -> void:
	var direction := 1.0 if facing_right else -1.0
	sparks.append({
		"position": emitter_position, "origin": emitter_position,
		"velocity": Vector2(SPEED * direction,randf_range(-15,30)),
		"age": 0.0, "length": randf_range(8,18), "color": COLORS[emitted_count % COLORS.size()],
	})
	emitted_count += 1


func _physics_process(delta: float) -> void:
	sync_from_fighter()
	if is_queued_for_deletion():
		return
	elapsed += delta
	if not emitting:
		_tail_remaining -= delta
	if emitting:
		_emission_accumulator += emission_rate * delta
		while _emission_accumulator >= 1.0:
			_emission_accumulator -= 1.0
			_emit_spark()
	for index in range(sparks.size()-1,-1,-1):
		var spark := sparks[index]
		var step := minf(delta,LIFETIME - float(spark.age))
		var previous: Vector2 = spark.position
		var movement: Vector2 = spark.velocity * step + Vector2(0,.5 * GRAVITY * step * step)
		spark.velocity.y += GRAVITY * step
		spark.position = previous + movement
		spark.age += step
		if _trace_spark(previous,spark.position) or float(spark.age) >= LIFETIME:
			# Damage can synchronously end the round and discard this whole effect.
			if is_queued_for_deletion():
				return
			sparks.remove_at(index)
		if is_queued_for_deletion():
			return
	if not emitting and sparks.is_empty() and _tail_remaining <= 0:
		queue_free()
	queue_redraw()


func _trace_spark(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from,to,4)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.hit_from_inside = true
	query.exclude = [source_fighter.get_node("Hurtbox").get_rid()]
	for attempt in 8:
		var contact := get_world_2d().direct_space_state.intersect_ray(query)
		if contact.is_empty():
			return false
		var area := contact.collider as Area2D
		if area != null and _hit_area(area):
			return true
		var excluded := query.exclude
		excluded.append(contact.rid)
		query.exclude = excluded
	return false


func _hit_area(area: Area2D) -> bool:
	if is_queued_for_deletion() or not area.is_in_group("hurtbox") or not source_fighter.controls_enabled:
		return false
	var target := area.get_parent() as Fighter
	if target == null or target == source_fighter:
		return false
	if hit_targets.has(target):
		_refresh_hurt_high(target)
		return true
	var crouched := target.get_crouch_progress() >= .5 or target.is_holding_low_guard()
	var height := AttackData.HitHeight.LOW if crouched else AttackData.HitHeight.MID
	var hitstun := maxf(.3,_hurt_cycle_duration(target))
	var result := target.combat.take_damage(damage,source_fighter,hitstun,.18,height,false,0,0,false,false,AttackData.HitHeight.HIGH,COLORS[emitted_count % COLORS.size()],true)
	if result == FighterCombat.DamageResult.IGNORED:
		return false
	hit_targets.append(target)
	if result == FighterCombat.DamageResult.HIT and target.is_on_floor():
		_remember_hurt_cycle(target)
	return true


func _remember_hurt_cycle(target: Fighter) -> void:
	var id := target.get_instance_id()
	_hurt_generations[id] = target.combat.action_generation
	_next_hurt_cycle[id] = elapsed + _hurt_cycle_duration(target)


func _hurt_cycle_duration(target: Fighter) -> float:
	var duration := target.get_animation_duration(&"hurt_high")
	if target.animated_sprite.sprite_frames.has_animation(&"hurt_high_reverse"):
		duration += target.get_animation_duration(&"hurt_high_reverse")
	return duration


func _refresh_hurt_high(target: Fighter) -> void:
	var id := target.get_instance_id()
	if (
		not _hurt_generations.has(id) or not target.is_on_floor()
		or not target.controls_enabled or target.combat.current_health <= 0
		or target.combat.action_generation != int(_hurt_generations[id])
		or elapsed < float(_next_hurt_cycle[id])
		or target.current_state != Fighter.State.IDLE
	):
		return
	# The next actual spark contact restarts a complete recoil, never the damage.
	# Short reactions (notably Oscare) remain visible throughout the welding jet.
	Reactions.hit_reaction(target.combat,maxf(.3,_hurt_cycle_duration(target)),AttackData.HitHeight.HIGH,source_fighter,0,false,COLORS[emitted_count % COLORS.size()])
	_remember_hurt_cycle(target)


func _draw() -> void:
	var direction := 1.0 if facing_right else -1.0
	for spark in sparks:
		var head: Vector2 = spark.position
		var length := minf(float(spark.length),absf(head.x - float(spark.origin.x)))
		var tail := head - Vector2(direction * length,0)
		var color: Color = spark.color
		color.a = maxf(0,1.0 - float(spark.age) / LIFETIME)
		var glow := color
		glow.a *= .2
		draw_line(to_local(tail),to_local(head),glow,5.0,true)
		draw_line(to_local(tail),to_local(head),color,1.6,true)
