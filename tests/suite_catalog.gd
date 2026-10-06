extends RefCounted

## Unica lista dei casi, condivisa dagli entry point singoli e dalla suite completa.
const SUITES := {
	"input": ["res://tests/cases/input_buffer.gd"],
	"arianna": [
		"res://tests/cases/arianna_light_punch_audio.gd",
		"res://tests/cases/arianna_moveset.gd",
		"res://tests/cases/arianna_lifecycle.gd",
	],
	"mangler": ["res://tests/cases/mangler_moveset.gd"],
	"combat": [
		"res://tests/cases/roster_crouched_guard.gd",
		"res://tests/cases/crouched_block_collision.gd",
		"res://tests/cases/airborne_hit.gd",
		"res://tests/cases/roster_knockdown.gd",
		"res://tests/cases/attack_data.gd",
		"res://tests/cases/guard_heights.gd",
		"res://tests/cases/crouched_heavy_launch.gd",
		"res://tests/cases/hurt_crouched.gd",
		"res://tests/cases/roster_block_medium.gd",
	],
	"arena": [
		"res://tests/cases/roster_strong_punch.gd",
		"res://tests/cases/roster_medium_punch.gd",
		"res://tests/cases/roster_light_punch.gd",
		"res://tests/cases/roster_run.gd",
		"res://tests/cases/roster_death.gd",
		"res://tests/cases/loading_screen.gd",
		"res://tests/cases/arena_contract.gd",
		"res://tests/cases/idle_roster_fighters.gd",
		"res://tests/cases/roster_hurt_low.gd",
		"res://tests/cases/roster_back_jump.gd",
	],
}
