extends "res://tests/support/suite_runner.gd"

func _run() -> void:
	await run_cases("mileto_shoulder",["res://tests/cases/mileto_shoulder_special.gd"])
	_finish_suite("mileto_shoulder")
