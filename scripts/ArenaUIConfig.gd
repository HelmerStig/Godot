extends RefCounted
class_name ArenaUIConfig

## Configurazione visiva delle barre vita, separata dal controller della UI.

const HEALTH_BAR_SHADOW := preload("res://assets/ui/bar/bar-01-shadow.png")
const HEALTH_BAR_GLOW := preload("res://assets/ui/bar/bar-02-glow.png")
const HEALTH_BAR_FILL := preload("res://assets/ui/bar/bar-03-fill.png")
const HEALTH_BAR_OUTLINE := preload("res://assets/ui/bar/bar-04-outline.png")

const HEALTH_BAR_SIZE := Vector2(350.0, 47.0)
const HEALTH_ANIMATION_DURATION := 0.34
const DAMAGE_GLOW_FADE_IN_DURATION := 0.045
const DAMAGE_GLOW_FADE_OUT_DURATION := 0.22
const HEALTH_ANIMATION_TRANSITION := Tween.TRANS_QUAD
const HEALTH_ANIMATION_EASE := Tween.EASE_OUT
