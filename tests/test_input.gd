extends "res://tests/smoke_tests.gd"

## Suite indipendente per buffer, direzioni e sequenze di input.


func _run() -> void:
	Engine.time_scale = 1.0
	print("=== SANMO INPUT TESTS ===")
	await _test_input_buffer()
	_finish_suite("INPUT")
