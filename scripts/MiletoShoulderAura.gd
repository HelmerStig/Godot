extends Node2D

var source_fighter: Fighter
var tint := Color.CYAN
var emitting := true
var age := 0.0
var fade := 1.0
var _sample_time := 0.0
var _ghosts: Array[Dictionary] = []
var _glow: Sprite2D
var _burst: CPUParticles2D


func setup(fighter: Fighter, color: Color) -> void:
	source_fighter = fighter
	tint = color


func _ready() -> void:
	add_to_group("mileto_shoulder_aura")
	z_index = source_fighter.z_index - 1
	var blend := CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = blend
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(tint,.48),Color(tint,.16),Color(tint,0)])
	gradient.offsets = PackedFloat32Array([0,.55,1])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(.5,.5)
	texture.fill_to = Vector2(1,.5)
	texture.width = 256
	texture.height = 256
	_glow = Sprite2D.new()
	_glow.texture = texture
	_glow.scale = Vector2(.85,1.4)
	add_child(_glow)
	_burst = CPUParticles2D.new()
	_burst.amount = 70
	_burst.lifetime = .4
	_burst.one_shot = true
	_burst.explosiveness = 1.0
	_burst.direction = Vector2.RIGHT
	_burst.spread = 180
	_burst.gravity = Vector2.ZERO
	_burst.initial_velocity_min = 180
	_burst.initial_velocity_max = 440
	_burst.scale_amount_min = 2
	_burst.scale_amount_max = 5
	_burst.color = tint
	_burst.local_coords = false
	add_child(_burst)
	_sync()
	_burst.emitting = true


func _sync() -> void:
	if is_instance_valid(source_fighter):
		_glow.global_position = source_fighter.global_position + Vector2(0,-150)
		_burst.global_position = _glow.global_position


func stop_emitting(immediate := false) -> void:
	emitting = false
	if is_instance_valid(_burst):
		_burst.emitting = false
	if immediate:
		queue_free()


func _process(delta: float) -> void:
	age += delta
	if not is_instance_valid(source_fighter) or not source_fighter.shoulder_active:
		emitting = false
	_sync()
	if emitting:
		_sample_time += delta
		if _sample_time >= .035 and absf(source_fighter.velocity.x) > 1:
			_sample_time = 0
			_add_ghost()
	else:
		fade = maxf(0,fade - delta / .2)
		if fade <= 0:
			queue_free()
			return
	for index in range(_ghosts.size()-1,-1,-1):
		var ghost: Dictionary = _ghosts[index]
		ghost.age += delta
		ghost.sprite.modulate.a = maxf(0,.42 * (1.0 - float(ghost.age) / .18))
		if ghost.age >= .18:
			ghost.sprite.queue_free()
			_ghosts.remove_at(index)
	_glow.modulate.a = fade * (.85 + .15 * sin(age * 32))
	queue_redraw()


func _add_ghost() -> void:
	var source := source_fighter.animated_sprite
	var sprite := Sprite2D.new()
	sprite.texture = source.sprite_frames.get_frame_texture(source.animation,source.frame)
	sprite.flip_h = source.flip_h
	sprite.offset = source.offset
	sprite.modulate = Color(tint,.42)
	add_child(sprite)
	sprite.global_transform = source.global_transform
	_ghosts.append({"sprite":sprite,"age":0.0})


func _draw() -> void:
	if not is_instance_valid(source_fighter):
		return
	var center := to_local(source_fighter.global_position + Vector2(0,-150))
	# Expanding ignition ring plus a flickering, elongated aura around the body.
	if age < .38:
		var radius := 25 + 210 * age / .38
		draw_arc(center,radius,0,TAU,64,Color(tint,(1-age/.38)*.85*fade),4,true)
	for layer in 2:
		var points := PackedVector2Array()
		for index in 49:
			var angle := index * TAU / 48.0
			var pulse := 1.0 + .07 * sin(angle * 9 + age * 40 + layer)
			points.append(center + Vector2(cos(angle)*78,sin(angle)*140) * pulse * (1 + layer*.08))
		draw_polyline(points,Color(tint,(.65-layer*.25)*fade),2.5-layer,true)
