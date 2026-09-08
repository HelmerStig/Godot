extends "res://tests/support/suite_runner.gd"


func _run() -> void:
	await run_named_suite("arianna")
