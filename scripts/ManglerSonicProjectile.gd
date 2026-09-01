extends Area2D
class_name ManglerSonicProjectile

const SHEET := preload(
	"res://assets/sprites/characters/mangler/specials/objects/piatti-spritesheet.png"
)
const FRAME_COUNT := 25
const COLUMNS := 5
const CELL_SIZE := Vector2(256.0, 256.0)
const SPEED := 520.0
const MAX_LIFETIME := 3.0
const DAMAGE := 12

var source_fighter: Fighter
var travel_direction := 1.0
var movement_speed := SPEED
var elapsed := 0.0
var has_hit := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("sonic_projectile")
	configure_animation()
	area_entered.connect(_on_area_entered)
	sprite.play(&"fly")


func configure(owner_fighter: Fighter, direction: float, speed_multiplier: float = 1.0) -> void:
	source_fighter = owner_fighter
	travel_direction = signf(direction)
	movement_speed = SPEED * maxf(speed_multiplier, 1.0)
	if is_zero_approx(travel_direction):
		travel_direction = 1.0
	if is_instance_valid(sprite):
		sprite.flip_h = travel_direction < 0.0
	var trail := get_node_or_null("Trail") as CPUParticles2D
	if trail != null:
		trail.direction = Vector2(-travel_direction, 0.0)


func _physics_process(delta: float) -> void:
	position.x += travel_direction * movement_speed * delta
	elapsed += delta
	if elapsed >= MAX_LIFETIME:
		queue_free()


func configure_animation() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"fly")
	frames.set_animation_speed(&"fly", 48.0)
	frames.set_animation_loop(&"fly", true)
	for source_index in range(FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % COLUMNS),
				float(floori(float(source_index) / COLUMNS))
			) * CELL_SIZE,
			CELL_SIZE
		)
		frames.add_frame(&"fly", atlas_frame)
	sprite.sprite_frames = frames


func _on_area_entered(area: Area2D) -> void:
	if has_hit or not area.is_in_group("hurtbox"):
		return
	var target := area.get_parent() as Fighter
	if target == null or target == source_fighter:
		return
	has_hit = true
	spawn_impact_explosion(target.global_position + Vector2(0.0, -150.0))
	target.combat.take_damage(
		DAMAGE,
		source_fighter,
		0.32,
		0.18,
		AttackData.HitHeight.MID,
		false,
		3
	)
	queue_free()


func spawn_impact_explosion(world_position: Vector2) -> Node2D:
	var explosion := Node2D.new()
	explosion.name = "SonicProjectileImpact"
	explosion.add_to_group("sonic_projectile_impact")
	explosion.z_index = 20
	var effect_parent: Node = get_tree().current_scene
	if effect_parent == null:
		effect_parent = get_tree().root
	effect_parent.add_child(explosion)
	explosion.global_position = world_position
	var additive_material := CanvasItemMaterial.new()
	additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var flash := Sprite2D.new()
	flash.texture = create_impact_glow_texture()
	flash.scale = Vector2(0.45, 0.45)
	flash.material = additive_material
	explosion.add_child(flash)
	var flash_tween := flash.create_tween()
	flash_tween.tween_property(flash, "scale", Vector2(1.35, 1.35), 0.16)
	flash_tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.28)
	var sparks := CPUParticles2D.new()
	sparks.name = "ImpactSparks"
	sparks.amount = 54
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.lifetime = 0.42
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 90.0
	sparks.initial_velocity_max = 310.0
	sparks.scale_amount_min = 1.8
	sparks.scale_amount_max = 4.8
	sparks.color = Color(1.0, 0.9, 0.16, 0.96)
	sparks.material = additive_material
	sparks.emitting = true
	explosion.add_child(sparks)
	get_tree().create_timer(0.52).timeout.connect(explosion.queue_free)
	return explosion


func create_impact_glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 0.58, 0.95),
		Color(1.0, 0.78, 0.08, 0.48),
		Color(1.0, 0.52, 0.0, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 160
	texture.height = 160
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture
