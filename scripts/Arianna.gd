extends Mangler
class_name Arianna

## Arianna riusa temporaneamente l'infrastruttura comune di Mangler (vita,
## collisioni, facing e reset), ma registra il proprio idle e resta immobile
## finché non verranno integrate le sue mosse.

const ARIANNA_IDLE_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/idle.png"
)
const ARIANNA_IDLE_FRAME_COUNT := 24
const ARIANNA_IDLE_COLUMNS := 7
const ARIANNA_IDLE_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_WALK_SHEET := preload(
	"res://assets/sprites/characters/arianna/basic-moves/01-walk.png"
)
const ARIANNA_WALK_FRAME_COUNT := 48
const ARIANNA_WALK_COLUMNS := 7
const ARIANNA_WALK_CELL_SIZE := Vector2(512.0, 512.0)
const ARIANNA_SPRITE_SCALE := Vector2(0.85, 0.85)
const ARIANNA_SPRITE_POSITION := Vector2(0.0, -120.0)


func _ready() -> void:
	# La scena ereditata punta allo SpriteFrames di Mangler: duplicarlo evita che
	# Player 2 sovrascriva l'atlante idle di Arianna durante il proprio _ready().
	animated_sprite.sprite_frames = animated_sprite.sprite_frames.duplicate(true)
	super._ready()
	_activate_idle()
	call_deferred("_activate_idle")


func _physics_process(_delta: float) -> void:
	if is_player_controlled:
		input_buffer.update(is_facing_right)
	var horizontal_axis := input_buffer.get_horizontal_axis() if input_buffer != null else 0.0
	var walking_forward := controls_enabled and can_move and is_forward_input(horizontal_axis)
	var walking_backward := controls_enabled and can_move and is_backward_input(horizontal_axis)
	var is_walking := walking_forward or walking_backward
	velocity = Vector2(
		signf(horizontal_axis) * character_data.walk_speed
		if is_walking
		else 0.0,
		0.0
	)
	current_state = State.WALKING if is_walking else State.IDLE
	move_and_slide()
	position.x = clampf(position.x, stage_left_limit, stage_right_limit)
	var desired_animation: StringName = (
		&"walk" if walking_forward else (&"backwalk" if walking_backward else &"idle")
	)
	if animated_sprite.animation != desired_animation or not animated_sprite.is_playing():
		animated_sprite.play(desired_animation)
	update_facing_direction()
	update_ground_shadow()


func _activate_idle() -> void:
	animated_sprite.position = ARIANNA_SPRITE_POSITION
	animated_sprite.scale = ARIANNA_SPRITE_SCALE
	animated_sprite.play(&"idle")


func update_sprite_scale() -> void:
	animated_sprite.scale = ARIANNA_SPRITE_SCALE
	animated_sprite.position = ARIANNA_SPRITE_POSITION
	grab_front_sprite.scale = ARIANNA_SPRITE_SCALE
	grab_front_sprite.position = ARIANNA_SPRITE_POSITION


func configure_idle_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"idle"):
		frames.remove_animation(&"idle")
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 24.0)
	frames.set_animation_loop(&"idle", true)
	for source_index in range(ARIANNA_IDLE_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = ARIANNA_IDLE_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % ARIANNA_IDLE_COLUMNS),
				float(floori(float(source_index) / ARIANNA_IDLE_COLUMNS))
			) * ARIANNA_IDLE_CELL_SIZE,
			ARIANNA_IDLE_CELL_SIZE
		)
		frames.add_frame(&"idle", atlas_frame)


func configure_walk_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"walk"):
		frames.remove_animation(&"walk")
	frames.add_animation(&"walk")
	frames.set_animation_speed(&"walk", 24.0)
	frames.set_animation_loop(&"walk", true)
	for source_index in range(ARIANNA_WALK_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = ARIANNA_WALK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % ARIANNA_WALK_COLUMNS),
				float(floori(float(source_index) / ARIANNA_WALK_COLUMNS))
			) * ARIANNA_WALK_CELL_SIZE,
			ARIANNA_WALK_CELL_SIZE
		)
		frames.add_frame(&"walk", atlas_frame)


func configure_backwalk_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames.has_animation(&"backwalk"):
		frames.remove_animation(&"backwalk")
	frames.add_animation(&"backwalk")
	frames.set_animation_speed(&"backwalk", 24.0)
	frames.set_animation_loop(&"backwalk", true)
	for source_index in range(ARIANNA_WALK_FRAME_COUNT - 1, -1, -1):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = ARIANNA_WALK_SHEET
		atlas_frame.region = Rect2(
			Vector2(
				float(source_index % ARIANNA_WALK_COLUMNS),
				float(floori(float(source_index) / ARIANNA_WALK_COLUMNS))
			) * ARIANNA_WALK_CELL_SIZE,
			ARIANNA_WALK_CELL_SIZE
		)
		frames.add_frame(&"backwalk", atlas_frame)


func is_forward_input(horizontal_axis: float) -> bool:
	return horizontal_axis > 0.0 if is_facing_right else horizontal_axis < 0.0


func is_backward_input(horizontal_axis: float) -> bool:
	return horizontal_axis < 0.0 if is_facing_right else horizontal_axis > 0.0


func handle_input() -> void:
	# Arianna resta in idle finché non dispone del proprio moveset.
	velocity.x = 0.0
