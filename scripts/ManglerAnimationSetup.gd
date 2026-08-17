extends RefCounted
class_name ManglerAnimationSetup

## Registra in un solo punto tutte le animazioni runtime di Mangler.
## Le funzioni di slicing restano temporaneamente compatibili sul fighter e verranno
## migrate qui per gruppi senza alterare gli atlas esistenti.


static func configure_all(fighter: Mangler) -> void:
	fighter.configure_idle_frames()
	fighter.configure_walk_frames()
	fighter.configure_backwalk_frames()
	fighter.configure_run_frames()
	fighter.configure_heavy_punch_high_frames()
	fighter.configure_crouched_heavy_punch_frames()
	fighter.configure_light_punch_frames()
	fighter.configure_crouched_light_punch_frames()
	fighter.configure_crouched_light_punch_crouched_frames()
	fighter.configure_crouch_frames()
	fighter.configure_block_high_frames()
	fighter.configure_block_mid_frames()
	fighter.configure_block_low_frames()
	fighter.configure_crouched_heavy_kick_frames()
	fighter.configure_sweep_knockdown_frames()
	fighter.configure_standing_heavy_kick_frames()
	fighter.configure_crouched_medium_kick_frames()
	fighter.configure_standing_medium_kick_frames()
	fighter.configure_crouched_light_kick_frames()
	fighter.configure_standing_light_kick_frames()
	fighter.configure_jump_light_kick_frames()
	fighter.configure_jump_light_punch_frames()
	fighter.configure_jump_medium_kick_frames()
	fighter.configure_jump_heavy_kick_frames()
	fighter.configure_medium_punch_frames()
	fighter.configure_crouched_medium_punch_frames()
	fighter.configure_crouched_medium_punch_crouched_frames()
	fighter.configure_jump_medium_punch_frames()
	fighter.configure_jump_heavy_punch_frames()
	fighter.configure_special_720_punch_frames()
	fighter.configure_special_sonic_boom_frames()
	fighter.configure_grab_tentative_frames()
	fighter.configure_grab_headbow_combined_frames()
	fighter.configure_grab_headbutt_frames()
	fighter.configure_grabbed_frames()
	fighter.configure_hurted_in_jump_frames()
