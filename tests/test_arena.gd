extends "res://tests/smoke_tests.gd"

## Suite indipendente per composizione, wiring e avvio dell'arena.


func _run() -> void:
	Engine.time_scale = 1.0
	print("=== SANMO ARENA TESTS ===")
	await _test_arena_contract()
	_finish_suite("ARENA")
