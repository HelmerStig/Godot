extends "res://tests/smoke_tests.gd"

## Suite indipendente per animazioni, movimento e moveset di Arianna.


func _run() -> void:
	Engine.time_scale = 1.0
	print("=== SANMO ARIANNA TESTS ===")
	await _test_arianna_idle()
	_finish_suite("ARIANNA")
