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
		and player1.animated_sprite.sprite_frames.get_frame_count(&"light_punch_single") == 18,
		"il pugno light usa 18 frame sul foglio unificato a 48 FPS"
	)
	var light_first := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"light_punch_single", 0)
		as AtlasTexture
	)
	var light_impact := (
		player1.animated_sprite.sprite_frames.get_frame_texture(&"light_punch_single", 16)
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
		"la presa separa e sincronizza i 25 frame rear e front"
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
			24.0
		),
		"sweep_knockdown è configurato a 24 FPS"
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
	var grab_target_original_position := player2.global_position
	player2.global_position = player1.global_position + Vector2(420.0, 0.0)
	player1.start_grab_tentative()
	await create_timer(1.08).timeout
	_expect(
		player1.current_state == Mangler.State.IDLE
		and player1.animated_sprite.animation == &"idle"
		and not player1.grab_succeeded
		and not player1.grab_front_sprite.visible,
		"se il tentativo di presa manca, riproduce 24-1 e torna in IDLE"
	)
	player2.global_position = player1.global_position + Vector2(120.0, 0.0)
	var health_before_grab_headbutt := player2.combat.current_health
	var headbutt_afterimages_before := player1.attack_afterimage_spawn_count
	player1.start_grab_tentative()
	await create_timer(0.56).timeout
	_expect(
		player1.grab_succeeded
		and player1.animated_sprite.animation == &"grab_headbutt"
		and player1.animated_sprite.is_playing()
		and player1.grab_front_sprite.visible
		and player1.grab_front_sprite.animation == &"grab_headbutt_front"
		and player1.grab_front_sprite.frame == player1.animated_sprite.frame
		and player2.grabbed_by == player1
		and not player2.controls_enabled
		and player2.animated_sprite.animation == &"grabbed"
		and player2.animated_sprite.is_playing(),
		"se la presa riesce, avvia subito la testata e mantiene l'avversario immobilizzato"
	)
	await create_timer(0.70).timeout
	_expect(
		player1.grab_headbutt_hit_landed
		and player2.combat.current_health == health_before_grab_headbutt - Mangler.GRAB_HEADBUTT_DAMAGE
		and player2.grabbed_by == player1
		and not player2.controls_enabled
		and player2.animated_sprite.animation == &"hurt_high",
		"la testata colpisce al frame 17 senza permettere risposta o parata"
	)
	_expect(
		player1.attack_afterimage_spawn_count > headbutt_afterimages_before
		and player1.get_tree().get_node_count_in_group("grab_headbutt_front_afterimage") > 0,
		"durante l'affondo la testata genera scie sincronizzate rear e front"
	)
	await create_timer(0.38).timeout
	_expect(
		player1.current_state == Mangler.State.IDLE
		and player2.grabbed_by == null
		and player2.controls_enabled,
		"al termine della testata entrambi i personaggi vengono liberati"
	)
	player2.global_position = grab_target_original_position
	player2.combat.reset()

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
	await process_frame
	await process_frame
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
		player1.animated_sprite.animation == &"medium_kick",
		"il medium kick avvia l'animazione standing"
	)
	var standing_mk_phases := player1.combat.get_attack_phase_durations(standing_medium_kick)
	_expect(
		is_equal_approx(standing_mk_phases.x, float(FighterCombat.STANDING_MEDIUM_KICK_ACTIVE_FRAME) / 24.0),
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
		crouched_heavy_shape.size == Vector2(80.0, 435.0)
		and player1.combat.hitbox_shape.position == Vector2(90.0, -255.0),
		"il pugno potente abbassato ha una hitbox ridotta di 30 px"
	)
	_expect(
		player1.combat.get_effective_hit_height(heavy_punch) == AttackData.HitHeight.LOW,
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
		is_equal_approx(crouched_medium_phases.x, float(FighterCombat.CROUCHED_MEDIUM_PUNCH_ACTIVE_FRAME) / 48.0)
		and is_equal_approx(crouched_medium_phases.y, 3.0 / 48.0)
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
	var health_before_crouched_light_guard := player2.combat.current_health
	Input.action_press(&"p2_move_right")
	await physics_frame
	await physics_frame
	player1.combat._apply_hit_to_area(player2.get_node("Hurtbox") as Area2D)
	Input.action_release(&"p2_move_right")
	_expect(
		player2.combat.current_health == health_before_crouched_light_guard
		and player2.current_state == Mangler.State.BLOCKING
		and player2.animated_sprite.animation == &"block_low",
		"il light punch basso parato attiva block_low senza infliggere danno"
	)
	player1.combat.is_attacking = false
	player2.combat.reset()
	player2.change_state(Mangler.State.IDLE)
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
	Input.action_release(&"p1_light_punch")
	Input.action_release(&"p1_medium_punch")
	Input.action_release(&"p1_move_left")
	Input.action_release(&"p1_move_right")
	Input.action_release(&"p1_medium_kick")
	Input.action_release(&"p1_heavy_kick")
	Input.action_release(&"p2_move_right")
