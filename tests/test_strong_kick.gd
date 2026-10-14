extends "res://tests/support/suite_runner.gd"

func _run() -> void:
	await run_cases("strong_kick", ["res://tests/cases/roster_strong_kick.gd"])
	_finish_suite("strong_kick")
