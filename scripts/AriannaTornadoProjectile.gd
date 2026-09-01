extends Area2D
class_name AriannaTornadoProjectile

const TORNADO_SHEET := preload(
	"res://assets/sprites/characters/arianna/special/tornado-spritesheet.png"
)
const FRAME_COUNT := 49
const COLUMNS := 7
const CELL_SIZE := Vector2(512.0, 512.0)
const ANIMATION_FPS := 48.0
const MOVE_SPEED := 420.0
const MEDIUM_MOVE_SPEED := 560.0
const HEAVY_MOVE_SPEED := 700.0
const MAX_LIFETIME := 4.0
const SPRITE_SCALE := Vector2(0.48, 0.48)
const START_SCALE := Vector2(0.08, 0.08)
const GROWTH_DURATION := 0.50
const DAMAGE := 10
const MEDIUM_DAMAGE := 14
const HEAVY_DAMAGE := 18
const HITBOX_SIZE := Vector2(145.0, 205.0)
const HITBOX_POSITION := Vector2(0.0, -8.0)
const IMPACT_OFFSET := Vector2(0.0, -150.0)
const IMPACT_PARTICLE_COUNT := 90
const LIGHT_IMPACT_COLOR := Color(0.3, 0.82, 1.0, 0.96)
const MEDIUM_IMPACT_COLOR := Color(1.0, 0.82, 0.12, 0.98)
const HEAVY_IMPACT_COLOR := Color(1.0, 0.22, 0.04, 0.98)
const LIGHT_FLASH_COLOR := Color(0.35, 0.82, 1.0, 1.0)
const MEDIUM_FLASH_COLOR := Color(1.0, 0.9, 0.24, 1.0)
const HEAVY_FLASH_COLOR := Color(1.0, 0.4, 0.06, 1.0)
const LIGHT_TRAIL_COLOR := Color(0.76, 0.9, 1.0, 0.48)
const MEDIUM_TRAIL_COLOR := Color(1.0, 0.86, 0.18, 0.58)
const HEAVY_TRAIL_COLOR := Color(1.0, 0.3, 0.06, 0.62)
const LIGHT_DUST_COLOR := Color(0.9, 0.94, 1.0, 0.42)
const MEDIUM_DUST_COLOR := Color(1.0, 0.78, 0.12, 0.48)
const HEAVY_DUST_COLOR := Color(0.95, 0.18, 0.04, 0.52)

var source_fighter: Fighter
var travel_direction := 1.0
var movement_speed := MOVE_SPEED
var impact_damage := DAMAGE
var effect_intensity := 1.0
var strength: StringName = &"light"
var impact_color := LIGHT_IMPACT_COLOR
var flash_color := LIGHT_FLASH_COLOR
var trail_color := LIGHT_TRAIL_COLOR
var dust_color := LIGHT_DUST_COLOR
var lifetime := 0.0
var has_hit := false
var tornado_sprite: AnimatedSprite2D


func setup(
	owner_fighter: Fighter,
	facing_right: bool,
	projectile_strength: StringName = &"light"
) -> void:
	source_fighter = owner_fighter
	travel_direction = 1.0 if facing_right else -1.0
	strength = projectile_strength
	match strength:
		&"medium":
			movement_speed = MEDIUM_MOVE_SPEED
			impact_damage = MEDIUM_DAMAGE
			effect_intensity = 1.35
			impact_color = MEDIUM_IMPACT_COLOR
			flash_color = MEDIUM_FLASH_COLOR
			trail_color = MEDIUM_TRAIL_COLOR
			dust_color = MEDIUM_DUST_COLOR
		&"heavy":
			movement_speed = HEAVY_MOVE_SPEED
			impact_damage = HEAVY_DAMAGE
			effect_intensity = 1.70
			impact_color = HEAVY_IMPACT_COLOR
			flash_color = HEAVY_FLASH_COLOR
			trail_color = HEAVY_TRAIL_COLOR
			dust_color = HEAVY_DUST_COLOR
		_:
			movement_speed = MOVE_SPEED
			impact_damage = DAMAGE
			effect_intensity = 1.0
			impact_color = LIGHT_IMPACT_COLOR
			flash_color = LIGHT_FLASH_COLOR
			trail_color = LIGHT_TRAIL_COLOR
			dust_color = LIGHT_DUST_COLOR


func _ready() -> void:
	add_to_group("arianna_baseball_tornado")
	collision_layer = 2
	collision_mask = 4
	area_entered.connect(_on_area_entered)
	_create_hitbox()
	tornado_sprite = AnimatedSprite2D.new()
	tornado_sprite.name = "TornadoSprite"
	tornado_sprite.sprite_frames = _create_frames()
	tornado_sprite.animation = &"spin"
	tornado_sprite.scale = START_SCALE
	tornado_sprite.flip_h = travel_direction < 0.0
	add_child(tornado_sprite)
	_create_wind_effects()
	tornado_sprite.play()
	var growth := tornado_sprite.create_tween()
	growth.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	growth.tween_property(tornado_sprite, "scale", SPRITE_SCALE, GROWTH_DURATION)


func _physics_process(delta: float) -> void:
	position.x += travel_direction * movement_speed * delta
	lifetime += delta
	if lifetime >= MAX_LIFETIME:
		queue_free()


func _create_hitbox() -> void:
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = HITBOX_SIZE
	collision.shape = shape
	collision.position = HITBOX_POSITION
	add_child(collision)


func _on_area_entered(area: Area2D) -> void:
	if has_hit or not area.is_in_group("hurtbox"):
		return
	var target := area.get_parent() as Fighter
	if target == null or target == source_fighter or source_fighter == null:
		return
	has_hit = true
	set_deferred("monitoring", false)
	spawn_impact_explosion(target.global_position + IMPACT_OFFSET)
	target.combat.take_damage(
		impact_damage, source_fighter, 0.32, 0.18,
		AttackData.HitHeight.MID, false, 4
	)
	queue_free()


func spawn_impact_explosion(world_position: Vector2) -> Node2D:
	var explosion := Node2D.new()
	explosion.name = "AriannaTornadoImpact"
	explosion.add_to_group("arianna_tornado_impact")
	explosion.z_index = 25
	var effect_parent: Node = get_tree().current_scene
	if effect_parent == null:
		effect_parent = get_tree().root
	effect_parent.add_child(explosion)
	explosion.global_position = world_position
	var additive_material := CanvasItemMaterial.new()
	additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var flash := Sprite2D.new()
	flash.name = "BlueFlash"
	flash.texture = _create_glow_texture()
	flash.scale = Vector2(0.35, 0.35) * effect_intensity
	flash.modulate = Color(
		flash_color.r,
		flash_color.g,
		flash_color.b,
		minf(1.0, 0.72 * effect_intensity)
	)
	flash.material = additive_material
	explosion.add_child(flash)
	var flash_tween := flash.create_tween()
	flash_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(
		flash, "scale", Vector2(1.55, 1.55) * effect_intensity, 0.16
	)
	flash_tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.30)
	var sparks := CPUParticles2D.new()
	sparks.name = "BlueSparks"
	sparks.amount = roundi(float(IMPACT_PARTICLE_COUNT) * effect_intensity)
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.lifetime = 0.46
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 100.0
	sparks.initial_velocity_max = 340.0
	sparks.scale_amount_min = 1.5
	sparks.scale_amount_max = 4.2
	sparks.color = impact_color
	sparks.material = additive_material
	explosion.add_child(sparks)
	sparks.emitting = true
	get_tree().create_timer(0.56).timeout.connect(explosion.queue_free)
	return explosion


func _create_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"spin")
	frames.set_animation_speed(&"spin", ANIMATION_FPS)
	frames.set_animation_loop(&"spin", true)
	for source_index in range(FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = TORNADO_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % COLUMNS),
				float(source_index / COLUMNS)
			) * CELL_SIZE,
			CELL_SIZE
		)
		frames.add_frame(&"spin", atlas_frame)
	return frames


func _create_wind_effects() -> void:
	var additive_material := CanvasItemMaterial.new()
	additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	var glow := Sprite2D.new()
	glow.name = "WindGlow"
	glow.texture = _create_glow_texture()
	glow.position = Vector2(0.0, -92.0)
	glow.scale = Vector2(1.05, 1.45) * effect_intensity
	glow.modulate = Color(
		flash_color.r,
		flash_color.g,
		flash_color.b,
		minf(0.72, 0.34 * effect_intensity)
	)
	glow.material = additive_material
	glow.z_index = -1
	add_child(glow)
	var glow_pulse := glow.create_tween().set_loops()
	glow_pulse.tween_property(glow, "modulate:a", 0.18, 0.12)
	glow_pulse.tween_property(glow, "modulate:a", 0.42, 0.12)

	var wind_trail := CPUParticles2D.new()
	wind_trail.name = "WindTrail"
	wind_trail.amount = roundi(36.0 * effect_intensity)
	wind_trail.lifetime = 0.42
	wind_trail.preprocess = 0.25
	wind_trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	wind_trail.emission_rect_extents = Vector2(34.0, 88.0)
	wind_trail.position = Vector2(0.0, -88.0)
	wind_trail.direction = Vector2(-travel_direction, 0.0)
	wind_trail.spread = 24.0
	wind_trail.initial_velocity_min = 80.0
	wind_trail.initial_velocity_max = 210.0
	wind_trail.gravity = Vector2.ZERO
	wind_trail.scale_amount_min = 1.2
	wind_trail.scale_amount_max = 3.2
	wind_trail.color = trail_color
	wind_trail.material = additive_material
	wind_trail.emitting = true
	wind_trail.z_index = -2
	add_child(wind_trail)

	var base_dust := CPUParticles2D.new()
	base_dust.name = "BaseDust"
	base_dust.amount = roundi(24.0 * effect_intensity)
	base_dust.lifetime = 0.34
	base_dust.preprocess = 0.2
	base_dust.position = Vector2(0.0, 94.0)
	base_dust.direction = Vector2(-travel_direction, -0.18).normalized()
	base_dust.spread = 48.0
	base_dust.initial_velocity_min = 55.0
	base_dust.initial_velocity_max = 155.0
	base_dust.gravity = Vector2(0.0, 120.0)
	base_dust.scale_amount_min = 1.0
	base_dust.scale_amount_max = 2.6
	base_dust.color = dust_color
	base_dust.material = additive_material
	base_dust.emitting = true
	add_child(base_dust)


func _create_glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(flash_color.r, flash_color.g, flash_color.b, 0.72),
		Color(impact_color.r, impact_color.g, impact_color.b, 0.25),
		Color(impact_color.r, impact_color.g, impact_color.b, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.48, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 190
	texture.height = 230
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture
