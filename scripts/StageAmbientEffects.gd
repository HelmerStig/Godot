extends Node2D

@export var effects_enabled := true
@export_range(0.25, 2.0, 0.05) var intensity := 1.0
@export var birds_texture: Texture2D

const STAGE_WIDTH := 2304.0
const DESPAWN_X := 2400.0

var _rng := RandomNumberGenerator.new()
var _birds: Array[Dictionary] = []
var _spawn_timer := 0.0
var _elapsed := 0.0


func _ready() -> void:
	_rng.randomize()
	if not effects_enabled:
		set_process(false)
		return

	for index in range(2):
		_spawn_birds(true)
	_reset_spawn_timer()


func _process(delta: float) -> void:
	_elapsed += delta
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_birds()
		_reset_spawn_timer()

	for index in range(_birds.size() - 1, -1, -1):
		var bird := _birds[index]
		var sprite: Sprite2D = bird["sprite"]
		sprite.position.x += float(bird["speed"]) * delta
		sprite.position.y = float(bird["base_y"]) + sin(
			_elapsed * float(bird["bob_frequency"]) + float(bird["phase"])
		) * float(bird["bob_amplitude"])

		if sprite.position.x > DESPAWN_X:
			_birds.remove_at(index)
			sprite.queue_free()


func _reset_spawn_timer() -> void:
	_spawn_timer = _rng.randf_range(5.0, 9.0) / intensity


func _spawn_birds(start_inside_stage := false) -> void:
	if birds_texture == null:
		return

	var sprite := Sprite2D.new()
	sprite.texture = birds_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(
		_rng.randf_range(0.0, STAGE_WIDTH) if start_inside_stage else -70.0,
		_rng.randf_range(90.0, 205.0)
	)
	sprite.scale = Vector2.ONE * _rng.randf_range(0.55, 0.85)
	sprite.z_index = -10
	add_child(sprite)

	_birds.append({
		"sprite": sprite,
		"speed": _rng.randf_range(38.0, 68.0),
		"base_y": sprite.position.y,
		"bob_amplitude": _rng.randf_range(2.0, 5.0),
		"bob_frequency": _rng.randf_range(0.8, 1.3),
		"phase": _rng.randf_range(0.0, TAU),
	})
