extends RefCounted

## Unica lista dei casi, condivisa dagli entry point singoli e dalla suite completa.
const SUITES := {
	"input": ["res://tests/cases/input_buffer.gd"],
	"arianna": [
		"res://tests/cases/arianna_moveset.gd",
		"res://tests/cases/arianna_lifecycle.gd",
	],
	"mangler": ["res://tests/cases/mangler_moveset.gd"],
	"combat": [
		"res://tests/cases/attack_data.gd",
		"res://tests/cases/guard_heights.gd",
		"res://tests/cases/crouched_heavy_launch.gd",
	],
	"arena": ["res://tests/cases/arena_contract.gd"],
}
