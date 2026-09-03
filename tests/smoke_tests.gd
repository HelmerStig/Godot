extends SceneTree

## Suite smoke senza dipendenze esterne.
## Esecuzione: Godot --headless --path . --script res://tests/smoke_tests.gd

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Engine.time_scale = 1.0
	print("=== SANMO HEADLESS SMOKE TESTS ===")
	_test_attack_data()
	await _test_input_buffer()
	await _test_arianna_idle()
	await _test_combat_flow()
	_release_test_actions()

	if failures == 0:
		print("SMOKE_TESTS_OK")
		quit(0)
	else:
		push_error("SMOKE_TESTS_FAILED: %d assertion(s)" % failures)
		quit(1)


func _finish_suite(suite_name: String) -> void:
	_release_test_actions()
	if failures == 0:
		print("%s_TESTS_OK" % suite_name.to_upper())
		quit(0)
	else:
		push_error("%s_TESTS_FAILED: %d assertion(s)" % [suite_name.to_upper(), failures])
		quit(1)


func _test_arena_contract() -> void:
	print("-- Arena")
	var arena_scene := load("res://scenes/MainArena.tscn") as PackedScene
	var arena := arena_scene.instantiate() as MainArena
	var player1 := arena.get_node("Player1")
	var player2 := arena.get_node("Player2")
	_expect(
		player1 is Arianna and player2 is Mangler and not (player2 is Arianna),
		"MainArena assegna Arianna al Player 1 e Mangler al Player 2"
	)
	_expect(
		player1 is Fighter and player2 is Fighter,
		"i nodi dell'arena rispettano il contratto Fighter"
	)
	root.add_child(arena)
	await process_frame
	_expect(
		arena.player1.opponent == arena.player2 and arena.player2.opponent == arena.player1,
		"MainArena collega reciprocamente gli avversari"
	)
	_expect(
		not arena.player1.controls_enabled and not arena.player2.controls_enabled,
		"l'arena blocca i controlli durante il countdown"
	)
	arena.queue_free()
	await process_frame


func _test_attack_data() -> void:
	print("-- AttackData")
	var character_data := CharacterData.create_default()
	var attack_ids: Array[StringName] = [
		&"light_punch",
		&"medium_punch",
		&"heavy_punch",
		&"light_kick",
		&"medium_kick",
		&"heavy_kick",
		&"special_720_punch",
		&"special_sonic_boom",
	]
	_expect(character_data.attacks.size() == 8, "il profilo predefinito contiene otto AttackData")
	for attack_id in attack_ids:
		var attack := character_data.get_attack(attack_id)
		_expect(attack != null, "risorsa caricata: " + str(attack_id))
		if attack != null:
			_expect(attack.is_valid(), "risorsa valida: " + str(attack_id))

	var light_punch := character_data.get_attack(&"light_punch")
	var standing_light: Resource
	var crouched_light: Resource
	if light_punch != null:
		for variant in light_punch.variants:
			if variant.variant_id == &"standing":
				standing_light = variant
			elif variant.variant_id == &"crouched":
				crouched_light = variant
	_expect(
		standing_light != null
		and standing_light.animation_name == &"light_punch_single"
		and standing_light.startup_frames == 11
		and standing_light.active_frames == 3,
		"il frame data del light punch in piedi proviene da AttackVariantData"
	)
	_expect(
		crouched_light != null
		and crouched_light.hitbox_size == Vector2(150.0, 35.0)
		and crouched_light.hit_height == AttackData.HitHeight.MID,
		"la variante accovacciata contiene hitbox e altezza del colpo"
	)
	_expect(
		light_punch != null and is_equal_approx(light_punch.get_total_duration(), 0.3),
		"startup, active e recovery determinano la durata totale"
	)
	_expect(
		light_punch != null
		and light_punch.hit_height == AttackData.HitHeight.HIGH
		and light_punch.hit_reaction_start_frame == 3,
		"il light punch colpisce alto e avvia la reazione dal quarto frame"
	)
	var heavy_punch := character_data.get_attack(&"heavy_punch")
	_expect(
		heavy_punch != null and heavy_punch.hit_height == AttackData.HitHeight.HIGH,
		"il pugno pesante colpisce in alto al volto"
	)
	var light_kick := character_data.get_attack(&"light_kick")
	var medium_kick := character_data.get_attack(&"medium_kick")
	_expect(
		light_kick != null and light_kick.hit_height == AttackData.HitHeight.MID,
		"il calcio leggero in piedi provoca hurt-medium"
	)
	_expect(
		medium_kick != null and medium_kick.hit_height == AttackData.HitHeight.LOW,
		"il calcio medio colpisce in basso"
	)
	var heavy_kick := character_data.get_attack(&"heavy_kick")
	_expect(
		heavy_kick != null
		and heavy_kick.hit_height == AttackData.HitHeight.MID
		and not heavy_kick.causes_knockdown,
		"il calcio pesante provoca hurt-medium senza knockdown"
	)


func _test_input_buffer() -> void:
	print("-- FighterInputBuffer")
	var buffer := FighterInputBuffer.new(1)
	var light_punch: Array[StringName] = [&"light_punch"]
	var no_attacks: Array[StringName] = []

	buffer.record_input_snapshot(1, 0, light_punch, true)
	_expect(
		buffer.get_current_direction() == FighterInputBuffer.Direction.FORWARD,
		"direzione assoluta destra convertita in FORWARD"
	)
	_expect(
		buffer.consume_attack(&"light_punch") == FighterInputBuffer.Direction.FORWARD,
		"attacco memorizzato con la direzione di pressione"
	)
	_expect(
		buffer.consume_attack(&"light_punch") == FighterInputBuffer.NO_DIRECTION,
		"lo stesso attacco non può essere consumato due volte"
	)
	buffer.clear()
	buffer.record_input_snapshot(1, 0, no_attacks, false)
	_expect(
		buffer.get_current_direction() == FighterInputBuffer.Direction.BACK,
		"la direzione viene invertita quando il fighter guarda a sinistra"
	)
	buffer.clear()
	buffer.record_input_snapshot(1, 0, no_attacks, true)
	_expect(buffer.is_forward_just_pressed(), "il primo tap avanti viene rilevato")
	buffer.record_input_snapshot(1, 0, no_attacks, true)
	_expect(not buffer.is_forward_just_pressed(), "mantenere avanti non genera nuovi tap")
	buffer.record_input_snapshot(0, 0, no_attacks, true)
	buffer.record_input_snapshot(1, 0, no_attacks, true)
	_expect(buffer.is_forward_just_pressed(), "un secondo tap distinto viene rilevato")
	buffer.clear()
	buffer.record_input_snapshot(-1, 0, no_attacks, true)
	_expect(buffer.is_back_just_pressed(), "il primo tap indietro viene rilevato")
	buffer.record_input_snapshot(-1, 0, no_attacks, true)
	_expect(not buffer.is_back_just_pressed(), "mantenere indietro non genera nuovi tap")
	buffer.record_input_snapshot(0, 0, no_attacks, true)
	buffer.record_input_snapshot(-1, 0, no_attacks, true)
	_expect(buffer.is_back_just_pressed(), "un secondo tap indietro distinto viene rilevato")
	buffer.clear()
	buffer.record_input_snapshot(0, 1, no_attacks, true)
	buffer.record_input_snapshot(1, 0, no_attacks, true)
	_expect(
		buffer.matches_recent_sequence([
			FighterInputBuffer.Direction.DOWN,
			FighterInputBuffer.Direction.DOWN_FORWARD,
			FighterInputBuffer.Direction.FORWARD,
		]),
		"un quarto di luna analogico rapido ricostruisce la diagonale tra DOWN e FORWARD"
	)
	_expect(
		buffer.matches_recent_sequence([
			FighterInputBuffer.Direction.DOWN,
			FighterInputBuffer.Direction.FORWARD,
		]),
		"riconoscimento di una sequenza direzionale recente"
	)
	buffer.clear()
	buffer.record_input_snapshot(-1, 0, no_attacks, true)
	buffer.record_input_snapshot(1, 1, no_attacks, true)
	buffer.record_input_snapshot(1, 0, no_attacks, true)
	_expect(
		buffer.matches_recent_sequence([
			FighterInputBuffer.Direction.BACK,
			FighterInputBuffer.Direction.DOWN_BACK,
			FighterInputBuffer.Direction.DOWN,
			FighterInputBuffer.Direction.DOWN_FORWARD,
			FighterInputBuffer.Direction.FORWARD,
		]),
		"la mezzaluna ricostruisce diagonali e basso saltati dallo stick rapido"
	)
	_expect(
		FighterInputBuffer.HISTORY_LIMIT == 60
		and FighterInputBuffer.DEFAULT_ATTACK_BUFFER_FRAMES == 10
		and FighterInputBuffer.DEFAULT_MOTION_WINDOW_FRAMES == 36
		and Mangler.SUPER_MOTION_WINDOW_FRAMES == 48,
		"quarti e mezze lune usano finestre temporali più tolleranti"
	)

func _test_arianna_idle() -> void:
	print("-- Arianna idle")
	var arianna_scene := load("res://scenes/Arianna.tscn") as PackedScene
	var arianna := arianna_scene.instantiate() as Arianna
	arianna.set_physics_process(false)
	root.add_child(arianna)
	await process_frame
	var frames := arianna.animated_sprite.sprite_frames
	var last_frame := frames.get_frame_texture(&"idle", 23) as AtlasTexture
	_expect(frames.get_frame_count(&"idle") == 24, "Arianna idle usa esattamente 24 frame")
	_expect(
		is_equal_approx(frames.get_animation_speed(&"idle"), 24.0),
		"Arianna idle è configurato a 24 FPS"
	)
	_expect(frames.get_animation_loop(&"idle"), "Arianna idle è configurato in loop")
	_expect(
		arianna.animated_sprite.is_playing()
		and arianna.animated_sprite.animation == &"idle",
		"Arianna avvia automaticamente idle"
	)
	_expect(
		last_frame != null
		and last_frame.atlas == Arianna.ARIANNA_IDLE_SHEET
		and last_frame.region == Rect2(1024.0, 1536.0, 512.0, 512.0),
		"Arianna usa i primi 24 riquadri della griglia 7x4"
	)
	_expect(
		arianna.animated_sprite.scale == Arianna.ARIANNA_SPRITE_SCALE
		and arianna.animated_sprite.position == Arianna.ARIANNA_SPRITE_POSITION,
		"Arianna idle mantiene scala e linea dei piedi configurate"
	)
	var walk_frames := arianna.animated_sprite.sprite_frames
	var walk_last_frame := walk_frames.get_frame_texture(&"walk", 47) as AtlasTexture
	_expect(
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
	_expect(
		walk_frames.get_frame_count(&"backwalk") == 48
		and is_equal_approx(walk_frames.get_animation_speed(&"backwalk"), 24.0)
		and walk_frames.get_animation_loop(&"backwalk")
		and backwalk_first_frame.region == walk_last_frame.region
		and backwalk_last_frame.region == Rect2(0.0, 0.0, 512.0, 512.0),
		"Arianna backwalk riusa i 48 frame di 01-walk in ordine inverso"
	)
	var run_first_frame := frames.get_frame_texture(&"run", 0) as AtlasTexture
	var run_last_frame := frames.get_frame_texture(&"run", 47) as AtlasTexture
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	var low_light_first := frames.get_frame_texture(&"arianna_low_light_punch", 0) as AtlasTexture
	var low_light_last := frames.get_frame_texture(&"arianna_low_light_punch", 14) as AtlasTexture
	var low_light_recovery_first := (
		frames.get_frame_texture(&"arianna_low_light_punch_recovery", 0) as AtlasTexture
	)
	var low_light_recovery_last := (
		frames.get_frame_texture(&"arianna_low_light_punch_recovery", 13) as AtlasTexture
	)
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
		Arianna.ARIANNA_LOW_MEDIUM_KICK_HITBOX_SIZE == Vector2(140.0, 45.0),
		"Arianna medium kick basso usa la hitbox accorciata di 80 px"
	)
	var strong_kick_first := frames.get_frame_texture(&"arianna_strong_kick", 0) as AtlasTexture
	var strong_kick_last := frames.get_frame_texture(&"arianna_strong_kick", 35) as AtlasTexture
	_expect(
		frames.get_frame_count(&"arianna_strong_kick") == 36
		and is_equal_approx(frames.get_animation_speed(&"arianna_strong_kick"), 32.0)
		and not frames.get_animation_loop(&"arianna_strong_kick")
		and strong_kick_first.atlas == Arianna.ARIANNA_STRONG_KICK_SHEET
		and strong_kick_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and strong_kick_last.region == Rect2(2560.0, 2560.0, 512.0, 512.0),
		"Arianna strong kick usa tutti i 36 fotogrammi a 32 FPS"
	)
	_expect(
		not arianna.get_attack_motion_profile(&"arianna_strong_kick").is_empty(),
		"Arianna strong kick usa l'effetto movimento delle mosse potenti"
	)
	var low_strong_kick_first := (
		frames.get_frame_texture(&"arianna_low_strong_kick", 0) as AtlasTexture
	)
	var low_strong_kick_last := (
		frames.get_frame_texture(&"arianna_low_strong_kick", 48) as AtlasTexture
	)
	_expect(
		frames.get_frame_count(&"arianna_low_strong_kick") == 49
		and is_equal_approx(frames.get_animation_speed(&"arianna_low_strong_kick"), 48.0)
		and not frames.get_animation_loop(&"arianna_low_strong_kick")
		and low_strong_kick_first.atlas == Arianna.ARIANNA_LOW_STRONG_KICK_SHEET
		and low_strong_kick_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and low_strong_kick_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0),
		"Arianna strong kick basso usa tutti i 49 frame a 48 FPS"
	)
	_expect(
		not arianna.get_attack_motion_profile(&"arianna_low_strong_kick").is_empty(),
		"Arianna strong kick basso usa l'effetto movimento delle mosse potenti"
	)
	var jump_first := frames.get_frame_texture(&"jump", 0) as AtlasTexture
	var jump_last := frames.get_frame_texture(&"jump", 48) as AtlasTexture
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
		arianna.current_state == Mangler.State.HIT
		and arianna.animated_sprite.animation == &"hurt_mid"
		and arianna.animated_sprite.frame <= 1
		and is_equal_approx(
			reduced_mid_pushback,
			Mangler.HIT_PUSHBACK_SPEED * Arianna.ARIANNA_HURT_MEDIUM_PUSHBACK_MULTIPLIER
		),
		"Arianna mantiene hurt_mid dal primo frame con rinculo ridotto"
	)
	var medium_hurt_explosion := get_first_node_in_group(
		"hurt_blue_explosion"
	) as Node2D
	_expect(
		is_instance_valid(medium_hurt_explosion)
		and (medium_hurt_explosion.get_node("BlueSparks") as CPUParticles2D).amount == 64,
		"hurt_medium mantiene l'esplosione azzurra sullo stomaco"
	)
	if is_instance_valid(medium_hurt_explosion):
		medium_hurt_explosion.queue_free()
	await process_frame
	arianna.position = reaction_test_position
	arianna.velocity = Vector2.ZERO
	arianna.change_state(Mangler.State.IDLE)
	arianna.start_hit_reaction(AttackData.HitHeight.LOW, null, 0, false)
	var low_hurt_explosion := get_first_node_in_group(
		"hurt_blue_explosion"
	) as Node2D
	_expect(
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
	_expect(
		arianna.animated_sprite.animation == &"hurt_low"
		and (arianna.animated_sprite.sprite_frames.get_frame_texture(&"hurt_low", 0) as AtlasTexture).atlas
			== Arianna.ARIANNA_HURT_LOW_SHEET,
		"un colpo LOW mostra il nuovo spritesheet hurt_low di Arianna"
	)
	arianna.combat.hit_reaction(0.0, AttackData.HitHeight.LOW, null, 4, false)
	_expect(
		arianna.animated_sprite.animation == &"hurt_low"
		and arianna.animated_sprite.frame == 0,
		"hurt_low di Arianna esegue sempre la sequenza completa dal primo frame"
	)
	await create_timer(0.34).timeout
	_expect(
		arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle",
		"dopo 1-6-1 Arianna torna in idle"
	)
	arianna.start_hit_reaction(AttackData.HitHeight.HIGH, null, 0, false)
	_expect(
		arianna.animated_sprite.animation == &"hurt_high"
		and (arianna.animated_sprite.sprite_frames.get_frame_texture(&"hurt_high", 0) as AtlasTexture).atlas
			== Arianna.ARIANNA_HURT_HIGH_SHEET,
		"pugni light e medium HIGH mostrano lo spritesheet hurt_high di Arianna"
	)
	arianna.change_state(Mangler.State.IDLE)
	arianna.combat.hit_reaction(0.0, AttackData.HitHeight.HIGH, null, 3, false)
	_expect(
		arianna.animated_sprite.animation == &"hurt_high"
		and arianna.animated_sprite.frame == 0,
		"hurt_high di Arianna esegue sempre la sequenza completa dal primo frame"
	)
	await create_timer(0.39).timeout
	_expect(
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
	_expect(
		arianna.current_state == Mangler.State.SWEEP_KNOCKDOWN
		and arianna.animated_sprite.animation == &"sweep_knockdown"
		and is_zero_approx(arianna.get_sweep_grounded_hold_duration()),
		"un calcio potente basso mantiene lo sweep_knockdown di Arianna nel frame fisico"
	)
	await create_timer(2.4).timeout
	var saw_knockdown_recovery := false
	for transition: Dictionary in knockdown_transitions:
		if (
			transition[&"state"] == Mangler.State.KNOCKDOWN_RECOVERY
			and transition[&"animation"] == &"knockdown_recovery"
		):
			saw_knockdown_recovery = true
			break
	_expect(
		saw_knockdown_recovery,
		"finito sweep_knockdown Arianna passa subito alla recovery"
	)
	_expect(
		arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle",
		"completata knockdown_recovery Arianna torna in idle"
	)
	arianna.combat.take_damage(arianna.combat.current_health, null)
	arianna._physics_process(0.0)
	await arianna.animated_sprite.animation_finished
	await process_frame
	_expect(
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
	root.add_child(tornado_preview)
	await process_frame
	var tornado_frames := tornado_preview.tornado_sprite.sprite_frames
	var tornado_first := tornado_frames.get_frame_texture(&"spin", 0) as AtlasTexture
	var tornado_last := tornado_frames.get_frame_texture(&"spin", 48) as AtlasTexture
	_expect(
		tornado_frames.get_frame_count(&"spin") == 49
		and is_equal_approx(tornado_frames.get_animation_speed(&"spin"), 48.0)
		and tornado_frames.get_animation_loop(&"spin")
		and tornado_first.atlas == AriannaTornadoProjectile.TORNADO_SHEET
		and tornado_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and tornado_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0),
		"il tornado baseball usa tutti i 49 frame in loop a 48 FPS"
	)
	_expect(
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
	_expect(
		tornado_preview.collision_layer == 2
		and tornado_preview.collision_mask == 4
		and tornado_shape.size == AriannaTornadoProjectile.HITBOX_SIZE
		and AriannaTornadoProjectile.DAMAGE == 10,
		"il tornado usa una hitbox MID e infligge 10 danni al primo contatto"
	)
	var preview_explosion := tornado_preview.spawn_impact_explosion(Vector2.ZERO)
	_expect(
		preview_explosion.is_in_group("arianna_tornado_impact")
		and preview_explosion.get_node_or_null("BlueFlash") != null
		and (preview_explosion.get_node_or_null("BlueSparks") as CPUParticles2D).amount == 90
		and AriannaTornadoProjectile.IMPACT_OFFSET == Vector2(0.0, -150.0),
		"l'impatto genera 90 scintille azzurre all'altezza della pancia"
	)
	preview_explosion.queue_free()
	tornado_preview.queue_free()
	await process_frame
	var medium_tornado := AriannaTornadoProjectile.new()
	medium_tornado.setup(arianna, true, &"medium")
	var heavy_tornado := AriannaTornadoProjectile.new()
	heavy_tornado.setup(arianna, true, &"heavy")
	_expect(
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
	_expect(
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
	_expect(
		arianna.jump_light_punch_active
		and arianna.current_state == Mangler.State.ATTACKING
		and arianna.animated_sprite.animation == &"arianna_jump_light_punch"
		and arianna.animated_sprite.scale == Arianna.ARIANNA_JUMP_LIGHT_PUNCH_SPRITE_SCALE
		and arianna.input_buffer.consume_attack(&"light_punch")
			== FighterInputBuffer.NO_DIRECTION,
		"il light punch durante il salto avvia la variante aerea dedicata"
	)
	arianna._finish_jump_light_punch(false)
	_expect(
		arianna.current_state == Mangler.State.JUMPING
		and arianna.animated_sprite.animation == &"jump"
		and arianna.animated_sprite.frame == 31,
		"terminato il light punch aereo Arianna riprende custom_jump dal frame 32"
	)
	arianna.jump_light_punch_active = true
	arianna.current_state = Mangler.State.ATTACKING
	arianna._finish_jump_light_punch(true)
	_expect(
		arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle"
		and arianna.animated_sprite.scale == Arianna.ARIANNA_SPRITE_SCALE
		and not arianna.jump_light_punch_active,
		"se il light punch aereo termina al suolo Arianna passa direttamente in idle"
	)
	arianna.current_state = Mangler.State.JUMPING
	arianna.aerial_attack_used = false
	arianna._start_jump_medium_punch()
	_expect(
		arianna.jump_medium_punch_active
		and arianna.current_state == Mangler.State.ATTACKING
		and arianna.animated_sprite.animation == &"arianna_jump_medium_punch"
		and arianna.animated_sprite.scale == Arianna.ARIANNA_JUMP_MEDIUM_PUNCH_SPRITE_SCALE
		and arianna.combat.is_airborne_medium_punch,
		"il medium punch durante il salto avvia la variante aerea dedicata"
	)
	arianna._finish_jump_medium_punch(false)
	_expect(
		arianna.current_state == Mangler.State.JUMPING
		and arianna.animated_sprite.animation == &"jump"
		and arianna.animated_sprite.frame == 28
		and not arianna.jump_medium_punch_active,
		"terminato il medium punch aereo Arianna riprende custom_jump dal frame 29"
	)
	arianna.current_state = Mangler.State.JUMPING
	arianna.aerial_attack_used = false
	arianna._start_jump_strong_punch()
	_expect(
		arianna.jump_strong_punch_active
		and arianna.current_state == Mangler.State.ATTACKING
		and arianna.animated_sprite.animation == &"arianna_jump_strong_punch"
		and arianna.animated_sprite.scale == Arianna.ARIANNA_JUMP_STRONG_PUNCH_SPRITE_SCALE
		and arianna.combat.is_airborne_heavy_punch,
		"lo strong punch durante il salto avvia la variante aerea dedicata"
	)
	arianna._finish_jump_strong_punch(false)
	_expect(
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
	_expect(
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
	_expect(
		not arianna.combat.hitbox_shape.disabled,
		"la hitbox del light kick aereo è attiva dal fotogramma visibile 9"
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_JUMP_LIGHT_KICK_ACTIVE_END_FRAME
	arianna._on_animation_frame_changed()
	_expect(
		not arianna.combat.hitbox_shape.disabled,
		"la hitbox del light kick aereo resta attiva fino al fotogramma visibile 15"
	)
	arianna._finish_jump_light_kick(false)
	_expect(
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
	_expect(
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
	_expect(
		not arianna.combat.hitbox_shape.disabled,
		"la hitbox del medium kick aereo si attiva al fotogramma visibile 28"
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_JUMP_MEDIUM_KICK_ACTIVE_END_FRAME
	arianna._on_animation_frame_changed()
	_expect(
		not arianna.combat.hitbox_shape.disabled,
		"la hitbox del medium kick aereo resta attiva fino alla fine"
	)
	arianna._finish_jump_medium_kick(false)
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
		arianna.baseball_special_active
		and arianna.current_state == Mangler.State.ATTACKING
		and arianna.animated_sprite.animation == &"arianna_baseball_special"
		and arianna.combat.is_attacking
		and arianna.combat.current_attack == null,
		"il quarto di luna con light punch avvia la speciale baseball senza hitbox prematura"
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_BASEBALL_TORNADO_SPAWN_FRAME
	arianna._on_animation_frame_changed()
	await process_frame
	var spawned_tornado := (
		get_first_node_in_group("arianna_baseball_tornado")
		as AriannaTornadoProjectile
	)
	var tornado_count_before_repeat: int = get_nodes_in_group(
		"arianna_baseball_tornado"
	).size()
	arianna._on_animation_frame_changed()
	_expect(
		is_instance_valid(spawned_tornado)
		and arianna.baseball_tornado_spawned
		and spawned_tornado.travel_direction == (1.0 if arianna.is_facing_right else -1.0)
		and is_equal_approx(
			spawned_tornado.global_position.y,
			arianna.global_position.y + Arianna.ARIANNA_BASEBALL_TORNADO_SPAWN_OFFSET.y
		)
		and get_nodes_in_group("arianna_baseball_tornado").size()
			== tornado_count_before_repeat,
		"al frame d'impatto la speciale genera una sola tromba d'aria dalla mazza"
	)
	if is_instance_valid(spawned_tornado):
		spawned_tornado.queue_free()
	await process_frame
	arianna._finish_baseball_special()
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
		heavy_baseball_command_started
		and arianna.baseball_special_strength == &"heavy",
		"quarto di luna avanti più pugno forte avvia il tornado forte"
	)
	arianna._finish_baseball_special()
	var whistle_target_scene := load("res://scenes/Mangler.tscn") as PackedScene
	var whistle_target := whistle_target_scene.instantiate() as Mangler
	whistle_target.set_physics_process(false)
	root.add_child(whistle_target)
	await process_frame
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
	_expect(
		points_forward_started
		and arianna.points_forward_super_active
		and arianna.animated_sprite.animation == &"arianna_points_forward_super"
		and whistle_target.current_state == Mangler.State.IDLE
		and not whistle_target.controls_enabled
		and not whistle_target.can_move,
		"mezzaluna indietro più LP+MP avvia points forward e mantiene il rivale in idle"
	)
	var cat_wave_generation_before := arianna.cat_wave_generation
	arianna.animated_sprite.frame = Arianna.ARIANNA_POINTS_FORWARD_CAT_WAVE_START_FRAME
	arianna._on_animation_frame_changed()
	_expect(
		arianna.points_forward_cat_wave_started
		and arianna.cat_wave_generation == cat_wave_generation_before + 1
		and Arianna.ARIANNA_POINTS_FORWARD_CAT_WAVE_START_FRAME
			== Arianna.ARIANNA_POINTS_FORWARD_SUPER_FRAME_COUNT - 24,
		"l'ondata dei gatti parte un secondo prima della fine della posa a 24 FPS"
	)
	arianna._finish_points_forward_super()
	var cat_test_target_position := whistle_target.global_position
	whistle_target.global_position.x = 10000.0 if arianna.is_facing_right else -10000.0
	await create_timer(2.15).timeout
	var tullio_nodes := get_nodes_in_group("arianna_tullio_projectile")
	var cats_by_id := {&"tullio": [], &"tilda": [], &"telma": []}
	for cat_node in tullio_nodes:
		if cat_node is AriannaTullioProjectile and cat_node.source_fighter == arianna:
			cat_node.set_physics_process(false)
			cats_by_id[cat_node.cat_id].append(cat_node)
	whistle_target.global_position = cat_test_target_position
	var tullio: AriannaTullioProjectile = (
		cats_by_id[&"tullio"][0] if not cats_by_id[&"tullio"].is_empty() else null
	)
	_expect(
		not arianna.points_forward_super_active
		and arianna.current_state == Mangler.State.IDLE
		and not whistle_target.controls_enabled
		and not whistle_target.can_move
		and cats_by_id[&"tullio"].size() == 4
		and cats_by_id[&"tilda"].size() == 4
		and cats_by_id[&"telma"].size() == 4
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
					and cat.animated_sprite.scale == Vector2(0.41, 0.41)
				)
		_expect(
			cat_profiles_valid
			and AriannaTullioProjectile.OFFSCREEN_MARGIN == 85.0,
			"ogni clone mantiene atlas, 24 FPS, scala ed effetto movimento del proprio gatto"
		)
		var health_before_tullio := whistle_target.combat.current_health
		tullio.current_state = AriannaTullioProjectile.State.ATTACKING
		for hit_index in range(AriannaTullioProjectile.ATTACK_LOOPS):
			tullio.hit_applied_in_current_loop = false
			tullio._apply_cat_hit()
			_expect(
				whistle_target.combat.current_health
				== health_before_tullio - AriannaTullioProjectile.DAMAGE_PER_HIT * (hit_index + 1)
				and whistle_target.animated_sprite.animation == &"hurt_low",
				"il colpo %d di Tullio infligge 1 danno e genera hurt_low" % (hit_index + 1)
			)
		_expect(
			whistle_target.combat.current_health == health_before_tullio - 3,
			"i tre attacchi di ogni gatto infliggono 1 danno ciascuno"
		)
		var all_cats: Array = []
		for cat_id in [&"tullio", &"tilda", &"telma"]:
			all_cats.append_array(cats_by_id[cat_id])
		for cat_index in range(all_cats.size() - 1):
			all_cats[cat_index]._emit_completion()
		_expect(
			not whistle_target.controls_enabled and not whistle_target.can_move,
			"il rivale resta fermo finche non sono usciti tutti i gatti"
		)
		all_cats.back()._emit_completion()
		_expect(
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
	await physics_frame
	await physics_frame
	await physics_frame
	arianna.input_buffer.record_input_snapshot(1, 0, [&"medium_kick"], true)
	var whistle_command_started := arianna._try_start_whistle_special()
	_expect(
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
	_expect(
		air_was_absent_before_frame_six
		and is_instance_valid(whistle_air)
		and whistle_air.emitting
		and whistle_air.position == Arianna.ARIANNA_WHISTLE_AIR_MOUTH_OFFSET
		and whistle_air.direction.x > 0.0,
		"dal fotogramma 6 il fischio emette aria dalla bocca verso l'avversario"
	)
	_expect(
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
	_expect(
		is_instance_valid(whistle_air)
		and not whistle_air.emitting
		and arianna.whistle_air_effect == null,
		"dopo il fotogramma 20 l'aria smette di essere emessa e si dissolve"
	)
	arianna.animated_sprite.frame = Arianna.ARIANNA_WHISTLE_SPECIAL_FRAME_COUNT - 1
	arianna._on_animation_finished()
	_expect(
		not arianna.whistle_special_active
		and arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle"
		and whistle_target.current_state == Mangler.State.IDLE
		and whistle_target.controls_enabled,
		"terminata la sequenza 1-25-1 Arianna e l'avversario vengono rilasciati in idle"
	)
	var bateau := get_first_node_in_group(
		"arianna_bateau_projectile"
	) as AriannaBateauProjectile
	var bateau_frames := bateau.animated_sprite.sprite_frames
	var bateau_run_first := bateau_frames.get_frame_texture(&"run", 0) as AtlasTexture
	var bateau_run_last := bateau_frames.get_frame_texture(&"run", 48) as AtlasTexture
	var bateau_attack_last := bateau_frames.get_frame_texture(&"attack", 24) as AtlasTexture
	var bateau_back_last := bateau_frames.get_frame_texture(&"back_to_run", 24) as AtlasTexture
	_expect(
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
	_expect(
		is_instance_valid(bateau)
		and bateau.current_state == AriannaBateauProjectile.State.RUNNING
		and bateau.global_position.x
			== arianna.stage_left_limit - AriannaBateauProjectile.OFFSCREEN_MARGIN
		and bateau.travel_direction > 0.0
		and bateau.animated_sprite.animation == &"run",
		"dopo il fischio Bateau entra correndo da fuori schermo"
	)
	_expect(
		bateau.run_audio_player.stream == AriannaBateauProjectile.RUN_SOUND
		and bateau.run_audio_player.playing
		and not bateau.attack_audio_player.playing,
		"all'ingresso di Bateau parte il suono della corsa"
	)
	var health_before_bateau := whistle_target.combat.current_health
	_expect(
		bateau.get_node_or_null("CollisionShape2D") == null
		and whistle_target.combat.current_health == health_before_bateau,
		"la corsa di Bateau non usa collisioni e non viene influenzata dalle hurtbox"
	)
	_expect(
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
	_expect(
		bateau.run_audio_player.playing
		and bateau.attack_audio_player.stream == AriannaBateauProjectile.ATTACK_SOUND
		and bateau.animated_sprite.frame >= AriannaBateauProjectile.ATTACK_SOUND_FRAME
		and bateau.attack_sound_played
		and bateau.attack_audio_player.playing,
		"abbaio e ringhio si sovrappongono alla corsa al frame parametrizzato"
	)
	bateau.animated_sprite.frame = AriannaBateauProjectile.ATTACK_HIT_FRAME
	bateau._on_frame_changed()
	var bateau_impact := get_first_node_in_group("arianna_bateau_bite_impact")
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
	_expect(
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
	root.add_child(ko_bateau)
	whistle_target.combat.current_health = roundi(
		float(whistle_target.combat.max_health) * AriannaBateauProjectile.DAMAGE_RATIO
	)
	ko_bateau._apply_bite()
	await create_timer(AriannaBateauProjectile.HIT_STOP_DURATION + 0.02).timeout
	_expect(
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
	_expect(
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
	_expect(
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
	await physics_frame
	await physics_frame
	var walked_forward := (
		arianna.position.x > walk_start_x
		and arianna.animated_sprite.animation == &"walk"
		and arianna.animated_sprite.is_playing()
	)
	Input.action_release(arianna_forward_action)
	await physics_frame
	_expect(
		walked_forward and arianna.animated_sprite.animation == &"idle",
		"tenere avanti muove Arianna con walk e il rilascio ripristina idle"
	)
	var backwalk_start_x := arianna.position.x
	var arianna_back_action := arianna.get_input_action("move_left")
	Input.action_press(arianna_back_action)
	await physics_frame
	await physics_frame
	var walked_backward := (
		arianna.position.x < backwalk_start_x
		and arianna.animated_sprite.animation == &"backwalk"
		and arianna.animated_sprite.is_playing()
	)
	Input.action_release(arianna_back_action)
	await physics_frame
	_expect(
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
	_expect(
		light_punch_started
		and light_punch_hitbox_activated
		and light_punch_hitbox_deactivated
		and light_punch_reversed
		and not arianna.light_punch_active
		and arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle",
		"il pugno leggero attiva la hitbox sul braccio, torna indietro e conclude in idle"
	)
	_expect(
		arianna.z_index == arianna_default_z,
		"Arianna ripristina lo z-index al termine dell'attacco"
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
	_expect(
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
	_expect(
		arianna.current_state == Mangler.State.IDLE
		and arianna.animated_sprite.animation == &"idle"
		and arianna.can_move
		and not arianna.points_forward_super_active,
		"il reset libera Arianna da victory e dai flag delle mosse ancora attivi"
	)
	arianna.queue_free()
	await process_frame
	var live_arena := (load("res://scenes/MainArena.tscn") as PackedScene).instantiate()
	root.add_child(live_arena)
	await process_frame
	var live_arianna := live_arena.get_node("Player1") as Arianna
	await physics_frame
	await physics_frame
	var live_idle_frame := live_arianna.animated_sprite.sprite_frames.get_frame_texture(
		&"idle", 0
	) as AtlasTexture
	_expect(
		live_arianna != null
		and live_idle_frame != null
		and live_idle_frame.atlas == Arianna.ARIANNA_IDLE_SHEET,
		"lo stage mostra l'atlante idle di Arianna sul Player 1"
	)
	await physics_frame
	await physics_frame
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	await physics_frame
	await physics_frame
	var live_low_light_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_low_light - live_arianna.character_data.get_attack(&"light_punch").damage
		and live_arianna.opponent.current_state == Mangler.State.HIT
		and live_arianna.opponent.animated_sprite.animation == &"hurt_mid"
	)
	live_arianna._on_animation_finished()
	live_arianna.input_buffer.record_input_snapshot(0, 0, [], true)
	live_arianna._on_animation_finished()
	_expect(
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
	await physics_frame
	await physics_frame
	var live_medium_punch_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_medium_punch - live_arianna.character_data.get_attack(&"medium_punch").damage
		and live_arianna.opponent.current_state == Mangler.State.HIT
		and live_arianna.opponent.animated_sprite.animation == &"hurt_high"
	)
	live_arianna._on_animation_finished()
	live_arianna._on_animation_finished()
	_expect(
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
	await physics_frame
	await physics_frame
	var live_low_medium_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_low_medium - live_arianna.character_data.get_attack(&"medium_punch").damage
		and live_arianna.opponent.current_state == Mangler.State.HIT
		and live_arianna.opponent.animated_sprite.animation == &"hurt_mid"
		and live_arianna.attack_afterimage_spawn_count > afterimages_before_low_medium
	)
	live_arianna._on_animation_finished()
	live_arianna._on_animation_finished()
	_expect(
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
	await physics_frame
	await physics_frame
	var live_strong_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_strong - live_arianna.character_data.get_attack(&"heavy_punch").damage
		and live_arianna.opponent.current_state == Mangler.State.HIT
		and live_arianna.opponent.animated_sprite.animation == &"hurt_high"
		and strong_hitbox_shape.size == Vector2(110.0, 65.0)
		and live_arianna.attack_afterimage_spawn_count > afterimages_before_strong
	)
	live_arianna._on_animation_finished()
	_expect(
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
	await physics_frame
	await physics_frame
	var live_crouched_strong_hit := (
		live_arianna.opponent.combat.current_health
			== health_before_crouched_strong - live_arianna.character_data.get_attack(&"heavy_punch").damage
		and live_arianna.opponent.current_state == Mangler.State.HIT
		and live_arianna.opponent.animated_sprite.animation == &"hurt_high"
		and live_arianna.attack_afterimage_spawn_count > afterimages_before_crouched_strong
	)
	live_arianna._on_animation_finished()
	_expect(
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
	await physics_frame
	await physics_frame
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
	_expect(
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
	await physics_frame
	await physics_frame
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
	_expect(
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
	await physics_frame
	await physics_frame
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
	_expect(
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
	await physics_frame
	await physics_frame
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(
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
	_expect(live_light_punch_started, "nello stage Arianna esegue il light punch a terra")
	_expect(
		live_arianna.current_state in [Mangler.State.JUMP_STARTUP, Mangler.State.JUMPING]
		and live_arianna.animated_sprite.animation == &"jump",
		"nello stage Arianna avvia il salto"
	)
	_expect(
		facing_locked_during_rotation
		and not live_arianna.is_facing_right
		and live_arianna.animated_sprite.flip_h,
		"Arianna cambia facing solo dopo rotazione completa e sorpasso"
	)
	live_arena.queue_free()
	await process_frame


func _test_combat_flow() -> void:
	print("-- Arena, combattimento e UI")
	var arena_scene := load("res://scenes/MainArena.tscn") as PackedScene
	var arena: Node = arena_scene.instantiate()
	var configured_player1 := arena.get_node("Player1")
	var configured_player2 := arena.get_node("Player2")
	_expect(
		configured_player1 is Arianna
		and configured_player2 is Mangler
		and not (configured_player2 is Arianna),
		"MainArena usa Arianna come Player 1 e Mangler come Player 2"
	)
	_expect(
		configured_player1 is Fighter and configured_player2 is Fighter,
		"entrambi i personaggi rispettano il contratto Fighter"
	)
	# La suite storica sottostante collauda il moveset completo di Mangler.
	# Sostituisce solo nel fixture Player 1, senza modificare la scena di gioco.
	var player1_index := configured_player1.get_index()
	var player1_position: Vector2 = configured_player1.position
	arena.remove_child(configured_player1)
	configured_player1.free()
	var mangler_fixture := (load("res://scenes/Mangler.tscn") as PackedScene).instantiate()
	mangler_fixture.name = "Player1"
	mangler_fixture.position = player1_position
	arena.add_child(mangler_fixture)
	arena.move_child(mangler_fixture, player1_index)
	root.add_child(arena)

	var player1 := arena.get_node("Player1") as Mangler
	var player2 := arena.get_node("Player2") as Mangler
	var player1_bar := arena.get_node("CanvasLayer/UI/Player1Health") as ProgressBar
	var player2_bar := arena.get_node("CanvasLayer/UI/Player2Health") as ProgressBar
	var round_label := arena.get_node("CanvasLayer/UI/RoundLabel") as Label

	_expect(player1.animated_sprite != null, "Mangler usa AnimatedSprite2D")
	var initial_body_collision := player1.collision_shape.shape as RectangleShape2D
	_expect(
		initial_body_collision.size == Vector2(120.0, 240.0)
		and Mangler.CROUCH_COLLISION_SIZE == Vector2(130.0, 175.0),
		"la collisione fisica segue l'altezza ripristinata del nuovo idle"
	)
	_expect(
		player1.animated_sprite.scale == Mangler.REWORK_SPRITE_SCALE
		and player1.animated_sprite.position == Mangler.REWORK_SPRITE_POSITION,
		"il nuovo idle recupera altezza e linea dei piedi precedenti"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"idle"),
		"SpriteFrames contiene l'animazione idle"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"idle") == 49,
		"idle contiene tutti i 49 frame del foglio 7x7"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"idle"), 24.0),
		"idle è configurato a 24 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_animation_loop(&"idle"),
		"idle è configurato in loop"
	)
	_expect(
		player1.animated_sprite.animation == &"idle" and player1.animated_sprite.is_playing(),
		"idle parte automaticamente"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"light_punch_single")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"light_punch_single") == 18,
		"il pugno light usa 18 frame sul foglio unificato a 48 FPS"
	)
	var light_first := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"light_punch_single", 0)
		as AtlasTexture
	)
	var light_impact := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"light_punch_single", 11)
		as AtlasTexture
	)
	var light_last := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"light_punch_single", 17)
		as AtlasTexture
	)
	_expect(
		light_first.atlas.resource_path.ends_with("light-punch.png")
		and light_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and light_impact.region == Rect2(512.0, 1024.0, 512.0, 512.0)
		and light_last.region == Rect2(1024.0, 1536.0, 512.0, 512.0),
		"il light punch usa il foglio unificato: impatto al frame 12 (indice 11)"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"light_punch_single"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"light_punch_single"),
		"il light singolo usa 48 FPS non ciclici"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"medium_open_hand_slap")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"medium_open_hand_slap") == 42
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"medium_open_hand_slap"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"medium_open_hand_slap"),
		"lo schiaffo medio combina preparation, hit e to-idle in 42 frame a 48 FPS"
	)
	var medium_slap_peak := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"medium_open_hand_slap", 25)
		as AtlasTexture
	)
	var medium_slap_last := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"medium_open_hand_slap", 41)
		as AtlasTexture
	)
	_expect(
		medium_slap_peak.atlas.resource_path.ends_with("medium-punch-hit.png")
		and medium_slap_peak.region.position == Vector2(1536.0, 1536.0)
		and medium_slap_last.atlas.resource_path.ends_with("medium-punch-to-idle.png")
		and medium_slap_last.region.position == Vector2(1536.0, 1536.0),
		"lo schiaffo medio completa i fogli hit e to-idle"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"heavy_punch")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"heavy_punch") == 70
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"heavy_punch"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"heavy_punch"),
		"il pugno pesante alto usa 1-49, poi 41-21, a 48 FPS"
	)
	var heavy_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"heavy_punch", 0
	) as AtlasTexture
	var heavy_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"heavy_punch", 69
	) as AtlasTexture
	var heavy_recovery_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"heavy_punch", 49
	) as AtlasTexture
	_expect(
		heavy_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and heavy_recovery_first.region == Rect2(2560.0, 2560.0, 512.0, 512.0)
		and heavy_last.region == Rect2(3072.0, 1024.0, 512.0, 512.0)
		and heavy_first.atlas.resource_path.ends_with("moves/00-heavy_punch_high.png"),
		"il pugno pesante alto termina sul fotogramma sorgente 21 prima dell'idle"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"light_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"light_kick") == 29,
		"il light kick usa 15 frame in avanti (11-25) e 14 di ritorno, 48 FPS"
	)
	var light_kick_first := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"light_kick", 0)
		as AtlasTexture
	)
	var light_kick_peak := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"light_kick", 14)
		as AtlasTexture
	)
	_expect(
		light_kick_first.atlas.resource_path.ends_with("light_kick.png")
		and light_kick_first.region == Rect2(0.0, 1024.0, 512.0, 512.0)
		and light_kick_peak.region == Rect2(2048.0, 2048.0, 512.0, 512.0),
		"il light kick parte dal fotogramma 11 e raggiunge il picco al 25 (indice sorgente 24)"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"light_kick"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"light_kick"),
		"il light kick in piedi usa 48 FPS non ciclici"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_light_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_light_kick") == 31
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_light_kick"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"crouched_light_kick"),
		"il calcio leggero basso usa 16 frame avanti e 15 indietro a 48 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"jump_light_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"jump_light_kick") == 39
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"jump_light_kick"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"jump_light_kick"),
		"il light kick aereo usa 6-25 e torna indietro fino al 6 a 48 FPS"
	)
	var jump_kick_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_light_kick", 0
	) as AtlasTexture
	var jump_kick_active := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_light_kick", 15
	) as AtlasTexture
	var jump_kick_hold := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_light_kick", 19
	) as AtlasTexture
	var jump_kick_release := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_light_kick", 20
	) as AtlasTexture
	var jump_kick_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_light_kick", 38
	) as AtlasTexture
	_expect(
		jump_kick_first.region == Rect2(0.0, 512.0, 512.0, 512.0)
		and jump_kick_active.region == Rect2(0.0, 2048.0, 512.0, 512.0)
		and jump_kick_hold.region == Rect2(2048.0, 2048.0, 512.0, 512.0)
		and jump_kick_release.region == Rect2(1536.0, 2048.0, 512.0, 512.0)
		and jump_kick_last.region == jump_kick_first.region,
		"il light kick aereo mappa i fotogrammi 6, 21, 25, 24 e 6"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"jump_light_punch")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"jump_light_punch") == 34
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"jump_light_punch"), 48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"jump_light_punch"),
		"il light punch aereo usa 6-20 e la recovery 24-6 a 48 FPS"
	)
	var jump_light_punch_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_light_punch", 0
	) as AtlasTexture
	var jump_light_punch_impact := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_light_punch", 14
	) as AtlasTexture
	var jump_light_punch_release := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_light_punch", 15
	) as AtlasTexture
	var jump_light_punch_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_light_punch", 33
	) as AtlasTexture
	_expect(
		jump_light_punch_first.region == Rect2(0.0, 512.0, 512.0, 512.0)
		and jump_light_punch_impact.region == Rect2(2048.0, 1536.0, 512.0, 512.0)
		and jump_light_punch_release.region == Rect2(1536.0, 2048.0, 512.0, 512.0)
		and jump_light_punch_last.region == jump_light_punch_first.region,
		"il light punch aereo mappa i fotogrammi sorgente 6, 20, 24 e 6"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"jump_heavy_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"jump_heavy_kick") == 39
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"jump_heavy_kick"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"jump_heavy_kick"),
		"il calcio potente aereo usa la sequenza 6-25-6 a 48 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"special_720_punch")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"special_720_punch") == 49
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"special_720_punch"), 48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"special_720_punch"),
		"720 Punch usa tutti i 49 fotogrammi a 48 FPS senza loop"
	)
	var special_720_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"special_720_punch", 0
	) as AtlasTexture
	var special_720_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"special_720_punch", 48
	) as AtlasTexture
	_expect(
		special_720_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and special_720_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0)
		and special_720_first.atlas.resource_path.ends_with("specials/720_punch.png"),
		"720 Punch mappa integralmente l'atlante 7x7"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"special_sonic_boom")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"special_sonic_boom") == 49
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"special_sonic_boom"), 48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"special_sonic_boom"),
		"il lancio Sonic Boom usa 49 fotogrammi a 48 FPS senza loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"grab_tentative")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"grab_tentative") == 25
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"grab_tentative"), 60.0
		)
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"grab_tentative_recovery"), 60.0
		)
		and is_equal_approx(
			player1.grab_front_sprite.sprite_frames.get_animation_speed(&"grab_tentative_front"), 60.0
		)
		and player1.animated_sprite.sprite_frames.get_frame_count(&"grab_tentative_recovery") == 24,
		"il tentativo di presa usa 25 frame a 60 FPS e recupera dai frame 24-1"
	)
	var grab_rear_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"grab_tentative", 24)
		as AtlasTexture
	)
	var grab_front_frame := (
		player1.grab_front_sprite.sprite_frames.get_frame_texture(&"grab_tentative_front", 24)
		as AtlasTexture
	)
	_expect(
		grab_rear_frame != null
		and grab_rear_frame.atlas == Mangler.GRAB_TENTATIVE_REAR_SHEET
		and grab_front_frame != null
		and grab_front_frame.atlas == Mangler.GRAB_TENTATIVE_FRONT_SHEET
		and player1.grab_front_sprite.sprite_frames.get_frame_count(&"grab_tentative_front") == 25,
		"il tentativo di presa sincronizza i fogli rear e front"
	)
	var combined_grab_last_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"grab_headbow_combined", 28)
		as AtlasTexture
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"grab_headbow_combined")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"grab_headbow_combined") == 29
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"grab_headbow_combined"), 48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"grab_headbow_combined")
		and Mangler.GRAB_HEADBOW_EXPLOSION_FRAME == 18
		and combined_grab_last_frame != null
		and combined_grab_last_frame.atlas == Mangler.GRAB_HEADBOW_COMBINED_SHEET,
		"la presa diretta usa i frame 1-29 a 48 FPS e attiva l'esplosione al frame 19"
	)
	var super_start_last_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"super_start", 24)
		as AtlasTexture
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"super_start")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"super_start") == 25
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"super_start"), 48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"super_start")
		and super_start_last_frame != null
		and super_start_last_frame.atlas == Mangler.SUPER_START_SHEET,
		"super_start usa tutti i 25 frame a 48 FPS senza loop"
	)
	var super_rotate_last_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"super_rotate_run", 24)
		as AtlasTexture
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"super_rotate_run")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"super_rotate_run") == 25
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"super_rotate_run"), 48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"super_rotate_run")
		and Mangler.SUPER_ROTATE_RUN_MOVE_FRAME == 19
		and super_rotate_last_frame != null
		and super_rotate_last_frame.atlas == Mangler.SUPER_ROTATE_RUN_SHEET,
		"super_rotate_run usa 25 frame a 48 FPS e avanza dal frame 20"
	)
	var super_run_last_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"super_run_only", 23)
		as AtlasTexture
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"super_run_only") == 24
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"super_run_only"), 48.0
		)
		and player1.animated_sprite.sprite_frames.get_animation_loop(&"super_run_only")
		and Mangler.SUPER_ROTATE_RUN_STOP_DISTANCE >= 120.0
		and super_run_last_frame != null
		and super_run_last_frame.atlas == Mangler.SUPER_RUN_ONLY_SHEET,
		"super_run_only usa 24 frame a 48 FPS in loop e rileva il contatto fisico"
	)
	var super_drum_last_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"super_drum_roll", 23)
		as AtlasTexture
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"super_drum_roll") == 24
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"super_drum_roll"), 48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"super_drum_roll")
		and Mangler.SUPER_DRUM_ROLL_TOTAL_LOOPS == 2
		and super_drum_last_frame != null
		and super_drum_last_frame.atlas == Mangler.SUPER_DRUM_ROLL_SHEET,
		"super_drum_roll usa 24 frame a 48 FPS e viene contato per due esecuzioni"
	)
	var super_drum_hurt_first_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"super_drum_hurt", 0)
		as AtlasTexture
	)
	var super_drum_hurt_last_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"super_drum_hurt", 9)
		as AtlasTexture
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"super_drum_hurt") == 10
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"super_drum_hurt"), 48.0
		)
		and player1.animated_sprite.sprite_frames.get_animation_loop(&"super_drum_hurt")
		and super_drum_hurt_first_frame.region.position == Vector2(1536.0, 0.0)
		and super_drum_hurt_last_frame.region.position == Vector2(0.0, 1536.0),
		"la reazione del rullo usa hurt-high dal fotogramma 4 al 13 in loop"
	)
	var super_knockdown_first_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"super_drum_knockdown", 0)
		as AtlasTexture
	)
	var super_knockdown_last_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"super_drum_knockdown", 14)
		as AtlasTexture
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"super_drum_knockdown") == 15
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"super_drum_knockdown"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(
			&"super_drum_knockdown"
		)
		and super_knockdown_first_frame
		== player1.animated_sprite.sprite_frames.get_frame_texture(&"ko", 10)
		and super_knockdown_last_frame
		== player1.animated_sprite.sprite_frames.get_frame_texture(&"ko", 24),
		"la caduta finale usa i fotogrammi 11-25 di ko.png a 24 FPS"
	)
	var headbutt_rear_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"grab_headbutt", 16)
		as AtlasTexture
	)
	var headbutt_front_frame := (
		player1.grab_front_sprite.sprite_frames.get_frame_texture(&"grab_headbutt_front", 16)
		as AtlasTexture
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"grab_headbutt")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"grab_headbutt") == 25
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"grab_headbutt"), 25.0
		)
		and headbutt_rear_frame != null
		and headbutt_rear_frame.atlas == Mangler.GRAB_HEADBUTT_REAR_SHEET
		and headbutt_front_frame != null
		and headbutt_front_frame.atlas == Mangler.GRAB_HEADBUTT_FRONT_SHEET
		and player1.grab_front_sprite.sprite_frames.get_frame_count(&"grab_headbutt_front") == 25
		and (player1.grab_headbutt_hitbox_shape.shape as RectangleShape2D).size == Vector2(95.0, 70.0)
		and player1.grab_headbutt_hitbox_shape.position == Vector2(76.0, -230.0),
		"la testata usa 25 frame a 25 FPS e una hitbox corta davanti al volto"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"grabbed")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"grabbed") == 32
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"grabbed"), 24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"grabbed"),
		"la vittima usa grabbed 10-25 e 25-10 a 24 FPS"
	)
	var grabbed_first_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"grabbed", 0) as AtlasTexture
	)
	var grabbed_last_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"grabbed", 31) as AtlasTexture
	)
	var grabbed_turnaround_frame := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"grabbed", 16) as AtlasTexture
	)
	_expect(
		grabbed_first_frame.region == Rect2(2048.0, 512.0, 512.0, 512.0)
		and grabbed_turnaround_frame.region == Rect2(2048.0, 2048.0, 512.0, 512.0)
		and grabbed_last_frame.region == Rect2(2048.0, 512.0, 512.0, 512.0),
		"grabbed mappa esattamente 10-25-10 duplicando la posa di inversione"
	)
	var sonic_boom_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"special_sonic_boom", 0
	) as AtlasTexture
	var sonic_boom_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"special_sonic_boom", 48
	) as AtlasTexture
	_expect(
		sonic_boom_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and sonic_boom_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0)
		and sonic_boom_first.atlas.resource_path.ends_with("specials/sonic-boom.png"),
		"il lancio Sonic Boom mappa integralmente l'atlante 7x7"
	)
	var jump_heavy_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_heavy_kick", 0
	) as AtlasTexture
	var jump_heavy_active := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_heavy_kick", 15
	) as AtlasTexture
	var jump_heavy_hold := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_heavy_kick", 19
	) as AtlasTexture
	var jump_heavy_release := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_heavy_kick", 20
	) as AtlasTexture
	var jump_heavy_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_heavy_kick", 38
	) as AtlasTexture
	_expect(
		jump_heavy_first.region == Rect2(0.0, 512.0, 512.0, 512.0)
		and jump_heavy_active.region == Rect2(0.0, 2048.0, 512.0, 512.0)
		and jump_heavy_hold.region == Rect2(2048.0, 2048.0, 512.0, 512.0)
		and jump_heavy_release.region == Rect2(1536.0, 2048.0, 512.0, 512.0)
		and jump_heavy_last.region == jump_heavy_first.region
		and jump_heavy_first.atlas.resource_path.ends_with("strong_jump-kick.png"),
		"il calcio potente aereo mappa i fotogrammi sorgente 6, 21, 25, 24 e 6"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"jump_medium_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"jump_medium_kick") == 39
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"jump_medium_kick"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"jump_medium_kick"),
		"il calcio medio aereo usa 6-25 e torna indietro fino al 6 a 48 FPS"
	)
	var jump_medium_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_kick", 0
	) as AtlasTexture
	var jump_medium_active := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_kick", 15
	) as AtlasTexture
	var jump_medium_hold := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_kick", 19
	) as AtlasTexture
	var jump_medium_release := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_kick", 20
	) as AtlasTexture
	var jump_medium_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_kick", 38
	) as AtlasTexture
	_expect(
		jump_medium_first.region == Rect2(0.0, 512.0, 512.0, 512.0)
		and jump_medium_active.region == Rect2(0.0, 2048.0, 512.0, 512.0)
		and jump_medium_hold.region == Rect2(2048.0, 2048.0, 512.0, 512.0)
		and jump_medium_release.region == Rect2(1536.0, 2048.0, 512.0, 512.0)
		and jump_medium_last.region == jump_medium_first.region
		and jump_medium_first.atlas.resource_path.ends_with("jump_mnedium_kick.png"),
		"il calcio medio aereo mappa i fotogrammi 6, 21, 25, 24 e 6"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"jump_medium_punch")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"jump_medium_punch") == 34
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"jump_medium_punch"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"jump_medium_punch"),
		"il pugno medio aereo usa 6-20 e la recovery 24-6 a 48 FPS"
	)
	var jump_medium_punch_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_punch", 0
	) as AtlasTexture
	var jump_medium_punch_active := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_punch", 12
	) as AtlasTexture
	var jump_medium_punch_hold := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_punch", 14
	) as AtlasTexture
	var jump_medium_punch_release := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_punch", 15
	) as AtlasTexture
	var jump_medium_punch_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_punch", 33
	) as AtlasTexture
	_expect(
		jump_medium_punch_first.region == Rect2(0.0, 512.0, 512.0, 512.0)
		and jump_medium_punch_active.region == Rect2(1024.0, 1536.0, 512.0, 512.0)
		and jump_medium_punch_hold.region == Rect2(2048.0, 1536.0, 512.0, 512.0)
		and jump_medium_punch_release.region == Rect2(1536.0, 2048.0, 512.0, 512.0)
		and jump_medium_punch_last.region == jump_medium_punch_first.region
		and jump_medium_punch_first.atlas.resource_path.ends_with("jumping-medium-punch.png"),
		"il pugno medio aereo mappa i fotogrammi 6, 18, 20, 24 e 6"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"jump_heavy_punch")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"jump_heavy_punch") == 31
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"jump_heavy_punch"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"jump_heavy_punch"),
		"il pugno potente aereo usa 16 frame avanti e 15 indietro a 48 FPS"
	)
	var jump_heavy_punch_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_heavy_punch", 0
	) as AtlasTexture
	var jump_heavy_punch_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_heavy_punch", 15
	) as AtlasTexture
	_expect(
		jump_heavy_punch_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and jump_heavy_punch_last.region == Rect2(1536.0, 1536.0, 512.0, 512.0)
		and jump_heavy_punch_first.atlas.resource_path.ends_with("heavy_punch_jump.png"),
		"il pugno potente aereo riproduce heavy_punch_jump dal primo all'ultimo frame"
	)
	var all_attacks_have_motion_effects := true
	for attack_animation in Mangler.ATTACK_EFFECT_ANIMATIONS:
		if not player1.has_attack_motion_effect(attack_animation):
			all_attacks_have_motion_effects = false
			break
	_expect(
		all_attacks_have_motion_effects,
		"ogni animazione d'attacco di Mangler ha un profilo di scia dedicato"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"medium_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"medium_kick") == 55,
		"il medium kick usa 28 frame avanti (15-42) e 27 di ritorno, 24 FPS"
	)
	var mk_first := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"medium_kick", 0)
		as AtlasTexture
	)
	var mk_peak := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"medium_kick", 26)
		as AtlasTexture
	)
	_expect(
		mk_first.atlas.resource_path.ends_with("medium_kick.png")
		and mk_first.region == Rect2(1024.0, 1024.0, 512.0, 512.0)
		and mk_peak.region == Rect2(2048.0, 3072.0, 512.0, 512.0),
		"il medium kick parte dal fotogramma 15 e raggiunge il picco al 41 (indice sorgente 40)"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"medium_kick"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"medium_kick"),
		"il medium kick usa 48 FPS non ciclici"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"heavy_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"heavy_kick") == 55
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"heavy_kick"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"heavy_kick"),
		"lo strong kick usa 28 frame avanti (22-49) e 27 di ritorno, 48 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_heavy_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_heavy_kick") == 49
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_heavy_kick"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"crouched_heavy_kick"),
		"la spazzata rotante usa tutti i 49 frame, non ciclici, a 48 FPS"
	)
	var sweep_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"crouched_heavy_kick", 0
	) as AtlasTexture
	var sweep_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"crouched_heavy_kick", 48
	) as AtlasTexture
	_expect(
		sweep_first != null
		and sweep_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and sweep_last != null
		and sweep_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0),
		"la spazzata usa il foglio completo dal fotogramma 1 al 49"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_medium_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_medium_kick") == 49
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_medium_kick"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"crouched_medium_kick"),
		"il calcio medio basso usa 25 frame avanti e 24 indietro a 48 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_power_punch")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_power_punch") == 49,
		"il pugno potente abbassato usa 25 frame avanti e 24 indietro"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_power_punch"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"crouched_power_punch"),
		"il pugno potente abbassato è non ciclico a 48 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_medium_punch")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_medium_punch") == 23
		and player1.animated_sprite.sprite_frames.has_animation(&"crouched_medium_punch_crouched")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_medium_punch_crouched") == 19,
		"il medio basso usa frame 9-23 avanti, ritorno fino al 15 (23 frame)"
	)
	var crouched_medium_first := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"crouched_medium_punch_crouched", 0)
		as AtlasTexture
	)
	_expect(
		crouched_medium_first.region.position == Vector2(1024.0, 1024.0)
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_medium_punch"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"crouched_medium_punch"),
		"dal crouch il medio basso parte dal frame 13 del foglio, 48 FPS non ciclici"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_punch")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_punch") == 21,
		"il pugno basso usa step=2 fino al frame 20, poi torna al frame 1"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_punch_crouched")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_punch_crouched") == 15,
		"il pugno basso da crouch usa 9-12 e torna fino al primo"
	)
	var crouched_sheet_frames := player1.animated_sprite.sprite_frames
	var crouched_peak := crouched_sheet_frames.get_frame_texture(&"crouched_punch", 10) as AtlasTexture
	var crouched_reverse := crouched_sheet_frames.get_frame_texture(&"crouched_punch", 11) as AtlasTexture
	var crouched_last := crouched_sheet_frames.get_frame_texture(&"crouched_punch", 20) as AtlasTexture
	_expect(
		crouched_peak.region == Rect2(2048.0, 1536.0, 512.0, 512.0)
		and crouched_reverse.region == Rect2(1536.0, 1536.0, 512.0, 512.0)
		and crouched_last.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and crouched_peak.atlas.resource_path.ends_with("crouched-light-punch.png"),
		"crouched_punch raggiunge il frame 20 (sorgente 19), inverte e termina sul frame 1"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_punch"),
			48.0
		)
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_punch_crouched"),
			48.0
		),
		"entrambe le varianti del pugno basso usano 48 FPS"
	)

	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"walk"),
		"SpriteFrames contiene l'animazione walk"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"walk") == 48,
		"walk contiene i 48 frame non vuoti del foglio 7x7"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"walk"), 24.0),
		"walk è configurato a 24 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_animation_loop(&"walk"),
		"walk è configurato in loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"backwalk"),
		"SpriteFrames contiene l'animazione backwalk"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"backwalk") == 26,
		"backwalk usa i primi 26 frame del nuovo foglio"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"backwalk"), 24.0),
		"backwalk è configurato a 24 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_animation_loop(&"backwalk"),
		"backwalk è configurato in loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"run"),
		"SpriteFrames contiene l'animazione run"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"run") == 46,
		"run contiene i 46 frame non vuoti del nuovo foglio 7x7"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"run"), 24.0),
		"run è configurato a 24 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_animation_loop(&"run"),
		"run è configurato in loop"
	)
	var run_first := player1.animated_sprite.sprite_frames.get_frame_texture(&"run", 0) as AtlasTexture
	var run_last := player1.animated_sprite.sprite_frames.get_frame_texture(&"run", 45) as AtlasTexture
	_expect(
		run_first != null
		and run_last != null
		and run_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and run_last.region == Rect2(1536.0, 3072.0, 512.0, 512.0)
		and run_first.atlas.resource_path.ends_with("05-run.png"),
		"run usa 05-run dal primo al quarantaseiesimo fotogramma"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouch"),
		"SpriteFrames contiene l'animazione crouch"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"crouch") == 25,
		"crouch contiene tutti i 25 frame del nuovo foglio"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"crouch"), 48.0),
		"crouch è configurato a 48 FPS"
	)
	_expect(
		not player1.animated_sprite.sprite_frames.get_animation_loop(&"crouch"),
		"crouch non è configurato in loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"dodge"),
		"SpriteFrames contiene l'animazione dodge"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"dodge") == 25,
		"dodge contiene le 25 celle da 512"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"dodge"), 48.0),
		"dodge è configurato a 48 FPS"
	)
	_expect(
		not player1.animated_sprite.sprite_frames.get_animation_loop(&"dodge"),
		"dodge non è configurato in loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"jump"),
		"SpriteFrames contiene l'animazione jump"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"jump") == 25,
		"jump contiene tutti i 25 frame del nuovo foglio 04-jump"
	)
	var jump_first := player1.animated_sprite.sprite_frames.get_frame_texture(&"jump", 0) as AtlasTexture
	var jump_last := player1.animated_sprite.sprite_frames.get_frame_texture(&"jump", 24) as AtlasTexture
	_expect(
		jump_first != null
		and jump_last != null
		and jump_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and jump_last.region == Rect2(2048.0, 2048.0, 512.0, 512.0)
		and jump_first.atlas.resource_path.ends_with("04-jump.png"),
		"jump usa il nuovo atlante 04-jump dal primo all'ultimo fotogramma"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"jump"), 24.0),
		"la preparazione del jump è configurata a 24 FPS"
	)
	_expect(
		not player1.animated_sprite.sprite_frames.get_animation_loop(&"jump"),
		"jump non è configurato in loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"hurt_mid"),
		"SpriteFrames contiene la reazione hurt_mid"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"hurt_mid") == 16,
		"hurt_mid contiene le 16 celle da 512"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"hurt_mid"), 24.0),
		"hurt_mid è configurato a 24 FPS"
	)
	_expect(
		not player1.animated_sprite.sprite_frames.get_animation_loop(&"hurt_mid"),
		"hurt_mid non è configurato in loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"hurt_high"),
		"SpriteFrames contiene la reazione hurt_high"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"hurt_high") == 16,
		"hurt_high contiene le 16 celle da 512"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"hurt_high"), 24.0),
		"hurt_high è configurato a 24 FPS"
	)
	_expect(
		not player1.animated_sprite.sprite_frames.get_animation_loop(&"hurt_high"),
		"hurt_high non è configurato in loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"hurt_low"),
		"SpriteFrames contiene la reazione hurt_low"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"hurt_low") == 10,
		"hurt_low usa le celle 7-16 dello spritesheet"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"hurt_low"), 24.0),
		"hurt_low è configurato a 24 FPS"
	)
	_expect(
		not player1.animated_sprite.sprite_frames.get_animation_loop(&"hurt_low"),
		"hurt_low non è configurato in loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"hurted_in_jump")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"hurted_in_jump") == 25
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"hurted_in_jump"), 24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"hurted_in_jump"),
		"hurted_in_jump usa 25 frame non ciclici a 24 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"sweep_knockdown"),
		"SpriteFrames contiene sweep_knockdown"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"sweep_knockdown") == 49,
		"sweep_knockdown contiene le 49 celle da 512"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"sweep_knockdown"),
			48.0
		),
		"sweep_knockdown è configurato a 48 FPS"
	)
	_expect(
		not player1.animated_sprite.sprite_frames.get_animation_loop(&"sweep_knockdown"),
		"sweep_knockdown non è configurato in loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"knockdown_recovery"),
		"SpriteFrames contiene knockdown_recovery"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"knockdown_recovery") == 16,
		"knockdown_recovery contiene le 16 celle da 512"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"knockdown_recovery"),
			24.0
		),
		"knockdown_recovery è configurato a 24 FPS"
	)
	_expect(
		not player1.animated_sprite.sprite_frames.get_animation_loop(&"knockdown_recovery"),
		"knockdown_recovery non è configurato in loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"block_mid"),
		"SpriteFrames contiene block_mid"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"block_mid") == 8,
		"block_mid usa tutti gli 8 fotogrammi del foglio aggiornato"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"block_mid"), 24.0),
		"block_mid è configurato a 24 FPS"
	)
	_expect(
		not player1.animated_sprite.sprite_frames.get_animation_loop(&"block_mid"),
		"block_mid non è configurato in loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"block_mid_recovery")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"block_mid_recovery") == 7,
		"block_mid_recovery torna indietro dai fotogrammi 7-1"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"block_mid_recovery"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"block_mid_recovery"),
		"block_mid_recovery è non ciclica a 24 FPS"
	)
	var block_mid_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"block_mid", 0
	) as AtlasTexture
	var block_mid_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"block_mid", 7
	) as AtlasTexture
	var block_mid_recovery_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"block_mid_recovery", 0
	) as AtlasTexture
	var block_mid_recovery_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"block_mid_recovery", 6
	) as AtlasTexture
	_expect(
		block_mid_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and block_mid_last.region == Rect2(1024.0, 512.0, 512.0, 512.0)
		and block_mid_recovery_first.region == Rect2(512.0, 512.0, 512.0, 512.0)
		and block_mid_recovery_last.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and block_mid_first.atlas.resource_path.ends_with("07-block-middle.png"),
		"block_mid usa 07-block-middle in avanti e poi al contrario"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"block_high")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"block_high") == 14,
		"block_high usa i fotogrammi 9-22 del nuovo foglio"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"block_high"), 48.0)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"block_high"),
		"block_high è non ciclica a 48 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"block_high_recovery")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"block_high_recovery") == 21,
		"block_high_recovery torna indietro dai fotogrammi 21-1"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"block_high_recovery"),
			48.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"block_high_recovery"),
		"block_high_recovery è non ciclica a 48 FPS"
	)
	var block_high_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"block_high", 0
	) as AtlasTexture
	var block_high_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"block_high", 13
	) as AtlasTexture
	var block_high_recovery_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"block_high_recovery", 0
	) as AtlasTexture
	var block_high_recovery_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"block_high_recovery", 20
	) as AtlasTexture
	_expect(
		block_high_first.region == Rect2(1536.0, 512.0, 512.0, 512.0)
		and block_high_last.region == Rect2(512.0, 2048.0, 512.0, 512.0)
		and block_high_recovery_first.region == Rect2(0.0, 2048.0, 512.0, 512.0)
		and block_high_recovery_last.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and block_high_first.atlas.resource_path.ends_with("06-block-high.png"),
		"block_high usa 06-block-high dal frame 9 e poi torna al primo"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"block_low")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"block_low") == 11,
		"block_low usa gli 11 fotogrammi della nuova sequenza crouched"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"block_low_crouched")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"block_low_crouched") == 11,
		"block_low da crouch usa la nuova sequenza completa"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"block_low_recovery")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"block_low_recovery") == 10,
		"block_low_recovery torna indietro dai fotogrammi 10-1"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"block_low"), 24.0)
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"block_low_crouched"),
			24.0
		)
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"block_low_recovery"),
			24.0
		),
		"le varianti block_low sono configurate a 24 FPS"
	)
	var block_low_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"block_low_crouched", 0
	) as AtlasTexture
	var block_low_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"block_low_crouched", 10
	) as AtlasTexture
	var block_low_recovery_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"block_low_recovery", 0
	) as AtlasTexture
	var block_low_recovery_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"block_low_recovery", 9
	) as AtlasTexture
	_expect(
		block_low_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and block_low_last.region == Rect2(0.0, 1024.0, 512.0, 512.0)
		and block_low_recovery_first.region == Rect2(2048.0, 512.0, 512.0, 512.0)
		and block_low_recovery_last.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and block_low_first.atlas.resource_path.ends_with("08-block-low.png"),
		"block_low usa 08-block-low in avanti e poi al contrario"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"ko"),
		"SpriteFrames contiene ko"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"ko") == 25,
		"ko contiene le 25 celle da 512"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"ko"), 24.0),
		"ko è configurato a 24 FPS"
	)
	_expect(
		not player1.animated_sprite.sprite_frames.get_animation_loop(&"ko"),
		"ko non è configurato in loop"
	)
	player1.is_facing_right = true
	player1.velocity.x = 100.0
	player1.change_state(Mangler.State.WALKING)
	_expect(player1.animated_sprite.animation == &"walk", "avanzando verso destra riproduce walk")
	player1.velocity.x = player1.character_data.run_speed
	player1.change_state(Mangler.State.RUNNING)
	_expect(player1.animated_sprite.animation == &"run", "RUNNING riproduce run")
	player1.velocity.x = -100.0
	player1.change_state(Mangler.State.WALKING)
	_expect(player1.animated_sprite.animation == &"backwalk", "arretrando verso sinistra riproduce backwalk")
	player1.is_facing_right = false
	player1.velocity.x = -100.0
	player1.change_state(Mangler.State.WALKING)
	_expect(player1.animated_sprite.animation == &"walk", "avanzando verso sinistra riproduce walk")
	player1.velocity.x = 100.0
	player1.change_state(Mangler.State.WALKING)
	_expect(player1.animated_sprite.animation == &"backwalk", "arretrando verso destra riproduce backwalk")
	player1.is_facing_right = true
	player1.velocity = Vector2.ZERO
	player1.change_state(Mangler.State.IDLE)
	_expect(player1.animated_sprite.animation == &"idle", "IDLE ripristina idle")

	_expect(player1_bar.value == 100.0, "vita iniziale Player 1 visualizzata")
	_expect(player2_bar.value == 100.0, "vita iniziale Player 2 visualizzata")
	await create_timer(3.1).timeout
	_expect(bool(arena.get("round_active")), "training attivo dopo il countdown")
	_expect(
		not player1.animated_sprite.flip_h and player2.animated_sprite.flip_h,
		"AnimatedSprite2D segue l'orientamento verso l'avversario"
	)
	Input.action_press(&"p1_move_right")
	await physics_frame
	await process_frame
	Input.action_release(&"p1_move_right")
	await physics_frame
	await process_frame
	Input.action_press(&"p1_move_right")
	await physics_frame
	await process_frame
	_expect(player1.current_state == Mangler.State.RUNNING, "il doppio tap avanti avvia RUNNING")
	_expect(
		is_equal_approx(player1.velocity.x, player1.character_data.run_speed),
		"RUNNING usa la velocità di corsa"
	)
	await physics_frame
	await process_frame
	_expect(player1.current_state == Mangler.State.RUNNING, "mantenere il secondo avanti continua la corsa")
	Input.action_release(&"p1_move_right")
	await physics_frame
	await process_frame
	_expect(player1.current_state == Mangler.State.IDLE, "rilasciare avanti termina la corsa")

	player1.input_buffer.clear()
	player1.input_buffer.record_input_snapshot(-1, 0, [], player1.is_facing_right)
	player1.handle_input()
	player1.input_buffer.record_input_snapshot(0, 0, [], player1.is_facing_right)
	player1.handle_input()
	player1.input_buffer.record_input_snapshot(-1, 0, [], player1.is_facing_right)
	player1.handle_input()
	_expect(
		player1.current_state == Mangler.State.BACK_HOP_STARTUP,
		"il doppio tap indietro avvia la preparazione di BACK_HOP"
	)
	_expect(
		player1.velocity == Vector2.ZERO and player1.animated_sprite.animation == &"dodge",
		"la preparazione riproduce dodge restando a terra"
	)
	player1.animated_sprite.frame = Mangler.BACK_HOP_TAKEOFF_FRAME - 1
	player1._on_animation_frame_changed()
	_expect(
		player1.current_state == Mangler.State.BACK_HOP_STARTUP and player1.velocity == Vector2.ZERO,
		"dodge resta a terra fino al frame precedente allo stacco"
	)
	player1.animated_sprite.frame = Mangler.BACK_HOP_TAKEOFF_FRAME
	player1._on_animation_frame_changed()
	_expect(player1.current_state == Mangler.State.BACK_HOP, "il frame di stacco avvia BACK_HOP")
	_expect(
		is_equal_approx(player1.velocity.x, -Mangler.BACK_HOP_HORIZONTAL_SPEED)
		and is_equal_approx(player1.velocity.y, Mangler.BACK_HOP_VERTICAL_SPEED),
		"BACK_HOP applica un impulso breve indietro e verso l'alto"
	)
	_expect(not player1.can_move, "BACK_HOP blocca il controllo fino all'atterraggio")
	_expect(player1.animated_sprite.animation == &"dodge", "BACK_HOP continua dodge senza riavviarlo")
	player1.velocity = Vector2.ZERO
	player1.change_state(Mangler.State.IDLE)

	Input.action_press(&"p1_crouch")
	await physics_frame
	await process_frame
	_expect(player1.current_state == Mangler.State.CROUCHING, "tenere giù avvia CROUCHING")
	_expect(player1.animated_sprite.animation == &"crouch", "CROUCHING riproduce crouch")
	await create_timer(0.75).timeout
	_expect(
		player1.current_state == Mangler.State.CROUCHING
		and player1.animated_sprite.frame == 24
		and not player1.animated_sprite.is_playing(),
		"crouch mantiene l'ultimo frame mentre giù resta premuto"
	)
	var crouch_collision := player1.collision_shape.shape as RectangleShape2D
	var crouch_head := player1.head_hurtbox.shape as RectangleShape2D
	var crouch_torso := player1.torso_hurtbox.shape as RectangleShape2D
	var crouch_legs := player1.legs_hurtbox.shape as RectangleShape2D
	_expect(
		crouch_collision.size == Mangler.CROUCH_COLLISION_SIZE
		and player1.collision_shape.position == Mangler.CROUCH_COLLISION_POSITION,
		"CROUCHING riduce e abbassa la collisione fisica"
	)
	_expect(
		crouch_head.size == Mangler.CROUCH_HEAD_SIZE
		and player1.head_hurtbox.position == Mangler.CROUCH_HEAD_POSITION,
		"CROUCHING abbassa la hurtbox della testa"
	)
	_expect(
		crouch_torso.size == Mangler.CROUCH_TORSO_SIZE
		and player1.torso_hurtbox.position == Mangler.CROUCH_TORSO_POSITION,
		"CROUCHING riduce e abbassa la hurtbox del torso"
	)
	_expect(
		crouch_legs.size == Mangler.CROUCH_LEGS_SIZE
		and player1.legs_hurtbox.position == Mangler.CROUCH_LEGS_POSITION,
		"CROUCHING riduce la hurtbox delle gambe"
	)
	Input.action_release(&"p1_crouch")
	await physics_frame
	await process_frame
	_expect(player1.current_state == Mangler.State.STANDING_UP, "rilasciare giù avvia STANDING_UP")
	_expect(player1.animated_sprite.get_playing_speed() < 0.0, "STANDING_UP riproduce crouch al contrario")
	await create_timer(0.75).timeout
	_expect(player1.current_state == Mangler.State.IDLE, "la rialzata termina in IDLE")
	_expect(
		crouch_collision.size == Mangler.STANDING_COLLISION_SIZE
		and player1.collision_shape.position == Mangler.STANDING_COLLISION_POSITION,
		"la rialzata ripristina la collisione fisica normale"
	)
	_expect(
		crouch_head.size == Mangler.STANDING_HEAD_SIZE
		and crouch_torso.size == Mangler.STANDING_TORSO_SIZE
		and crouch_legs.size == Mangler.STANDING_LEGS_SIZE,
		"la rialzata ripristina tutte le hurtbox normali"
	)

	player1.start_jump(0.0)
	_expect(
		player1.current_state == Mangler.State.JUMP_STARTUP
		and player1.velocity == Vector2.ZERO,
		"UP avvia prima la preparazione a terra"
	)
	_expect(
		player1.animated_sprite.animation == &"jump"
		and player1.animated_sprite.is_playing()
		and player1.animated_sprite.scale == Mangler.REWORK_SPRITE_SCALE
		and player1.animated_sprite.position == Mangler.REWORK_SPRITE_POSITION,
		"JUMP_STARTUP riproduce il nuovo jump con scala e allineamento rework"
	)
	player1.animated_sprite.frame = Mangler.JUMP_TAKEOFF_FRAME - 1
	player1._on_animation_frame_changed()
	_expect(
		player1.current_state == Mangler.State.JUMP_STARTUP
		and player1.velocity == Vector2.ZERO,
		"i primi cinque frame restano a terra"
	)
	player1.animated_sprite.frame = Mangler.JUMP_TAKEOFF_FRAME
	player1._on_animation_frame_changed()
	_expect(
		player1.current_state == Mangler.State.JUMPING
		and is_zero_approx(player1.velocity.x)
		and is_equal_approx(
			player1.velocity.y,
			player1.character_data.jump_velocity * Mangler.JUMP_SPEED_MULTIPLIER
		)
		and player1.animated_sprite.frame == Mangler.JUMP_TAKEOFF_FRAME
		and player1.animated_sprite.is_playing(),
		"il sesto frame avvia il salto senza riavviare l'animazione"
	)
	player1.update_state()
	_expect(
		player1.current_state == Mangler.State.JUMPING
		and player1.animated_sprite.frame == Mangler.JUMP_TAKEOFF_FRAME
		and player1.animated_sprite.is_playing(),
		"il primo frame di salita non viene scambiato per un atterraggio"
	)
	player1.velocity = Vector2.ZERO
	player1.change_state(Mangler.State.IDLE)
	player1.start_jump(1.0)
	player1.animated_sprite.frame = Mangler.JUMP_TAKEOFF_FRAME
	player1._on_animation_frame_changed()
	var forward_jump_speed := player1.velocity.x
	_expect(
		is_equal_approx(forward_jump_speed, player1.character_data.air_speed),
		"UP+destra avvia un salto diagonale verso destra"
	)
	player1.input_buffer.record_input_snapshot(-1, 0, [], player1.is_facing_right)
	player1.handle_input()
	_expect(
		is_equal_approx(player1.velocity.x, forward_jump_speed),
		"la direzione del salto non cambia durante il volo"
	)
	player1.velocity = Vector2.ZERO
	player1.change_state(Mangler.State.IDLE)
	player1.start_jump(-1.0)
	player1.animated_sprite.frame = Mangler.JUMP_TAKEOFF_FRAME
	player1._on_animation_frame_changed()
	_expect(
		is_equal_approx(player1.velocity.x, -player1.character_data.air_speed),
		"UP+sinistra avvia un salto diagonale verso sinistra"
	)
	player1.velocity = Vector2.ZERO
	player1.change_state(Mangler.State.IDLE)
	player1.change_state(Mangler.State.RUNNING)
	player1.start_jump(1.0)
	player1.animated_sprite.frame = Mangler.JUMP_TAKEOFF_FRAME
	player1._on_animation_frame_changed()
	_expect(
		is_equal_approx(
			player1.velocity.x,
			player1.character_data.air_speed * Mangler.RUN_JUMP_HORIZONTAL_MULTIPLIER
		)
		and is_equal_approx(
			player1.velocity.y,
			player1.character_data.jump_velocity * Mangler.JUMP_SPEED_MULTIPLIER
		),
		"saltare durante RUNNING aumenta solo la velocità orizzontale"
	)
	player1.velocity = Vector2.ZERO
	player1.change_state(Mangler.State.IDLE)

	var aerial_test_position := player1.position
	player1.combat.cancel_current_action()
	player1.start_jump(1.0)
	player1.animated_sprite.frame = Mangler.JUMP_TAKEOFF_FRAME
	player1._on_animation_frame_changed()
	player1.move_and_slide()
	player1.change_state(Mangler.State.JUMPING)
	var aerial_velocity_before_attack := player1.velocity
	Input.action_press(player1.get_input_action("light_punch"))
	player1.input_buffer.record_input_snapshot(
		0, 0, [&"light_punch"], player1.is_facing_right
	)
	player1.handle_input()
	_expect(
		player1.combat.is_airborne_light_punch
		and player1.current_state == Mangler.State.ATTACKING
		and player1.animated_sprite.animation == &"jump_light_punch",
		"l'input LIGHT PUNCH durante JUMPING avvia il pugno leggero aereo"
	)
	var jump_light_punch_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		player1.animated_sprite.scale == Mangler.REWORK_SPRITE_SCALE
		and player1.animated_sprite.position == Mangler.REWORK_SPRITE_POSITION,
		"il light punch aereo usa scala e offset dei nuovi sprite"
	)
	_expect(
		jump_light_punch_shape.size == Vector2(135.0, 180.0)
		and player1.combat.hitbox_shape.position == Vector2(55.0, -170.0),
		"la hitbox del light punch aereo copre braccia e busto verso il basso"
	)
	await create_timer(0.65).timeout
	_expect(
		player1.animated_sprite.frame == 14
		and not player1.animated_sprite.is_playing()
		and not player1.combat.hitbox_shape.disabled,
		"tenendo il light punch aereo mantiene il fotogramma 20 e la hitbox"
	)
	Input.action_release(player1.get_input_action("light_punch"))
	await process_frame
	await process_frame
	_expect(
		player1.animated_sprite.frame >= 15
		and player1.combat.hitbox_shape.disabled,
		"rilasciando il light punch aereo avvia la recovery dal fotogramma 24"
	)
	player1.combat.cancel_current_action()
	player1.position = aerial_test_position
	player1.velocity = Vector2.ZERO
	player1.change_state(Mangler.State.IDLE)
	player1.aerial_attack_used = false
	player1.start_jump(1.0)
	player1.animated_sprite.frame = Mangler.JUMP_TAKEOFF_FRAME
	player1._on_animation_frame_changed()
	player1.move_and_slide()
	player1.change_state(Mangler.State.JUMPING)
	aerial_velocity_before_attack = player1.velocity
	Input.action_press(player1.get_input_action("light_kick"))
	player1.combat.try_attack(&"light_kick")
	_expect(
		player1.combat.is_airborne_light_kick
		and player1.current_state == Mangler.State.ATTACKING
		and player1.animated_sprite.animation == &"jump_light_kick",
		"LIGHT KICK durante JUMPING avvia il calcio leggero aereo"
	)
	_expect(
		is_equal_approx(player1.velocity.x, aerial_velocity_before_attack.x),
		"il calcio aereo conserva la traiettoria orizzontale del salto"
	)
	var jump_light_kick_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	await create_timer(0.45).timeout
	_expect(
		jump_light_kick_shape.size == Vector2(170.0, 55.0)
		and player1.combat.hitbox_shape.position == Vector2(95.0, -55.0)
		and is_equal_approx(player1.combat.hitbox_shape.rotation_degrees, 12.0),
		"il calcio leggero aereo usa una hitbox nella parte bassa"
	)
	_expect(
		player1.animated_sprite.frame == 19
		and not player1.animated_sprite.is_playing()
		and not player1.combat.hitbox_shape.disabled,
		"tenendo il calcio leggero aereo mantiene frame 25 e hitbox attiva"
	)
	_expect(
		player1.animated_sprite.scale == Mangler.JUMP_LIGHT_KICK_SPRITE_SCALE
		and player1.animated_sprite.position == Mangler.REWORK_SPRITE_POSITION,
		"il calcio leggero aereo usa la scala corretta 0.80"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 92
		and player2.animated_sprite.animation == &"hurt_high",
		"il calcio leggero aereo infligge danno light e provoca hurt_high"
	)
	Input.action_release(player1.get_input_action("light_kick"))
	await process_frame
	await process_frame
	_expect(
		player1.animated_sprite.frame >= 20
		and player1.combat.hitbox_shape.disabled,
		"rilasciando il calcio leggero aereo avvia la recovery dal frame 24"
	)
	player1.global_position.y = player1.shadow_ground_y
	player1.velocity.y = 1.0
	player1.move_and_slide()
	player1.update_state()
	_expect(
		player1.current_state == Mangler.State.IDLE
		and player1.animated_sprite.animation == &"idle"
		and not player1.combat.is_attacking
		and player1.combat.hitbox_shape.disabled,
		"atterrando durante il calcio leggero aereo Mangler torna subito in IDLE"
	)
	player1.position = aerial_test_position
	player1.velocity = Vector2(0.0, 1.0)
	player1.move_and_slide()
	player1.velocity = Vector2.ZERO
	player1.change_state(Mangler.State.IDLE)
	player2.combat.reset()

	player1.combat.cancel_current_action()
	player1.start_jump(1.0)
	player1.animated_sprite.frame = Mangler.JUMP_TAKEOFF_FRAME
	player1._on_animation_frame_changed()
	player1.move_and_slide()
	player1.change_state(Mangler.State.JUMPING)
	var aerial_medium_punch_velocity_before_attack := player1.velocity
	var aerial_medium_punch := player1.character_data.get_attack(&"medium_punch")
	Input.action_press(player1.get_input_action("medium_punch"))
	player1.input_buffer.record_input_snapshot(
		0, 0, [&"medium_punch"], player1.is_facing_right
	)
	player1.handle_input()
	_expect(
		player1.combat.is_airborne_medium_punch
		and player1.current_state == Mangler.State.ATTACKING
		and player1.animated_sprite.animation == &"jump_medium_punch",
		"MEDIUM PUNCH durante JUMPING avvia il pugno medio aereo"
	)
	_expect(
		is_equal_approx(player1.velocity.x, aerial_medium_punch_velocity_before_attack.x),
		"il pugno medio aereo conserva la traiettoria del salto"
	)
	var jump_medium_punch_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	await create_timer(0.65).timeout
	_expect(
		player1.animated_sprite.frame == 14
		and not player1.animated_sprite.is_playing()
		and not player1.combat.hitbox_shape.disabled,
		"il pugno medio aereo attiva dal frame 18 e mantiene la posa 20"
	)
	_expect(
		jump_medium_punch_shape.size == Vector2(200.0, 48.0)
		and player1.combat.hitbox_shape.position == Vector2(102.0, -142.0)
		and is_equal_approx(player1.combat.hitbox_shape.rotation_degrees, 24.0),
		"la hitbox del pugno medio aereo segue il braccio che colpisce"
	)
	_expect(
		player1.animated_sprite.scale == Mangler.REWORK_SPRITE_SCALE,
		"il pugno medio aereo usa la scala dei nuovi sprite"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 90
		and player2.animated_sprite.animation == &"hurt_high",
		"il pugno medio aereo infligge danno medium e provoca hurt_high"
	)
	Input.action_release(player1.get_input_action("medium_punch"))
	await process_frame
	await process_frame
	_expect(
		player1.animated_sprite.frame >= 15
		and player1.combat.hitbox_shape.disabled,
		"rilasciando il pugno medio aereo avvia la recovery dal frame 24"
	)
	player1.global_position.y = player1.shadow_ground_y
	player1.velocity.y = 1.0
	player1.move_and_slide()
	player1.update_state()
	_expect(
		player1.current_state == Mangler.State.IDLE
		and player1.animated_sprite.animation == &"idle"
		and not player1.combat.is_attacking,
		"atterrando durante il pugno medio aereo Mangler torna subito in IDLE"
	)
	player1.position = aerial_test_position
	player1.velocity = Vector2(0.0, 1.0)
	player1.move_and_slide()
	player1.velocity = Vector2.ZERO
	player1.change_state(Mangler.State.IDLE)
	player2.combat.reset()

	player1.combat.cancel_current_action()
	player1.start_jump(1.0)
	player1.animated_sprite.frame = Mangler.JUMP_TAKEOFF_FRAME
	player1._on_animation_frame_changed()
	player1.move_and_slide()
	player1.change_state(Mangler.State.JUMPING)
	var aerial_heavy_punch_velocity_before_attack := player1.velocity
	player1.combat.try_attack(&"heavy_punch")
	_expect(
		player1.combat.is_airborne_heavy_punch
		and player1.current_state == Mangler.State.ATTACKING
		and player1.animated_sprite.animation == &"jump_heavy_punch",
		"HEAVY PUNCH durante JUMPING avvia il pugno potente aereo"
	)
	_expect(
		is_equal_approx(player1.velocity.x, aerial_heavy_punch_velocity_before_attack.x),
		"il pugno potente aereo conserva la traiettoria del salto"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 85
		and player2.animated_sprite.animation == &"hurt_high",
		"il pugno potente aereo infligge danno heavy e provoca hurt_high"
	)
	await create_timer(player1.get_animation_duration(&"jump_heavy_punch") + 0.05).timeout
	player1.position = aerial_test_position
	player1.velocity = Vector2(0.0, 1.0)
	player1.move_and_slide()
	player1.velocity = Vector2.ZERO
	player1.change_state(Mangler.State.IDLE)
	player2.combat.reset()

	player1.combat.cancel_current_action()
	player1.start_jump(1.0)
	player1.animated_sprite.frame = Mangler.JUMP_TAKEOFF_FRAME
	player1._on_animation_frame_changed()
	player1.move_and_slide()
	player1.change_state(Mangler.State.JUMPING)
	var aerial_medium_velocity_before_attack := player1.velocity
	Input.action_press(player1.get_input_action("medium_kick"))
	player1.input_buffer.record_input_snapshot(
		0, 0, [&"medium_kick"], player1.is_facing_right
	)
	player1.handle_input()
	_expect(
		player1.combat.is_airborne_medium_kick
		and player1.current_state == Mangler.State.ATTACKING
		and player1.animated_sprite.animation == &"jump_medium_kick",
		"MEDIUM KICK durante JUMPING avvia il calcio medio aereo"
	)
	_expect(
		is_equal_approx(player1.velocity.x, aerial_medium_velocity_before_attack.x),
		"il calcio medio aereo conserva la traiettoria del salto"
	)
	var jump_medium_kick_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	await create_timer(0.45).timeout
	_expect(
		jump_medium_kick_shape.size == Vector2(170.0, 55.0)
		and player1.combat.hitbox_shape.position == Vector2(95.0, -55.0)
		and is_equal_approx(player1.combat.hitbox_shape.rotation_degrees, 12.0),
		"il calcio medio aereo usa una hitbox nella parte bassa"
	)
	_expect(
		player1.animated_sprite.frame == 19
		and not player1.animated_sprite.is_playing()
		and not player1.combat.hitbox_shape.disabled,
		"tenendo il calcio medio aereo mantiene frame 25 e hitbox attiva"
	)
	_expect(
		player1.animated_sprite.scale == Mangler.JUMP_LIGHT_KICK_SPRITE_SCALE,
		"il calcio medio aereo usa la scala corretta 0.80"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 88
		and player2.animated_sprite.animation == &"hurt_high",
		"il calcio medio aereo infligge danno medium e provoca hurt_high"
	)
	Input.action_release(player1.get_input_action("medium_kick"))
	await process_frame
	await process_frame
	_expect(
		player1.animated_sprite.frame >= 20
		and player1.combat.hitbox_shape.disabled,
		"rilasciando il calcio medio aereo avvia la recovery dal frame 24"
	)
	player1.global_position.y = player1.shadow_ground_y
	player1.velocity.y = 1.0
	player1.move_and_slide()
	player1.update_state()
	_expect(
		player1.current_state == Mangler.State.IDLE
		and player1.animated_sprite.animation == &"idle"
		and not player1.combat.is_attacking,
		"atterrando durante il calcio medio aereo Mangler torna subito in IDLE"
	)
	player2.combat.reset()

	player1.combat.cancel_current_action()
	player1.start_jump(1.0)
	player1.animated_sprite.frame = Mangler.JUMP_TAKEOFF_FRAME
	player1._on_animation_frame_changed()
	player1.move_and_slide()
	player1.change_state(Mangler.State.JUMPING)
	var aerial_heavy_velocity_before_attack := player1.velocity
	Input.action_press(player1.get_input_action("heavy_kick"))
	player1.input_buffer.record_input_snapshot(
		0, 0, [&"heavy_kick"], player1.is_facing_right
	)
	player1.handle_input()
	_expect(
		player1.combat.is_airborne_heavy_kick
		and player1.current_state == Mangler.State.ATTACKING
		and player1.animated_sprite.animation == &"jump_heavy_kick",
		"HEAVY KICK durante JUMPING avvia il calcio potente aereo"
	)
	_expect(
		is_equal_approx(player1.velocity.x, aerial_heavy_velocity_before_attack.x),
		"il calcio potente aereo conserva la traiettoria del salto"
	)
	await create_timer(0.45).timeout
	var jump_heavy_kick_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		jump_heavy_kick_shape.size == FighterCombat.JUMP_HEAVY_KICK_HITBOX_SIZE
		and player1.combat.hitbox_shape.position == FighterCombat.JUMP_HEAVY_KICK_HITBOX_POSITION
		and is_equal_approx(player1.combat.hitbox_shape.rotation_degrees, 10.0),
		"il calcio potente aereo usa una hitbox inclinata lungo la gamba"
	)
	_expect(
		player1.animated_sprite.frame == 19
		and not player1.animated_sprite.is_playing()
		and not player1.combat.hitbox_shape.disabled,
		"tenendo HEAVY KICK il calcio aereo resta sul fotogramma 25 con hitbox attiva"
	)
	_expect(
		player1.animated_sprite.scale == Mangler.JUMP_LIGHT_KICK_SPRITE_SCALE,
		"il calcio potente aereo mantiene la scala dei nuovi sprite di salto"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 80
		and player2.animated_sprite.animation == &"hurt_high",
		"il calcio potente aereo infligge danno heavy e provoca hurt_high"
	)
	Input.action_release(player1.get_input_action("heavy_kick"))
	await process_frame
	await process_frame
	_expect(
		player1.animated_sprite.frame >= 20
		and player1.combat.hitbox_shape.disabled,
		"rilasciando HEAVY KICK il calcio potente torna indietro e disattiva la hitbox"
	)
	player1.global_position.y = player1.shadow_ground_y
	player1.velocity = Vector2(0.0, 1.0)
	player1.move_and_slide()
	player1.update_state()
	_expect(
		player1.current_state == Mangler.State.IDLE
		and player1.animated_sprite.animation == &"idle"
		and not player1.combat.is_attacking,
		"atterrando durante il calcio potente aereo Mangler torna subito in IDLE"
	)
	player2.combat.reset()

	player1.combat.cancel_current_action()
	player1.change_state(Mangler.State.IDLE)
	var grab_attacker_original_position := player1.global_position
	var grab_target_original_position := player2.global_position
	player2.global_position = player1.global_position + Vector2(420.0, 0.0)
	player1.start_direct_grab()
	await process_frame
	_expect(
		player1.current_state == Mangler.State.IDLE
		and player1.animated_sprite.animation == &"idle"
		and not player1.grab_succeeded
		and not player1.grab_front_sprite.visible,
		"se la presa diretta è fuori portata, Mangler resta in IDLE"
	)
	player2.global_position = player1.global_position + Vector2(120.0, 0.0)
	var shift_helper_attacker_x := player1.global_position.x
	var shift_helper_victim_x := player2.global_position.x
	player1.global_position.x = 500.0
	player2.global_position.x = 620.0
	player1.grabbed_target = player2
	player1.shift_grab_pair_forward()
	_expect(
		is_equal_approx(
			player1.global_position.x,
			clampf(
				500.0
				+ (Mangler.GRAB_END_FORWARD_SHIFT if player1.is_facing_right else -Mangler.GRAB_END_FORWARD_SHIFT),
				player1.stage_left_limit,
				player1.stage_right_limit
			)
		)
		and is_equal_approx(
			player2.global_position.x,
			clampf(
				620.0
				+ (Mangler.GRAB_END_FORWARD_SHIFT if player1.is_facing_right else -Mangler.GRAB_END_FORWARD_SHIFT),
				player2.stage_left_limit,
				player2.stage_right_limit
			)
		),
		"la chiusura della presa sposta entrambi di 15 px rispettando i bordi"
	)
	player1.global_position.x = shift_helper_attacker_x
	player2.global_position.x = shift_helper_victim_x
	player1.grabbed_target = null
	player2.animated_sprite.play(&"idle")
	player2.animated_sprite.frame = 7
	player2.animated_sprite.pause()
	var combined_grab_impacts_before := player1.get_tree().get_node_count_in_group(
		"light_punch_hit_effect"
	)
	player1.start_direct_grab()
	await create_timer(0.43).timeout
	_expect(
		player1.grab_succeeded
		and player1.animated_sprite.animation == &"grab_headbow_combined"
		and player1.animated_sprite.is_playing()
		and not player1.grab_front_sprite.visible
		and is_equal_approx(
			player1.animated_sprite.position.x,
			Mangler.REWORK_SPRITE_POSITION.x
			+ (Mangler.GRAB_HEADBOW_FORWARD_OFFSET if player1.is_facing_right else -Mangler.GRAB_HEADBOW_FORWARD_OFFSET)
		)
		and player2.grabbed_by == player1
		and not player2.controls_enabled
		and not player2.animated_sprite.visible
		and not player2.ground_shadow.visible
		and player1.grab_headbow_explosion_spawned
		and player1.get_tree().get_node_count_in_group("light_punch_hit_effect")
		> combined_grab_impacts_before,
		"al frame 19 la presa usa l'esplosione rossa del light punch"
	)
	await create_timer(0.70).timeout
	_expect(
		player1.current_state == Mangler.State.IDLE
		and player1.animated_sprite.animation == &"idle"
		and player2.current_state == Mangler.State.IDLE
		and player2.animated_sprite.animation == &"idle"
		and player2.animated_sprite.visible
		and player2.ground_shadow.visible
		and player2.grabbed_by == null
		and player2.controls_enabled,
		"al termine della presa entrambi tornano visibili in IDLE"
	)
	player1.global_position = grab_attacker_original_position
	player2.global_position = grab_target_original_position
	player2.combat.reset()

	player1.combat.cancel_current_action()
	player1.change_state(Mangler.State.IDLE)
	player2.combat.set_guarding(false)
	player2.change_state(Mangler.State.IDLE)
	var super_test_player1_position := player1.global_position
	var super_test_player2_position := player2.global_position
	player1.start_super_start()
	await create_timer(0.40).timeout
	var super_auras := player1.get_tree().get_nodes_in_group("super_start_aura")
	var super_aura := super_auras.back() as Node2D if not super_auras.is_empty() else null
	_expect(
		player1.super_start_aura_spawned
		and super_aura != null
		and super_aura.get_node_or_null("AuraFlash") != null
		and super_aura.get_node_or_null("AuraParticles") != null,
		"al frame 19 super_start esplode in un'aura di particelle gialle"
	)
	await create_timer(0.15).timeout
	_expect(
		player1.animated_sprite.animation == &"super_rotate_run"
		and player1.animated_sprite.is_playing()
		and player2.current_state == Mangler.State.IDLE
		and player2.animated_sprite.animation == &"idle"
		and player2.animated_sprite.is_playing()
		and not player2.controls_enabled
		and not player2.can_move
		and player1.z_index > player2.z_index
		and Mangler.SUPER_ROTATE_RUN_SPEED == 480.0
		and player1.has_attack_motion_effect(&"super_rotate_run")
		and player1.has_attack_motion_effect(&"super_run_only"),
		"la super corre veloce con scia, attaccante davanti e avversario in idle animato"
	)
	var super_run_start_x := player1.global_position.x
	await create_timer(0.42).timeout
	_expect(
		player1.animated_sprite.animation == &"super_rotate_run"
		and player1.animated_sprite.frame >= Mangler.SUPER_ROTATE_RUN_MOVE_FRAME
		and player1.global_position.x != super_run_start_x,
		"dal frame 20 della corsa rotante Mangler avanza verso l'avversario"
	)
	await create_timer(0.10).timeout
	_expect(
		player1.animated_sprite.animation in [&"super_run_only", &"super_drum_roll"]
		and player1.animated_sprite.is_playing(),
		"dopo la corsa rotante parte run_only in loop fino al contatto"
	)
	player1.global_position.x = player2.global_position.x - Mangler.SUPER_ROTATE_RUN_STOP_DISTANCE
	player1.animated_sprite.play(&"super_run_only")
	var health_before_super_drum := player2.combat.current_health
	await process_frame
	player1._physics_process(0.0)
	_expect(
		player1.animated_sprite.animation == &"super_drum_roll"
		and player1.super_drum_roll_completed_loops == 0
		and player2.current_state == Mangler.State.HIT
		and player2.animated_sprite.animation == &"super_drum_hurt"
		and player2.animated_sprite.is_playing()
		and player2.animated_sprite.scale == Mangler.LEGACY_SPRITE_SCALE
		and player2.combat.current_health
		== health_before_super_drum - roundi(
			float(player2.combat.max_health) * Mangler.SUPER_DAMAGE_RATIO
		),
		"al contatto il drum roll avvia hurt-high e toglie il 25% della vita massima"
	)
	player1.animated_sprite.frame = Mangler.SUPER_DRUM_ROLL_IMPACT_FRAMES[0]
	player1._on_animation_frame_changed()
	var drum_impacts := player1.get_tree().get_nodes_in_group("super_drum_roll_impact")
	var latest_drum_impact := drum_impacts.back() as Node2D if not drum_impacts.is_empty() else null
	_expect(
		latest_drum_impact != null
		and latest_drum_impact.global_position.is_equal_approx(
			player2.head_hurtbox.global_position
		),
		"il drum roll genera esplosioni rosse all'altezza della testa avversaria"
	)
	player1._on_animation_finished()
	var first_drum_loop_restarted := (
		player1.animated_sprite.animation == &"super_drum_roll"
		and player1.super_drum_roll_completed_loops == 1
	)
	player1._on_animation_finished()
	_expect(
		first_drum_loop_restarted
		and player1.super_drum_roll_completed_loops == 2
		and player1.current_state == Mangler.State.IDLE
		and not player2.controls_enabled
		and player2.current_state == Mangler.State.KNOCKED_DOWN
		and player2.animated_sprite.animation == &"super_drum_knockdown",
		"dopo due loop l'avversario cade usando i frame 11-25 di ko"
	)
	player2._on_animation_finished()
	_expect(
		player2.current_state == Mangler.State.KNOCKDOWN_RECOVERY
		and player2.animated_sprite.animation == &"knockdown_recovery",
		"terminata la caduta parte knockdown_recovery"
	)
	player1.release_super_freeze()
	player1.global_position = super_test_player1_position
	player2.global_position = super_test_player2_position
	player1.combat.cancel_current_action()
	player1.change_state(Mangler.State.IDLE)
	player2.combat.set_guarding(true)
	player1.start_super_start()
	await process_frame
	_expect(
		player2.current_state == Mangler.State.BLOCKING
		and player2.animated_sprite.animation == &"block_high"
		and player2.animated_sprite.frame
		== player2.animated_sprite.sprite_frames.get_frame_count(&"block_high") - 1
		and not player2.animated_sprite.is_playing()
		and not player2.controls_enabled,
		"super_start congela in parata alta chi stava già parando"
	)
	player1.release_super_freeze()
	player1.combat.cancel_current_action()
	player1.change_state(Mangler.State.IDLE)
	# Isola il danno percentuale della super dai test di combattimento successivi.
	player2.combat.reset()
	player2.controls_enabled = true
	player2.can_move = true
	player2.change_state(Mangler.State.IDLE)

	player1.combat.cancel_current_action()
	player1.change_state(Mangler.State.IDLE)
	player1.input_buffer.clear()
	player1.input_buffer.record_input_snapshot(0, 1, [], player1.is_facing_right)
	player1.input_buffer.record_input_snapshot(1, 1, [], player1.is_facing_right)
	player1.input_buffer.record_input_snapshot(
		1, 0, [&"light_punch"], player1.is_facing_right
	)
	var sonic_motion_effect_count := player1.attack_afterimage_spawn_count
	player1.handle_input()
	_expect(
		player1.combat.is_special_sonic_boom
		and player1.current_state == Mangler.State.ATTACKING
		and player1.animated_sprite.animation == &"special_sonic_boom",
		"DOWN, DOWN-FORWARD, FORWARD + LIGHT PUNCH avvia il lancio Sonic Boom"
	)
	_expect(
		player1.combat.hitbox_shape.disabled,
		"la sola animazione di lancio Sonic Boom non attiva ancora una hitbox"
	)
	await create_timer(0.32).timeout
	var sonic_effect := player1.get_node_or_null("SonicChargeEffect") as Node2D
	_expect(
		sonic_effect != null
		and sonic_effect.get_child_count() == 2
		and sonic_effect.get_child(0).get_node_or_null("ArmGlow") != null
		and sonic_effect.get_child(0).get_node_or_null("GatheringParticles") != null,
		"dal fotogramma 14 il Sonic Boom crea aloni e particelle sulle due braccia"
	)
	_expect(
		player1.attack_afterimage_spawn_count > sonic_motion_effect_count,
		"il lancio Sonic Boom usa una scia di movimento giallo-dorata accentuata"
	)
	var sonic_first_arm_position := (sonic_effect.get_child(0) as Node2D).position
	await create_timer(0.18).timeout
	_expect(
		player1.get_node_or_null("SonicChargeEffect") == null
		and player1.get_node_or_null("SonicChargeExplosion") != null
		and sonic_first_arm_position != player1.get_sonic_arm_positions(22)[0],
		"la scia segue le braccia dal frame 14 e culmina nell'esplosione al frame 23"
	)
	var sonic_projectiles := get_nodes_in_group("sonic_projectile")
	var sonic_projectile := sonic_projectiles.back() as Area2D if not sonic_projectiles.is_empty() else null
	var projectile_sprite := (
		sonic_projectile.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if sonic_projectile != null else null
	)
	_expect(
		sonic_projectile != null
		and projectile_sprite != null
		and projectile_sprite.sprite_frames.get_frame_count(&"fly") == 25
		and is_equal_approx(projectile_sprite.sprite_frames.get_animation_speed(&"fly"), 48.0)
		and is_equal_approx(float(sonic_projectile.get("movement_speed")), 520.0)
		and (sonic_projectile.get_node("Trail") as CPUParticles2D).emitting,
		"il pugno leggero lancia i piatti a 520 px/s, 48 FPS e con una scia gialla accentuata"
	)
	var sonic_impact := (
		sonic_projectile.call(
			"spawn_impact_explosion", player2.global_position + Vector2(0.0, -150.0)
		) as Node2D
		if sonic_projectile != null else null
	)
	_expect(
		sonic_impact != null
		and sonic_impact.is_in_group("sonic_projectile_impact")
		and sonic_impact.get_node_or_null("ImpactSparks") != null,
		"il contatto del proiettile genera un'esplosione gialla sull'avversario"
	)
	var projectile_start_x := sonic_projectile.global_position.x if sonic_projectile != null else 0.0
	await create_timer(0.12).timeout
	_expect(
		sonic_projectile == null
		or not is_instance_valid(sonic_projectile)
		or absf(sonic_projectile.global_position.x - projectile_start_x) > 40.0,
		"il proiettile Sonic Boom viaggia in avanti"
	)
	if sonic_projectile != null and is_instance_valid(sonic_projectile):
		sonic_projectile.call(
			"_on_area_entered", player2.get_node("Hurtbox") as Area2D
		)
		await process_frame
		_expect(
			player2.combat.current_health == 88
			and player2.animated_sprite.animation == &"hurt_mid",
			"il proiettile Sonic Boom provoca hurt_middle sull'avversario"
		)
	await create_timer(0.48).timeout
	_expect(
		player1.current_state == Mangler.State.IDLE
		and not player1.combat.is_attacking
		and player1.get_node_or_null("SonicChargeEffect") == null,
		"il lancio Sonic Boom completa i 49 frame e torna in IDLE"
	)
	for sonic_variant: Dictionary in [
		{&"punch": &"medium_punch", &"multiplier": 1.3, &"label": "MEDIUM PUNCH"},
		{&"punch": &"heavy_punch", &"multiplier": 1.6, &"label": "HEAVY PUNCH"},
	]:
		player1.combat.cancel_current_action()
		player1.change_state(Mangler.State.IDLE)
		player1.input_buffer.clear()
		player1.input_buffer.record_input_snapshot(0, 1, [], player1.is_facing_right)
		player1.input_buffer.record_input_snapshot(1, 1, [], player1.is_facing_right)
		player1.input_buffer.record_input_snapshot(
			1, 0, [sonic_variant[&"punch"]], player1.is_facing_right
		)
		player1.handle_input()
		_expect(
			player1.combat.is_special_sonic_boom
			and is_equal_approx(
				player1.pending_sonic_projectile_speed_multiplier,
				float(sonic_variant[&"multiplier"])
			),
			"DOWN, DOWN-FORWARD, FORWARD + %s avvia il Sonic Boom con velocità dedicata"
			% sonic_variant[&"label"]
		)

	player1.combat.cancel_current_action()
	player1.change_state(Mangler.State.IDLE)
	player2.combat.reset()
	Input.action_release(player1.get_input_action("light_punch"))
	Input.action_release(player1.get_input_action("medium_punch"))
	await process_frame
	Input.action_press(player1.get_input_action("light_punch"))
	Input.action_press(player1.get_input_action("medium_punch"))
	player1.input_buffer.record_input_snapshot(
		0, 0, [&"light_punch", &"medium_punch"], player1.is_facing_right
	)
	_expect(
		player1.is_special_720_punch_chord_pressed(),
		"LIGHT PUNCH + MEDIUM PUNCH insieme riconoscono il comando 720 Punch"
	)
	player1.handle_input()
	_expect(
		player1.combat.is_special_720_punch
		and player1.current_state == Mangler.State.ATTACKING
		and player1.animated_sprite.animation == &"special_720_punch",
		"il comando combinato avvia la speciale 720 Punch"
	)
	var special_effect_count := player1.attack_afterimage_spawn_count
	Input.action_release(player1.get_input_action("move_left"))
	Input.action_press(player1.get_input_action("move_right"))
	await physics_frame
	await physics_frame
	_expect(
		is_equal_approx(
			absf(player1.get_special_720_movement_velocity()), Mangler.SPECIAL_720_MOVE_SPEED
		)
		and Mangler.SPECIAL_720_MOVE_SPEED < player1.character_data.walk_speed,
		"durante 720 Punch Mangler può avanzare lentamente"
	)
	await create_timer(0.25).timeout
	var special_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		special_shape.size == Vector2(340.0, 60.0)
		and player1.combat.hitbox_shape.position == Vector2(0.0, -165.0)
		and not player1.combat.hitbox_shape.disabled,
		"la hitbox di 720 Punch copre l'intera apertura delle braccia"
	)
	_expect(
		player1.attack_afterimage_spawn_count > special_effect_count,
		"720 Punch genera una scia di movimento accentuata"
	)
	for hit_index in range(3):
		player1.combat.hit_targets.clear()
		player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 82
		and player2.animated_sprite.animation == &"hurt_high",
		"l'avversario dentro la hitbox riceve tre colpi e tre reazioni hurt_high"
	)
	Input.action_release(player1.get_input_action("move_right"))
	Input.action_release(player1.get_input_action("light_punch"))
	Input.action_release(player1.get_input_action("medium_punch"))
	await create_timer(0.85).timeout
	_expect(
		player1.current_state == Mangler.State.IDLE and not player1.combat.is_attacking,
		"720 Punch completa i 49 fotogrammi e torna in IDLE"
	)
	player2.combat.reset()

	var light_punch := player1.character_data.get_attack(&"light_punch")
	var player1_default_z := player1.z_index
	player1.combat.try_attack(&"light_punch")
	_expect(player1.current_state == Mangler.State.ATTACKING, "AttackData avvia lo stato ATTACKING")
	_expect(
		player1.z_index > player2.z_index,
		"Player 1 passa in primo piano durante qualsiasi attacco"
	)
	_expect(player1.combat.current_attack == light_punch, "FighterCombat usa la risorsa selezionata")
	var attack_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		attack_shape.size == FighterCombat.STANDING_LIGHT_PUNCH_HITBOX_SIZE
		and player1.combat.hitbox_shape.position
		== FighterCombat.STANDING_LIGHT_PUNCH_HITBOX_POSITION,
		"AttackData configura geometria e posizione della hitbox"
	)
	_expect(
		FighterCombat.STANDING_LIGHT_PUNCH_HITBOX_SIZE == Vector2(205.0, 35.0)
		and FighterCombat.STANDING_LIGHT_PUNCH_HITBOX_POSITION == Vector2(52.5, -210.0),
		"il light punch usa hitbox 205 px con origine invariata"
	)
	_expect(
		light_punch.hitbox_size == Vector2(100.0, 35.0)
		and light_punch.hitbox_position == Vector2(50.0, -110.0),
		"il light punch è accorciato di 50 px soltanto verso l'avversario"
	)
	var light_punch_phases := player1.combat.get_attack_phase_durations(light_punch)
	_expect(
		is_equal_approx(
			light_punch_phases.x,
			float(FighterCombat.STANDING_LIGHT_PUNCH_ACTIVE_FRAME) / 48.0
		),
		"la hitbox del light punch diventa attiva al frame 17 (48 FPS)"
	)
	await create_timer(light_punch.get_total_duration() + 0.7).timeout
	_expect(
		player1.current_state == Mangler.State.IDLE,
		"il jab singolo completa preparation, hit e ritorno a idle"
	)
	_expect(
		player1.z_index == player1_default_z,
		"Player 1 ripristina l'ordine grafico normale al termine dell'attacco"
	)
	var player2_default_z := player2.z_index
	player2.combat.try_attack(&"light_punch")
	_expect(
		player2.z_index > player1.z_index,
		"anche Player 2 passa davanti all'avversario quando attacca"
	)
	player2.combat.cancel_current_action()
	player2.change_state(Mangler.State.IDLE)
	_expect(
		player2.z_index == player2_default_z,
		"Player 2 ripristina lo z-index quando l'attacco viene interrotto"
	)

	var medium_punch := player1.character_data.get_attack(&"medium_punch")
	player1.combat.try_attack(&"medium_punch")
	_expect(
		player1.animated_sprite.animation == &"medium_open_hand_slap"
		and medium_punch.hit_height == AttackData.HitHeight.HIGH,
		"il pugno medio avvia lo schiaffo a mano aperta come colpo alto"
	)
	var standing_medium_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		standing_medium_shape.size == player1.combat.current_variant.hitbox_size
		and player1.combat.hitbox_shape.position == player1.combat.current_variant.hitbox_position,
		"il medium punch in piedi usa la hitbox della variante standing"
	)
	await create_timer(player1.get_animation_duration(&"medium_open_hand_slap") + 0.05).timeout
	_expect(player1.current_state == Mangler.State.IDLE, "lo schiaffo medio completa 1-13 e il ritorno 13-1")

	var heavy_punch := player1.character_data.get_attack(&"heavy_punch")
	player1.combat.try_attack(&"heavy_punch")
	_expect(
		player1.animated_sprite.animation == &"heavy_punch"
		and player1.combat.get_effective_hit_height(heavy_punch) == AttackData.HitHeight.MID
		and player1.combat.get_hit_reaction_start_frame(heavy_punch) == 4
		and player1.combat.get_attack_phase_durations(heavy_punch)
		== Vector3(38.0, 4.0, 28.0) / 48.0,
		"il nuovo pugno potente provoca hurt-medium e sincronizza il contatto finale"
	)
	var heavy_punch_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		heavy_punch_shape.size == FighterCombat.STANDING_HEAVY_PUNCH_HITBOX_SIZE
		and player1.combat.hitbox_shape.position
		== FighterCombat.STANDING_HEAVY_PUNCH_HITBOX_POSITION,
		"il pugno potente alto estende la hitbox di 100 px verso l'avversario"
	)
	await create_timer(9.5 / 24.0).timeout
	_expect(
		player1.velocity == Vector2.ZERO and player1.is_on_floor(),
		"il nuovo pugno potente resta a terra perché l'affondo è già nello sprite"
	)
	_expect(
		player1.animated_sprite.frame < 38,
		"la lunga preparazione resta nella fase di startup"
	)
	await create_timer(player1.get_animation_duration(&"heavy_punch") + 0.05).timeout
	_expect(player1.current_state == Mangler.State.IDLE, "il pugno pesante completa anche il recupero inverso")

	var standing_light_kick := player1.character_data.get_attack(&"light_kick")
	player1.combat.try_attack(&"light_kick")
	_expect(
		player1.animated_sprite.animation == &"light_kick"
		and player1.combat.get_effective_hit_height(standing_light_kick) == AttackData.HitHeight.LOW,
		"il light kick in piedi avvia light_kick e provoca hurt_low"
	)
	var standing_lk_phases := player1.combat.get_attack_phase_durations(standing_light_kick)
	_expect(
		is_equal_approx(standing_lk_phases.x, float(FighterCombat.STANDING_LIGHT_KICK_ACTIVE_FRAME) / 48.0),
		"la hitbox del light kick diventa attiva al picco (pos. animazione 14, sorgente 25)"
	)
	var standing_light_kick_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		standing_light_kick_shape.size == Vector2(185.0, 35.0)
		and player1.combat.hitbox_shape.position == Vector2(97.5, -55.0),
		"il light kick estende la hitbox di 100 px verso l'avversario"
	)
	await create_timer(standing_lk_phases.x + standing_lk_phases.y + standing_lk_phases.z + 0.1).timeout
	_expect(player1.current_state == Mangler.State.IDLE, "il light kick completa l'intera animazione")

	player1.combat.try_attack(&"light_kick", FighterInputBuffer.Direction.DOWN)
	_expect(
		player1.combat.is_crouched_light_kick
		and player1.animated_sprite.animation == &"crouched_light_kick",
		"DOWN+calcio leggero avvia il nuovo calcio leggero basso"
	)
	var crouched_light_kick_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		crouched_light_kick_shape.size == FighterCombat.CROUCHED_LIGHT_KICK_HITBOX_SIZE
		and player1.combat.hitbox_shape.position == FighterCombat.CROUCHED_LIGHT_KICK_HITBOX_POSITION,
		"il calcio leggero basso usa una hitbox all'altezza delle gambe"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 92
		and player2.current_state == Mangler.State.HIT
		and player2.animated_sprite.animation == &"hurt_low"
		and player2.animated_sprite.frame == 4,
		"il calcio leggero basso provoca hurt_low dal fotogramma 5"
	)
	await create_timer(player1.get_animation_duration(&"crouched_light_kick") + 0.05).timeout
	player2.combat.reset()

	var standing_medium_kick := player1.character_data.get_attack(&"medium_kick")
	player1.combat.try_attack(&"medium_kick")
	_expect(
		player1.animated_sprite.animation == &"medium_kick",
		"il medium kick avvia l'animazione standing"
	)
	var standing_mk_phases := player1.combat.get_attack_phase_durations(standing_medium_kick)
	_expect(
		is_equal_approx(standing_mk_phases.x, float(FighterCombat.STANDING_MEDIUM_KICK_ACTIVE_FRAME) / 48.0),
		"la hitbox del medium kick diventa attiva al frame 41 (pos. anim. 26)"
	)
	var standing_medium_kick_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		standing_medium_kick_shape.size == Vector2(165.0, 45.0)
		and player1.combat.hitbox_shape.position == Vector2(97.5, -165.0),
		"il medium kick usa la hitbox estesa verso l'avversario"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 94
		and player2.animated_sprite.animation == &"hurt_high"
		and player2.animated_sprite.frame == 0,
		"il primo impatto del medium kick infligge 6 danni e avvia hurt-high"
	)
	player1.animated_sprite.frame = 28
	player1._on_animation_frame_changed()
	_expect(
		player2.combat.current_health == 88
		and player2.animated_sprite.animation == &"hurt_mid"
		and player2.animated_sprite.frame == 4,
		"alla posizione inversa il secondo impatto infligge 6 danni e avvia hurt-medium"
	)
	await create_timer(player1.get_animation_duration(&"medium_kick") + 0.05).timeout
	_expect(player1.current_state == Mangler.State.IDLE, "il medium kick completa l'intera animazione")
	player2.combat.reset()

	player1.combat.try_attack(&"medium_kick", FighterInputBuffer.Direction.DOWN)
	_expect(
		player1.combat.is_crouched_medium_kick
		and player1.animated_sprite.animation == &"crouched_medium_kick",
		"DOWN+calcio medio avvia il nuovo calcio medio basso"
	)
	var crouched_medium_kick_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		crouched_medium_kick_shape.size == FighterCombat.CROUCHED_MEDIUM_KICK_HITBOX_SIZE
		and player1.combat.hitbox_shape.position == FighterCombat.CROUCHED_MEDIUM_KICK_HITBOX_POSITION,
		"il calcio medio basso usa una hitbox all'altezza delle gambe"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 88
		and player2.current_state == Mangler.State.HIT
		and player2.animated_sprite.animation == &"hurt_mid"
		and player2.animated_sprite.frame == 4,
		"il calcio medio basso infligge il danno completo e provoca hurt_medium"
	)
	await create_timer(player1.get_animation_duration(&"crouched_medium_kick") + 0.05).timeout
	player2.combat.reset()

	var standing_heavy_kick := player1.character_data.get_attack(&"heavy_kick")
	player1.combat.try_attack(&"heavy_kick")
	_expect(
		player1.animated_sprite.animation == &"heavy_kick"
		and player1.combat.get_effective_hit_height(standing_heavy_kick) == AttackData.HitHeight.HIGH,
		"lo strong kick in piedi avvia heavy_kick e provoca hurt_high"
	)
	var standing_hk_phases := player1.combat.get_attack_phase_durations(standing_heavy_kick)
	_expect(
		is_equal_approx(standing_hk_phases.x, float(FighterCombat.STANDING_HEAVY_KICK_ACTIVE_FRAME) / 48.0),
		"la hitbox dello strong kick diventa attiva al frame 46 (pos. anim. 24, parte dal frame 22)"
	)
	var standing_hk_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		standing_hk_shape.size == FighterCombat.STANDING_HEAVY_KICK_HITBOX_SIZE
		and player1.combat.hitbox_shape.position == FighterCombat.STANDING_HEAVY_KICK_HITBOX_POSITION,
		"lo strong kick usa hitbox 165 px"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 80
		and player2.current_state == Mangler.State.HIT
		and player2.animated_sprite.animation == &"hurt_high",
		"lo strong kick infligge 20 danni e avvia hurt_high"
	)
	await create_timer(player1.get_animation_duration(&"heavy_kick") + 0.05).timeout
	_expect(player1.current_state == Mangler.State.IDLE, "lo strong kick completa l'animazione")
	player2.combat.reset()

	player1.combat.try_attack(&"heavy_kick", FighterInputBuffer.Direction.DOWN)
	_expect(
		player1.combat.is_crouched_heavy_kick
		and player1.animated_sprite.animation == &"crouched_heavy_kick",
		"DOWN+calcio potente avvia la spazzata rotante"
	)
	var crouched_heavy_kick_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		crouched_heavy_kick_shape.size == FighterCombat.CROUCHED_HEAVY_KICK_HITBOX_SIZE
		and player1.combat.hitbox_shape.position == FighterCombat.CROUCHED_HEAVY_KICK_HITBOX_POSITION,
		"la spazzata usa una hitbox bassa estesa in avanti"
	)
	var sweep_afterimages_before := player1.sweep_afterimage_spawn_count
	player1.animated_sprite.frame = Mangler.SWEEP_AFTERIMAGE_START_FRAME
	player1.spawn_sweep_motion_afterimage()
	_expect(
		player1.sweep_afterimage_spawn_count > sweep_afterimages_before
		and player1.get_tree().get_node_count_in_group("sweep_afterimage") > 0,
		"la rotazione della spazzata genera una breve scia semitrasparente"
	)
	var crouched_heavy_kick_phases := player1.combat.get_attack_phase_durations(standing_heavy_kick)
	_expect(
		is_equal_approx(crouched_heavy_kick_phases.x, 22.0 / 48.0)
		and is_equal_approx(crouched_heavy_kick_phases.y, 7.0 / 48.0)
		and player1.combat.get_effective_hit_height(standing_heavy_kick) == AttackData.HitHeight.LOW,
		"la nuova spazzata attiva il colpo sul quarto frame della sequenza 32-48"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.current_state == Mangler.State.SWEEP_KNOCKDOWN,
		"la spazzata potente provoca knockdown"
	)
	await create_timer(player1.get_animation_duration(&"crouched_heavy_kick") + 0.05).timeout
	_expect(
		player1.current_state == Mangler.State.IDLE,
		"la spazzata termina al frame 48 e libera il fighter; mantenendo giù torna all'idle basso"
	)
	player2.combat.reset()

	player1.combat.try_attack(&"heavy_punch", FighterInputBuffer.Direction.DOWN)
	_expect(
		player1.combat.is_crouched_heavy_punch
		and not player1.combat.crouched_heavy_punch_started_crouched
		and player1.animated_sprite.animation == &"crouched_power_punch",
		"DOWN+pesante da posizione alta avvia il pugno abbassato dal frame 1"
	)
	var crouched_heavy_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		crouched_heavy_shape.size == Vector2(80.0, 435.0)
		and player1.combat.hitbox_shape.position == Vector2(90.0, -255.0),
		"il pugno potente abbassato ha una hitbox ridotta di 30 px"
	)
	_expect(
		player1.combat.get_effective_hit_height(heavy_punch) == AttackData.HitHeight.HIGH,
		"il pugno potente abbassato provoca la reazione hurt_high e lancia l'avversario"
	)
	var crouched_heavy_phases := player1.combat.get_attack_phase_durations(heavy_punch)
	_expect(
		is_equal_approx(crouched_heavy_phases.x, float(FighterCombat.CROUCHED_HEAVY_PUNCH_ACTIVE_FRAME) / 48.0)
		and is_equal_approx(crouched_heavy_phases.y, 6.0 / 48.0),
		"il pugno potente abbassato diventa attivo al frame 9 (salto) e lancia l'avversario"
	)
	await create_timer(player1.get_animation_duration(&"crouched_power_punch") + 0.05).timeout
	player1.change_state(Mangler.State.CROUCHING)
	player1.animated_sprite.pause()
	player1.animated_sprite.frame = 6
	player1.combat.try_attack(&"heavy_punch", FighterInputBuffer.Direction.DOWN)
	_expect(
		player1.combat.crouched_heavy_punch_started_crouched
		and player1.animated_sprite.animation == &"crouched_power_punch"
		and player1.animated_sprite.frame == 0,
		"DOWN+pesante dal crouch avvia l'intera animazione dal frame 1"
	)
	await create_timer(player1.get_animation_duration(&"crouched_power_punch") + 0.1).timeout

	player1.combat.try_attack(&"medium_punch", FighterInputBuffer.Direction.DOWN)
	_expect(
		player1.combat.is_crouched_medium_punch
		and not player1.combat.crouched_medium_punch_started_crouched
		and player1.animated_sprite.animation == &"crouched_medium_punch",
		"DOWN+medio da posizione alta avvia il gancio ai reni dal frame 1"
	)
	var crouched_medium_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		crouched_medium_shape.size == FighterCombat.CROUCHED_MEDIUM_HITBOX_SIZE
		and player1.combat.hitbox_shape.position == FighterCombat.CROUCHED_MEDIUM_HITBOX_POSITION,
		"il gancio medio basso mantiene invariata la propria hitbox"
	)
	var crouched_medium_phases := player1.combat.get_attack_phase_durations(medium_punch)
	_expect(
		is_equal_approx(crouched_medium_phases.x, float(FighterCombat.CROUCHED_MEDIUM_PUNCH_ACTIVE_FRAME) / 48.0)
		and is_equal_approx(crouched_medium_phases.y, 4.0 / 48.0)
		and player1.combat.get_hit_reaction_start_frame(medium_punch) == 4,
		"la hitbox del medio basso diventa attiva al frame 23 (pos. anim. 14) e hurt-medium parte dal frame 5"
	)
	await create_timer(player1.get_animation_duration(&"crouched_medium_punch") + 0.05).timeout
	player1.change_state(Mangler.State.CROUCHING)
	player1.animated_sprite.pause()
	player1.animated_sprite.frame = 6
	player1.combat.try_attack(&"medium_punch", FighterInputBuffer.Direction.DOWN)
	_expect(
		player1.combat.is_crouched_medium_punch
		and player1.combat.crouched_medium_punch_started_crouched
		and player1.animated_sprite.animation == &"crouched_medium_punch_crouched",
		"DOWN+medio dal crouch avvia il gancio ai reni dal frame 5"
	)
	await create_timer(medium_punch.get_total_duration() + 0.05).timeout

	player1.combat.try_attack(&"light_punch", FighterInputBuffer.Direction.DOWN)
	_expect(
		player1.combat.is_crouched_light_punch
		and not player1.combat.crouched_punch_started_crouched
		and player1.animated_sprite.animation == &"crouched_punch",
		"DOWN+light da posizione alta parte dal fotogramma 1 di crouched_punch"
	)
	var crouched_light_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		crouched_light_shape.size == FighterCombat.CROUCHED_LIGHT_HITBOX_SIZE
		and player1.combat.hitbox_shape.position == FighterCombat.CROUCHED_LIGHT_HITBOX_POSITION,
		"il light punch abbassato ripristina la hitbox a 150 px verso l'avversario"
	)
	await create_timer(player1.get_animation_duration(&"crouched_punch") + 0.05).timeout
	player1.change_state(Mangler.State.CROUCHING)
	player1.animated_sprite.frame = 6
	player1.animated_sprite.pause()
	player1.combat.try_attack(&"light_punch", FighterInputBuffer.Direction.DOWN)
	_expect(
		player1.combat.is_crouched_light_punch
		and player1.combat.crouched_punch_started_crouched
		and player1.animated_sprite.animation == &"crouched_punch_crouched",
		"DOWN+light dal frame 7 di crouch passa al fotogramma 9 di crouched_punch"
	)
	player2.combat.cancel_current_action()
	player2.combat.reset()
	player2.change_state(Mangler.State.IDLE)
	player2.controls_enabled = true
	player2.can_move = true
	player2.velocity = Vector2.ZERO
	var health_before_crouched_light_guard := player2.combat.current_health
	Input.action_press(&"p2_move_right")
	await physics_frame
	await physics_frame
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	Input.action_release(&"p2_move_right")
	_expect(
		player2.combat.current_health == health_before_crouched_light_guard
		and player2.current_state == Mangler.State.BLOCKING
		and player2.animated_sprite.animation == &"block_mid",
		"il light punch basso parato attiva block_mid senza infliggere danno"
	)
	player1.combat.is_attacking = false
	player2.combat.reset()
	player2.change_state(Mangler.State.IDLE)
	await create_timer(player1.get_animation_duration(&"crouched_punch_crouched") + 0.05).timeout
	var airborne_hit_ground_y := player2.shadow_ground_y
	player2.global_position.y = airborne_hit_ground_y - 90.0
	player2.velocity = Vector2(0.0, 80.0)
	player2.change_state(Mangler.State.JUMPING)
	player2.move_and_slide()
	await physics_frame
	player2.combat.take_damage(0, player1)
	_expect(
		player2.current_state == Mangler.State.HIT
		and player2.animated_sprite.animation == &"hurted_in_jump",
		"un personaggio colpito in salto avvia hurted_in_jump"
	)
	player2.global_position.y = airborne_hit_ground_y
	player2.velocity = Vector2(0.0, 1.0)
	player2.move_and_slide()
	await physics_frame
	await physics_frame
	_expect(
		player2.current_state == Mangler.State.HIT
		and player2.animated_sprite.animation == &"hurted_in_jump"
		and player2.animated_sprite.frame == 24
		and not player2.animated_sprite.is_playing(),
		"all'atterraggio mantiene il fotogramma 25 di hurted_in_jump"
	)
	await create_timer(1.05).timeout
	_expect(
		player2.current_state == Mangler.State.KNOCKDOWN_RECOVERY
		and player2.animated_sprite.animation == &"knockdown_recovery",
		"dopo un secondo a terra avvia knockdown_recovery"
	)
	await create_timer(0.75).timeout
	_expect(player2.current_state == Mangler.State.IDLE, "la recovery dal colpo aereo torna in IDLE")

	var position_before_hit := player2.position.x
	player2.combat.take_damage(20, player1)
	_expect(player2.combat.current_health == 80, "danno normale applicato")
	_expect(player2.current_state == Mangler.State.HIT, "danno normale attiva HIT")
	_expect(
		player2.animated_sprite.animation == &"hurt_mid",
		"un colpo medio riproduce hurt_mid"
	)
	_expect(player2.animated_sprite.frame == 4, "hurt-medium parte sempre dal fotogramma 5")
	_expect(player2_bar.value == 80.0, "segnale di danno aggiorna la UI")
	await create_timer(0.35).timeout
	_expect(player2.current_state == Mangler.State.HIT, "HIT resta attivo fino alla fine dell'animazione")
	_expect(player2.position.x > position_before_hit, "il colpo spinge leggermente lontano dall'attaccante")
	await create_timer(0.75).timeout
	_expect(player2.current_state == Mangler.State.IDLE, "l'animazione completa termina in IDLE")

	player2.combat.take_damage(
		0,
		player1,
		FighterCombat.DEFAULT_HITSTUN,
		FighterCombat.DEFAULT_BLOCKSTUN,
		AttackData.HitHeight.HIGH,
		false,
		3
	)
	_expect(
		player2.current_state == Mangler.State.HIT
		and player2.animated_sprite.animation == &"hurt_high"
		and player2.animated_sprite.frame == 3,
		"il light punch riproduce hurt_high partendo dal fotogramma 4"
	)
	await create_timer(0.85).timeout
	_expect(player2.current_state == Mangler.State.IDLE, "hurt_high completa i fotogrammi 4-16")

	player2.combat.take_damage(
		0,
		player1,
		FighterCombat.DEFAULT_HITSTUN,
		FighterCombat.DEFAULT_BLOCKSTUN,
		AttackData.HitHeight.LOW
	)
	_expect(
		player2.current_state == Mangler.State.HIT
		and player2.animated_sprite.animation == &"hurt_low",
		"un calcio basso leggero o medio riproduce hurt_low"
	)
	await create_timer(0.7).timeout
	_expect(player2.current_state == Mangler.State.IDLE, "hurt_low completa i frame 7-16")

	player2.combat.take_damage(
		0,
		player1,
		FighterCombat.DEFAULT_HITSTUN,
		FighterCombat.DEFAULT_BLOCKSTUN,
		AttackData.HitHeight.LOW,
		true
	)
	_expect(
		player2.current_state == Mangler.State.SWEEP_KNOCKDOWN
		and player2.animated_sprite.animation == &"sweep_knockdown",
		"il calcio basso potente avvia sweep_knockdown"
	)
	var sweep_duration := player2.get_animation_duration(&"sweep_knockdown")
	await create_timer(sweep_duration + FighterCombat.SWEEP_GROUNDED_HOLD - 0.1).timeout
	_expect(
		player2.current_state == Mangler.State.SWEEP_KNOCKDOWN
		and player2.animated_sprite.frame == 48,
		"la spazzata completa i 49 frame e mantiene brevemente la posa a terra"
	)
	await create_timer(0.2).timeout
	_expect(
		player2.current_state == Mangler.State.KNOCKDOWN_RECOVERY
		and player2.animated_sprite.animation == &"knockdown_recovery",
		"dopo la pausa a terra parte knockdown_recovery"
	)
	var health_during_recovery := player2.combat.current_health
	player2.combat.take_damage(10, player1)
	_expect(
		player2.combat.current_health == health_during_recovery
		and player2.current_state == Mangler.State.KNOCKDOWN_RECOVERY,
		"la rialzata è invulnerabile"
	)
	await create_timer(1.05).timeout
	_expect(player2.current_state == Mangler.State.IDLE, "la rialzata completa torna in IDLE")

	var health_before_guard := player2.combat.current_health
	Input.action_press(&"p2_move_right")
	await physics_frame
	await physics_frame
	player1.combat.is_attacking = true
	player2.combat.take_damage(20, player1)
	Input.action_release(&"p2_move_right")
	_expect(
		player2.combat.current_health == health_before_guard,
		"la guardia riuscita non infligge danno"
	)
	_expect(player2.current_state == Mangler.State.BLOCKING, "guardia attiva BLOCKING")
	_expect(player2.animated_sprite.animation == &"block_mid", "la guardia centrale riproduce block_mid")
	_expect(player2_bar.value == 80.0, "la barra non cala durante la guardia")
	await create_timer(player2.get_animation_duration(&"block_mid") + 0.05).timeout
	player2.update_animation()
	_expect(
		player2.current_state == Mangler.State.BLOCKING
		and player2.animated_sprite.animation == &"block_mid"
		and player2.animated_sprite.frame == 7
		and not player2.animated_sprite.is_playing(),
		"block_mid si ferma sul fotogramma 8 senza ripetere l'animazione"
	)
	player1.combat.is_attacking = false
	await create_timer(0.05).timeout
	_expect(
		player2.current_state == Mangler.State.BLOCK_RECOVERY
		and player2.animated_sprite.animation == &"block_mid_recovery",
		"a fine blocco medio riproduce i fotogrammi inversi fino al primo"
	)
	await create_timer(player2.get_animation_duration(&"block_mid_recovery") + 0.05).timeout
	_expect(player2.current_state == Mangler.State.IDLE, "block_mid_recovery termina in IDLE")

	Input.action_press(&"p2_move_right")
	await physics_frame
	await physics_frame
	player1.combat.is_attacking = true
	player2.combat.take_damage(
		20,
		player1,
		FighterCombat.DEFAULT_HITSTUN,
		FighterCombat.DEFAULT_BLOCKSTUN,
		AttackData.HitHeight.HIGH
	)
	Input.action_release(&"p2_move_right")
	_expect(
		player2.current_state == Mangler.State.BLOCKING
		and player2.animated_sprite.animation == &"block_high",
		"un colpo alto bloccato riproduce il nuovo block_high"
	)
	await create_timer(player2.get_animation_duration(&"block_high") + 0.05).timeout
	_expect(
		player2.current_state == Mangler.State.BLOCKING
		and player2.animated_sprite.animation == &"block_high"
		and player2.animated_sprite.frame == 13,
		"la parata alta mantiene l'ultimo frame finché l'attacco avversario è attivo"
	)
	player1.combat.is_attacking = false
	await create_timer(0.05).timeout
	_expect(
		player2.current_state == Mangler.State.BLOCK_RECOVERY
		and player2.animated_sprite.animation == &"block_high_recovery",
		"quando l'attacco termina la parata alta riparte al contrario"
	)
	await create_timer(player2.get_animation_duration(&"block_high_recovery") + 0.05).timeout
	_expect(player2.current_state == Mangler.State.IDLE, "block_high_recovery termina in IDLE")

	player2.start_block_reaction(AttackData.HitHeight.LOW, false)
	_expect(
		player2.current_state == Mangler.State.BLOCKING
		and player2.animated_sprite.animation == &"block_low",
		"da posizione alta la parata bassa parte dal fotogramma 1"
	)
	player2.change_state(Mangler.State.IDLE)
	player2.start_block_reaction(AttackData.HitHeight.LOW, true)
	_expect(
		player2.current_state == Mangler.State.BLOCKING
		and player2.animated_sprite.animation == &"block_low_crouched",
		"da posizione già bassa la parata usa 08-block-low dal primo fotogramma"
	)
	player2.change_state(Mangler.State.IDLE)

	player2.change_state(Mangler.State.CROUCHING)
	Input.action_press(&"p2_move_right")
	Input.action_press(&"p2_crouch")
	await physics_frame
	player2.combat.block_reaction(FighterCombat.DEFAULT_BLOCKSTUN, AttackData.HitHeight.LOW)
	await create_timer(0.55).timeout
	_expect(
		player2.current_state == Mangler.State.CROUCHING
		and player2.animated_sprite.animation == &"crouch"
		and player2.animated_sprite.frame == 24
		and not player2.animated_sprite.is_playing(),
		"mantenere basso e indietro torna al frame finale del nuovo crouch"
	)
	Input.action_release(&"p2_move_right")
	Input.action_release(&"p2_crouch")
	await physics_frame
	player2.combat.set_guarding(false)
	player2.input_buffer.clear()
	player2.change_state(Mangler.State.IDLE)

	player2.combat.take_damage(
		player2.combat.current_health,
		player1,
		FighterCombat.DEFAULT_HITSTUN,
		FighterCombat.DEFAULT_BLOCKSTUN,
		AttackData.HitHeight.HIGH,
		false,
		4,
		10
	)
	_expect(player2.combat.current_health == 0, "danno letale porta la vita a zero")
	_expect(player2.current_state == Mangler.State.KNOCKED_DOWN, "danno letale attiva KO")
	_expect(
		player2.animated_sprite.animation == &"ko" and player2.animated_sprite.frame == 10,
		"l'ultimo light della combo avvia ko dal fotogramma 11"
	)
	_expect(not bool(arena.get("round_active")), "KO ferma il training")
	_expect(not player1.controls_enabled and not player2.controls_enabled, "KO blocca i controlli")
	_expect(
		round_label.visible and round_label.text.begins_with("PLAYER 1 WINS"),
		"KO aggiorna il messaggio UI"
	)
	await create_timer(1.65).timeout
	_expect(
		player2.current_state == Mangler.State.KNOCKED_DOWN
		and player2.animated_sprite.animation == &"ko"
		and player2.animated_sprite.frame == 24
		and not player2.animated_sprite.is_playing(),
		"KO completa i 25 frame e mantiene la posa finale"
	)

	arena.call("start_round")
	_expect(player1.combat.current_health == player1.combat.max_health, "reset vita Player 1")
	_expect(player2.combat.current_health == player2.combat.max_health, "reset vita Player 2")
	_expect(
		player1.current_state == Mangler.State.IDLE,
		"reset stato Player 1"
	)
	_expect(
		player1.animated_sprite.animation == &"idle",
		"reset animazione Player 1"
	)
	_expect(
		player1.can_move,
		"reset movimento Player 1"
	)
	_expect(
		player2.current_state == Mangler.State.IDLE
		and player2.animated_sprite.animation == &"idle"
		and player2.can_move,
		"reset stato, animazione e movimento Player 2"
	)
	_expect(player1_bar.value == 100.0 and player2_bar.value == 100.0, "reset barre UI")
	_expect(not player1.controls_enabled and not player2.controls_enabled, "controlli bloccati durante il countdown")
	await create_timer(2.1).timeout
	_expect(bool(arena.get("round_active")), "training riattivato dopo il reset")
	_expect(player1.controls_enabled and player2.controls_enabled, "controlli riattivati dopo il reset")
	var arianna_reset_start_x := player1.position.x
	Input.action_press(&"p1_move_right")
	await physics_frame
	await physics_frame
	Input.action_release(&"p1_move_right")
	_expect(
		player1.position.x > arianna_reset_start_x,
		"il Player 1 può muoversi realmente dopo il restart del round"
	)

	arena.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
		return
	failures += 1
	push_error("FAIL: " + description)


func _release_test_actions() -> void:
	Input.action_release(&"p1_move_right")
	Input.action_release(&"p1_crouch")
	Input.action_release(&"p1_light_punch")
	Input.action_release(&"p1_medium_punch")
	Input.action_release(&"p1_move_left")
	Input.action_release(&"p1_move_right")
	Input.action_release(&"p1_medium_kick")
	Input.action_release(&"p1_heavy_kick")
	Input.action_release(&"p2_move_right")
