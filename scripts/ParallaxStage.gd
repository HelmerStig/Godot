extends Node2D

## Parallasse orizzontale leggero per lo stage predefinito.

const SKY_SCROLL_FACTOR = 0.05
const MIDGROUND_SCROLL_FACTOR = 0.15
# Il terreno è ancorato al mondo per non scivolare sotto i fighter.
const FOREGROUND_SCROLL_FACTOR = 1.0

@export var stage_center_x = 1152.0

@onready var sky: Sprite2D = $Sky
@onready var midground: Sprite2D = $Midground
@onready var foreground: Sprite2D = $Foreground


func _process(_delta):
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return

	var camera_offset = camera.get_screen_center_position().x - stage_center_x
	sky.position.x = stage_center_x + camera_offset * (1.0 - SKY_SCROLL_FACTOR)
	midground.position.x = stage_center_x + camera_offset * (1.0 - MIDGROUND_SCROLL_FACTOR)
	foreground.position.x = stage_center_x + camera_offset * (1.0 - FOREGROUND_SCROLL_FACTOR)
