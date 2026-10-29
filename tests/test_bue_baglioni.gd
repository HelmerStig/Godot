extends "res://tests/support/suite_runner.gd"

func _run() -> void:
	await run_cases("bue_baglioni",["res://tests/cases/bue_baglioni_special.gd"])
	_finish_suite("bue_baglioni")
