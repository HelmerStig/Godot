extends "res://tests/support/suite_runner.gd"

func _run() -> void:
	await run_cases("jump_light_punch", ["res://tests/cases/roster_jump_light_punch.gd"])
	_finish_suite("jump_light_punch")
