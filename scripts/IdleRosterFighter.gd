extends Fighter
class_name IdleRosterFighter

## Fighter iniziale con idle e camminata, in attesa del moveset completo.
## La scena resta compatibile con arena e MovementTest.

const IDLE_FPS := 18.0
const WALK_FPS := 24.0
const GRAVITY := 3150.0

@export var fighter_id: StringName
@export var fighter_display_name := "Fighter"
@export var idle_sheet: Texture2D
@export_range(1, 999, 1) var idle_frame_count := 1
@export_range(1, 99, 1) var idle_columns := 7
@export var idle_cell_size := Vector2(512.0, 512.0)
@export var walk_sheet: Texture2D
@export_range(1, 999, 1) var walk_frame_count := 49
@export_range(1, 99, 1) var walk_columns := 7
@export var walk_cell_size := Vector2(512.0, 512.0)
@export var idle_sprite_scale := Vector2(0.85, 0.85)
@export var idle_sprite_position := Vector2(0.0, -115.0)


func _ready() -> void:
	_configure_animations()
	var data := CharacterData.create_default()
	data.character_name = String(fighter_id)
	data.display_name = fighter_display_name
	character_data = data
	super._ready()
	animated_sprite.play(&"idle")


func _physics_process(delta: float) -> void:
	if is_player_controlled and input_buffer != null:
		input_buffer.update(is_facing_right)
	var can_walk := (
		controls_enabled
		and can_move
		and current_state in [State.IDLE, State.WALKING]
		and is_on_floor()
		and input_buffer != null
	)
	var direction := input_buffer.get_horizontal_axis() if can_walk else 0.0
	velocity.x = direction * character_data.walk_speed
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	update_physical_collision()
	move_and_slide()
	position.x = clampf(position.x, stage_left_limit, stage_right_limit)
	update_facing_direction()
	update_ground_shadow()
	if current_state in [State.IDLE, State.WALKING]:
		var next_state := State.WALKING if not is_zero_approx(velocity.x) and is_on_floor() else State.IDLE
		if current_state != next_state:
			change_state(next_state)
		else:
			update_animation()


func update_sprite_scale() -> void:
	animated_sprite.scale = idle_sprite_scale
	animated_sprite.position = idle_sprite_position


func _configure_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_sheet_animation(frames, &"idle", idle_sheet, idle_frame_count, idle_columns, idle_cell_size, IDLE_FPS)
	if walk_sheet != null:
		_add_sheet_animation(frames, &"walk", walk_sheet, walk_frame_count, walk_columns, walk_cell_size, WALK_FPS)
		_add_sheet_animation(frames, &"backwalk", walk_sheet, walk_frame_count, walk_columns, walk_cell_size, WALK_FPS, true)
	animated_sprite.sprite_frames = frames
	animated_sprite.animation = &"idle"
	update_sprite_scale()


func _add_sheet_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	sheet: Texture2D,
	frame_count: int,
	columns: int,
	cell_size: Vector2,
	fps: float,
	reverse := false
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, true)
	for frame_index in frame_count:
		var source_index: int = frame_count - 1 - frame_index if reverse else frame_index
		var texture := AtlasTexture.new()
		texture.atlas = sheet
		texture.region = Rect2(
			float(source_index % columns) * cell_size.x,
			float(source_index / columns) * cell_size.y,
			cell_size.x,
			cell_size.y
		)
		frames.add_frame(animation_name, texture)
