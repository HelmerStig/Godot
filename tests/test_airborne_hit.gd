extends "res://tests/support/suite_runner.gd"


func _run() -> void:
	await run_cases("airborne_hit", ["res://tests/cases/airborne_hit.gd"])
	_finish_suite("airborne_hit")
