extends "res://tests/support/suite_runner.gd"


func _run() -> void:
	await run_cases("run", ["res://tests/cases/roster_run.gd"])
	_finish_suite("run")
