extends "res://tests/support/suite_runner.gd"


func _run() -> void:
	await run_cases("knockdown", ["res://tests/cases/roster_knockdown.gd"])
	_finish_suite("knockdown")
