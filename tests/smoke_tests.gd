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
	await _test_combat_flow()
	_release_test_actions()

	if failures == 0:
		print("SMOKE_TESTS_OK")
		quit(0)
	else:
		push_error("SMOKE_TESTS_FAILED: %d assertion(s)" % failures)
		quit(1)


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
	]
	_expect(character_data.attacks.size() == 6, "il profilo predefinito contiene sei AttackData")
	for attack_id in attack_ids:
		var attack := character_data.get_attack(attack_id)
		_expect(attack != null, "risorsa caricata: " + str(attack_id))
		if attack != null:
			_expect(attack.is_valid(), "risorsa valida: " + str(attack_id))

	var light_punch := character_data.get_attack(&"light_punch")
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
			FighterInputBuffer.Direction.FORWARD,
		]),
		"riconoscimento di una sequenza direzionale recente"
	)

func _test_combat_flow() -> void:
	print("-- Arena, combattimento e UI")
	var arena_scene := load("res://scenes/MainArena.tscn") as PackedScene
	var arena: Node = arena_scene.instantiate()
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
		and player1.animated_sprite.sprite_frames.get_frame_count(&"light_punch_single") == 12,
		"il pugno light singolo usa 1-6 e torna indietro da 6 a 1"
	)
	var light_single_impact := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"light_punch_single", 5)
		as AtlasTexture
	)
	var light_single_last := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"light_punch_single", 11)
		as AtlasTexture
	)
	_expect(
		light_single_impact.region.position == Vector2(512.0, 512.0)
		and light_single_last.region.position == Vector2.ZERO,
		"il light singolo raggiunge il frame 6 e termina tornando al frame 1"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"light_punch_double")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"light_punch_double") == 16,
		"la combo light usa 1-6 e prosegue dal frame 7 fino al frame 16"
	)
	var light_combo_last := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"light_punch_double", 15)
		as AtlasTexture
	)
	_expect(
		light_combo_last.region.position == Vector2(1536.0, 1536.0),
		"la combo light termina sul frame 16 del nuovo foglio"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"light_punch_single"),
			24.0
		)
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"light_punch_double"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"light_punch_single")
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"light_punch_double"),
		"entrambe le animazioni light sono non cicliche a 24 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"medium_open_hand_slap")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"medium_open_hand_slap") == 26
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"medium_open_hand_slap"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"medium_open_hand_slap"),
		"lo schiaffo medio usa 1-13 e torna indietro da 13 a 1, a 24 FPS"
	)
	var medium_slap_peak := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"medium_open_hand_slap", 12)
		as AtlasTexture
	)
	var medium_slap_last := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"medium_open_hand_slap", 25)
		as AtlasTexture
	)
	_expect(
		medium_slap_peak.region.position == Vector2(0.0, 1536.0)
		and medium_slap_last.region.position == Vector2.ZERO,
		"lo schiaffo medio raggiunge il frame 13 e termina tornando al frame 1"
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
		and player1.animated_sprite.sprite_frames.get_frame_count(&"light_kick") == 16
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"light_kick"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"light_kick"),
		"il light kick in piedi usa tutti i 16 frame, non ciclici, a 24 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_light_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_light_kick") == 16
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_light_kick"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"crouched_light_kick"),
		"il calcio leggero basso usa tutti i 16 frame, non ciclici, a 24 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"jump_light_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"jump_light_kick") == 9
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"jump_light_kick"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"jump_light_kick"),
		"il light kick aereo usa 12-16 e torna indietro fino al 12 a 24 FPS"
	)
	var jump_kick_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_light_kick", 0
	) as AtlasTexture
	var jump_kick_peak := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_light_kick", 4
	) as AtlasTexture
	var jump_kick_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_light_kick", 8
	) as AtlasTexture
	_expect(
		jump_kick_first.region == Rect2(1536.0, 1024.0, 512.0, 512.0)
		and jump_kick_peak.region == Rect2(1536.0, 1536.0, 512.0, 512.0)
		and jump_kick_last.region == jump_kick_first.region,
		"il light kick aereo raggiunge il frame 16 e torna al frame 12"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"jump_heavy_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"jump_heavy_kick") == 16
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"jump_heavy_kick"),
			30.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"jump_heavy_kick"),
		"il calcio potente aereo usa tutti i 16 frame di medium_jump_kick a 30 FPS"
	)
	var jump_heavy_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_heavy_kick", 0
	) as AtlasTexture
	var jump_heavy_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_heavy_kick", 15
	) as AtlasTexture
	_expect(
		jump_heavy_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and jump_heavy_last.region == Rect2(1536.0, 1536.0, 512.0, 512.0)
		and jump_heavy_first.atlas.resource_path.ends_with("medium_jump_kick.png"),
		"il calcio potente aereo riproduce il foglio dal primo all'ultimo frame"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"jump_medium_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"jump_medium_kick") == 16
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"jump_medium_kick"),
			30.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"jump_medium_kick"),
		"il calcio medio aereo usa tutti i 16 frame di custom_jump_kick_2 a 30 FPS"
	)
	var jump_medium_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_kick", 0
	) as AtlasTexture
	var jump_medium_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_kick", 15
	) as AtlasTexture
	_expect(
		jump_medium_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and jump_medium_last.region == Rect2(1536.0, 1536.0, 512.0, 512.0)
		and jump_medium_first.atlas.resource_path.ends_with("custom_jump_kick_2.png"),
		"il calcio medio aereo riproduce il foglio dal primo all'ultimo frame"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"jump_medium_punch")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"jump_medium_punch") == 16
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"jump_medium_punch"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"jump_medium_punch"),
		"il pugno medio aereo usa tutti i 16 frame di medium-punch-jump a 24 FPS"
	)
	var jump_medium_punch_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_punch", 0
	) as AtlasTexture
	var jump_medium_punch_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"jump_medium_punch", 15
	) as AtlasTexture
	_expect(
		jump_medium_punch_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
		and jump_medium_punch_last.region == Rect2(1536.0, 1536.0, 512.0, 512.0)
		and jump_medium_punch_first.atlas.resource_path.ends_with("medium-punch-jump.png"),
		"il pugno medio aereo riproduce lo spritesheet dal primo all'ultimo frame"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"jump_heavy_punch")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"jump_heavy_punch") == 16
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"jump_heavy_punch"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"jump_heavy_punch"),
		"il pugno potente aereo usa tutti i 16 frame a 24 FPS"
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
		and player1.animated_sprite.sprite_frames.get_frame_count(&"medium_kick") == 12
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"medium_kick"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"medium_kick"),
		"il medium kick usa soltanto i primi 12 frame, non ciclici, a 24 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"heavy_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"heavy_kick") == 16
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"heavy_kick"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"heavy_kick"),
		"il nuovo heavy kick usa tutti i 16 frame, non ciclici, a 24 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_heavy_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_heavy_kick") == 17
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_heavy_kick"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"crouched_heavy_kick"),
		"la spazzata rotante usa i frame sorgente 32-48, non ciclici, a 24 FPS"
	)
	var sweep_first := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"crouched_heavy_kick", 0
	) as AtlasTexture
	var sweep_last := player1.animated_sprite.sprite_frames.get_frame_texture(
		&"crouched_heavy_kick", 16
	) as AtlasTexture
	_expect(
		sweep_first != null
		and sweep_first.region == Rect2(3584.0, 1536.0, 512.0, 512.0)
		and sweep_last != null
		and sweep_last.region == Rect2(3584.0, 2560.0, 512.0, 512.0),
		"la spazzata parte esattamente dal fotogramma 32 e termina al 48"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_medium_kick")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_medium_kick") == 16
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_medium_kick"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"crouched_medium_kick"),
		"il calcio medio basso usa tutti i 16 frame, non ciclici, a 24 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_power_punch")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_power_punch") == 16,
		"il pugno potente abbassato usa l'intera animazione 1-16"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_power_punch"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"crouched_power_punch"),
		"il pugno potente abbassato è non ciclico a 24 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_medium_punch")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_medium_punch") == 16
		and player1.animated_sprite.sprite_frames.has_animation(&"crouched_medium_punch_crouched")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_medium_punch_crouched") == 12,
		"il medio basso usa 1-16 da posizione alta e 5-16 dal crouch"
	)
	var crouched_medium_first := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"crouched_medium_punch_crouched", 0)
		as AtlasTexture
	)
	_expect(
		crouched_medium_first.region.position == Vector2(0.0, 512.0)
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_medium_punch"),
			24.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"crouched_medium_punch"),
		"dal crouch il medio basso parte dal frame 5 ed entrambe le varianti sono non cicliche a 24 FPS"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_punch")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_punch") == 23,
		"il pugno basso da posizione alta usa i fotogrammi 1-12 e torna fino al primo"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"crouched_punch_crouched")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"crouched_punch_crouched") == 15,
		"il pugno basso da crouch usa 9-12 e torna fino al primo"
	)
	var crouched_sheet_frames := player1.animated_sprite.sprite_frames
	var crouched_peak := crouched_sheet_frames.get_frame_texture(&"crouched_punch", 11) as AtlasTexture
	var crouched_reverse := crouched_sheet_frames.get_frame_texture(&"crouched_punch", 12) as AtlasTexture
	var crouched_last := crouched_sheet_frames.get_frame_texture(&"crouched_punch", 22) as AtlasTexture
	_expect(
		crouched_peak.region.position == Vector2(1536.0, 1024.0)
		and crouched_reverse.region.position == Vector2(1024.0, 1024.0)
		and crouched_last.region.position == Vector2.ZERO,
		"crouched_punch raggiunge il frame 12, inverte e termina sul frame 1"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_punch"),
			24.0
		)
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"crouched_punch_crouched"),
			24.0
		),
		"le due varianti del pugno basso sono configurate a 24 FPS"
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
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"hurt_mid"), 16.0),
		"hurt_mid è configurato a 16 FPS"
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
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"hurt_high"), 16.0),
		"hurt_high è configurato a 16 FPS"
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
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"hurt_low"), 16.0),
		"hurt_low è configurato a 16 FPS"
	)
	_expect(
		not player1.animated_sprite.sprite_frames.get_animation_loop(&"hurt_low"),
		"hurt_low non è configurato in loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"sweep_knockdown"),
		"SpriteFrames contiene sweep_knockdown"
	)
	_expect(
		player1.animated_sprite.sprite_frames.get_frame_count(&"sweep_knockdown") == 25,
		"sweep_knockdown contiene le 25 celle da 512"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"sweep_knockdown"),
			16.0
		),
		"sweep_knockdown è configurato a 16 FPS"
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
			16.0
		),
		"knockdown_recovery è configurato a 16 FPS"
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
		player1.animated_sprite.sprite_frames.get_frame_count(&"block_mid") == 4,
		"block_mid usa soltanto i fotogrammi 4-7"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"block_mid"), 16.0),
		"block_mid è configurato a 16 FPS"
	)
	_expect(
		not player1.animated_sprite.sprite_frames.get_animation_loop(&"block_mid"),
		"block_mid non è configurato in loop"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"block_mid_recovery")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"block_mid_recovery") == 9,
		"block_mid_recovery usa i fotogrammi 8-16"
	)
	_expect(
		is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"block_mid_recovery"),
			16.0
		)
		and not player1.animated_sprite.sprite_frames.get_animation_loop(&"block_mid_recovery"),
		"block_mid_recovery è non ciclica a 16 FPS"
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
		and player1.animated_sprite.sprite_frames.get_frame_count(&"block_low") == 16,
		"block_low da posizione alta parte dal fotogramma 1"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"block_low_crouched")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"block_low_crouched") == 8,
		"block_low da posizione bassa parte dal fotogramma 9"
	)
	_expect(
		player1.animated_sprite.sprite_frames.has_animation(&"block_low_recovery")
		and player1.animated_sprite.sprite_frames.get_frame_count(&"block_low_recovery") == 15,
		"block_low_recovery torna indietro dai fotogrammi 15-1"
	)
	_expect(
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"block_low"), 16.0)
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"block_low_crouched"),
			16.0
		)
		and is_equal_approx(
			player1.animated_sprite.sprite_frames.get_animation_speed(&"block_low_recovery"),
			16.0
		),
		"le varianti block_low sono configurate a 16 FPS"
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
		is_equal_approx(player1.animated_sprite.sprite_frames.get_animation_speed(&"ko"), 16.0),
		"ko è configurato a 16 FPS"
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
	_expect(
		jump_light_kick_shape.size == FighterCombat.JUMP_LIGHT_KICK_HITBOX_SIZE
		and player1.combat.hitbox_shape.position == FighterCombat.JUMP_LIGHT_KICK_HITBOX_POSITION,
		"il calcio leggero aereo usa la propria hitbox"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 92
		and player2.animated_sprite.animation == &"hurt_high",
		"il calcio leggero aereo infligge danno light e provoca hurt_high"
	)
	await create_timer(player1.get_animation_duration(&"jump_light_kick") + 0.05).timeout
	var jump_light_last_frame := (
		player1.animated_sprite.sprite_frames.get_frame_count(&"jump_light_kick") - 1
	)
	_expect(
		player1.current_state == Mangler.State.ATTACKING
		and player1.animated_sprite.frame == jump_light_last_frame
		and not player1.animated_sprite.is_playing()
		and not player1.combat.hitbox_shape.disabled,
		"tenendo premuto il calcio aereo conserva ultimo frame e hitbox attiva"
	)
	player1.global_position.y = (
		player1.shadow_ground_y - FighterCombat.AIRBORNE_ATTACK_GROUND_CANCEL_HEIGHT + 1.0
	)
	player1.velocity.y = 1.0
	await create_timer(0.1).timeout
	_expect(
		player1.current_state == Mangler.State.JUMPING
		and player1.animated_sprite.animation == &"idle"
		and player1.combat.hitbox_shape.disabled,
		"a 40 px dal terreno il colpo aereo termina anche mantenendo premuto il tasto"
	)
	Input.action_release(player1.get_input_action("light_kick"))
	var health_after_first_aerial_attack := player2.combat.current_health
	player1.combat.try_attack(&"medium_kick")
	_expect(
		player1.current_state == Mangler.State.JUMPING
		and not player1.combat.is_attacking
		and player2.combat.current_health == health_after_first_aerial_attack,
		"un secondo attacco aereo nello stesso salto viene ignorato"
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
	player1.combat.try_attack(&"medium_punch")
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
	_expect(
		jump_medium_punch_shape.size == aerial_medium_punch.hitbox_size
		and player1.combat.hitbox_shape.position == aerial_medium_punch.hitbox_position,
		"il pugno medio aereo usa la hitbox del danno medium"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 90
		and player2.animated_sprite.animation == &"hurt_high",
		"il pugno medio aereo infligge danno medium e provoca hurt_high"
	)
	await create_timer(player1.get_animation_duration(&"jump_medium_punch") + 0.05).timeout
	_expect(
		player1.current_state == Mangler.State.JUMPING,
		"al termine del pugno medio aereo Mangler torna allo stato di salto"
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
	player1.combat.try_attack(&"medium_kick")
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
	_expect(
		jump_medium_kick_shape.size == FighterCombat.JUMP_MEDIUM_KICK_HITBOX_SIZE
		and player1.combat.hitbox_shape.position == FighterCombat.JUMP_MEDIUM_KICK_HITBOX_POSITION,
		"il calcio medio aereo usa la propria hitbox"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 88
		and player2.animated_sprite.animation == &"hurt_high",
		"il calcio medio aereo infligge danno medium e provoca hurt_high"
	)
	await create_timer(player1.get_animation_duration(&"jump_medium_kick") + 0.05).timeout
	_expect(
		player1.current_state == Mangler.State.JUMPING,
		"al termine del calcio medio aereo Mangler torna allo stato di salto"
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
	var aerial_heavy_velocity_before_attack := player1.velocity
	player1.combat.try_attack(&"heavy_kick")
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
	var jump_heavy_kick_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		jump_heavy_kick_shape.size == FighterCombat.JUMP_HEAVY_KICK_HITBOX_SIZE
		and player1.combat.hitbox_shape.position == FighterCombat.JUMP_HEAVY_KICK_HITBOX_POSITION,
		"il calcio potente aereo usa la propria hitbox"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 80
		and player2.animated_sprite.animation == &"hurt_high",
		"il calcio potente aereo infligge danno heavy e provoca hurt_high"
	)
	await create_timer(player1.get_animation_duration(&"jump_heavy_kick") + 0.05).timeout
	_expect(
		player1.current_state == Mangler.State.JUMPING,
		"al termine del calcio potente aereo Mangler torna allo stato di salto"
	)
	player1.position = aerial_test_position
	player1.velocity = Vector2(0.0, 1.0)
	player1.move_and_slide()
	player1.velocity = Vector2.ZERO
	player1.change_state(Mangler.State.IDLE)
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
		attack_shape.size == light_punch.hitbox_size
		and player1.combat.hitbox_shape.position == light_punch.hitbox_position,
		"AttackData configura geometria e posizione della hitbox"
	)
	_expect(
		light_punch.hitbox_size == Vector2(100.0, 35.0)
		and light_punch.hitbox_position == Vector2(50.0, -110.0),
		"il light punch è accorciato di 50 px soltanto verso l'avversario"
	)
	await create_timer(player1.get_animation_duration(&"light_punch_single") + 0.05).timeout
	_expect(player1.current_state == Mangler.State.IDLE, "il jab singolo completa 1-6 e il ritorno 6-1")
	_expect(
		player1.z_index == player1_default_z,
		"Player 1 ripristina l'ordine grafico normale al termine dell'attacco"
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
		standing_medium_shape.size == Vector2(105.0, 40.0)
		and player1.combat.hitbox_shape.position == Vector2(55.0, -108.0),
		"il medium punch in piedi estende la hitbox di 20 px verso l'avversario"
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
		and standing_light_kick.hit_height == AttackData.HitHeight.MID
		and player1.combat.get_hit_reaction_start_frame(standing_light_kick) == 4
		and is_equal_approx(standing_light_kick.startup, 6.0 / 24.0)
		and is_equal_approx(standing_light_kick.active, 4.0 / 24.0)
		and is_equal_approx(standing_light_kick.recovery, 6.0 / 24.0),
		"il light kick in piedi sincronizza startup, hurt-medium e recupero sui 16 frame"
	)
	var standing_light_kick_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		standing_light_kick_shape.size == Vector2(185.0, 35.0)
		and player1.combat.hitbox_shape.position == Vector2(97.5, -55.0),
		"il light kick estende la hitbox di 100 px verso l'avversario"
	)
	await create_timer(player1.get_animation_duration(&"light_kick") + 0.05).timeout
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
		and player2.animated_sprite.animation == &"hurt_mid"
		and player2.animated_sprite.frame == 4,
		"il calcio leggero basso provoca hurt_medium dal fotogramma 5"
	)
	await create_timer(player1.get_animation_duration(&"crouched_light_kick") + 0.05).timeout
	player2.combat.reset()

	var standing_medium_kick := player1.character_data.get_attack(&"medium_kick")
	player1.combat.try_attack(&"medium_kick")
	_expect(
		player1.animated_sprite.animation == &"medium_kick"
		and is_zero_approx(standing_medium_kick.startup)
		and is_equal_approx(standing_medium_kick.active, 8.0 / 24.0)
		and is_equal_approx(standing_medium_kick.recovery, 4.0 / 24.0),
		"il medium kick sincronizza i due impatti sui fotogrammi 1 e 8"
	)
	var standing_medium_kick_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		standing_medium_kick_shape.size == Vector2(165.0, 45.0)
		and player1.combat.hitbox_shape.position == Vector2(97.5, -65.0),
		"il medium kick usa la hitbox estesa verso l'avversario"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 94
		and player2.animated_sprite.animation == &"hurt_high"
		and player2.animated_sprite.frame == 0,
		"il primo impatto del medium kick infligge 6 danni e avvia hurt-high dal frame 1"
	)
	player1.animated_sprite.frame = 7
	_expect(
		player2.combat.current_health == 88
		and player2.animated_sprite.animation == &"hurt_mid"
		and player2.animated_sprite.frame == 4,
		"al fotogramma 8 il secondo impatto infligge 6 danni e avvia hurt-medium"
	)
	await create_timer(player1.get_animation_duration(&"medium_kick") + 0.05).timeout
	_expect(player1.current_state == Mangler.State.IDLE, "il medium kick torna in idle dopo il fotogramma 12")
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
		and not standing_heavy_kick.causes_knockdown
		and standing_heavy_kick.hit_height == AttackData.HitHeight.MID
		and player1.combat.get_hit_reaction_start_frame(standing_heavy_kick) == 4
		and is_equal_approx(standing_heavy_kick.startup, 8.0 / 24.0)
		and is_equal_approx(standing_heavy_kick.active, 2.0 / 24.0)
		and is_equal_approx(standing_heavy_kick.recovery, 6.0 / 24.0),
		"il nuovo heavy kick colpisce sui fotogrammi 9-10 con hurt-medium"
	)
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	_expect(
		player2.combat.current_health == 80
		and player2.current_state == Mangler.State.HIT
		and player2.animated_sprite.animation == &"hurt_mid"
		and player2.animated_sprite.frame == 4,
		"l'heavy kick infligge 20 danni e avvia hurt-medium dal fotogramma 5"
	)
	await create_timer(player1.get_animation_duration(&"heavy_kick") + 0.05).timeout
	_expect(player1.current_state == Mangler.State.IDLE, "il nuovo heavy kick completa tutti i 16 frame")
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
		is_equal_approx(crouched_heavy_kick_phases.x, 3.0 / 24.0)
		and is_equal_approx(crouched_heavy_kick_phases.y, 2.0 / 24.0)
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
		crouched_heavy_shape.size == Vector2(180.0, 170.0)
		and player1.combat.hitbox_shape.position == Vector2(90.0, -155.0),
		"il pugno potente abbassato ha una hitbox ridotta di 30 px"
	)
	_expect(
		player1.combat.get_effective_hit_height(heavy_punch) == AttackData.HitHeight.LOW,
		"il pugno potente abbassato provoca la reazione hurt_low"
	)
	var crouched_heavy_phases := player1.combat.get_attack_phase_durations(heavy_punch)
	_expect(
		is_equal_approx(crouched_heavy_phases.x, 9.0 / 24.0)
		and is_equal_approx(crouched_heavy_phases.y, 2.0 / 24.0),
		"il pugno potente abbassato diventa attivo al frame 10"
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
	await create_timer(16.0 / 24.0 + 0.05).timeout

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
		is_equal_approx(crouched_medium_phases.x, 8.0 / 24.0)
		and is_equal_approx(crouched_medium_phases.y, 3.0 / 24.0)
		and player1.combat.get_hit_reaction_start_frame(medium_punch) == 4,
		"al frame 9 il medio basso diventa attivo e hurt-medium parte dal frame 5"
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

	player1.combat.try_attack(&"light_punch")
	await create_timer(0.05).timeout
	player1.input_buffer.record_input_snapshot(0, 0, [&"light_punch"], true)
	player1.try_queue_light_punch_combo()
	_expect(
		player1.light_punch_combo_queued
		and player1.animated_sprite.animation == &"light_punch_double",
		"un secondo light ravvicinato continua dal jab nella combo da 16 frame"
	)
	player2.combat.take_damage(
		light_punch.damage,
		player1,
		light_punch.hitstun,
		light_punch.blockstun,
		light_punch.hit_height,
		false,
		light_punch.hit_reaction_start_frame,
		0,
		false
	)
	_expect(is_zero_approx(player2.velocity.x), "il light punch non spinge indietro l'avversario")
	player1.combat.light_punch_connected_targets.append(player2)
	player1.animated_sprite.frame = 7
	player1._on_animation_frame_changed()
	_expect(
		player1.combat.light_punch_followup_done
		and player2.combat.current_health == 90
		and player2.animated_sprite.animation == &"hurt_high"
		and player2.animated_sprite.frame == 4,
		"la combo infligge due danni light e al frame 8 riavvia hurt_high dal frame 5"
	)
	player2.combat.reset()
	player2.change_state(Mangler.State.IDLE)
	await create_timer(player1.get_animation_duration(&"light_punch_double") + 0.05).timeout
	_expect(player1.current_state == Mangler.State.IDLE, "la combo light completa torna in IDLE")

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
	await create_timer(player1.get_animation_duration(&"crouched_punch_crouched") + 0.05).timeout

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
	await create_timer(1.65).timeout
	_expect(
		player2.current_state == Mangler.State.SWEEP_KNOCKDOWN
		and player2.animated_sprite.frame == 24,
		"la spazzata completa i 25 frame e mantiene brevemente la posa a terra"
	)
	await create_timer(0.35).timeout
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
	player2.combat.take_damage(20, player1)
	Input.action_release(&"p2_move_right")
	_expect(
		player2.combat.current_health == health_before_guard,
		"la guardia riuscita non infligge danno"
	)
	_expect(player2.current_state == Mangler.State.BLOCKING, "guardia attiva BLOCKING")
	_expect(player2.animated_sprite.animation == &"block_mid", "la guardia centrale riproduce block_mid")
	_expect(player2_bar.value == 80.0, "la barra non cala durante la guardia")
	await create_timer(0.2).timeout
	_expect(player2.current_state == Mangler.State.BLOCKING, "BLOCKING mantiene i fotogrammi 4-7")
	await create_timer(0.1).timeout
	_expect(
		player2.current_state == Mangler.State.BLOCK_RECOVERY
		and player2.animated_sprite.animation == &"block_mid_recovery",
		"a fine blocco prosegue dai fotogrammi 8-16"
	)
	await create_timer(0.6).timeout
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
		"da posizione già bassa la parata parte dal fotogramma 9"
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
	_expect(player1.current_state == Mangler.State.IDLE, "reset stato Player 1")
	_expect(player2.current_state == Mangler.State.IDLE, "reset stato Player 2")
	_expect(player1_bar.value == 100.0 and player2_bar.value == 100.0, "reset barre UI")
	_expect(not player1.controls_enabled and not player2.controls_enabled, "controlli bloccati durante il countdown")
	await create_timer(2.1).timeout
	_expect(bool(arena.get("round_active")), "training riattivato dopo il reset")
	_expect(player1.controls_enabled and player2.controls_enabled, "controlli riattivati dopo il reset")

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
	Input.action_release(&"p2_move_right")
