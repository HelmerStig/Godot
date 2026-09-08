extends RefCounted


static func run(_tree: SceneTree, expect: Callable) -> bool:
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
	expect.call(character_data.attacks.size() == 8, "il profilo predefinito contiene otto AttackData")
	for attack_id in attack_ids:
		var attack := character_data.get_attack(attack_id)
		expect.call(attack != null, "risorsa caricata: " + str(attack_id))
		if attack != null:
			expect.call(attack.is_valid(), "risorsa valida: " + str(attack_id))

	var light_punch := character_data.get_attack(&"light_punch")
	var standing_light: Resource
	var crouched_light: Resource
	if light_punch != null:
		for variant in light_punch.variants:
			if variant.variant_id == &"standing":
				standing_light = variant
			elif variant.variant_id == &"crouched":
				crouched_light = variant
	expect.call(
		standing_light != null
		and standing_light.animation_name == &"light_punch_single"
		and standing_light.startup_frames == 11
		and standing_light.active_frames == 3,
		"il frame data del light punch in piedi proviene da AttackVariantData"
	)
	expect.call(
		crouched_light != null
		and crouched_light.hitbox_size == Vector2(150.0, 35.0)
		and crouched_light.hit_height == AttackData.HitHeight.MID,
		"la variante accovacciata contiene hitbox e altezza del colpo"
	)
	expect.call(
		light_punch != null and is_equal_approx(light_punch.get_total_duration(), 0.3),
		"startup, active e recovery determinano la durata totale"
	)
	expect.call(
		light_punch != null
		and light_punch.hit_height == AttackData.HitHeight.HIGH
		and light_punch.hit_reaction_start_frame == 3,
		"il light punch colpisce alto e avvia la reazione dal quarto frame"
	)
	var heavy_punch := character_data.get_attack(&"heavy_punch")
	expect.call(
		heavy_punch != null and heavy_punch.hit_height == AttackData.HitHeight.HIGH,
		"il pugno pesante colpisce in alto al volto"
	)
	var light_kick := character_data.get_attack(&"light_kick")
	var medium_kick := character_data.get_attack(&"medium_kick")
	expect.call(
		light_kick != null and light_kick.hit_height == AttackData.HitHeight.MID,
		"il calcio leggero in piedi provoca hurt-medium"
	)
	expect.call(
		medium_kick != null and medium_kick.hit_height == AttackData.HitHeight.LOW,
		"il calcio medio colpisce in basso"
	)
	var heavy_kick := character_data.get_attack(&"heavy_kick")
	expect.call(
		heavy_kick != null
		and heavy_kick.hit_height == AttackData.HitHeight.MID
		and not heavy_kick.causes_knockdown,
		"il calcio pesante provoca hurt-medium senza knockdown"
	)
	return true
