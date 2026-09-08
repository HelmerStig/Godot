extends "res://tests/smoke_tests.gd"

## Suite indipendente per animazioni, movimento e moveset storico di Mangler.


func _run() -> void:
	Engine.time_scale = 1.0
	print("=== SANMO MANGLER TESTS ===")
	await _test_combat_flow()
	_finish_suite("MANGLER")
