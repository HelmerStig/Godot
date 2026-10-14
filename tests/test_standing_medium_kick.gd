extends "res://tests/support/suite_runner.gd"


func _run() -> void:
	await run_cases("standing_medium_kick", ["res://tests/cases/roster_standing_medium_kick.gd"])
	_finish_suite("standing_medium_kick")
