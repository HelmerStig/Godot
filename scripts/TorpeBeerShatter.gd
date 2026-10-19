extends Node2D
class_name TorpeBeerShatter

const TEXTURE := preload("res://assets/sprites/characters/torpe/beer_bottle.png")
const BREAK_SOUND := preload("res://assets/sounds/sfx/bottiglia-rotta.wav")
const SOURCE_RECT := Rect2(320, 51, 389, 1400)
const OUTLINE := [Vector2(.30,0), Vector2(.70,0), Vector2(.75,.30), Vector2(.95,.40), Vector2(1,.48), Vector2(1,.95), Vector2(.90,1), Vector2(.10,1), Vector2(0,.95), Vector2(0,.48), Vector2(.05,.40), Vector2(.25,.30)]

var source_fighter: Fighter
var bottle_length := 73.44
var bottle_rotation := 0.0
var incoming_velocity := Vector2.ZERO
var elapsed := 0.0


func _ready() -> void:
	add_to_group("torpe_beer_shatter")
	z_index = 10
	var audio := AudioStreamPlayer.new()
	audio.name = "BeerBottleBreakAudio"
	audio.stream = BREAK_SOUND
	audio.set_meta(&"source_id", source_fighter.get_instance_id() if is_instance_valid(source_fighter) else 0)
	get_parent().add_child(audio)
	audio.add_to_group("torpe_beer_break_audio")
	audio.finished.connect(audio.queue_free)
	audio.play()
	var size := Vector2(bottle_length * SOURCE_RECT.size.x / SOURCE_RECT.size.y, bottle_length)
	var center := Vector2(.5, .60)
	for index in OUTLINE.size():
		var normalized := PackedVector2Array([center, OUTLINE[index], OUTLINE[(index + 1) % OUTLINE.size()]])
		var centroid := ((normalized[0] + normalized[1] + normalized[2]) / 3.0 - Vector2(.5,.5)) * size
		var points := PackedVector2Array()
		var uv := PackedVector2Array()
		for point in normalized:
			points.append((point - Vector2(.5,.5)) * size - centroid)
			uv.append(SOURCE_RECT.position + point * SOURCE_RECT.size)
		var body := RigidBody2D.new()
		body.name = "GlassShard%d" % index
		body.position = centroid.rotated(bottle_rotation)
		body.rotation = bottle_rotation
		body.mass = .03
		body.collision_layer = 0
		body.collision_mask = 1
		body.gravity_scale = .8
		body.linear_damp = .4
		body.angular_damp = 1.2
		var material := PhysicsMaterial.new()
		material.bounce = .25
		material.friction = .8
		body.physics_material_override = material
		var polygon := Polygon2D.new()
		polygon.polygon = points
		polygon.uv = uv
		polygon.texture = TEXTURE
		body.add_child(polygon)
		var collision := CollisionPolygon2D.new()
		collision.polygon = points
		body.add_child(collision)
		body.linear_velocity = centroid.normalized().rotated(bottle_rotation) * randf_range(120, 240) + incoming_velocity * .18 + Vector2(0, -120)
		body.angular_velocity = randf_range(-9,9)
		add_child(body)
	var spray := CPUParticles2D.new()
	spray.name = "BeerSpray"
	spray.amount = 24
	spray.lifetime = .55
	spray.one_shot = true
	spray.explosiveness = 1.0
	spray.direction = Vector2.UP
	spray.spread = 100
	spray.gravity = Vector2(0,900)
	spray.initial_velocity_min = 80
	spray.initial_velocity_max = 180
	spray.scale_amount_min = 2
	spray.scale_amount_max = 4
	spray.color = Color(1,.67,.2,.85)
	add_child(spray)
	spray.emitting = true


func _process(delta: float) -> void:
	elapsed += delta
	modulate.a = clampf((1.4 - elapsed) / .4, 0, 1)
	if elapsed >= 1.4:
		queue_free()
