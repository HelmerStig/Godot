extends "res://tests/support/suite_runner.gd"

func _run() -> void:
	await run_cases("torpe_welding", ["res://tests/cases/torpe_welding_special.gd"])
	_finish_suite("torpe_welding")
