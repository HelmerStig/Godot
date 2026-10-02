extends "res://tests/support/suite_runner.gd"


func _run() -> void:
	await run_cases("loading", ["res://tests/cases/loading_screen.gd"])
	_finish_suite("loading")
