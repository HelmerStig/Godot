extends "res://tests/smoke_tests.gd"

## Suite indipendente per risorse e frame data del sistema di combattimento.


func _run() -> void:
	Engine.time_scale = 1.0
	print("=== SANMO COMBAT TESTS ===")
	_test_attack_data()
	_finish_suite("COMBAT")
