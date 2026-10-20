extends "res://tests/support/suite_runner.gd"

func _run() -> void:
	await run_cases("jump_response",["res://tests/cases/jump_response.gd"])
	_finish_suite("jump_response")
