extends "res://tests/support/suite_runner.gd"


func _run() -> void:
	await run_cases("oscare_smoke", ["res://tests/cases/oscare_smoke_special.gd"])
	_finish_suite("oscare_smoke")
