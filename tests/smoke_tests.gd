extends "res://tests/support/suite_runner.gd"

## Entry point completo: esegue gli stessi casi delle cinque suite indipendenti.


func _run() -> void:
	print("=== SANMO HEADLESS SMOKE TESTS ===")
	for suite_name in SuiteCatalog.SUITES:
		await run_cases(suite_name, SuiteCatalog.SUITES[suite_name])
	_finish_suite("SMOKE")
