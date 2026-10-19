extends "res://tests/support/suite_runner.gd"

func _run() -> void:
	await run_cases("hitboxes",["res://tests/cases/calibrated_hitboxes.gd"])
	_finish_suite("hitboxes")
