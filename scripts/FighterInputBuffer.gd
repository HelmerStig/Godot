extends RefCounted
class_name FighterInputBuffer

## Memorizza gli input recenti di un fighter in direzioni relative all'avversario.
## Le direzioni arrivano dal D-pad o dallo stick sinistro tramite l'Input Map.

enum Direction {
	NEUTRAL,
	UP,
	DOWN,
	FORWARD,
	BACK,
	UP_FORWARD,
	UP_BACK,
	DOWN_FORWARD,
	DOWN_BACK,
}

const NO_DIRECTION := -1
const HISTORY_LIMIT := 30
const DEFAULT_ATTACK_BUFFER_FRAMES := 6
const ATTACK_ACTIONS := [
	&"light_punch",
	&"medium_punch",
	&"heavy_punch",
	&"light_kick",
	&"medium_kick",
	&"heavy_kick",
]

var player_number: int
var _history: Array[Dictionary] = []
var _consumed_attack_frames: Dictionary = {}
var _horizontal := 0
var _vertical := 0
var _current_direction := Direction.NEUTRAL


func _init(new_player_number: int = 1) -> void:
	player_number = new_player_number


func update(is_facing_right: bool) -> void:
	_horizontal = (
		int(Input.is_action_pressed(get_action(&"move_right")))
		- int(Input.is_action_pressed(get_action(&"move_left")))
	)
	_vertical = (
		int(Input.is_action_pressed(get_action(&"crouch")))
		- int(Input.is_action_pressed(get_action(&"jump")))
	)
	_current_direction = _to_relative_direction(_horizontal, _vertical, is_facing_right)

	var pressed_attacks: Array[StringName] = []
	for attack_action in ATTACK_ACTIONS:
		if Input.is_action_just_pressed(get_action(attack_action)):
			pressed_attacks.append(attack_action)

	_history.push_front({
		"frame": Engine.get_physics_frames(),
		"direction": _current_direction,
		"attacks": pressed_attacks,
	})
	if _history.size() > HISTORY_LIMIT:
		_history.pop_back()


func clear() -> void:
	_history.clear()
	_consumed_attack_frames.clear()
	_horizontal = 0
	_vertical = 0
	_current_direction = Direction.NEUTRAL


func get_action(action_name: StringName) -> StringName:
	return StringName("p%d_%s" % [player_number, action_name])


func get_horizontal_axis() -> float:
	return float(_horizontal)


func get_current_direction() -> int:
	return _current_direction


func is_down_held() -> bool:
	return _vertical > 0


func is_back_held() -> bool:
	return _current_direction in [Direction.BACK, Direction.UP_BACK, Direction.DOWN_BACK]


func consume_attack(
	attack_action: StringName,
	max_age_frames: int = DEFAULT_ATTACK_BUFFER_FRAMES
) -> int:
	"""Consuma un attacco recente e restituisce la direzione tenuta alla pressione."""
	var current_frame := Engine.get_physics_frames()
	var last_consumed_frame := int(_consumed_attack_frames.get(attack_action, -1))

	for entry in _history:
		var entry_frame := int(entry["frame"])
		if current_frame - entry_frame > max_age_frames:
			break
		var attacks: Array = entry["attacks"]
		if attacks.has(attack_action) and entry_frame > last_consumed_frame:
			_consumed_attack_frames[attack_action] = entry_frame
			return int(entry["direction"])

	return NO_DIRECTION


func matches_recent_sequence(sequence: Array[int], within_frames: int = 20) -> bool:
	"""Base per future mosse speciali, ad esempio DOWN, DOWN_FORWARD, FORWARD."""
	if sequence.is_empty():
		return false

	var current_frame := Engine.get_physics_frames()
	var expected_index := sequence.size() - 1
	var previous_direction := NO_DIRECTION
	for entry in _history:
		if current_frame - int(entry["frame"]) > within_frames:
			break
		var direction := int(entry["direction"])
		if direction == previous_direction:
			continue
		previous_direction = direction
		if direction == sequence[expected_index]:
			expected_index -= 1
			if expected_index < 0:
				return true

	return false


func _to_relative_direction(
	absolute_horizontal: int,
	absolute_vertical: int,
	is_facing_right: bool
) -> int:
	var relative_horizontal := absolute_horizontal if is_facing_right else -absolute_horizontal

	if absolute_vertical < 0:
		if relative_horizontal > 0:
			return Direction.UP_FORWARD
		if relative_horizontal < 0:
			return Direction.UP_BACK
		return Direction.UP
	if absolute_vertical > 0:
		if relative_horizontal > 0:
			return Direction.DOWN_FORWARD
		if relative_horizontal < 0:
			return Direction.DOWN_BACK
		return Direction.DOWN
	if relative_horizontal > 0:
		return Direction.FORWARD
	if relative_horizontal < 0:
		return Direction.BACK
	return Direction.NEUTRAL
