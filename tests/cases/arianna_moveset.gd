extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	print("-- Arianna idle")
	var arianna_scene := load("res://scenes/Arianna.tscn") as PackedScene
	var arianna := arianna_scene.instantiate() as Arianna
	arianna.set_physics_process(false)
	tree.root.add_child(arianna)
	await tree.process_frame
	expect.call(
		arianna is Fighter
		and arianna.get_script().get_base_script() == load("res://scripts/Fighter.gd")
		and not arianna.has_node("GrabFrontSprite")
		and not arianna.has_node("GrabBox")
		and not arianna.has_node("GrabHeadbuttHitbox"),
		"Arianna eredita direttamente da Fighter e non contiene nodi specifici di Mangler"
	)
	var frames := arianna.animated_sprite.sprite_frames
	var last_frame := frames.get_frame_texture(&"idle", 23) as AtlasTexture
	expect.call(frames.get_frame_count(&"idle") == 24, "Arianna idle usa esattamente 24 frame")
	expect.call(
		is_equal_approx(frames.get_animation_speed(&"idle"), 24.0),
		"Arianna idle è configurato a 24 FPS"
	)
	expect.call(frames.get_animation_loop(&"idle"), "Arianna idle è configurato in loop")
	expect.call(
		arianna.animated_sprite.is_playing()
		and arianna.animated_sprite.animation == &"idle",
		"Arianna avvia automaticamente idle"
	)
	expect.call(
		last_frame != null
		and last_frame.atlas == Arianna.ARIANNA_IDLE_SHEET
		and last_frame.region == Rect2(1024.0, 1536.0, 512.0, 512.0),
		"Arianna usa i primi 24 riquadri della griglia 7x4"
	)
	expect.call(
		arianna.animated_sprite.scale == Arianna.ARIANNA_SPRITE_SCALE
		and arianna.animated_sprite.position == Arianna.ARIANNA_SPRITE_POSITION,
		"Arianna idle mantiene scala e linea dei piedi configurate"
	)
	var walk_frames := arianna.animated_sprite.sprite_frames
	var walk_last_frame := walk_frames.get_frame_texture(&"walk", 47) as AtlasTexture
	expect.call(
		walk_frames.get_frame_count(&"walk") == 48
		and is_equal_approx(walk_frames.get_animation_speed(&"walk"), 24.0)
		and walk_frames.get_animation_loop(&"walk")
		and walk_last_frame != null
		and walk_last_frame.atlas == Arianna.ARIANNA_WALK_SHEET
		and walk_last_frame.region == Rect2(2560.0, 3072.0, 512.0, 512.0),
		"Arianna walk usa 48 frame a 24 FPS in loop"
	)
	var backwalk_first_frame := walk_frames.get_frame_texture(&"backwalk", 0) as AtlasTexture
	var backwalk_last_frame := walk_frames.get_frame_texture(&"backwalk", 47) as AtlasTexture
	expect.call(
		walk_frames.get_frame_count(&"backwalk") == 48
		and is_equal_approx(walk_frames.get_animation_speed(&"backwalk"), 24.0)
		and walk_frames.get_animation_loop(&"backwalk")
		and backwalk_first_frame.region == walk_last_frame.region
		and backwalk_last_frame.region == Rect2(0.0, 0.0, 512.0, 512.0),
		"Arianna backwalk riusa i 48 frame di 01-walk in ordine inverso"
	)
	var run_first_frame := frames.get_frame_texture(&"run", 0) as AtlasTexture
	var run_last_frame := frames.get_frame_texture(&"run", 47) as AtlasTexture
	expect.call(
		frames.get_frame_count(&"run") == 48
		and is_equal_approx(frames.get_animation_speed(&"run"), 24.0)
		and frames.get_animation_loop(&"run")
		and run_first_frame.atlas == Arianna.ARIANNA_RUN_SHEET
		and run_first_frame.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and run_last_frame.region == Rect2(2560.0, 3072.0, 512.0, 512.0),
		"Arianna run usa i primi 48 frame della griglia 7x7 in loop a 24 FPS"
	)
	var back_jump_first := frames.get_frame_texture(&"arianna_back_jump", 0) as AtlasTexture
	var back_jump_peak := frames.get_frame_texture(&"arianna_back_jump", 11) as AtlasTexture
	var back_jump_last := frames.get_frame_texture(&"arianna_back_jump", 21) as AtlasTexture
	expect.call(
		frames.get_frame_count(&"arianna_back_jump") == 22
		and is_equal_approx(frames.get_animation_speed(&"arianna_back_jump"), 48.0)
		and not frames.get_animation_loop(&"arianna_back_jump")
		and back_jump_first.atlas == Arianna.ARIANNA_BACK_JUMP_SHEET
		and back_jump_first.region == Rect2(3072.0, 1536.0, 512.0, 512.0)
		and back_jump_peak.region == Rect2(1536.0, 2560.0, 512.0, 512.0)
		and back_jump_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0),
		"Arianna back jump usa i frame sorgente 28-49 di back-jump.png a 48 FPS"
	)
	var crouch_first := frames.get_frame_texture(&"crouch", 0) as AtlasTexture
	var crouch_last := frames.get_frame_texture(&"crouch", 18) as AtlasTexture
	var crouch_recovery_first := (
		frames.get_frame_texture(&"arianna_crouch_recovery", 0) as AtlasTexture
	)
	var crouch_recovery_last := (
		frames.get_frame_texture(&"arianna_crouch_recovery", 17) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"crouch") == 19
		and frames.get_frame_count(&"arianna_crouch_recovery") == 18
		and is_equal_approx(frames.get_animation_speed(&"crouch"), 48.0)
		and is_equal_approx(frames.get_animation_speed(&"arianna_crouch_recovery"), 48.0)
		and not frames.get_animation_loop(&"crouch")
		and not frames.get_animation_loop(&"arianna_crouch_recovery")
		and crouch_first.atlas == Arianna.ARIANNA_CROUCH_SHEET
		and crouch_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and crouch_last.region == Rect2(1536.0, 1536.0, 512.0, 512.0)
		and crouch_recovery_first.region == Rect2(1024.0, 1536.0, 512.0, 512.0)
		and crouch_recovery_last.region == crouch_first.region,
		"Arianna crouch usa 1-19 e recovery 18-1 a 48 FPS"
	)
	var guard_high_first := frames.get_frame_texture(&"block_high", 0) as AtlasTexture
	var guard_high_last := frames.get_frame_texture(&"block_high", 15) as AtlasTexture
	var guard_high_recovery_first := (
		frames.get_frame_texture(&"block_high_recovery", 0) as AtlasTexture
	)
	var guard_high_recovery_last := (
		frames.get_frame_texture(&"block_high_recovery", 14) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"block_high") == 16
		and frames.get_frame_count(&"block_high_recovery") == 15
		and is_equal_approx(frames.get_animation_speed(&"block_high"), 48.0)
		and is_equal_approx(frames.get_animation_speed(&"block_high_recovery"), 48.0)
		and not frames.get_animation_loop(&"block_high")
		and not frames.get_animation_loop(&"block_high_recovery")
		and guard_high_first.atlas == Arianna.ARIANNA_GUARD_HIGH_SHEET
		and guard_high_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and guard_high_last.region == Rect2(1536.0, 1536.0, 512.0, 512.0)
		and guard_high_recovery_first.region == Rect2(1024.0, 1536.0, 512.0, 512.0)
		and guard_high_recovery_last.region == guard_high_first.region,
		"Arianna guardia alta usa 1-16 e recovery 15-1 a 48 FPS"
	)
	var guard_middle_first := frames.get_frame_texture(&"block_mid", 0) as AtlasTexture
	var guard_middle_last := frames.get_frame_texture(&"block_mid", 12) as AtlasTexture
	var guard_middle_recovery_first := (
		frames.get_frame_texture(&"block_mid_recovery", 0) as AtlasTexture
	)
	var guard_middle_recovery_last := (
		frames.get_frame_texture(&"block_mid_recovery", 11) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"block_mid") == 13
		and frames.get_frame_count(&"block_mid_recovery") == 12
		and is_equal_approx(frames.get_animation_speed(&"block_mid"), 48.0)
		and is_equal_approx(frames.get_animation_speed(&"block_mid_recovery"), 48.0)
		and not frames.get_animation_loop(&"block_mid")
		and not frames.get_animation_loop(&"block_mid_recovery")
		and guard_middle_first.atlas == Arianna.ARIANNA_GUARD_MIDDLE_SHEET
		and guard_middle_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and guard_middle_last.region == Rect2(0.0, 1536.0, 512.0, 512.0)
		and guard_middle_recovery_first.region == Rect2(1536.0, 1024.0, 512.0, 512.0)
		and guard_middle_recovery_last.region == guard_middle_first.region,
		"Arianna guardia media usa 1-13 e recovery 12-1 a 48 FPS"
	)
	var guard_low_first := frames.get_frame_texture(&"block_low_crouched", 0) as AtlasTexture
	var guard_low_last := frames.get_frame_texture(&"block_low_crouched", 15) as AtlasTexture
	var guard_low_recovery_first := (
		frames.get_frame_texture(&"block_low_recovery", 0) as AtlasTexture
	)
	var guard_low_recovery_last := (
		frames.get_frame_texture(&"block_low_recovery", 14) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"block_low") == 16
		and frames.get_frame_count(&"block_low_crouched") == 16
		and frames.get_frame_count(&"block_low_recovery") == 15
		and is_equal_approx(frames.get_animation_speed(&"block_low_crouched"), 48.0)
		and is_equal_approx(frames.get_animation_speed(&"block_low_recovery"), 48.0)
		and not frames.get_animation_loop(&"block_low_crouched")
		and not frames.get_animation_loop(&"block_low_recovery")
		and guard_low_first.atlas == Arianna.ARIANNA_GUARD_LOW_SHEET
		and guard_low_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and guard_low_last.region == Rect2(1536.0, 1536.0, 512.0, 512.0)
		and guard_low_recovery_first.region == Rect2(1024.0, 1536.0, 512.0, 512.0)
		and guard_low_recovery_last.region == guard_low_first.region,
		"Arianna guardia bassa usa 1-16 e recovery 15-1 a 48 FPS"
	)
	var light_punch_first := frames.get_frame_texture(&"arianna_light_punch", 0) as AtlasTexture
	var light_punch_last := frames.get_frame_texture(&"arianna_light_punch", 8) as AtlasTexture
	var light_punch_recovery_first := (
		frames.get_frame_texture(&"arianna_light_punch_recovery", 0) as AtlasTexture
	)
	var light_punch_recovery_last := (
		frames.get_frame_texture(&"arianna_light_punch_recovery", 8) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_light_punch") == 9
		and frames.get_frame_count(&"arianna_light_punch_recovery") == 9
		and is_equal_approx(frames.get_animation_speed(&"arianna_light_punch"), 48.0)
		and is_equal_approx(frames.get_animation_speed(&"arianna_light_punch_recovery"), 48.0)
		and not frames.get_animation_loop(&"arianna_light_punch")
		and not frames.get_animation_loop(&"arianna_light_punch_recovery")
		and light_punch_first.atlas == Arianna.ARIANNA_LIGHT_PUNCH_SHEET
		and light_punch_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and light_punch_last.region == Rect2(512.0, 512.0, 512.0, 512.0)
		and light_punch_recovery_first.region == light_punch_last.region
		and light_punch_recovery_last.region == light_punch_first.region,
		"Arianna light punch esegue 1-9 e 9-1 a 48 FPS"
	)
	var combo_lp_last := frames.get_frame_texture(&"arianna_combo_lp", 7) as AtlasTexture
	var combo_lp_recovery_last := (
		frames.get_frame_texture(&"arianna_combo_lp_recovery", 2) as AtlasTexture
	)
	var combo_mp_first := frames.get_frame_texture(&"arianna_combo_mp", 0) as AtlasTexture
	var combo_mp_last := frames.get_frame_texture(&"arianna_combo_mp", 7) as AtlasTexture
	var combo_mp_recovery_last := (
		frames.get_frame_texture(&"arianna_combo_mp_recovery", 6) as AtlasTexture
	)
	var combo_mk_first := frames.get_frame_texture(&"arianna_combo_mk", 0) as AtlasTexture
	var combo_mk_last := frames.get_frame_texture(&"arianna_combo_mk", 13) as AtlasTexture
	var combo_mk_recovery_last := (
		frames.get_frame_texture(&"arianna_combo_mk_recovery", 27) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_combo_lp") == 8
		and frames.get_frame_count(&"arianna_combo_lp_recovery") == 3
		and frames.get_frame_count(&"arianna_combo_mp") == 8
		and frames.get_frame_count(&"arianna_combo_mp_recovery") == 7
		and frames.get_frame_count(&"arianna_combo_mk") == 14
		and frames.get_frame_count(&"arianna_combo_mk_recovery") == 28
		and combo_lp_last.region == Rect2(0.0, 512.0, 512.0, 512.0)
		and combo_lp_recovery_last.region == Rect2(2048.0, 0.0, 512.0, 512.0)
		and combo_mp_first.region == Rect2(1024.0, 1536.0, 512.0, 512.0)
		and combo_mp_last.region == Rect2(2048.0, 2048.0, 512.0, 512.0)
		and combo_mp_recovery_last.region == combo_mp_first.region
		and combo_mk_first.region == Rect2(512.0, 1024.0, 512.0, 512.0)
		and combo_mk_last.region == Rect2(0.0, 2048.0, 512.0, 512.0)
		and combo_mk_recovery_last.region == Rect2(0.0, 0.0, 512.0, 512.0),
		"la combo usa LP 1-8-5, MP 18-25-18 e MK 16-29-1 a 48 FPS"
	)
	var low_light_first := frames.get_frame_texture(&"arianna_low_light_punch", 0) as AtlasTexture
	var low_light_last := frames.get_frame_texture(&"arianna_low_light_punch", 14) as AtlasTexture
	var low_light_recovery_first := (
		frames.get_frame_texture(&"arianna_low_light_punch_recovery", 0) as AtlasTexture
	)
	var low_light_recovery_last := (
		frames.get_frame_texture(&"arianna_low_light_punch_recovery", 13) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_low_light_punch") == 15
		and frames.get_frame_count(&"arianna_low_light_punch_recovery") == 14
		and is_equal_approx(frames.get_animation_speed(&"arianna_low_light_punch"), 48.0)
		and is_equal_approx(frames.get_animation_speed(&"arianna_low_light_punch_recovery"), 48.0)
		and not frames.get_animation_loop(&"arianna_low_light_punch")
		and low_light_first.atlas == Arianna.ARIANNA_LOW_LIGHT_PUNCH_SHEET
		and low_light_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and low_light_last.region == Rect2(2048.0, 1024.0, 512.0, 512.0)
		and low_light_recovery_first.region == Rect2(1536.0, 1024.0, 512.0, 512.0)
		and low_light_recovery_last.region == low_light_first.region,
		"Arianna light punch basso usa 1-15 e recovery 14-1 a 48 FPS"
	)
	var medium_punch_first := frames.get_frame_texture(&"arianna_medium_punch", 0) as AtlasTexture
	var medium_punch_last := frames.get_frame_texture(&"arianna_medium_punch", 24) as AtlasTexture
	var medium_punch_recovery_first := (
		frames.get_frame_texture(&"arianna_medium_punch_recovery", 0) as AtlasTexture
	)
	var medium_punch_recovery_last := (
		frames.get_frame_texture(&"arianna_medium_punch_recovery", 23) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_medium_punch") == 25
		and frames.get_frame_count(&"arianna_medium_punch_recovery") == 24
		and is_equal_approx(frames.get_animation_speed(&"arianna_medium_punch"), 48.0)
		and is_equal_approx(frames.get_animation_speed(&"arianna_medium_punch_recovery"), 48.0)
		and not frames.get_animation_loop(&"arianna_medium_punch")
		and medium_punch_first.atlas == Arianna.ARIANNA_MEDIUM_PUNCH_SHEET
		and medium_punch_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and medium_punch_last.region == Rect2(2048.0, 2048.0, 512.0, 512.0)
		and medium_punch_recovery_first.region == Rect2(1536.0, 2048.0, 512.0, 512.0)
		and medium_punch_recovery_last.region == medium_punch_first.region,
		"Arianna medium punch usa 1-25 e recovery 24-1 a 48 FPS"
	)
	var low_medium_first := frames.get_frame_texture(&"arianna_low_medium_punch", 0) as AtlasTexture
	var low_medium_last := frames.get_frame_texture(&"arianna_low_medium_punch", 11) as AtlasTexture
	var low_medium_recovery_first := (
		frames.get_frame_texture(&"arianna_low_medium_punch_recovery", 0) as AtlasTexture
	)
	var low_medium_recovery_last := (
		frames.get_frame_texture(&"arianna_low_medium_punch_recovery", 7) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_low_medium_punch") == 12
		and frames.get_frame_count(&"arianna_low_medium_punch_recovery") == 8
		and is_equal_approx(frames.get_animation_speed(&"arianna_low_medium_punch"), 24.0)
		and is_equal_approx(frames.get_animation_speed(&"arianna_low_medium_punch_recovery"), 24.0)
		and not frames.get_animation_loop(&"arianna_low_medium_punch")
		and low_medium_first.atlas == Arianna.ARIANNA_LOW_MEDIUM_PUNCH_SHEET
		and low_medium_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and low_medium_last.region == Rect2(512.0, 1024.0, 512.0, 512.0)
		and low_medium_recovery_first.region == Rect2(0.0, 1024.0, 512.0, 512.0)
		and low_medium_recovery_last.region == Rect2(1536.0, 0.0, 512.0, 512.0)
		and not arianna.get_attack_motion_profile(&"arianna_low_medium_punch").is_empty(),
		"Arianna medium punch basso usa 1-12 e recovery 11-4 a 24 FPS con scia strong"
	)
	var strong_punch_first := frames.get_frame_texture(&"arianna_strong_punch", 0) as AtlasTexture
	var strong_punch_last := frames.get_frame_texture(&"arianna_strong_punch", 48) as AtlasTexture
	expect.call(
		frames.get_frame_count(&"arianna_strong_punch") == 49
		and is_equal_approx(frames.get_animation_speed(&"arianna_strong_punch"), 48.0)
		and not frames.get_animation_loop(&"arianna_strong_punch")
		and strong_punch_first.atlas == Arianna.ARIANNA_STRONG_PUNCH_SHEET
		and strong_punch_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and strong_punch_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0)
		and not arianna.get_attack_motion_profile(&"arianna_strong_punch").is_empty(),
		"Arianna strong punch usa tutti i 49 frame a 48 FPS con effetti strong"
	)
	var crouched_strong_before_skip := (
		frames.get_frame_texture(&"arianna_crouched_strong_punch", 20) as AtlasTexture
	)
	var crouched_strong_after_skip := (
		frames.get_frame_texture(&"arianna_crouched_strong_punch", 21) as AtlasTexture
	)
	var crouched_strong_last := (
		frames.get_frame_texture(&"arianna_crouched_strong_punch", 34) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_crouched_strong_punch") == 35
		and is_equal_approx(frames.get_animation_speed(&"arianna_crouched_strong_punch"), 48.0)
		and not frames.get_animation_loop(&"arianna_crouched_strong_punch")
		and crouched_strong_before_skip.region == Rect2(3072.0, 1024.0, 512.0, 512.0)
		and crouched_strong_after_skip.region == Rect2(0.0, 2560.0, 512.0, 512.0)
		and crouched_strong_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0)
		and crouched_strong_last.atlas == Arianna.ARIANNA_CROUCHED_STRONG_PUNCH_SHEET
		and not arianna.get_attack_motion_profile(&"arianna_crouched_strong_punch").is_empty(),
		"Arianna strong punch basso salta i frame sorgente 22-35 e usa la scia sul doppio pugno"
	)
	var light_kick_first := frames.get_frame_texture(&"arianna_light_kick", 0) as AtlasTexture
	var light_kick_last := frames.get_frame_texture(&"arianna_light_kick", 12) as AtlasTexture
	var light_kick_recovery_first := (
		frames.get_frame_texture(&"arianna_light_kick_recovery", 0) as AtlasTexture
	)
	var light_kick_recovery_last := (
		frames.get_frame_texture(&"arianna_light_kick_recovery", 11) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_light_kick") == 13
		and frames.get_frame_count(&"arianna_light_kick_recovery") == 12
		and is_equal_approx(frames.get_animation_speed(&"arianna_light_kick"), 48.0)
		and is_equal_approx(frames.get_animation_speed(&"arianna_light_kick_recovery"), 48.0)
		and not frames.get_animation_loop(&"arianna_light_kick")
		and not frames.get_animation_loop(&"arianna_light_kick_recovery")
		and light_kick_first.atlas == Arianna.ARIANNA_LIGHT_KICK_SHEET
		and light_kick_first.region == Rect2(0.0, 1024.0, 512.0, 512.0)
		and light_kick_last.region == Rect2(1024.0, 2048.0, 512.0, 512.0)
		and light_kick_recovery_first.region == Rect2(512.0, 2048.0, 512.0, 512.0)
		and light_kick_recovery_last.region == light_kick_first.region,
		"Arianna light kick usa i sorgente 11-23 e recovery 22-11 a 48 FPS"
	)
	var low_light_kick_first := (
		frames.get_frame_texture(&"arianna_low_light_kick", 0) as AtlasTexture
	)
	var low_light_kick_last := (
		frames.get_frame_texture(&"arianna_low_light_kick", 20) as AtlasTexture
	)
	var low_light_kick_recovery_first := (
		frames.get_frame_texture(&"arianna_low_light_kick_recovery", 0) as AtlasTexture
	)
	var low_light_kick_recovery_last := (
		frames.get_frame_texture(&"arianna_low_light_kick_recovery", 19) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_low_light_kick") == 21
		and frames.get_frame_count(&"arianna_low_light_kick_recovery") == 20
		and is_equal_approx(frames.get_animation_speed(&"arianna_low_light_kick"), 60.0)
		and is_equal_approx(frames.get_animation_speed(&"arianna_low_light_kick_recovery"), 60.0)
		and not frames.get_animation_loop(&"arianna_low_light_kick")
		and not frames.get_animation_loop(&"arianna_low_light_kick_recovery")
		and low_light_kick_first.atlas == Arianna.ARIANNA_LOW_LIGHT_KICK_SHEET
		and low_light_kick_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and low_light_kick_last.region == Rect2(3072.0, 1024.0, 512.0, 512.0)
		and low_light_kick_recovery_first.region == Rect2(2560.0, 1024.0, 512.0, 512.0)
		and low_light_kick_recovery_last.region == low_light_kick_first.region,
		"Arianna light kick basso usa 1-21 e recovery 20-1 a 60 FPS"
	)
	var medium_kick_first := frames.get_frame_texture(&"arianna_medium_kick", 0) as AtlasTexture
	var medium_kick_last := frames.get_frame_texture(&"arianna_medium_kick", 20) as AtlasTexture
	var medium_kick_recovery_first := (
		frames.get_frame_texture(&"arianna_medium_kick_recovery", 0) as AtlasTexture
	)
	var medium_kick_recovery_last := (
		frames.get_frame_texture(&"arianna_medium_kick_recovery", 19) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_medium_kick") == 21
		and frames.get_frame_count(&"arianna_medium_kick_recovery") == 20
		and is_equal_approx(frames.get_animation_speed(&"arianna_medium_kick"), 48.0)
		and is_equal_approx(frames.get_animation_speed(&"arianna_medium_kick_recovery"), 48.0)
		and not frames.get_animation_loop(&"arianna_medium_kick")
		and not frames.get_animation_loop(&"arianna_medium_kick_recovery")
		and medium_kick_first.atlas == Arianna.ARIANNA_MEDIUM_KICK_SHEET
		and medium_kick_first.region == Rect2(0.0, 512.0, 512.0, 512.0)
		and medium_kick_last.region == Rect2(3072.0, 1536.0, 512.0, 512.0)
		and medium_kick_recovery_first.region == Rect2(2560.0, 1536.0, 512.0, 512.0)
		and medium_kick_recovery_last.region == medium_kick_first.region,
		"Arianna medium kick usa i sorgente 8-28 e recovery 27-8 a 48 FPS"
	)
	var low_medium_kick_first := frames.get_frame_texture(&"arianna_low_medium_kick", 0) as AtlasTexture
	var low_medium_kick_last := frames.get_frame_texture(&"arianna_low_medium_kick", 13) as AtlasTexture
	var low_medium_kick_recovery_first := frames.get_frame_texture(
		&"arianna_low_medium_kick_recovery", 0
	) as AtlasTexture
	var low_medium_kick_recovery_last := frames.get_frame_texture(
		&"arianna_low_medium_kick_recovery", 12
	) as AtlasTexture
	expect.call(
		frames.get_frame_count(&"arianna_low_medium_kick") == 14
		and frames.get_frame_count(&"arianna_low_medium_kick_recovery") == 13
		and is_equal_approx(frames.get_animation_speed(&"arianna_low_medium_kick"), 48.0)
		and low_medium_kick_first.atlas == Arianna.ARIANNA_LOW_MEDIUM_KICK_SHEET
		and low_medium_kick_first.region == Rect2(0.0, 512.0, 512.0, 512.0)
		and low_medium_kick_last.region == Rect2(3072.0, 1024.0, 512.0, 512.0)
		and low_medium_kick_recovery_first.region == Rect2(2560.0, 1024.0, 512.0, 512.0)
		and low_medium_kick_recovery_last.region == low_medium_kick_first.region,
		"Arianna medium kick basso usa i sorgente 8-21 e recovery 20-8 a 48 FPS"
	)
	expect.call(
		Arianna.ARIANNA_LOW_MEDIUM_KICK_HITBOX_SIZE == Vector2(140.0, 45.0),
		"Arianna medium kick basso usa la hitbox accorciata di 80 px"
	)
	var strong_kick_first := frames.get_frame_texture(&"arianna_strong_kick", 0) as AtlasTexture
	var strong_kick_last := frames.get_frame_texture(&"arianna_strong_kick", 35) as AtlasTexture
	expect.call(
		frames.get_frame_count(&"arianna_strong_kick") == 36
		and is_equal_approx(frames.get_animation_speed(&"arianna_strong_kick"), 32.0)
		and not frames.get_animation_loop(&"arianna_strong_kick")
		and strong_kick_first.atlas == Arianna.ARIANNA_STRONG_KICK_SHEET
		and strong_kick_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and strong_kick_last.region == Rect2(2560.0, 2560.0, 512.0, 512.0),
		"Arianna strong kick usa tutti i 36 fotogrammi a 32 FPS"
	)
	expect.call(
		not arianna.get_attack_motion_profile(&"arianna_strong_kick").is_empty(),
		"Arianna strong kick usa l'effetto movimento delle mosse potenti"
	)
	var low_strong_kick_first := (
		frames.get_frame_texture(&"arianna_low_strong_kick", 0) as AtlasTexture
	)
	var low_strong_kick_last := (
		frames.get_frame_texture(&"arianna_low_strong_kick", 48) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_low_strong_kick") == 49
		and is_equal_approx(frames.get_animation_speed(&"arianna_low_strong_kick"), 48.0)
		and not frames.get_animation_loop(&"arianna_low_strong_kick")
		and low_strong_kick_first.atlas == Arianna.ARIANNA_LOW_STRONG_KICK_SHEET
		and low_strong_kick_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and low_strong_kick_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0),
		"Arianna strong kick basso usa tutti i 49 frame a 48 FPS"
	)
	expect.call(
		not arianna.get_attack_motion_profile(&"arianna_low_strong_kick").is_empty(),
		"Arianna strong kick basso usa l'effetto movimento delle mosse potenti"
	)
	var jump_first := frames.get_frame_texture(&"jump", 0) as AtlasTexture
	var jump_last := frames.get_frame_texture(&"jump", 48) as AtlasTexture
	expect.call(
		frames.get_frame_count(&"jump") == 49
		and is_equal_approx(
			frames.get_animation_speed(&"jump"), Arianna.ARIANNA_JUMP_FPS
		)
		and not frames.get_animation_loop(&"jump")
		and jump_first.atlas == Arianna.ARIANNA_JUMP_SHEET
		and jump_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and jump_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0),
		"Arianna jump usa tutti i 49 frame custom_jump agli FPS dedicati"
	)
	var jump_light_first := frames.get_frame_texture(&"arianna_jump_light_punch", 0) as AtlasTexture
	var jump_light_active := frames.get_frame_texture(&"arianna_jump_light_punch", 5) as AtlasTexture
	var jump_light_hold_end := frames.get_frame_texture(&"arianna_jump_light_punch", 11) as AtlasTexture
	var jump_light_recovery := frames.get_frame_texture(&"arianna_jump_light_punch", 12) as AtlasTexture
	var jump_light_last := frames.get_frame_texture(&"arianna_jump_light_punch", 16) as AtlasTexture
	expect.call(
		frames.get_frame_count(&"arianna_jump_light_punch") == 17
		and is_equal_approx(frames.get_animation_speed(&"arianna_jump_light_punch"), 48.0)
		and not frames.get_animation_loop(&"arianna_jump_light_punch")
		and jump_light_first.region == Rect2(3072.0, 512.0, 512.0, 512.0)
		and jump_light_active.region == Rect2(2048.0, 1024.0, 512.0, 512.0)
		and jump_light_hold_end.region == jump_light_active.region
		and jump_light_recovery.region == Rect2(1536.0, 1024.0, 512.0, 512.0)
		and jump_light_last.region == jump_light_first.region,
		"Arianna jump light punch usa 14-19, mantiene il 19 per 7 frame e torna 18-14 a 48 FPS"
	)
	var jump_medium_first := (
		frames.get_frame_texture(&"arianna_jump_medium_punch", 0) as AtlasTexture
	)
	var jump_medium_last := (
		frames.get_frame_texture(&"arianna_jump_medium_punch", 29) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_jump_medium_punch") == 30
		and is_equal_approx(frames.get_animation_speed(&"arianna_jump_medium_punch"), 48.0)
		and not frames.get_animation_loop(&"arianna_jump_medium_punch")
		and jump_medium_first.atlas == Arianna.ARIANNA_JUMP_MEDIUM_PUNCH_SHEET
		and jump_medium_first.region == Rect2(2048.0, 0.0, 512.0, 512.0)
		and jump_medium_last.region == Rect2(512.0, 512.0, 512.0, 512.0),
		"Arianna jump medium punch usa 5-25 e torna 23-7 saltando un frame a 48 FPS"
	)
	var jump_strong_first := (
		frames.get_frame_texture(&"arianna_jump_strong_punch", 0) as AtlasTexture
	)
	var jump_strong_last := (
		frames.get_frame_texture(&"arianna_jump_strong_punch", 26) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_jump_strong_punch") == 27
		and is_equal_approx(frames.get_animation_speed(&"arianna_jump_strong_punch"), 48.0)
		and not frames.get_animation_loop(&"arianna_jump_strong_punch")
		and jump_strong_first.atlas == Arianna.ARIANNA_JUMP_STRONG_PUNCH_SHEET
		and jump_strong_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and jump_strong_last.region == Rect2(2560.0, 1536.0, 512.0, 512.0),
		"Arianna jump strong punch usa tutti i 27 frame a 48 FPS"
	)
	var jump_light_kick_first := (
		frames.get_frame_texture(&"arianna_jump_light_kick", 0) as AtlasTexture
	)
	var jump_light_kick_impact := (
		frames.get_frame_texture(&"arianna_jump_light_kick", 14) as AtlasTexture
	)
	var jump_light_kick_recovery := (
		frames.get_frame_texture(&"arianna_jump_light_kick", 15) as AtlasTexture
	)
	var jump_light_kick_last := (
		frames.get_frame_texture(&"arianna_jump_light_kick", 28) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_jump_light_kick") == 29
		and is_equal_approx(frames.get_animation_speed(&"arianna_jump_light_kick"), 48.0)
		and not frames.get_animation_loop(&"arianna_jump_light_kick")
		and jump_light_kick_first.atlas == Arianna.ARIANNA_JUMP_LIGHT_KICK_SHEET
		and jump_light_kick_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and jump_light_kick_impact.region == Rect2(0.0, 1024.0, 512.0, 512.0)
		and jump_light_kick_recovery.region == Rect2(3072.0, 512.0, 512.0, 512.0)
		and jump_light_kick_last.region == jump_light_kick_first.region,
		"Arianna jump light kick usa 1-15 e torna 14-1 a 48 FPS"
	)
	var jump_medium_kick_first := (
		frames.get_frame_texture(&"arianna_jump_medium_kick", 0) as AtlasTexture
	)
	var jump_medium_kick_peak := (
		frames.get_frame_texture(&"arianna_jump_medium_kick", 34) as AtlasTexture
	)
	var jump_medium_kick_recovery := (
		frames.get_frame_texture(&"arianna_jump_medium_kick", 35) as AtlasTexture
	)
	var jump_medium_kick_last := (
		frames.get_frame_texture(&"arianna_jump_medium_kick", 47) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_jump_medium_kick") == 48
		and is_equal_approx(frames.get_animation_speed(&"arianna_jump_medium_kick"), 60.0)
		and not frames.get_animation_loop(&"arianna_jump_medium_kick")
		and jump_medium_kick_first.atlas == Arianna.ARIANNA_JUMP_MEDIUM_KICK_SHEET
		and jump_medium_kick_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and jump_medium_kick_peak.region == Rect2(3072.0, 2048.0, 512.0, 512.0)
		and jump_medium_kick_recovery.region == Rect2(2560.0, 2048.0, 512.0, 512.0)
		and jump_medium_kick_last.region == Rect2(0.0, 1536.0, 512.0, 512.0),
		"Arianna jump medium kick usa 1-35 e torna 34-22 a 60 FPS"
	)
	var jump_strong_kick_first := (
		frames.get_frame_texture(&"arianna_jump_strong_kick", 0) as AtlasTexture
	)
	var jump_strong_kick_last := (
		frames.get_frame_texture(&"arianna_jump_strong_kick", 29) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_jump_strong_kick") == 30
		and is_equal_approx(frames.get_animation_speed(&"arianna_jump_strong_kick"), 48.0)
		and not frames.get_animation_loop(&"arianna_jump_strong_kick")
		and jump_strong_kick_first.atlas == Arianna.ARIANNA_JUMP_STRONG_KICK_SHEET
		and jump_strong_kick_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and jump_strong_kick_last.region == Rect2(512.0, 2048.0, 512.0, 512.0),
		"Arianna jump strong kick usa tutti i 30 frame a 48 FPS"
	)
	var baseball_special_first := (
		frames.get_frame_texture(&"arianna_baseball_special", 0) as AtlasTexture
	)
	var baseball_special_last := (
		frames.get_frame_texture(&"arianna_baseball_special", 48) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_baseball_special") == 49
		and is_equal_approx(frames.get_animation_speed(&"arianna_baseball_special"), 48.0)
		and not frames.get_animation_loop(&"arianna_baseball_special")
		and baseball_special_first.atlas == Arianna.ARIANNA_BASEBALL_SPECIAL_SHEET
		and baseball_special_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and baseball_special_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0),
		"la speciale baseball di Arianna usa tutti i 49 frame a 48 FPS"
	)
	var points_forward_first := (
		frames.get_frame_texture(&"arianna_points_forward_super", 0) as AtlasTexture
	)
	var points_forward_last := (
		frames.get_frame_texture(&"arianna_points_forward_super", 33) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_points_forward_super") == 34
		and is_equal_approx(
			frames.get_animation_speed(&"arianna_points_forward_super"), 24.0
		)
		and not frames.get_animation_loop(&"arianna_points_forward_super")
		and points_forward_first.atlas == Arianna.ARIANNA_POINTS_FORWARD_SUPER_SHEET
		and points_forward_first.region == Rect2(1024.0, 512.0, 512.0, 512.0)
		and points_forward_last.region == Rect2(0.0, 3072.0, 512.0, 512.0),
		"points forward usa una sola volta la sequenza 10-43 a 24 FPS"
	)
	var whistle_first := (
		frames.get_frame_texture(&"arianna_whistle_special", 0) as AtlasTexture
	)
	var whistle_peak := (
		frames.get_frame_texture(&"arianna_whistle_special", 24) as AtlasTexture
	)
	var whistle_last := (
		frames.get_frame_texture(&"arianna_whistle_special", 48) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"arianna_whistle_special") == 49
		and is_equal_approx(
			frames.get_animation_speed(&"arianna_whistle_special"), 24.0
		)
		and not frames.get_animation_loop(&"arianna_whistle_special")
		and whistle_first.atlas == Arianna.ARIANNA_WHISTLE_SPECIAL_SHEET
		and whistle_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and whistle_peak.region == Rect2(2048.0, 2048.0, 512.0, 512.0)
		and whistle_last.region == whistle_first.region,
		"la speciale fischio usa la sequenza 1-25-1 di whishtles2.png a 24 FPS"
	)
	var arianna_hurt_mid_first := frames.get_frame_texture(&"hurt_mid", 0) as AtlasTexture
	var arianna_hurt_mid_peak := frames.get_frame_texture(&"hurt_mid", 7) as AtlasTexture
	var arianna_hurt_mid_last := frames.get_frame_texture(&"hurt_mid", 14) as AtlasTexture
	expect.call(
		frames.get_frame_count(&"hurt_mid") == 15
		and is_equal_approx(frames.get_animation_speed(&"hurt_mid"), 48.0)
		and not frames.get_animation_loop(&"hurt_mid")
		and arianna_hurt_mid_first.atlas == Arianna.ARIANNA_HURT_MEDIUM_SHEET
		and arianna_hurt_mid_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and arianna_hurt_mid_peak.region == Rect2(1024.0, 512.0, 512.0, 512.0)
		and arianna_hurt_mid_last.region == arianna_hurt_mid_first.region,
		"hurt_mid di Arianna usa 1-8-1 a 48 FPS"
	)
	var arianna_hurt_high_first := frames.get_frame_texture(&"hurt_high", 0) as AtlasTexture
	var arianna_hurt_high_last := frames.get_frame_texture(&"hurt_high", 6) as AtlasTexture
	var arianna_hurt_high_return := frames.get_frame_texture(&"hurt_high", 7) as AtlasTexture
	var arianna_hurt_low_first := frames.get_frame_texture(&"hurt_low", 0) as AtlasTexture
	var arianna_hurt_low_last := frames.get_frame_texture(&"hurt_low", 5) as AtlasTexture
	var arianna_hurt_low_return := frames.get_frame_texture(&"hurt_low", 6) as AtlasTexture
	expect.call(
		frames.get_frame_count(&"hurt_high") == 8
		and is_equal_approx(frames.get_animation_speed(&"hurt_high"), 24.0)
		and not frames.get_animation_loop(&"hurt_high")
		and arianna_hurt_high_first.atlas == Arianna.ARIANNA_HURT_HIGH_SHEET
		and arianna_hurt_high_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and arianna_hurt_high_last.region == Rect2(512.0, 512.0, 512.0, 512.0)
		and arianna_hurt_high_return.region == arianna_hurt_high_first.region
		and frames.get_frame_count(&"hurt_low") == 7
		and is_equal_approx(frames.get_animation_speed(&"hurt_low"), 24.0)
		and not frames.get_animation_loop(&"hurt_low")
		and arianna_hurt_low_first.atlas == Arianna.ARIANNA_HURT_LOW_SHEET
		and arianna_hurt_low_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and arianna_hurt_low_last.region == Rect2(0.0, 512.0, 512.0, 512.0)
		and arianna_hurt_low_return.region == arianna_hurt_low_first.region,
		"hurt_high e hurt_low usano gli atlas Arianna, tornano al primo e non vanno in loop"
	)
	var arianna_sweep_first := frames.get_frame_texture(&"sweep_knockdown", 0) as AtlasTexture
	var arianna_sweep_last := frames.get_frame_texture(&"sweep_knockdown", 24) as AtlasTexture
	expect.call(
		frames.get_frame_count(&"sweep_knockdown") == 25
		and is_equal_approx(frames.get_animation_speed(&"sweep_knockdown"), 24.0)
		and not frames.get_animation_loop(&"sweep_knockdown")
		and arianna_sweep_first.atlas == Arianna.ARIANNA_SWEEP_KNOCKDOWN_SHEET
		and arianna_sweep_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and arianna_sweep_last.region == Rect2(2048.0, 2048.0, 512.0, 512.0),
		"sweep_knockdown di Arianna usa tutti i 25 frame a 24 FPS"
	)
	var arianna_recovery_first := (
		frames.get_frame_texture(&"knockdown_recovery", 0) as AtlasTexture
	)
	var arianna_recovery_last := (
		frames.get_frame_texture(&"knockdown_recovery", 24) as AtlasTexture
	)
	expect.call(
		frames.get_frame_count(&"knockdown_recovery") == 25
		and is_equal_approx(frames.get_animation_speed(&"knockdown_recovery"), 24.0)
		and not frames.get_animation_loop(&"knockdown_recovery")
		and arianna_recovery_first.atlas == Arianna.ARIANNA_KNOCKDOWN_RECOVERY_SHEET
		and arianna_recovery_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and arianna_recovery_last.region == Rect2(2048.0, 2048.0, 512.0, 512.0),
		"knockdown_recovery di Arianna usa tutti i 25 frame a 24 FPS"
	)
	var arianna_ko_first := frames.get_frame_texture(&"ko", 0) as AtlasTexture
	var arianna_ko_last := frames.get_frame_texture(&"ko", 24) as AtlasTexture
	expect.call(
		frames.get_frame_count(&"ko") == 25
		and is_equal_approx(frames.get_animation_speed(&"ko"), 24.0)
		and not frames.get_animation_loop(&"ko")
		and arianna_ko_first.atlas == Arianna.ARIANNA_KO_SHEET
		and arianna_ko_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and arianna_ko_last.region == Rect2(2048.0, 2048.0, 512.0, 512.0),
		"KO di Arianna usa tutti i 25 frame a 24 FPS"
	)
	var reaction_test_position := arianna.position
	arianna.start_hit_reaction(AttackData.HitHeight.MID, null, 4, true)
	var reduced_mid_pushback := absf(arianna.velocity.x)
	arianna._physics_process(1.0 / 60.0)
	expect.call(
		arianna.current_state == Mangler.State.HIT
		and arianna.animated_sprite.animation == &"hurt_mid"
		and arianna.animated_sprite.frame <= 1
		and is_equal_approx(
			reduced_mid_pushback,
			Mangler.HIT_PUSHBACK_SPEED * Arianna.ARIANNA_HURT_MEDIUM_PUSHBACK_MULTIPLIER
		),
		"Arianna mantiene hurt_mid dal primo frame con rinculo ridotto"
	)
	var medium_hurt_explosion := tree.get_first_node_in_group(
		"hurt_blue_explosion"
	) as Node2D
	expect.call(
		is_instance_valid(medium_hurt_explosion)
		and (medium_hurt_explosion.get_node("BlueSparks") as CPUParticles2D).amount == 64,
		"hurt_medium mantiene l'esplosione azzurra sullo stomaco"
	)
	if is_instance_valid(medium_hurt_explosion):
		medium_hurt_explosion.queue_free()
	await tree.process_frame
	arianna.position = reaction_test_position
	arianna.velocity = Vector2.ZERO
	arianna.change_state(Mangler.State.IDLE)
	arianna.start_hit_reaction(AttackData.HitHeight.LOW, null, 0, false)
	var low_hurt_explosion := tree.get_first_node_in_group(
		"hurt_blue_explosion"
	) as Node2D
	expect.call(
		is_instance_valid(low_hurt_explosion)
		and is_equal_approx(
			low_hurt_explosion.global_position.y,
			arianna.global_position.y + Mangler.HURT_LOW_EFFECT_OFFSET.y
		)
		and (low_hurt_explosion.get_node("BlueSparks") as CPUParticles2D).amount == 64,
		"hurt_low genera un'esplosione azzurra sulle gambe"
	)
	if is_instance_valid(low_hurt_explosion):
		low_hurt_explosion.queue_free()
	expect.call(
		arianna.animated_sprite.animation == &"hurt_low"
		and (arianna.animated_sprite.sprite_frames.get_frame_texture(&"hurt_low", 0) as AtlasTexture).atlas
			== Arianna.ARIANNA_HURT_LOW_SHEET,
		"un colpo LOW mostra il nuovo spritesheet hurt_low di Arianna"
	)
	arianna.combat.hit_reaction(0.0, AttackData.HitHeight.LOW, null, 4, false)
	expect.call(
		arianna.animated_sprite.animation == &"hurt_low"
		and arianna.animated_sprite.frame == 0,
		"hurt_low di Arianna esegue sempre la sequenza completa dal primo frame"
	)
	await tree.create_timer(0.34).timeout
	expect.call(
		arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle",
		"dopo 1-6-1 Arianna torna in idle"
	)
	arianna.start_hit_reaction(AttackData.HitHeight.HIGH, null, 0, false)
	expect.call(
		arianna.animated_sprite.animation == &"hurt_high"
		and (arianna.animated_sprite.sprite_frames.get_frame_texture(&"hurt_high", 0) as AtlasTexture).atlas
			== Arianna.ARIANNA_HURT_HIGH_SHEET,
		"pugni light e medium HIGH mostrano lo spritesheet hurt_high di Arianna"
	)
	arianna.change_state(Mangler.State.IDLE)
	arianna.combat.hit_reaction(0.0, AttackData.HitHeight.HIGH, null, 3, false)
	expect.call(
		arianna.animated_sprite.animation == &"hurt_high"
		and arianna.animated_sprite.frame == 0,
		"hurt_high di Arianna esegue sempre la sequenza completa dal primo frame"
	)
	await tree.create_timer(0.39).timeout
	expect.call(
		arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle",
		"dopo 7-1 Arianna torna in idle"
	)
	var knockdown_transitions: Array[Dictionary] = []
	arianna.state_changed.connect(
		func(_previous_state: int, next_state: int) -> void:
			knockdown_transitions.append({
				&"state": next_state,
				&"animation": arianna.animated_sprite.animation,
			})
	)
	arianna.combat.take_damage(
		1,
		null,
		FighterCombat.DEFAULT_HITSTUN,
		FighterCombat.DEFAULT_BLOCKSTUN,
		AttackData.HitHeight.LOW,
		true
	)
	arianna._physics_process(0.0)
	expect.call(
		arianna.current_state == Mangler.State.SWEEP_KNOCKDOWN
		and arianna.animated_sprite.animation == &"sweep_knockdown"
		and is_zero_approx(arianna.get_sweep_grounded_hold_duration()),
		"un calcio potente basso mantiene lo sweep_knockdown di Arianna nel frame fisico"
	)
	await tree.create_timer(2.4).timeout
	var saw_knockdown_recovery := false
	for transition: Dictionary in knockdown_transitions:
		if (
			transition[&"state"] == Mangler.State.KNOCKDOWN_RECOVERY
			and transition[&"animation"] == &"knockdown_recovery"
		):
			saw_knockdown_recovery = true
			break
	expect.call(
		saw_knockdown_recovery,
		"finito sweep_knockdown Arianna passa subito alla recovery"
	)
	expect.call(
		arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle",
		"completata knockdown_recovery Arianna torna in idle"
	)
	arianna.combat.take_damage(arianna.combat.current_health, null)
	arianna._physics_process(0.0)
	await arianna.animated_sprite.animation_finished
	await tree.process_frame
	expect.call(
		arianna.combat.current_health == 0
		and arianna.current_state == Mangler.State.KNOCKED_DOWN
		and arianna.animated_sprite.animation == &"ko"
		and arianna.animated_sprite.frame == Arianna.ARIANNA_KO_FRAME_COUNT - 1
		and not arianna.animated_sprite.is_playing(),
		"a energia esaurita Arianna completa il KO e mantiene l'ultimo frame"
	)
	arianna.combat.reset()
	arianna.change_state(Mangler.State.IDLE)
	var tornado_preview := AriannaTornadoProjectile.new()
	tornado_preview.setup(arianna, true)
	tree.root.add_child(tornado_preview)
	await tree.process_frame
	var tornado_frames := tornado_preview.tornado_sprite.sprite_frames
	var tornado_first := tornado_frames.get_frame_texture(&"spin", 0) as AtlasTexture
	var tornado_last := tornado_frames.get_frame_texture(&"spin", 48) as AtlasTexture
	expect.call(
		tornado_frames.get_frame_count(&"spin") == 49
		and is_equal_approx(tornado_frames.get_animation_speed(&"spin"), 48.0)
		and tornado_frames.get_animation_loop(&"spin")
		and tornado_first.atlas == AriannaTornadoProjectile.TORNADO_SHEET
		and tornado_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and tornado_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0),
		"il tornado baseball usa tutti i 49 frame in loop a 48 FPS"
	)
	expect.call(
		tornado_preview.tornado_sprite.scale.x >= AriannaTornadoProjectile.START_SCALE.x
		and tornado_preview.tornado_sprite.scale.x <= 0.60
		and is_equal_approx(AriannaTornadoProjectile.GROWTH_DURATION, 0.50)
		and tornado_preview.get_node_or_null("WindGlow") != null
		and (tornado_preview.get_node_or_null("WindTrail") as CPUParticles2D).emitting
		and (tornado_preview.get_node_or_null("BaseDust") as CPUParticles2D).emitting,
		"il tornado cresce rapidamente e usa alone, scia di vento e polvere alla base"
	)
	var tornado_collision := tornado_preview.get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	var tornado_shape := tornado_collision.shape as RectangleShape2D
	expect.call(
		tornado_preview.collision_layer == 2
		and tornado_preview.collision_mask == 4
		and tornado_shape.size == AriannaTornadoProjectile.HITBOX_SIZE
		and AriannaTornadoProjectile.DAMAGE == 10,
		"il tornado usa una hitbox MID e infligge 10 danni al primo contatto"
	)
	var preview_explosion := tornado_preview.spawn_impact_explosion(Vector2.ZERO)
	expect.call(
		preview_explosion.is_in_group("arianna_tornado_impact")
		and preview_explosion.get_node_or_null("BlueFlash") != null
		and (preview_explosion.get_node_or_null("BlueSparks") as CPUParticles2D).amount == 90
		and AriannaTornadoProjectile.IMPACT_OFFSET == Vector2(0.0, -150.0),
		"l'impatto genera 90 scintille azzurre all'altezza della pancia"
	)
	preview_explosion.queue_free()
	tornado_preview.queue_free()
	await tree.process_frame
	var medium_tornado := AriannaTornadoProjectile.new()
	medium_tornado.setup(arianna, true, &"medium")
	var heavy_tornado := AriannaTornadoProjectile.new()
	heavy_tornado.setup(arianna, true, &"heavy")
	expect.call(
		medium_tornado.movement_speed == 560.0
		and medium_tornado.impact_damage == 14
		and is_equal_approx(medium_tornado.effect_intensity, 1.35)
		and medium_tornado.impact_color == AriannaTornadoProjectile.MEDIUM_IMPACT_COLOR
		and medium_tornado.trail_color == AriannaTornadoProjectile.MEDIUM_TRAIL_COLOR
		and heavy_tornado.movement_speed == 700.0
		and heavy_tornado.impact_damage == 18
		and is_equal_approx(heavy_tornado.effect_intensity, 1.70)
		and heavy_tornado.impact_color == AriannaTornadoProjectile.HEAVY_IMPACT_COLOR
		and heavy_tornado.trail_color == AriannaTornadoProjectile.HEAVY_TRAIL_COLOR,
		"medium usa particelle gialle e heavy arancio-rosse con statistiche dedicate"
	)
	medium_tornado.free()
	heavy_tornado.free()
	arianna.start_jump(1.0)
	var jump_prepared := (
		arianna.current_state == Mangler.State.JUMP_STARTUP
		and arianna.animated_sprite.animation == &"jump"
		and arianna.velocity == Vector2.ZERO
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_JUMP_TAKEOFF_FRAME
	arianna._on_animation_frame_changed()
	arianna.update_physical_collision()
	arianna.update_collision_profile()
	var air_collision := arianna.collision_shape.shape as RectangleShape2D
	expect.call(
		jump_prepared
		and arianna.current_state == Mangler.State.JUMPING
		and arianna.velocity.x > 0.0
		and is_equal_approx(arianna.velocity.y, arianna.character_data.jump_velocity)
		and air_collision.size == Arianna.ARIANNA_AIR_COLLISION_SIZE
		and arianna.collision_shape.position == Arianna.ARIANNA_AIR_COLLISION_POSITION
		and is_equal_approx(
			Arianna.ARIANNA_AIR_COLLISION_POSITION.y
				+ Arianna.ARIANNA_AIR_COLLISION_SIZE.y * 0.5,
			Mangler.STANDING_COLLISION_POSITION.y
				+ Mangler.STANDING_COLLISION_SIZE.y * 0.5
		)
		and arianna.collision_layer == 0
		and arianna.collision_mask == Mangler.GROUND_COLLISION_LAYER,
		"Arianna stacca al frame dedicato senza spostare il bordo inferiore della collisione"
	)
	arianna.input_buffer.record_input_snapshot(
		0, 0, [&"light_punch"], arianna.is_facing_right
	)
	arianna._physics_process(0.0)
	expect.call(
		arianna.jump_light_punch_active
		and arianna.current_state == Mangler.State.ATTACKING
		and arianna.animated_sprite.animation == &"arianna_jump_light_punch"
		and arianna.animated_sprite.scale == Arianna.ARIANNA_JUMP_LIGHT_PUNCH_SPRITE_SCALE
		and arianna.input_buffer.consume_attack(&"light_punch")
			== FighterInputBuffer.NO_DIRECTION,
		"il light punch durante il salto avvia la variante aerea dedicata"
	)
	arianna._finish_jump_light_punch(false)
	expect.call(
		arianna.current_state == Mangler.State.JUMPING
		and arianna.animated_sprite.animation == &"jump"
		and arianna.animated_sprite.frame == 31,
		"terminato il light punch aereo Arianna riprende custom_jump dal frame 32"
	)
	arianna.jump_light_punch_active = true
	arianna.current_state = Mangler.State.ATTACKING
	arianna._finish_jump_light_punch(true)
	expect.call(
		arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle"
		and arianna.animated_sprite.scale == Arianna.ARIANNA_SPRITE_SCALE
		and not arianna.jump_light_punch_active,
		"se il light punch aereo termina al suolo Arianna passa direttamente in idle"
	)
	arianna.current_state = Mangler.State.JUMPING
	arianna.aerial_attack_used = false
	arianna._start_jump_medium_punch()
	expect.call(
		arianna.jump_medium_punch_active
		and arianna.current_state == Mangler.State.ATTACKING
		and arianna.animated_sprite.animation == &"arianna_jump_medium_punch"
		and arianna.animated_sprite.scale == Arianna.ARIANNA_JUMP_MEDIUM_PUNCH_SPRITE_SCALE
		and arianna.combat.is_airborne_medium_punch,
		"il medium punch durante il salto avvia la variante aerea dedicata"
	)
	arianna._finish_jump_medium_punch(false)
	expect.call(
		arianna.current_state == Mangler.State.JUMPING
		and arianna.animated_sprite.animation == &"jump"
		and arianna.animated_sprite.frame == 28
		and not arianna.jump_medium_punch_active,
		"terminato il medium punch aereo Arianna riprende custom_jump dal frame 29"
	)
	arianna.current_state = Mangler.State.JUMPING
	arianna.aerial_attack_used = false
	arianna._start_jump_strong_punch()
	expect.call(
		arianna.jump_strong_punch_active
		and arianna.current_state == Mangler.State.ATTACKING
		and arianna.animated_sprite.animation == &"arianna_jump_strong_punch"
		and arianna.animated_sprite.scale == Arianna.ARIANNA_JUMP_STRONG_PUNCH_SPRITE_SCALE
		and arianna.combat.is_airborne_heavy_punch,
		"lo strong punch durante il salto avvia la variante aerea dedicata"
	)
	arianna._finish_jump_strong_punch(false)
	expect.call(
		arianna.current_state == Mangler.State.JUMPING
		and arianna.animated_sprite.animation == &"jump"
		and arianna.animated_sprite.frame == 39
		and arianna.animated_sprite.scale == Arianna.ARIANNA_SPRITE_SCALE
		and not arianna.jump_strong_punch_active,
		"terminato lo strong punch aereo Arianna riprende custom_jump dal frame 40"
	)
	arianna.current_state = Mangler.State.JUMPING
	arianna.aerial_attack_used = false
	arianna._start_jump_light_kick()
	expect.call(
		arianna.jump_light_kick_active
		and arianna.current_state == Mangler.State.ATTACKING
		and arianna.animated_sprite.animation == &"arianna_jump_light_kick"
		and arianna.animated_sprite.scale == Arianna.ARIANNA_JUMP_LIGHT_KICK_SPRITE_SCALE
		and arianna.combat.is_airborne_light_kick
		and arianna.combat.current_variant != null
		and arianna.combat.current_variant.hit_height == AttackData.HitHeight.MID
		and arianna.combat.get_effective_hit_height(arianna.combat.current_attack)
			== AttackData.HitHeight.MID,
		"il light kick durante il salto avvia la variante aerea dedicata"
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_JUMP_LIGHT_KICK_ACTIVE_START_FRAME
	arianna._on_animation_frame_changed()
	expect.call(
		not arianna.combat.hitbox_shape.disabled,
		"la hitbox del light kick aereo è attiva dal fotogramma visibile 9"
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_JUMP_LIGHT_KICK_ACTIVE_END_FRAME
	arianna._on_animation_frame_changed()
	expect.call(
		not arianna.combat.hitbox_shape.disabled,
		"la hitbox del light kick aereo resta attiva fino al fotogramma visibile 15"
	)
	arianna._finish_jump_light_kick(false)
	expect.call(
		arianna.current_state == Mangler.State.JUMPING
		and arianna.animated_sprite.animation == &"jump"
		and arianna.animated_sprite.frame == 39
		and arianna.animated_sprite.scale == Arianna.ARIANNA_SPRITE_SCALE
		and not arianna.jump_light_kick_active,
		"terminato il light kick aereo Arianna riprende custom_jump dal frame 40"
	)
	arianna.current_state = Mangler.State.JUMPING
	arianna.aerial_attack_used = false
	arianna._start_jump_medium_kick()
	expect.call(
		arianna.jump_medium_kick_active
		and arianna.current_state == Mangler.State.ATTACKING
		and arianna.animated_sprite.animation == &"arianna_jump_medium_kick"
		and arianna.animated_sprite.scale == Arianna.ARIANNA_JUMP_MEDIUM_KICK_SPRITE_SCALE
		and arianna.combat.is_airborne_medium_kick
		and arianna.combat.current_variant != null
		and arianna.combat.current_variant.hit_height == AttackData.HitHeight.HIGH
		and arianna.combat.get_effective_hit_height(arianna.combat.current_attack)
			== AttackData.HitHeight.HIGH
		and arianna.combat.hitbox_shape.position
			== Arianna.ARIANNA_JUMP_MEDIUM_KICK_HITBOX_POSITION,
		"il medium kick durante il salto avvia la variante aerea dedicata"
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_JUMP_MEDIUM_KICK_ACTIVE_START_FRAME
	arianna._on_animation_frame_changed()
	expect.call(
		not arianna.combat.hitbox_shape.disabled,
		"la hitbox del medium kick aereo si attiva al fotogramma visibile 28"
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_JUMP_MEDIUM_KICK_ACTIVE_END_FRAME
	arianna._on_animation_frame_changed()
	expect.call(
		not arianna.combat.hitbox_shape.disabled,
		"la hitbox del medium kick aereo resta attiva fino alla fine"
	)
	arianna._finish_jump_medium_kick(false)
	expect.call(
		arianna.current_state == Mangler.State.JUMPING
		and arianna.animated_sprite.animation == &"jump"
		and arianna.animated_sprite.frame == 29
		and arianna.animated_sprite.scale == Arianna.ARIANNA_SPRITE_SCALE
		and not arianna.jump_medium_kick_active,
		"terminato il medium kick aereo Arianna riprende custom_jump dal frame 30"
	)
	arianna.current_state = Mangler.State.JUMPING
	arianna.aerial_attack_used = false
	arianna._start_jump_strong_kick()
	expect.call(
		arianna.jump_strong_kick_active
		and arianna.current_state == Mangler.State.ATTACKING
		and arianna.animated_sprite.animation == &"arianna_jump_strong_kick"
		and arianna.animated_sprite.scale == Arianna.ARIANNA_JUMP_STRONG_KICK_SPRITE_SCALE
		and arianna.combat.is_airborne_heavy_kick
		and arianna.combat.current_variant != null
		and arianna.combat.current_variant.hit_height == AttackData.HitHeight.HIGH,
		"lo strong kick durante il salto avvia la variante aerea dedicata"
	)
	arianna._finish_jump_strong_kick(false)
	expect.call(
		arianna.current_state == Mangler.State.JUMPING
		and arianna.animated_sprite.animation == &"jump"
		and arianna.animated_sprite.frame == 34
		and arianna.animated_sprite.scale == Arianna.ARIANNA_SPRITE_SCALE
		and not arianna.jump_strong_kick_active,
		"terminato lo strong kick aereo Arianna riprende custom_jump dal frame 35"
	)
	arianna.velocity = Vector2.ZERO
	arianna.change_state(Mangler.State.IDLE)
	arianna._start_baseball_special()
	expect.call(
		arianna.baseball_special_active
		and arianna.current_state == Mangler.State.ATTACKING
		and arianna.animated_sprite.animation == &"arianna_baseball_special"
		and arianna.combat.is_attacking
		and arianna.combat.current_attack == null,
		"il quarto di luna con light punch avvia la speciale baseball senza hitbox prematura"
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_BASEBALL_TORNADO_SPAWN_FRAME
	arianna._on_animation_frame_changed()
	await tree.process_frame
	var spawned_tornado := (
		tree.get_first_node_in_group("arianna_baseball_tornado")
		as AriannaTornadoProjectile
	)
	var tornado_count_before_repeat: int = tree.get_nodes_in_group(
		"arianna_baseball_tornado"
	).size()
	arianna._on_animation_frame_changed()
	expect.call(
		is_instance_valid(spawned_tornado)
		and arianna.baseball_tornado_spawned
		and spawned_tornado.travel_direction == (1.0 if arianna.is_facing_right else -1.0)
		and is_equal_approx(
			spawned_tornado.global_position.y,
			arianna.global_position.y + Arianna.ARIANNA_BASEBALL_TORNADO_SPAWN_OFFSET.y
		)
		and tree.get_nodes_in_group("arianna_baseball_tornado").size()
			== tornado_count_before_repeat,
		"al frame d'impatto la speciale genera una sola tromba d'aria dalla mazza"
	)
	if is_instance_valid(spawned_tornado):
		spawned_tornado.queue_free()
	await tree.process_frame
	arianna._finish_baseball_special()
	expect.call(
		arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle"
		and not arianna.baseball_special_active
		and not arianna.combat.is_attacking,
		"la speciale baseball completa l'animazione e torna in idle"
	)
	arianna.input_buffer.clear()
	arianna.input_buffer.record_input_snapshot(0, 1, [], arianna.is_facing_right)
	arianna.input_buffer.record_input_snapshot(1, 1, [&"light_punch"], arianna.is_facing_right)
	var diagonal_baseball_command_started := arianna._try_start_baseball_special()
	expect.call(
		diagonal_baseball_command_started
		and arianna.baseball_special_active
		and arianna.animated_sprite.animation == &"arianna_baseball_special",
		"la speciale baseball accetta light punch sulla diagonale finale"
	)
	arianna._finish_baseball_special()
	arianna.input_buffer.clear()
	arianna.input_buffer.record_input_snapshot(0, 1, [], arianna.is_facing_right)
	arianna.input_buffer.record_input_snapshot(1, 1, [], arianna.is_facing_right)
	arianna.input_buffer.record_input_snapshot(1, 0, [&"light_punch"], arianna.is_facing_right)
	var forward_baseball_command_started := arianna._try_start_baseball_special()
	expect.call(
		forward_baseball_command_started
		and arianna.baseball_special_active
		and arianna.animated_sprite.animation == &"arianna_baseball_special",
		"la speciale baseball accetta il quarto di luna completo con light punch su avanti"
	)
	arianna._finish_baseball_special()
	arianna.input_buffer.clear()
	arianna.input_buffer.record_input_snapshot(0, 1, [], arianna.is_facing_right)
	arianna.input_buffer.record_input_snapshot(1, 1, [], arianna.is_facing_right)
	arianna.input_buffer.record_input_snapshot(1, 0, [&"medium_punch"], arianna.is_facing_right)
	var medium_baseball_command_started := arianna._try_start_baseball_special()
	expect.call(
		medium_baseball_command_started
		and arianna.baseball_special_strength == &"medium",
		"quarto di luna avanti più pugno medio avvia il tornado medio"
	)
	arianna._finish_baseball_special()
	arianna.input_buffer.clear()
	arianna.input_buffer.record_input_snapshot(0, 1, [], arianna.is_facing_right)
	arianna.input_buffer.record_input_snapshot(1, 1, [], arianna.is_facing_right)
	arianna.input_buffer.record_input_snapshot(1, 0, [&"heavy_punch"], arianna.is_facing_right)
	var heavy_baseball_command_started := arianna._try_start_baseball_special()
	expect.call(
		heavy_baseball_command_started
		and arianna.baseball_special_strength == &"heavy",
		"quarto di luna avanti più pugno forte avvia il tornado forte"
	)
	arianna._finish_baseball_special()
	var whistle_target_scene := load("res://scenes/Mangler.tscn") as PackedScene
	var whistle_target := whistle_target_scene.instantiate() as Mangler
	whistle_target.set_physics_process(false)
	tree.root.add_child(whistle_target)
	await tree.process_frame
	arianna.opponent = whistle_target
	whistle_target.opponent = arianna
	whistle_target.controls_enabled = true
	whistle_target.change_state(Mangler.State.WALKING)
	arianna.input_buffer.clear()
	arianna.input_buffer.record_input_snapshot(1, 0, [], true)
	arianna.input_buffer.record_input_snapshot(1, 1, [], true)
	arianna.input_buffer.record_input_snapshot(0, 1, [], true)
	arianna.input_buffer.record_input_snapshot(-1, 1, [], true)
	arianna.input_buffer.record_input_snapshot(
		-1, 0, [&"light_punch", &"medium_punch"], true
	)
	var points_forward_started := arianna._try_start_points_forward_super()
	expect.call(
		points_forward_started
		and arianna.points_forward_super_active
		and arianna.animated_sprite.animation == &"arianna_points_forward_super"
		and whistle_target.current_state == Mangler.State.IDLE
		and not whistle_target.controls_enabled
		and not whistle_target.can_move,
		"mezzaluna indietro più LP+MP avvia points forward e mantiene il rivale in idle"
	)
	var cat_test_target_position := whistle_target.global_position
	whistle_target.global_position.x = 10000.0 if arianna.is_facing_right else -10000.0
	var cat_wave_generation_before := arianna.cat_wave_generation
	arianna.animated_sprite.frame = Arianna.ARIANNA_POINTS_FORWARD_CAT_WAVE_START_FRAME
	arianna._on_animation_frame_changed()
	expect.call(
		arianna.points_forward_cat_wave_started
		and arianna.cat_wave_generation == cat_wave_generation_before + 1
		and Arianna.ARIANNA_POINTS_FORWARD_CAT_WAVE_START_FRAME
			== Arianna.ARIANNA_POINTS_FORWARD_SUPER_FRAME_COUNT - 24,
		"l'ondata dei gatti parte un secondo prima della fine della posa a 24 FPS"
	)
	arianna._finish_points_forward_super()
	var cat_spawn_wait := 0.0
	while cat_spawn_wait < 3.0:
		var spawned_cats := tree.get_nodes_in_group("arianna_tullio_projectile")
		for spawned_cat in spawned_cats:
			if spawned_cat is AriannaTullioProjectile and spawned_cat.source_fighter == arianna:
				spawned_cat.set_physics_process(false)
		var recorded_spawn_count := (
			int(arianna.cat_wave_spawn_counts[&"tullio"])
			+ int(arianna.cat_wave_spawn_counts[&"tilda"])
			+ int(arianna.cat_wave_spawn_counts[&"telma"])
		)
		if recorded_spawn_count >= 12:
			break
		await tree.create_timer(0.05).timeout
		cat_spawn_wait += 0.05
	var tullio_nodes := tree.get_nodes_in_group("arianna_tullio_projectile")
	var cats_by_id := {&"tullio": [], &"tilda": [], &"telma": []}
	for cat_node in tullio_nodes:
		if cat_node is AriannaTullioProjectile and cat_node.source_fighter == arianna:
			cat_node.set_physics_process(false)
			cats_by_id[cat_node.cat_id].append(cat_node)
	whistle_target.global_position = cat_test_target_position
	var tullio: AriannaTullioProjectile = (
		cats_by_id[&"tullio"][0] if not cats_by_id[&"tullio"].is_empty() else null
	)
	expect.call(
		not arianna.points_forward_super_active
		and arianna.current_state == Mangler.State.IDLE
		and not whistle_target.controls_enabled
		and not whistle_target.can_move
		and arianna.cat_wave_spawn_counts[&"tullio"] == 4
		and arianna.cat_wave_spawn_counts[&"tilda"] == 4
		and arianna.cat_wave_spawn_counts[&"telma"] == 4
		and tullio != null,
		"finita points forward entrano dodici gatti: quattro Tullio, Tilda e Telma"
	)
	if tullio != null:
		var cat_profiles_valid := true
		for cat_id in [&"tullio", &"tilda", &"telma"]:
			for cat: AriannaTullioProjectile in cats_by_id[cat_id]:
				var cat_frames := cat.animated_sprite.sprite_frames
				var expected_run_frames := 49 if cat_id == &"telma" else 42
				cat_profiles_valid = cat_profiles_valid and (
					cat_frames.get_frame_count(&"run") == expected_run_frames
					and cat_frames.get_frame_count(&"jump") == 15
					and cat_frames.get_frame_count(&"attack") == 12
					and is_equal_approx(cat_frames.get_animation_speed(&"run"), 24.0)
					and cat.movement_particles != null
					and cat.running_dust != null
					and cat.running_dust.amount == 24
					and is_equal_approx(cat.running_dust.scale_amount_max, 0.42)
					and cat.running_dust.emitting == (cat.animated_sprite.animation == &"run")
					and cat.animated_sprite.scale == Vector2(0.41, 0.41)
				)
		expect.call(
			cat_profiles_valid
			and AriannaTullioProjectile.OFFSCREEN_MARGIN == 85.0,
			"ogni clone mantiene atlas, 24 FPS, scala, scia e polvere di corsa"
		)
		var health_before_tullio := whistle_target.combat.current_health
		tullio.current_state = AriannaTullioProjectile.State.ATTACKING
		for hit_index in range(AriannaTullioProjectile.ATTACK_LOOPS):
			tullio.hit_applied_in_current_loop = false
			tullio._apply_cat_hit()
			expect.call(
				whistle_target.combat.current_health
				== health_before_tullio - AriannaTullioProjectile.DAMAGE_PER_HIT * (hit_index + 1)
				and whistle_target.animated_sprite.animation == &"hurt_low",
				"il colpo %d di Tullio infligge 1 danno e genera hurt_low" % (hit_index + 1)
			)
		expect.call(
			whistle_target.combat.current_health == health_before_tullio - 3,
			"i tre attacchi di ogni gatto infliggono 1 danno ciascuno"
		)
		var health_before_face_jump := whistle_target.combat.current_health
		tullio.current_state = AriannaTullioProjectile.State.APPROACHING
		tullio.uses_face_jump_attack = true
		tullio.global_position.x = (
			whistle_target.global_position.x
			- tullio.travel_direction * (AriannaTullioProjectile.FACE_JUMP_TRIGGER_DISTANCE - 1.0)
		)
		tullio._physics_process(0.0)
		expect.call(
			tullio.current_state == AriannaTullioProjectile.State.FACE_JUMP
			and tullio.animated_sprite.animation == &"jump"
			and is_equal_approx(AriannaTullioProjectile.FACE_JUMP_CHANCE, 0.30),
			"il 30% dei gatti sostituisce attack con il salto al volto"
		)
		var face_jump_start_x := tullio.global_position.x
		tullio._physics_process(0.1)
		var expected_face_jump_distance := (
			tullio.move_speed
			* AriannaTullioProjectile.FACE_JUMP_HORIZONTAL_SPEED_MULTIPLIER
			* 0.1
		)
		tullio.animated_sprite.frame = 3
		tullio._on_frame_changed()
		expect.call(
			tullio.face_jump_particles != null
			and tullio.face_jump_particles.emitting
			and tullio.face_jump_afterimage_spawn_count > 0
			and tullio.get_tree().get_first_node_in_group("arianna_cat_jump_afterimage") != null,
			"il salto al volto lascia una scia azzurra e leggere immagini residue"
		)
		tullio.animated_sprite.frame = AriannaTullioProjectile.FACE_JUMP_HIT_FRAME
		tullio._on_frame_changed()
		var face_jump_kept_moving := is_equal_approx(
			absf(tullio.global_position.x - face_jump_start_x),
			expected_face_jump_distance
		)
		var face_jump_reached_head := is_equal_approx(
			tullio.global_position.y,
			whistle_target.head_hurtbox.global_position.y
				+ AriannaTullioProjectile.FACE_JUMP_FACE_OFFSET_Y
		)
		tullio._on_animation_looped()
		expect.call(
			whistle_target.combat.current_health
				== health_before_face_jump - AriannaTullioProjectile.FACE_JUMP_DAMAGE
			and whistle_target.animated_sprite.animation == &"hurt_high"
			and face_jump_kept_moving
			and face_jump_reached_head
			and is_equal_approx(tullio.global_position.y, tullio.face_jump_ground_y)
			and tullio.current_state == AriannaTullioProjectile.State.EXITING
			and tullio.animated_sprite.animation == &"run",
			"il salto lungo infligge 2 danni high senza fermarsi e prosegue verso l'uscita"
		)
		var all_cats: Array = []
		for cat_id in [&"tullio", &"tilda", &"telma"]:
			all_cats.append_array(cats_by_id[cat_id])
		for cat_index in range(all_cats.size() - 1):
			all_cats[cat_index]._emit_completion()
		expect.call(
			not whistle_target.controls_enabled and not whistle_target.can_move,
			"il rivale resta fermo finche non sono usciti tutti i gatti"
		)
		all_cats.back()._emit_completion()
		expect.call(
			whistle_target.controls_enabled and whistle_target.can_move,
			"l'ultimo gatto libera l'avversario dopo l'uscita"
		)
		for cat in all_cats:
			cat.queue_free()
	whistle_target.combat.reset()
	whistle_target.change_state(Mangler.State.WALKING)
	arianna.input_buffer.clear()
	arianna.input_buffer.record_input_snapshot(-1, 0, [], true)
	arianna.input_buffer.record_input_snapshot(-1, 1, [], true)
	arianna.input_buffer.record_input_snapshot(0, 1, [], true)
	arianna.input_buffer.record_input_snapshot(1, 1, [], true)
	arianna.input_buffer.record_input_snapshot(1, 0, [&"light_kick"], true)
	await tree.physics_frame
	await tree.physics_frame
	await tree.physics_frame
	arianna.input_buffer.record_input_snapshot(1, 0, [&"medium_kick"], true)
	var whistle_command_started := arianna._try_start_whistle_special()
	expect.call(
		whistle_command_started
		and arianna.whistle_special_active
		and arianna.animated_sprite.animation == &"arianna_whistle_special"
		and whistle_target.current_state == Mangler.State.IDLE
		and not whistle_target.controls_enabled
		and not whistle_target.can_move,
		"la mezzaluna tollera 3 frame tra i due calci e mantiene il rivale in idle"
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_WHISTLE_AIR_START_FRAME - 1
	arianna._on_animation_frame_changed()
	var air_was_absent_before_frame_six := (
		arianna.whistle_air_effect == null
		and not arianna.whistle_sound_played
		and not arianna.whistle_audio_player.playing
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_WHISTLE_AIR_START_FRAME
	arianna._on_animation_frame_changed()
	var whistle_air := arianna.whistle_air_effect
	expect.call(
		air_was_absent_before_frame_six
		and is_instance_valid(whistle_air)
		and whistle_air.emitting
		and whistle_air.position == Arianna.ARIANNA_WHISTLE_AIR_MOUTH_OFFSET
		and whistle_air.direction.x > 0.0,
		"dal fotogramma 6 il fischio emette aria dalla bocca verso l'avversario"
	)
	expect.call(
		air_was_absent_before_frame_six
		and arianna.whistle_sound_played
		and arianna.whistle_audio_player.stream == Arianna.ARIANNA_WHISTLE_SOUND
		and arianna.whistle_audio_player.playing,
		"il WAV del fischio parte una sola volta al fotogramma visibile 6"
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_WHISTLE_AIR_END_FRAME
	arianna._on_animation_frame_changed()
	arianna.animated_sprite.frame = Arianna.ARIANNA_WHISTLE_AIR_END_FRAME + 1
	arianna._on_animation_frame_changed()
	expect.call(
		is_instance_valid(whistle_air)
		and not whistle_air.emitting
		and arianna.whistle_air_effect == null,
		"dopo il fotogramma 20 l'aria smette di essere emessa e si dissolve"
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_WHISTLE_SPECIAL_FRAME_COUNT - 1
	arianna._on_animation_finished()
	expect.call(
		not arianna.whistle_special_active
		and arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle"
		and whistle_target.current_state == Mangler.State.IDLE
		and whistle_target.controls_enabled,
		"terminata la sequenza 1-25-1 Arianna e l'avversario vengono rilasciati in idle"
	)
	var bateau := tree.get_first_node_in_group(
		"arianna_bateau_projectile"
	) as AriannaBateauProjectile
	var bateau_frames := bateau.animated_sprite.sprite_frames
	var bateau_run_first := bateau_frames.get_frame_texture(&"run", 0) as AtlasTexture
	var bateau_run_last := bateau_frames.get_frame_texture(&"run", 48) as AtlasTexture
	var bateau_attack_last := bateau_frames.get_frame_texture(&"attack", 24) as AtlasTexture
	var bateau_back_last := bateau_frames.get_frame_texture(&"back_to_run", 24) as AtlasTexture
	expect.call(
		bateau_frames.get_frame_count(&"run") == 49
		and bateau_frames.get_frame_count(&"attack") == 25
		and bateau_frames.get_frame_count(&"back_to_run") == 25
		and is_equal_approx(bateau_frames.get_animation_speed(&"run"), 24.0)
		and is_equal_approx(bateau_frames.get_animation_speed(&"attack"), 24.0)
		and is_equal_approx(bateau_frames.get_animation_speed(&"back_to_run"), 24.0)
		and bateau_frames.get_animation_loop(&"run")
		and not bateau_frames.get_animation_loop(&"attack")
		and not bateau_frames.get_animation_loop(&"back_to_run")
		and bateau_run_first.atlas == AriannaBateauProjectile.RUN_SHEET
		and bateau_run_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0)
		and bateau_attack_last.region == Rect2(2048.0, 2048.0, 512.0, 512.0)
		and bateau_back_last.region == Rect2(2048.0, 2048.0, 512.0, 512.0),
		"Bateau usa run 49, attack 25 e back_to_run 25, tutti a 24 FPS"
	)
	expect.call(
		is_instance_valid(bateau)
		and bateau.current_state == AriannaBateauProjectile.State.RUNNING
		and bateau.global_position.x
			== arianna.stage_left_limit - AriannaBateauProjectile.OFFSCREEN_MARGIN
		and bateau.travel_direction > 0.0
		and bateau.animated_sprite.animation == &"run",
		"dopo il fischio Bateau entra correndo da fuori schermo"
	)
	expect.call(
		bateau.run_audio_player.stream == AriannaBateauProjectile.RUN_SOUND
		and bateau.run_audio_player.playing
		and not bateau.attack_audio_player.playing,
		"all'ingresso di Bateau parte il suono della corsa"
	)
	var health_before_bateau := whistle_target.combat.current_health
	expect.call(
		bateau.get_node_or_null("CollisionShape2D") == null
		and whistle_target.combat.current_health == health_before_bateau,
		"la corsa di Bateau non usa collisioni e non viene influenzata dalle hurtbox"
	)
	expect.call(
		AriannaBateauProjectile.MOVE_SPEED > 520.0
		and bateau.animated_sprite.position == AriannaBateauProjectile.SPRITE_POSITION
		and bateau.get_node_or_null("RunDust") is CPUParticles2D
		and bateau.get_node_or_null("SpeedTrail") is CPUParticles2D
		and bateau.get_node_or_null("BlueMagicTrail") is CPUParticles2D
		and (bateau.get_node("BlueMagicTrail") as CPUParticles2D).texture is GradientTexture2D
		and (bateau.get_node("BlueMagicTrail") as CPUParticles2D).amount == 58
		and (bateau.get_node("BlueMagicTrail") as CPUParticles2D).scale_amount_max < 0.6,
		"Bateau usa velocità, offset, polvere e le due scie configurate"
	)
	bateau.set_physics_process(false)
	bateau.global_position.x = (
		whistle_target.global_position.x
		- AriannaBateauProjectile.ATTACK_TRIGGER_DISTANCE
		+ 1.0
	)
	bateau._physics_process(0.0)
	var bateau_started_attack := (
		bateau.current_state == AriannaBateauProjectile.State.ATTACKING
		and bateau.animated_sprite.animation == &"attack"
	)
	bateau.animated_sprite.frame = AriannaBateauProjectile.ATTACK_SOUND_FRAME
	bateau._on_frame_changed()
	expect.call(
		bateau.run_audio_player.playing
		and bateau.attack_audio_player.stream == AriannaBateauProjectile.ATTACK_SOUND
		and bateau.animated_sprite.frame >= AriannaBateauProjectile.ATTACK_SOUND_FRAME
		and bateau.attack_sound_played
		and bateau.attack_audio_player.playing,
		"abbaio e ringhio si sovrappongono alla corsa al frame parametrizzato"
	)
	bateau.animated_sprite.frame = AriannaBateauProjectile.ATTACK_HIT_FRAME
	bateau._on_frame_changed()
	var bateau_impact := tree.get_first_node_in_group("arianna_bateau_bite_impact")
	var bite_position := bateau.global_position.x
	bateau._move_attack_toward_target(0.1)
	var bateau_bit_target := (
		bateau.has_hit
		and whistle_target.combat.current_health
			== health_before_bateau
			- roundi(float(whistle_target.combat.max_health) * AriannaBateauProjectile.DAMAGE_RATIO)
		and whistle_target.animated_sprite.animation == &"hurt_high"
		and is_instance_valid(bateau_impact)
		and bateau_impact.get_node_or_null("BiteSparks") is CPUParticles2D
		and bateau_impact.get_node_or_null("BiteFlash") is Polygon2D
		and is_equal_approx(
			bateau.global_position.x,
			bite_position + bateau.travel_direction * AriannaBateauProjectile.MOVE_SPEED * 0.1
		)
	)
	bateau._on_animation_finished()
	var bateau_started_back_to_run := (
		bateau.current_state == AriannaBateauProjectile.State.BACK_TO_RUN
		and bateau.animated_sprite.animation == &"back_to_run"
	)
	var back_to_run_start_x := bateau.global_position.x
	bateau._physics_process(0.1)
	var bateau_kept_moving_during_back_to_run := is_equal_approx(
		bateau.global_position.x,
		back_to_run_start_x + bateau.travel_direction * AriannaBateauProjectile.MOVE_SPEED * 0.1
	)
	bateau._on_animation_finished()
	var bateau_resumed_run := (
		bateau.current_state == AriannaBateauProjectile.State.EXITING
		and bateau.animated_sprite.animation == &"run"
	)
	bateau.global_position.x = (
		bateau.visible_right + AriannaBateauProjectile.OFFSCREEN_MARGIN + 1.0
	)
	bateau._physics_process(0.0)
	expect.call(
		bateau_started_attack
		and bateau_bit_target
		and bateau_started_back_to_run
		and bateau_kept_moving_during_back_to_run
		and bateau_resumed_run
		and bateau.is_queued_for_deletion(),
		"dopo il morso Bateau attraversa il rivale e continua a muoversi fino all'uscita"
	)
	var ko_bateau := AriannaBateauProjectile.new()
	ko_bateau.setup(arianna, whistle_target)
	tree.root.add_child(ko_bateau)
	whistle_target.combat.current_health = roundi(
		float(whistle_target.combat.max_health) * AriannaBateauProjectile.DAMAGE_RATIO
	)
	ko_bateau._apply_bite()
	await tree.create_timer(AriannaBateauProjectile.HIT_STOP_DURATION + 0.02).timeout
	expect.call(
		whistle_target.combat.current_health == 0
		and whistle_target.current_state == Fighter.State.KNOCKED_DOWN
		and whistle_target.animated_sprite.animation == &"ko"
		and whistle_target.animated_sprite.is_playing(),
		"un morso letale riprende e completa l'animazione KO dopo l'hit-stop"
	)
	ko_bateau.queue_free()
	whistle_target.combat.reset()
	whistle_target.change_state(Fighter.State.IDLE)
	whistle_target.combat.set_guarding(true)
	whistle_target.controls_enabled = true
	whistle_target.change_state(Mangler.State.BLOCKING)
	arianna.input_buffer.record_input_snapshot(-1, 0, [], true)
	arianna.input_buffer.record_input_snapshot(-1, 1, [], true)
	arianna.input_buffer.record_input_snapshot(0, 1, [], true)
	arianna.input_buffer.record_input_snapshot(1, 1, [], true)
	arianna.input_buffer.record_input_snapshot(
		1, 0, [&"light_kick", &"medium_kick"], true
	)
	var guarded_whistle_started := arianna._try_start_whistle_special()
	expect.call(
		guarded_whistle_started
		and whistle_target.current_state == Mangler.State.BLOCKING
		and whistle_target.combat.is_blocking
		and whistle_target.controls_enabled
		and arianna.whistle_frozen_target == null,
		"la speciale fischio non forza in idle un avversario già in parata"
	)
	arianna._finish_whistle_special()
	whistle_target.combat.set_guarding(false)
	whistle_target.queue_free()
	arianna.opponent = null
	arianna.velocity = Vector2.ZERO
	arianna.change_state(Mangler.State.IDLE)
	arianna.is_facing_right = true
	var forward_right_is_valid := arianna.is_forward_input(1.0)
	var backward_right_is_rejected := not arianna.is_forward_input(-1.0)
	arianna.is_facing_right = false
	expect.call(
		forward_right_is_valid
		and backward_right_is_rejected
		and arianna.is_forward_input(-1.0),
		"Arianna cammina soltanto verso l'avversario in entrambe le direzioni"
	)
	arianna.is_facing_right = true
	arianna.controls_enabled = true
	arianna.can_move = true
	arianna.set_physics_process(true)
	var walk_start_x := arianna.position.x
	var arianna_forward_action := arianna.get_input_action("move_right")
	Input.action_press(arianna_forward_action)
	await tree.physics_frame
	await tree.physics_frame
	var walked_forward := (
		arianna.position.x > walk_start_x
		and arianna.animated_sprite.animation == &"walk"
		and arianna.animated_sprite.is_playing()
	)
	Input.action_release(arianna_forward_action)
	await tree.physics_frame
	expect.call(
		walked_forward and arianna.animated_sprite.animation == &"idle",
		"tenere avanti muove Arianna con walk e il rilascio ripristina idle"
	)
	var backwalk_start_x := arianna.position.x
	var arianna_back_action := arianna.get_input_action("move_left")
	Input.action_press(arianna_back_action)
	await tree.physics_frame
	await tree.physics_frame
	var walked_backward := (
		arianna.position.x < backwalk_start_x
		and arianna.animated_sprite.animation == &"backwalk"
		and arianna.animated_sprite.is_playing()
	)
	Input.action_release(arianna_back_action)
	await tree.physics_frame
	expect.call(
		walked_backward and arianna.animated_sprite.animation == &"idle",
		"tenere indietro muove Arianna con backwalk e mantiene il facing"
	)
	arianna.set_physics_process(false)
	var arianna_default_z := arianna.z_index
	arianna._start_light_punch()
	var light_punch_started := (
		arianna.light_punch_active
		and arianna.current_state == Mangler.State.ATTACKING
		and arianna.animated_sprite.animation == &"arianna_light_punch"
		and is_zero_approx(arianna.velocity.x)
		and arianna.combat.current_attack != null
		and (arianna.combat.hitbox_shape.shape as RectangleShape2D).size
			== Arianna.ARIANNA_LIGHT_PUNCH_HITBOX_SIZE
		and arianna.combat.hitbox_shape.position
			== Arianna.ARIANNA_LIGHT_PUNCH_HITBOX_POSITION
		and arianna.z_index > arianna_default_z
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_LIGHT_PUNCH_ACTIVE_START_FRAME
	arianna._on_animation_frame_changed()
	var light_punch_hitbox_activated := not arianna.combat.hitbox_shape.disabled
	arianna._on_animation_finished()
	var light_punch_hitbox_deactivated := arianna.combat.hitbox_shape.disabled
	var light_punch_reversed := (
		arianna.light_punch_active
		and arianna.animated_sprite.animation == &"arianna_light_punch_recovery"
	)
	arianna._on_animation_finished()
	expect.call(
		light_punch_started
		and light_punch_hitbox_activated
		and light_punch_hitbox_deactivated
		and light_punch_reversed
		and not arianna.light_punch_active
		and arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle",
		"il pugno leggero attiva la hitbox sul braccio, torna indietro e conclude in idle"
	)
	expect.call(
		arianna.z_index == arianna_default_z,
		"Arianna ripristina lo z-index al termine dell'attacco"
	)
	arianna._start_light_punch()
	arianna._on_animation_finished()
	arianna.animated_sprite.frame = Arianna.ARIANNA_LP_MP_COMBO_LP_RECOVERY_INPUT_END_FRAME
	arianna.input_buffer.record_input_snapshot(
		0, 0, [&"medium_punch"], arianna.is_facing_right
	)
	var combo_queued := arianna._try_queue_lp_mp_combo()
	var combo_lp_reversed := (
		arianna.animated_sprite.animation == &"arianna_combo_lp_recovery"
		and arianna.animated_sprite.frame == 2
	)
	arianna._on_animation_finished()
	var combo_mp_started := (
		arianna.medium_punch_active
		and arianna.animated_sprite.animation == &"arianna_combo_mp"
	)
	arianna._on_animation_finished()
	var combo_mp_reversed := arianna.animated_sprite.animation == &"arianna_combo_mp_recovery"
	arianna.animated_sprite.frame = (
		Arianna.ARIANNA_LP_MP_MK_COMBO_MP_RECOVERY_INPUT_END_FRAME
	)
	arianna.input_buffer.record_input_snapshot(
		0, 0, [&"medium_kick"], arianna.is_facing_right
	)
	var combo_mk_queued := arianna._try_queue_lp_mp_mk_combo()
	arianna._on_animation_finished()
	var combo_mk_started := (
		arianna.medium_kick_active
		and arianna.animated_sprite.animation == &"arianna_combo_mk"
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_LP_MP_MK_COMBO_MK_ACTIVE_START_FRAME - 1
	arianna._on_animation_frame_changed()
	var combo_mk_hitbox_delayed := arianna.combat.hitbox_shape.disabled
	arianna.animated_sprite.frame = Arianna.ARIANNA_LP_MP_MK_COMBO_MK_ACTIVE_START_FRAME
	arianna._on_animation_frame_changed()
	combo_mk_hitbox_delayed = combo_mk_hitbox_delayed and not arianna.combat.hitbox_shape.disabled
	arianna._on_animation_finished()
	var combo_mk_reversed := arianna.animated_sprite.animation == &"arianna_combo_mk_recovery"
	arianna._on_animation_finished()
	expect.call(
		combo_queued
		and combo_lp_reversed
		and combo_mp_started
		and combo_mp_reversed
		and combo_mk_queued
		and combo_mk_started
		and combo_mk_hitbox_delayed
		and combo_mk_reversed
		and not arianna.lp_mp_combo_active
		and arianna.current_state == Mangler.State.IDLE,
		"MP e MK restano concatenabili fino ai frame 5 e 18 delle rispettive recovery"
	)
	arianna._start_low_light_punch()
	arianna.animated_sprite.frame = Arianna.ARIANNA_LOW_LIGHT_PUNCH_ACTIVE_START_FRAME
	arianna._on_animation_frame_changed()
	var low_light_shape := arianna.combat.hitbox_shape.shape as RectangleShape2D
	var low_light_configured := (
		arianna.low_light_punch_active
		and arianna.animated_sprite.animation == &"arianna_low_light_punch"
		and not arianna.combat.hitbox_shape.disabled
		and low_light_shape.size == Arianna.ARIANNA_LOW_LIGHT_PUNCH_HITBOX_SIZE
		and arianna.combat.hitbox_shape.position == Arianna.ARIANNA_LOW_LIGHT_PUNCH_HITBOX_POSITION
		and arianna.combat.get_effective_hit_height(arianna.combat.current_attack)
			== AttackData.HitHeight.MID
		and arianna.get_block_animation(AttackData.HitHeight.MID) == &"block_mid"
	)
	arianna._on_animation_finished()
	var low_light_reversed := (
		arianna.animated_sprite.animation == &"arianna_low_light_punch_recovery"
	)
	arianna.input_buffer.record_input_snapshot(0, 1, [], arianna.is_facing_right)
	arianna._on_animation_finished()
	expect.call(
		low_light_configured
		and low_light_reversed
		and not arianna.low_light_punch_active
		and arianna.current_state == Mangler.State.CROUCHING
		and arianna.animated_sprite.animation == &"crouch"
		and arianna.animated_sprite.frame == Arianna.ARIANNA_CROUCH_FRAME_COUNT - 1,
		"il light punch basso è MID e mantenendo giù conclude nella posa crouch"
	)
	arianna.input_buffer.record_input_snapshot(0, 0, [], arianna.is_facing_right)
	arianna.change_state(Mangler.State.IDLE)
	arianna.points_forward_super_active = true
	arianna._on_round_ended(arianna.player_number)
	arianna.reset_fighter(arianna.position)
	expect.call(
		arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle"
		and arianna.can_move
		and not arianna.points_forward_super_active,
		"il reset libera Arianna da victory e dai flag delle mosse ancora attivi"
	)
	arianna.queue_free()
	await tree.process_frame
	var live_arena := (load("res://scenes/MainArena.tscn") as PackedScene).instantiate()
	tree.root.add_child(live_arena)
	await tree.process_frame
	var live_arianna := live_arena.get_node("Player1") as Arianna
	await tree.physics_frame
	await tree.physics_frame
	var live_idle_frame := live_arianna.animated_sprite.sprite_frames.get_frame_texture(
		&"idle", 0
	) as AtlasTexture
	expect.call(
		live_arianna != null
		and live_idle_frame != null
		and live_idle_frame.atlas == Arianna.ARIANNA_IDLE_SHEET,
		"lo stage mostra l'atlante idle di Arianna sul Player 1"
	)
	await tree.physics_frame
	await tree.physics_frame
	live_arianna.controls_enabled = true
	live_arianna.can_move = true
	live_arianna.input_buffer.record_input_snapshot(
		0, 0, [&"light_punch"], live_arianna.is_facing_right
	)
	live_arianna._physics_process(0.0)
	var live_light_punch_started := (
		live_arianna.is_on_floor()
		and live_arianna.light_punch_active
		and live_arianna.animated_sprite.animation == &"arianna_light_punch"
	)
	live_arianna._on_animation_finished()
	live_arianna._on_animation_finished()
	live_arianna.is_player_controlled = false
	live_arianna.input_buffer.clear()
	live_arianna.input_buffer.record_input_snapshot(0, 1, [], live_arianna.is_facing_right)
	live_arianna._physics_process(0.0)
	live_arianna.animated_sprite.frame = 18
	live_arianna._on_animation_finished()
	var live_crouch_held := (
		live_arianna.current_state == Mangler.State.CROUCHING
		and live_arianna.animated_sprite.animation == &"crouch"
		and live_arianna.animated_sprite.frame == 18
	)
	live_arianna.input_buffer.record_input_snapshot(0, 0, [], live_arianna.is_facing_right)
	live_arianna._physics_process(0.0)
	var live_crouch_released := (
		live_arianna.current_state == Mangler.State.STANDING_UP
		and live_arianna.animated_sprite.animation == &"arianna_crouch_recovery"
	)
	live_arianna._on_animation_finished()
	expect.call(
		live_crouch_held
		and live_crouch_released
		and live_arianna.current_state == Mangler.State.IDLE,
		"Arianna mantiene il frame 19 accovacciata e al rilascio torna 18-1 fino a idle"
	)
	live_arianna.input_buffer.clear()
	live_arianna.last_back_tap_frame = -100000
	live_arianna.opponent.combat.is_attacking = false
	live_arianna.input_buffer.record_input_snapshot(-1, 0, [], true)
	live_arianna._physics_process(0.0)
	var live_guard_stays_inactive_without_attack := (
		live_arianna.current_state != Mangler.State.BLOCKING
		and live_arianna.animated_sprite.animation == &"backwalk"
	)
	live_arianna.opponent.combat.is_attacking = true
	live_arianna.input_buffer.record_input_snapshot(-1, 0, [], true)
	live_arianna._physics_process(0.0)
	live_arianna.animated_sprite.frame = 15
	live_arianna._on_animation_finished()
	var live_guard_high_held := (
		live_arianna.current_state == Mangler.State.BLOCKING
		and live_arianna.combat.is_blocking
		and live_arianna.animated_sprite.animation == &"block_high"
		and live_arianna.animated_sprite.frame == 15
	)
	live_arianna.opponent.combat.is_attacking = false
	live_arianna.input_buffer.record_input_snapshot(-1, 0, [], true)
	live_arianna._physics_process(0.0)
	var live_guard_high_released := (
		live_arianna.current_state == Mangler.State.BLOCK_RECOVERY
		and not live_arianna.combat.is_blocking
		and live_arianna.animated_sprite.animation == &"block_high_recovery"
	)
	live_arianna._on_animation_finished()
	expect.call(
		live_guard_stays_inactive_without_attack
		and live_guard_high_held
		and live_guard_high_released
		and live_arianna.current_state == Mangler.State.IDLE,
		"Arianna attiva la guardia solo durante l'attacco e poi torna indietro fino a idle"
	)
	live_arianna.input_buffer.record_input_snapshot(0, 0, [], true)
	live_arianna.last_back_tap_frame = -100000
	live_arianna.input_buffer.clear()
	live_arianna.opponent.combat.current_attack = (
		live_arianna.opponent.character_data.get_attack(&"light_kick")
	)
	live_arianna.opponent.combat.current_variant = null
	live_arianna.opponent.combat.is_attacking = true
	live_arianna.input_buffer.record_input_snapshot(-1, 0, [], true)
	live_arianna._physics_process(0.0)
	var live_guard_middle_started := (
		live_arianna.current_state == Mangler.State.BLOCKING
		and live_arianna.animated_sprite.animation == &"block_mid"
		and live_arianna.combat.is_blocking
	)
	live_arianna.opponent.combat.is_attacking = false
	live_arianna.input_buffer.record_input_snapshot(-1, 0, [], true)
	live_arianna._physics_process(0.0)
	var live_guard_middle_released := (
		live_arianna.current_state == Mangler.State.BLOCK_RECOVERY
		and live_arianna.animated_sprite.animation == &"block_mid_recovery"
	)
	live_arianna._on_animation_finished()
	expect.call(
		live_guard_middle_started
		and live_guard_middle_released
		and live_arianna.current_state == Mangler.State.IDLE,
		"Arianna seleziona guardia e recovery medie contro un attacco MID"
	)
	live_arianna.opponent.combat.current_attack = null
	live_arianna.input_buffer.record_input_snapshot(0, 0, [], true)
	live_arianna.last_back_tap_frame = -100000
	live_arianna.input_buffer.clear()
	live_arianna.opponent.combat.current_attack = (
		live_arianna.opponent.character_data.get_attack(&"medium_kick")
	)
	live_arianna.opponent.combat.current_variant = null
	live_arianna.opponent.combat.is_attacking = true
	live_arianna.input_buffer.record_input_snapshot(-1, 1, [], true)
	live_arianna._physics_process(0.0)
	var live_guard_low_started := (
		live_arianna.current_state == Mangler.State.BLOCKING
		and live_arianna.animated_sprite.animation == &"block_low_crouched"
		and live_arianna.combat.is_blocking
	)
	live_arianna.opponent.combat.is_attacking = false
	live_arianna.input_buffer.record_input_snapshot(-1, 1, [], true)
	live_arianna._physics_process(0.0)
	var live_guard_low_released := (
		live_arianna.current_state == Mangler.State.BLOCK_RECOVERY
		and live_arianna.animated_sprite.animation == &"block_low_recovery"
	)
	live_arianna._on_animation_finished()
	expect.call(
		live_guard_low_started
		and live_guard_low_released
		and live_arianna.current_state == Mangler.State.IDLE,
		"Arianna seleziona guardia e recovery basse contro un attacco LOW"
	)
	live_arianna.opponent.combat.current_attack = null
	live_arianna.input_buffer.record_input_snapshot(0, 0, [], true)
	live_arianna.last_back_tap_frame = -100000
	live_arianna.opponent.combat.reset()
	live_arianna.opponent.change_state(Mangler.State.IDLE)
	live_arianna.global_position.x = live_arianna.opponent.global_position.x - 120.0
	live_arianna.is_facing_right = true
	live_arianna.animated_sprite.flip_h = false
	live_arianna.input_buffer.clear()
	var health_before_low_light := live_arianna.opponent.combat.current_health
	live_arianna.input_buffer.record_input_snapshot(0, 1, [&"light_punch"], true)
	live_arianna._physics_process(0.0)
	live_arianna.animated_sprite.frame = Arianna.ARIANNA_LOW_LIGHT_PUNCH_ACTIVE_START_FRAME
	live_arianna._on_animation_frame_changed()
	await tree.physics_frame
	await tree.physics_frame
	var live_low_light_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_low_light - live_arianna.character_data.get_attack(&"light_punch").damage
		and live_arianna.opponent.current_state == Mangler.State.HIT
		and live_arianna.opponent.animated_sprite.animation == &"hurt_mid"
	)
	live_arianna._on_animation_finished()
	live_arianna.input_buffer.record_input_snapshot(0, 0, [], true)
	live_arianna._on_animation_finished()
	expect.call(
		live_low_light_hit,
		"il pugno leggero basso infligge danno reale e genera hurt_mid"
	)
	live_arianna.opponent.combat.reset()
	live_arianna.opponent.change_state(Mangler.State.IDLE)
	live_arianna.input_buffer.clear()
	var health_before_medium_punch := live_arianna.opponent.combat.current_health
	live_arianna.input_buffer.record_input_snapshot(0, 0, [&"medium_punch"], true)
	live_arianna._physics_process(0.0)
	live_arianna.animated_sprite.frame = Arianna.ARIANNA_MEDIUM_PUNCH_ACTIVE_START_FRAME
	live_arianna._on_animation_frame_changed()
	await tree.physics_frame
	await tree.physics_frame
	var live_medium_punch_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_medium_punch - live_arianna.character_data.get_attack(&"medium_punch").damage
		and live_arianna.opponent.current_state == Mangler.State.HIT
		and live_arianna.opponent.animated_sprite.animation == &"hurt_high"
	)
	live_arianna._on_animation_finished()
	live_arianna._on_animation_finished()
	expect.call(
		live_medium_punch_hit
		and live_arianna.current_state == Mangler.State.IDLE,
		"il pugno medio di Arianna infligge danno e genera hurt_high"
	)
	live_arianna.opponent.combat.reset()
	live_arianna.opponent.change_state(Mangler.State.IDLE)
	live_arianna.input_buffer.clear()
	var health_before_low_medium := live_arianna.opponent.combat.current_health
	var afterimages_before_low_medium := live_arianna.attack_afterimage_spawn_count
	live_arianna.input_buffer.record_input_snapshot(0, 1, [&"medium_punch"], true)
	live_arianna._physics_process(0.0)
	live_arianna.animated_sprite.frame = Arianna.ARIANNA_LOW_MEDIUM_PUNCH_ACTIVE_START_FRAME
	live_arianna._on_animation_frame_changed()
	await tree.physics_frame
	await tree.physics_frame
	var live_low_medium_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_low_medium - live_arianna.character_data.get_attack(&"medium_punch").damage
		and live_arianna.opponent.current_state == Mangler.State.HIT
		and live_arianna.opponent.animated_sprite.animation == &"hurt_mid"
		and live_arianna.attack_afterimage_spawn_count > afterimages_before_low_medium
	)
	live_arianna._on_animation_finished()
	live_arianna._on_animation_finished()
	expect.call(
		live_low_medium_hit
		and live_arianna.current_state == Mangler.State.CROUCHING,
		"il pugno medio basso infligge danno MID, usa la scia e torna alla crouch pose"
	)
	live_arianna.opponent.combat.reset()
	live_arianna.opponent.change_state(Mangler.State.IDLE)
	live_arianna.input_buffer.clear()
	live_arianna.change_state(Mangler.State.IDLE)
	var health_before_strong := live_arianna.opponent.combat.current_health
	var afterimages_before_strong := live_arianna.attack_afterimage_spawn_count
	live_arianna.input_buffer.record_input_snapshot(0, 0, [&"heavy_punch"], true)
	live_arianna._physics_process(0.0)
	var strong_hitbox_shape := live_arianna.combat.hitbox_shape.shape as RectangleShape2D
	live_arianna.animated_sprite.frame = Arianna.ARIANNA_STRONG_PUNCH_ACTIVE_START_FRAME
	live_arianna._on_animation_frame_changed()
	await tree.physics_frame
	await tree.physics_frame
	var live_strong_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_strong - live_arianna.character_data.get_attack(&"heavy_punch").damage
		and live_arianna.opponent.current_state == Mangler.State.HIT
		and live_arianna.opponent.animated_sprite.animation == &"hurt_high"
		and strong_hitbox_shape.size == Vector2(110.0, 65.0)
		and live_arianna.attack_afterimage_spawn_count > afterimages_before_strong
	)
	live_arianna._on_animation_finished()
	expect.call(
		live_strong_hit
		and live_arianna.current_state == Mangler.State.IDLE
		and not live_arianna.strong_punch_active,
		"lo strong punch usa la hitbox accorciata, infligge danno HIGH e conclude in idle"
	)
	live_arianna.opponent.combat.reset()
	live_arianna.opponent.change_state(Mangler.State.IDLE)
	live_arianna.input_buffer.clear()
	var health_before_crouched_strong := live_arianna.opponent.combat.current_health
	var afterimages_before_crouched_strong := live_arianna.attack_afterimage_spawn_count
	live_arianna.input_buffer.record_input_snapshot(0, 1, [&"heavy_punch"], true)
	live_arianna._physics_process(0.0)
	live_arianna.animated_sprite.frame = Arianna.ARIANNA_CROUCHED_STRONG_PUNCH_ACTIVE_START_FRAME
	live_arianna._on_animation_frame_changed()
	await tree.physics_frame
	await tree.physics_frame
	var live_crouched_strong_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_crouched_strong - live_arianna.character_data.get_attack(&"heavy_punch").damage
		and live_arianna.opponent.current_state == Mangler.State.HIT
		and live_arianna.opponent.animated_sprite.animation == &"hurt_high"
		and live_arianna.attack_afterimage_spawn_count > afterimages_before_crouched_strong
	)
	live_arianna._on_animation_finished()
	expect.call(
		live_crouched_strong_hit
		and live_arianna.current_state == Mangler.State.CROUCHING
		and not live_arianna.crouched_strong_punch_active,
		"lo strong punch basso infligge danno HIGH, genera la scia e torna in crouch"
	)
	live_arianna.opponent.combat.reset()
	live_arianna.opponent.change_state(Mangler.State.IDLE)
	live_arianna.input_buffer.clear()
	live_arianna.change_state(Mangler.State.IDLE)
	var health_before_light_kick := live_arianna.opponent.combat.current_health
	live_arianna.input_buffer.record_input_snapshot(0, 0, [&"light_kick"], true)
	live_arianna._physics_process(0.0)
	var light_kick_shape := live_arianna.combat.hitbox_shape.shape as RectangleShape2D
	live_arianna.animated_sprite.frame = Arianna.ARIANNA_LIGHT_KICK_ACTIVE_START_FRAME
	live_arianna._on_animation_frame_changed()
	await tree.physics_frame
	await tree.physics_frame
	var live_light_kick_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_light_kick - live_arianna.character_data.get_attack(&"light_kick").damage
		and live_arianna.opponent.current_state == Mangler.State.HIT
		and live_arianna.opponent.animated_sprite.animation == &"hurt_mid"
		and live_arianna.combat.get_effective_hit_height(
			live_arianna.character_data.get_attack(&"light_kick")
		) == AttackData.HitHeight.MID
		and light_kick_shape.size == Vector2(165.0, 55.0)
	)
	live_arianna._on_animation_finished()
	live_arianna._on_animation_finished()
	expect.call(
		live_light_kick_hit
		and live_arianna.current_state == Mangler.State.IDLE
		and not live_arianna.light_kick_active,
		"il light kick infligge danno MID, genera hurt_mid e conclude in idle"
	)
	live_arianna.opponent.combat.reset()
	live_arianna.opponent.change_state(Mangler.State.IDLE)
	live_arianna.input_buffer.clear()
	live_arianna.change_state(Mangler.State.IDLE)
	var health_before_low_light_kick := live_arianna.opponent.combat.current_health
	live_arianna.input_buffer.record_input_snapshot(0, 1, [&"light_kick"], true)
	live_arianna._physics_process(0.0)
	var low_light_kick_shape := live_arianna.combat.hitbox_shape.shape as RectangleShape2D
	live_arianna.animated_sprite.frame = Arianna.ARIANNA_LOW_LIGHT_KICK_ACTIVE_START_FRAME
	live_arianna._on_animation_frame_changed()
	await tree.physics_frame
	await tree.physics_frame
	var live_low_light_kick_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_low_light_kick - live_arianna.character_data.get_attack(&"light_kick").damage
		and live_arianna.opponent.current_state == Mangler.State.HIT
		and live_arianna.opponent.animated_sprite.animation == &"hurt_low"
		and live_arianna.combat.get_effective_hit_height(
			live_arianna.character_data.get_attack(&"light_kick")
		) == AttackData.HitHeight.LOW
		and low_light_kick_shape.size == Arianna.ARIANNA_LOW_LIGHT_KICK_HITBOX_SIZE
	)
	live_arianna._on_animation_finished()
	live_arianna._on_animation_finished()
	expect.call(
		live_low_light_kick_hit
		and live_arianna.current_state == Mangler.State.CROUCHING
		and not live_arianna.low_light_kick_active,
		"il light kick basso genera hurt_low e mantenendo giù conclude in crouch"
	)
	live_arianna.opponent.combat.reset()
	live_arianna.opponent.change_state(Mangler.State.IDLE)
	live_arianna.input_buffer.clear()
	live_arianna.change_state(Mangler.State.IDLE)
	var health_before_medium_kick := live_arianna.opponent.combat.current_health
	live_arianna.input_buffer.record_input_snapshot(0, 0, [&"medium_kick"], true)
	live_arianna._physics_process(0.0)
	var medium_kick_shape := live_arianna.combat.hitbox_shape.shape as RectangleShape2D
	live_arianna.animated_sprite.frame = Arianna.ARIANNA_MEDIUM_KICK_ACTIVE_START_FRAME
	live_arianna._on_animation_frame_changed()
	await tree.physics_frame
	await tree.physics_frame
	var live_medium_kick_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_medium_kick - live_arianna.character_data.get_attack(&"medium_kick").damage
		and live_arianna.opponent.current_state == Mangler.State.HIT
		and live_arianna.opponent.animated_sprite.animation == &"hurt_mid"
		and live_arianna.combat.get_effective_hit_height(
			live_arianna.character_data.get_attack(&"medium_kick")
		) == AttackData.HitHeight.MID
		and medium_kick_shape.size == Arianna.ARIANNA_MEDIUM_KICK_HITBOX_SIZE
	)
	live_arianna._on_animation_finished()
	live_arianna._on_animation_finished()
	expect.call(
		live_medium_kick_hit
		and live_arianna.current_state == Mangler.State.IDLE
		and not live_arianna.medium_kick_active,
		"il medium kick genera hurt_mid e conclude in idle"
	)
	live_arianna.opponent.combat.reset()
	live_arianna.opponent.change_state(Mangler.State.IDLE)
	live_arianna.input_buffer.clear()
	live_arianna.change_state(Mangler.State.IDLE)
	var health_before_low_medium_kick := live_arianna.opponent.combat.current_health
	live_arianna.input_buffer.record_input_snapshot(0, 1, [&"medium_kick"], true)
	live_arianna._physics_process(0.0)
	var low_medium_kick_shape := live_arianna.combat.hitbox_shape.shape as RectangleShape2D
	live_arianna.animated_sprite.frame = Arianna.ARIANNA_LOW_MEDIUM_KICK_ACTIVE_START_FRAME
	live_arianna._on_animation_frame_changed()
	await tree.physics_frame
	await tree.physics_frame
	var live_low_medium_kick_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_low_medium_kick - live_arianna.character_data.get_attack(&"medium_kick").damage
		and live_arianna.opponent.animated_sprite.animation == &"hurt_low"
		and live_arianna.combat.get_effective_hit_height(
			live_arianna.character_data.get_attack(&"medium_kick")
		) == AttackData.HitHeight.LOW
		and low_medium_kick_shape.size == Vector2(140.0, 45.0)
	)
	live_arianna._on_animation_finished()
	live_arianna._on_animation_finished()
	expect.call(
		live_low_medium_kick_hit
		and live_arianna.current_state == Mangler.State.CROUCHING
		and not live_arianna.low_medium_kick_active,
		"il medium kick basso genera hurt_low, usa la hitbox ridotta e torna in crouch"
	)
	live_arianna.opponent.combat.reset()
	live_arianna.opponent.change_state(Mangler.State.IDLE)
	live_arianna.input_buffer.clear()
	live_arianna.change_state(Mangler.State.IDLE)
	live_arianna._start_strong_kick()
	expect.call(
		live_arianna.animated_sprite.animation == &"arianna_strong_kick"
		and live_arianna.combat.current_variant != null
		and live_arianna.combat.current_variant.hit_height == AttackData.HitHeight.HIGH,
		"lo strong kick di Arianna genera hurt_high o block_high"
	)
	live_arianna._on_animation_finished()
	live_arianna.input_buffer.clear()
	live_arianna.input_buffer.record_input_snapshot(0, 1, [&"heavy_kick"], true)
	live_arianna._physics_process(0.0)
	var low_strong_kick_shape := live_arianna.combat.hitbox_shape.shape as RectangleShape2D
	expect.call(
		live_arianna.animated_sprite.animation == &"arianna_low_strong_kick"
		and live_arianna.low_strong_kick_active
		and live_arianna.combat.current_variant != null
		and live_arianna.combat.current_variant.hit_height == AttackData.HitHeight.LOW
		and live_arianna.combat.current_variant.causes_knockdown
		and low_strong_kick_shape.size == Arianna.ARIANNA_LOW_STRONG_KICK_HITBOX_SIZE,
		"il strong kick basso usa hitbox LOW e provoca sweep knockdown"
	)
	live_arianna.animated_sprite.frame = Arianna.ARIANNA_LOW_STRONG_KICK_ACTIVE_START_FRAME
	live_arianna._on_animation_frame_changed()
	expect.call(
		not live_arianna.combat.hitbox_shape.disabled,
		"lo strong kick basso attiva la hitbox durante l'estensione della gamba"
	)
	live_arianna._on_animation_finished()
	live_arianna.opponent.combat.reset()
	live_arianna.opponent.change_state(Mangler.State.IDLE)
	live_arianna.input_buffer.clear()
	live_arianna.change_state(Mangler.State.IDLE)
	live_arianna.velocity = Vector2.ZERO
	live_arianna.position.y = live_arianna.opponent.position.y
	live_arianna.update_physical_collision()
	live_arianna.global_position.x = live_arianna.opponent.global_position.x - 400.0
	live_arianna.is_facing_right = true
	live_arianna.animated_sprite.flip_h = false
	live_arianna.is_player_controlled = false
	live_arianna.input_buffer.clear()
	live_arianna.input_buffer.record_input_snapshot(1, 0, [], true)
	live_arianna._physics_process(0.0)
	live_arianna.input_buffer.record_input_snapshot(0, 0, [], true)
	live_arianna._physics_process(0.0)
	live_arianna.input_buffer.record_input_snapshot(1, 0, [], true)
	live_arianna._physics_process(0.0)
	var live_run_started := (
		live_arianna.current_state == Mangler.State.RUNNING
		and live_arianna.animated_sprite.animation == &"run"
		and live_arianna.animated_sprite.is_playing()
		and is_equal_approx(
			absf(live_arianna.velocity.x),
			live_arianna.character_data.run_speed * Arianna.ARIANNA_RUN_SPEED_MULTIPLIER
		)
	)
	live_arianna.global_position.x = live_arianna.opponent.global_position.x - 121.0
	live_arianna._physics_process(1.0 / 60.0)
	expect.call(
		live_run_started
		and live_arianna.current_state == Mangler.State.IDLE
		and live_arianna.animated_sprite.animation == &"idle",
		"la corsa di Arianna termina in idle alla collisione con l'avversario"
	)
	live_arianna.global_position.x = live_arianna.opponent.global_position.x - 200.0
	live_arianna.change_state(Mangler.State.IDLE)
	live_arianna.velocity = Vector2.ZERO
	live_arianna.is_player_controlled = true
	live_arianna.controls_enabled = true
	live_arianna.can_move = true
	live_arianna.is_player_controlled = false
	live_arianna.input_buffer.clear()
	live_arianna.input_buffer.record_input_snapshot(-1, 0, [], true)
	live_arianna._physics_process(0.0)
	live_arianna.input_buffer.record_input_snapshot(0, 0, [], true)
	live_arianna._physics_process(0.0)
	live_arianna.input_buffer.record_input_snapshot(-1, 0, [], true)
	live_arianna._physics_process(0.0)
	var back_jump_started_x := live_arianna.back_jump_start_x
	var back_jump_started_y := live_arianna.back_jump_start_y
	var live_back_jump_started := (
		live_arianna.back_jump_active
		and live_arianna.current_state == Mangler.State.BACK_HOP
		and live_arianna.animated_sprite.animation == &"arianna_back_jump"
		and is_zero_approx(live_arianna.velocity.y)
	)
	live_arianna._on_animation_finished()
	var live_back_jump_returns_to_idle_animation := (
		live_arianna.back_jump_active
		and live_arianna.current_state == Mangler.State.IDLE
		and live_arianna.animated_sprite.animation == &"idle"
		and live_arianna.animated_sprite.is_playing()
	)
	live_arianna._physics_process(Arianna.ARIANNA_BACK_JUMP_DURATION)
	expect.call(
		live_back_jump_started
		and live_back_jump_returns_to_idle_animation
		and is_equal_approx(
			back_jump_started_x - live_arianna.position.x,
			Arianna.ARIANNA_BACK_JUMP_DISTANCE
		)
		and is_equal_approx(live_arianna.position.y, back_jump_started_y)
		and live_arianna.current_state == Mangler.State.IDLE,
		"il back jump torna subito visivamente in idle e completa 50 px in un secondo"
	)
	live_arianna.is_player_controlled = true
	live_arianna.controls_enabled = true
	live_arianna.can_move = true
	live_arianna.start_jump(0.0)
	var facing_before_cross := live_arianna.is_facing_right
	live_arianna.global_position.x = live_arianna.opponent.global_position.x + 10.0
	live_arianna._update_jump_facing()
	var facing_locked_during_rotation := live_arianna.is_facing_right == facing_before_cross
	live_arianna.animated_sprite.frame = Arianna.ARIANNA_JUMP_FRAME_COUNT - 1
	live_arianna._on_animation_frame_changed()
	expect.call(live_light_punch_started, "nello stage Arianna esegue il light punch a terra")
	expect.call(
		live_arianna.current_state in [Mangler.State.JUMP_STARTUP, Mangler.State.JUMPING]
		and live_arianna.animated_sprite.animation == &"jump",
		"nello stage Arianna avvia il salto"
	)
	expect.call(
		facing_locked_during_rotation
		and not live_arianna.is_facing_right
		and live_arianna.animated_sprite.flip_h,
		"Arianna cambia facing solo dopo rotazione completa e sorpasso"
	)
	live_arena.queue_free()
	await tree.process_frame
	return true
