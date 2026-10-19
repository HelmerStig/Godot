extends "res://tests/support/suite_runner.gd"


func _run() -> void:
	await run_cases("roster_victory", ["res://tests/cases/roster_victory.gd"])
	_finish_suite("roster_victory")
