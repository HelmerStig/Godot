extends "res://tests/support/suite_runner.gd"

func _run() -> void:
	await run_cases("menu_navigation",["res://tests/cases/menu_navigation.gd","res://tests/cases/loading_screen.gd"])
	_finish_suite("menu_navigation")
