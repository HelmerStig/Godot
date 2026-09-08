extends RefCounted
class_name ManglerAnimationSetup

## Punto di ingresso compatibile per il catalogo runtime di Mangler.

const AnimationCatalog := preload("res://scripts/ManglerAnimationCatalog.gd")


static func configure_all(fighter: Mangler) -> void:
	AnimationCatalog.new(fighter).configure_all()
