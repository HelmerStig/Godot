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

var source_fighter: Mangler
var travel_direction := 1.0
var elapsed := 0.0
var has_hit := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("sonic_projectile")
	configure_animation()
	area_entered.connect(_on_area_entered)
	sprite.play(&"fly")


func configure(owner_fighter: Mangler, direction: float) -> void:
	source_fighter = owner_fighter
	travel_direction = signf(direction)
	if is_zero_approx(travel_direction):
		travel_direction = 1.0
	if is_instance_valid(sprite):
		sprite.flip_h = travel_direction < 0.0
	var trail := get_node_or_null("Trail") as CPUParticles2D
	if trail != null:
		trail.direction = Vector2(-travel_direction, 0.0)


func _physics_process(delta: float) -> void:
	position.x += travel_direction * SPEED * delta
	elapsed += delta
	if elapsed >= MAX_LIFETIME:
		queue_free()


func configure_animation() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"fly")
	frames.set_animation_speed(&"fly", 24.0)
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
	var target := area.get_parent() as Mangler
	if target == null or target == source_fighter:
		return
	has_hit = true
	target.combat.take_damage(
		DAMAGE,
		source_fighter,
		0.32,
		0.18,
		AttackData.HitHeight.HIGH,
		false,
		3
	)
	queue_free()
