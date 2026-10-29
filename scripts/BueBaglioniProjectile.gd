extends "res://scripts/BueSingerProjectile.gd"

const BAGLIONI_MATERIALIZE := preload("res://assets/sprites/characters/bue/baglioni_electric_materialize.png")
const BAGLIONI_RUN := preload("res://assets/sprites/characters/bue/baglioni_run_singing.png")
const BAGLIONI_SLAPS := preload("res://assets/sprites/characters/bue/baglioni_slap_flurry.png")
const BAGLIONI_SONG := preload("res://assets/sounds/baglioni.mp3")

func _ready() -> void:
	add_to_group("bue_baglioni_projectile")
	super._ready()

func _animation_specs() -> Array:
	return [[&"materialize",BAGLIONI_MATERIALIZE,28,60.0,false],[&"run",BAGLIONI_RUN,49,48.0,true],[&"slaps",BAGLIONI_SLAPS,49,60.0,false]]

func _song_stream() -> AudioStream:
	return BAGLIONI_SONG

func _song_start() -> float:
	return 132.0

func _strike_frames() -> Array:
	return [23,35,40] # Source frames 24,36,41: three forward palm strikes.

func _sprite_y() -> float:
	return -150.0

func _exit_on_last_strike() -> bool:
	return false # Complete Slap flurry before resuming the run.
