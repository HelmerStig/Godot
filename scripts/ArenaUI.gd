extends Control
class_name ArenaUI

## Presenta lo stato dell'arena senza essere interrogata direttamente dal gameplay.

@onready var player1_health_bar: ProgressBar = $Player1Health
@onready var player2_health_bar: ProgressBar = $Player2Health
@onready var round_timer_label: Label = $RoundTimer
@onready var round_label: Label = $RoundLabel


func _ready() -> void:
	var arena: Node = owner
	if arena == null:
		push_error("ArenaUI deve appartenere a una MainArena")
		return

	for required_signal in [
		&"fighter_health_changed",
		&"round_time_changed",
		&"round_message_changed",
	]:
		if not arena.has_signal(required_signal):
			push_error("MainArena non espone il segnale richiesto: " + str(required_signal))
			return

	arena.connect(&"fighter_health_changed", _on_fighter_health_changed)
	arena.connect(&"round_time_changed", _on_round_time_changed)
	arena.connect(&"round_message_changed", _on_round_message_changed)


func _on_fighter_health_changed(
	player_number: int,
	current_health: int,
	max_health: int
) -> void:
	var health_bar := player1_health_bar if player_number == 1 else player2_health_bar
	health_bar.value = _health_percentage(current_health, max_health)


func _on_round_time_changed(seconds_remaining: int) -> void:
	round_timer_label.text = str(seconds_remaining)


func _on_round_message_changed(message: String, is_visible: bool) -> void:
	round_label.text = message
	round_label.visible = is_visible


func _health_percentage(current_health: int, max_health: int) -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health) * 100.0
