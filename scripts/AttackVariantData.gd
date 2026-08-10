extends Resource
class_name AttackVariantData

## Configurazione di una variante contestuale dello stesso attacco base.

@export var variant_id: StringName = &"standing"
@export var animation_name: StringName
@export_range(1.0, 120.0, 1.0) var animation_fps := 48.0

@export_group("Frame data")
@export_range(0, 999, 1, "or_greater") var startup_frames := 0
@export_range(1, 999, 1, "or_greater") var active_frames := 1
@export_range(0, 999, 1, "or_greater") var recovery_frames := 0
@export_range(0, 999, 1, "or_greater") var active_animation_frame := 0

@export_group("Hit")
@export var hitbox_size := Vector2(70.0, 35.0)
@export var hitbox_position := Vector2(35.0, -110.0)
@export_enum("High", "Mid", "Low") var hit_height := 1
@export var causes_knockdown := false
@export_range(0, 99, 1, "or_greater") var hit_reaction_start_frame := 0


func get_phase_durations() -> Vector3:
	return Vector3(startup_frames, active_frames, recovery_frames) / animation_fps


func is_valid() -> bool:
	return (
		variant_id != StringName()
		and animation_fps > 0.0
		and active_frames > 0
		and hitbox_size.x > 0.0
		and hitbox_size.y > 0.0
	)
