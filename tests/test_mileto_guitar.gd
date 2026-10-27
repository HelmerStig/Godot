extends "res://tests/support/suite_runner.gd"

func _run() -> void:
	await run_cases("mileto_guitar",["res://tests/cases/mileto_guitar_special.gd"])
	_finish_suite("mileto_guitar")
