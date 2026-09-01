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
const HISTORY_LIMIT := 60
const DEFAULT_ATTACK_BUFFER_FRAMES := 10
const DEFAULT_MOTION_WINDOW_FRAMES := 36
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
var _forward_was_held := false
var _forward_just_pressed := false
var _back_was_held := false
var _back_just_pressed := false


func _init(new_player_number: int = 1) -> void:
	player_number = new_player_number


func update(is_facing_right: bool) -> void:
	var absolute_horizontal := (
		int(Input.is_action_pressed(get_action(&"move_right")))
		- int(Input.is_action_pressed(get_action(&"move_left")))
	)
	var absolute_vertical := (
		int(Input.is_action_pressed(get_action(&"crouch")))
		- int(Input.is_action_pressed(get_action(&"jump")))
	)

	var pressed_attacks: Array[StringName] = []
	for attack_action in ATTACK_ACTIONS:
		if Input.is_action_just_pressed(get_action(attack_action)):
			pressed_attacks.append(attack_action)
	record_input_snapshot(
		absolute_horizontal,
		absolute_vertical,
		pressed_attacks,
		is_facing_right
	)


func record_input_snapshot(
	absolute_horizontal: int,
	absolute_vertical: int,
	pressed_attacks: Array[StringName],
	is_facing_right: bool
) -> void:
	"""Registra uno snapshot esplicito, utile anche per replay, IA e test headless."""
	var previous_direction := _current_direction
	_horizontal = clampi(absolute_horizontal, -1, 1)
	_vertical = clampi(absolute_vertical, -1, 1)
	_current_direction = _to_relative_direction(_horizontal, _vertical, is_facing_right)
	var forward_is_held := _current_direction == Direction.FORWARD
	_forward_just_pressed = forward_is_held and not _forward_was_held
	_forward_was_held = forward_is_held
	var back_is_held := _current_direction == Direction.BACK
	_back_just_pressed = back_is_held and not _back_was_held
	_back_was_held = back_is_held

	_history.push_front({
		"frame": Engine.get_physics_frames(),
		"direction": _current_direction,
		"attacks": pressed_attacks.duplicate(),
	})
	# Uno stick analogico può attraversare la diagonale fra due frame fisici.
	# Conserviamo quel passaggio implicito per non perdere i quarti di luna rapidi.
	var inferred_directions: Array[int] = []
	if previous_direction == Direction.BACK and _current_direction == Direction.DOWN:
		inferred_directions = [Direction.DOWN_BACK]
	elif previous_direction == Direction.BACK and _current_direction == Direction.DOWN_FORWARD:
		inferred_directions = [Direction.DOWN_BACK, Direction.DOWN]
	elif previous_direction == Direction.DOWN_BACK and _current_direction == Direction.DOWN_FORWARD:
		inferred_directions = [Direction.DOWN]
	elif previous_direction == Direction.DOWN_BACK and _current_direction == Direction.FORWARD:
		inferred_directions = [Direction.DOWN, Direction.DOWN_FORWARD]
	elif previous_direction == Direction.DOWN and _current_direction == Direction.FORWARD:
		inferred_directions = [Direction.DOWN_FORWARD]
	for inferred_direction in inferred_directions:
		_history.insert(1, {
			"frame": Engine.get_physics_frames(),
			"direction": inferred_direction,
			"attacks": [],
		})
	if _history.size() > HISTORY_LIMIT:
		_history.resize(HISTORY_LIMIT)


func clear() -> void:
	_history.clear()
	_consumed_attack_frames.clear()
	_horizontal = 0
	_vertical = 0
	_current_direction = Direction.NEUTRAL
	_forward_was_held = false
	_forward_just_pressed = false
	_back_was_held = false
	_back_just_pressed = false


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


func is_forward_held() -> bool:
	return _current_direction == Direction.FORWARD


func is_forward_just_pressed() -> bool:
	return _forward_just_pressed


func is_back_just_pressed() -> bool:
	return _back_just_pressed


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


func consume_attack_chord(
	attack_actions: Array[StringName],
	max_age_frames: int = DEFAULT_ATTACK_BUFFER_FRAMES,
	chord_window_frames: int = 0
) -> int:
	"""Consuma più attacchi simultanei o premuti entro una breve finestra."""
	if attack_actions.is_empty():
		return NO_DIRECTION
	var current_frame := Engine.get_physics_frames()
	var matched_frames: Dictionary = {}
	var newest_frame := -1
	var newest_direction := NO_DIRECTION
	for entry in _history:
		var entry_frame := int(entry["frame"])
		if current_frame - entry_frame > max_age_frames:
			break
		var attacks: Array = entry["attacks"]
		for attack_action in attack_actions:
			if (
				matched_frames.has(attack_action)
				or not attacks.has(attack_action)
				or entry_frame <= int(_consumed_attack_frames.get(attack_action, -1))
			):
				continue
			matched_frames[attack_action] = entry_frame
			if entry_frame > newest_frame:
				newest_frame = entry_frame
				newest_direction = int(entry["direction"])
	if matched_frames.size() != attack_actions.size():
		return NO_DIRECTION
	var oldest_frame := newest_frame
	for matched_frame in matched_frames.values():
		oldest_frame = mini(oldest_frame, int(matched_frame))
	if newest_frame - oldest_frame > chord_window_frames:
		return NO_DIRECTION
	for attack_action in attack_actions:
		_consumed_attack_frames[attack_action] = int(matched_frames[attack_action])
	return newest_direction


func matches_recent_sequence(
	sequence: Array[int], within_frames: int = DEFAULT_MOTION_WINDOW_FRAMES
) -> bool:
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
