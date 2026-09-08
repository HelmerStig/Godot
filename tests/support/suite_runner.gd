extends SceneTree

const SuiteCatalog := preload("res://tests/suite_catalog.gd")

var failures := 0
var passes := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	push_error("Usare un entry point tests/test_*.gd oppure tests/smoke_tests.gd")
	quit(1)


func run_named_suite(suite_name: String) -> void:
	print("=== SANMO %s TESTS ===" % suite_name.to_upper())
	await run_cases(suite_name, SuiteCatalog.SUITES[suite_name])
	_finish_suite(suite_name)


func run_cases(suite_name: String, case_paths: Array) -> void:
	var passes_before := passes
	var failures_before := failures
	for case_path in case_paths:
		_reset_test_environment()
		var scenario := load(case_path) as GDScript
		if scenario == null or not scenario.can_instantiate() or not scenario.has_method("run"):
			_expect(false, "Scenario non caricabile: " + str(case_path))
			continue
		var completed: Variant = await scenario.run(self, _expect)
		if completed != true:
			_expect(false, "Scenario interrotto prima del completamento: " + str(case_path))
		_reset_test_environment()
	print("SUITE_RESULT: %s passed=%d failed=%d" % [suite_name.to_upper(), passes - passes_before, failures - failures_before])


func _finish_suite(suite_name: String) -> void:
	_reset_test_environment()
	print("TEST_TOTAL: passed=%d failed=%d" % [passes, failures])
	if failures == 0:
		print("%s_TESTS_OK" % suite_name.to_upper())
		quit(0)
	else:
		push_error("%s_TESTS_FAILED: %d assertion(s)" % [suite_name.to_upper(), failures])
		quit(1)


func _expect(condition: bool, description: String) -> void:
	if condition:
		passes += 1
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)


func _reset_test_environment() -> void:
	Engine.time_scale = 1.0
	for action in InputMap.get_actions():
		Input.action_release(action)
