extends RefCounted
class_name ManglerVisualConfig

## Unica fonte dei profili degli effetti visivi delle animazioni di Mangler.

const PROFILES := {
	&"grab_headbutt": {
		"start_ratio": 0.42, "end_ratio": 0.75, "tint": Color(1.0, 0.78, 0.52),
		"alpha": 0.32, "lifetime": 0.17, "offset": 11.0, "stretch": 1.07,
	},
	&"special_sonic_boom": {
		"start_ratio": 0.16, "end_ratio": 0.72, "tint": Color(1.0, 0.82, 0.24),
		"alpha": 0.38, "lifetime": 0.20, "offset": 14.0, "stretch": 1.08,
	},
	&"special_720_punch": {
		"start_ratio": 0.24, "end_ratio": 0.80, "tint": Color(1.0, 0.58, 0.26),
		"alpha": 0.33, "lifetime": 0.18, "offset": 11.0, "stretch": 1.065,
	},
	&"super_rotate_run": {
		"start_ratio": 0.72, "end_ratio": 1.0, "tint": Color(1.0, 0.78, 0.22),
		"alpha": 0.30, "lifetime": 0.14, "offset": 13.0, "stretch": 1.07,
	},
	&"super_run_only": {
		"start_ratio": 0.0, "end_ratio": 1.0, "tint": Color(1.0, 0.72, 0.16),
		"alpha": 0.32, "lifetime": 0.15, "offset": 15.0, "stretch": 1.08,
	},
	&"crouched_heavy_kick": {
		"start_ratio": 0.12, "end_ratio": 0.63, "tint": Color(0.82, 0.9, 1.0),
		"alpha": 0.28, "lifetime": 0.14, "offset": 8.0, "stretch": 1.04,
	},
	&"jump_heavy_punch": {
		"start_ratio": 0.10, "end_ratio": 0.90, "tint": Color(1.0, 0.72, 0.35),
		"alpha": 0.40, "lifetime": 0.22, "offset": 14.0, "stretch": 1.12,
	},
}

const AIRBORNE := [
	&"jump_light_punch", &"jump_light_kick", &"jump_medium_kick", &"jump_heavy_kick",
	&"jump_medium_punch",
]
const HEAVY := [&"heavy_punch", &"crouched_power_punch", &"heavy_kick"]
const MEDIUM := [
	&"medium_open_hand_slap", &"crouched_medium_punch", &"crouched_medium_punch_crouched",
	&"light_kick", &"medium_kick", &"crouched_medium_kick",
]
const LIGHT := [
	&"light_punch_single", &"light_punch_double", &"crouched_punch",
	&"crouched_punch_crouched", &"crouched_light_kick",
]


static func get_motion_profile(animation_name: StringName) -> Dictionary:
	if PROFILES.has(animation_name):
		return PROFILES[animation_name]
	if animation_name in AIRBORNE:
		return _profile(0.18, 0.78, Color(0.72, 0.88, 1.0), 0.24, 0.13, 7.0, 1.03)
	if animation_name in HEAVY:
		return _profile(0.28, 0.78, Color(1.0, 0.78, 0.55), 0.3, 0.16, 10.0, 1.06)
	if animation_name in MEDIUM:
		return _profile(0.24, 0.72, Color(0.86, 0.92, 1.0), 0.22, 0.12, 6.0, 1.025)
	if animation_name in LIGHT:
		return _profile(0.2, 0.62, Color.WHITE, 0.16, 0.09, 4.0, 1.01)
	return {}


static func _profile(
	start_ratio: float, end_ratio: float, tint: Color, alpha: float,
	lifetime: float, offset: float, stretch: float
) -> Dictionary:
	return {
		"start_ratio": start_ratio, "end_ratio": end_ratio, "tint": tint,
		"alpha": alpha, "lifetime": lifetime, "offset": offset, "stretch": stretch,
	}
