extends "res://tests/support/suite_runner.gd"

func _run() -> void:
	await run_cases("torpe_beer", ["res://tests/cases/torpe_beer_special.gd"])
	_finish_suite("torpe_beer")
