extends Resource
class_name AttackData

## Dati completi di un attacco, indipendenti dal controller del fighter.

enum HitHeight {
	HIGH,
	MID,
	LOW,
}

@export var attack_id: StringName
@export_range(0, 999, 1, "or_greater") var damage := 0

@export_group("Timing")
@export_range(0.0, 5.0, 0.001, "or_greater") var startup := 0.0
@export_range(0.0, 5.0, 0.001, "or_greater") var active := 0.0
@export_range(0.0, 5.0, 0.001, "or_greater") var recovery := 0.0
@export_range(0.0, 5.0, 0.001, "or_greater") var hitstun := 0.3
@export_range(0.0, 5.0, 0.001, "or_greater") var blockstun := 0.15

@export_group("Hitbox")
@export var hit_height := HitHeight.MID
@export_range(0, 99, 1, "or_greater") var hit_reaction_start_frame := 0
@export var causes_knockdown := false
@export var hitbox_size := Vector2(70.0, 35.0)
@export var hitbox_position := Vector2(35.0, -110.0)

@export_group("Variants")
@export var variants: Array[Resource] = []


func get_total_duration() -> float:
	return startup + active + recovery


func get_variant(variant_id: StringName) -> Resource:
	for variant in variants:
		if variant != null and variant.variant_id == variant_id:
			return variant
	return null


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
		and _variants_are_valid()
	)


func _variants_are_valid() -> bool:
	var seen_ids: Dictionary = {}
	for variant in variants:
		if variant == null or not variant.is_valid() or seen_ids.has(variant.variant_id):
			return false
		seen_ids[variant.variant_id] = true
	return true
