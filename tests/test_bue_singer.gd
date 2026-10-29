extends "res://tests/support/suite_runner.gd"
func _run() -> void:
	await run_cases("bue_singer",["res://tests/cases/bue_singer_special.gd"])
	_finish_suite("bue_singer")
