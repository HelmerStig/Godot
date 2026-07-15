extends Resource
class_name AttackData

## Dati completi di un attacco, indipendenti dal controller del fighter.

@export var attack_id: StringName
@export_range(0, 999, 1, "or_greater") var damage := 0

@export_group("Timing")
@export_range(0.0, 5.0, 0.001, "or_greater") var startup := 0.0
@export_range(0.0, 5.0, 0.001, "or_greater") var active := 0.0
@export_range(0.0, 5.0, 0.001, "or_greater") var recovery := 0.0
@export_range(0.0, 5.0, 0.001, "or_greater") var hitstun := 0.3
@export_range(0.0, 5.0, 0.001, "or_greater") var blockstun := 0.15

@export_group("Hitbox")
@export var hitbox_size := Vector2(70.0, 35.0)
@export var hitbox_position := Vector2(35.0, -110.0)


func get_total_duration() -> float:
	return startup + active + recovery


func is_valid() -> bool:
	return (
		attack_id != StringName()
		and damage >= 0
		and startup >= 0.0
		and active > 0.0
		and recovery >= 0.0
		and hitstun >= 0.0
		and blockstun >= 0.0
		and hitbox_size.x > 0.0
		and hitbox_size.y > 0.0
	)
