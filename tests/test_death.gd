extends "res://tests/support/suite_runner.gd"


func _run() -> void:
	await run_cases("death", ["res://tests/cases/roster_death.gd"])
	_finish_suite("death")
