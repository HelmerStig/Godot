extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	var movement := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(movement)
	for tick in 4:
		await tree.physics_frame
	movement.set_physics_process(false)
	var fighter: Mangler
	for node in movement._fighters:
		node.set_physics_process(false)
		node.is_player_controlled = false
		node.position.x = -5000.0
		if node is Mangler:
			fighter = node
	var audio: Node = fighter.attack_audio
	var contracts := {
		&"light_punch": ["res://sound-libraries/punch_short_whoosh_30.wav", "res://assets/sounds/sfx/light-punch.wav"],
		&"medium_punch": ["res://assets/sounds/sfx/swosh.wav", "res://assets/sounds/sfx/light-punch.wav"],
		&"heavy_punch": ["res://assets/sounds/sfx/swosh.wav", "res://assets/sounds/sfx/strong-punch.wav"],
		&"light_kick": ["res://sound-libraries/kick_short_whoosh_12.wav", "res://sound-libraries/body_hit_small_11.wav"],
		&"medium_kick": ["res://sound-libraries/kick_short_whoosh_23.wav", "res://sound-libraries/body_hit_large_44.wav"],
		&"heavy_kick": ["res://sound-libraries/kick_long_whoosh_19.wav", "res://sound-libraries/body_hit_large_76.wav"],
	}
	for stance in ["standing", "crouched", "airborne"]:
		for attack_name in contracts:
			fighter.reset_fighter(Vector2(1000.0, movement.FLOOR_Y - (300.0 if stance == "airborne" else 0.0)))
			fighter.opponent = null
			fighter.velocity = Vector2(0.0, -1.0 if stance == "airborne" else 1.0)
			fighter.move_and_slide()
			if stance == "airborne":
				fighter.change_state(Fighter.State.JUMPING)
			elif stance == "crouched":
				fighter.return_to_crouch_pose()
			var down: bool = stance == "crouched"
			fighter.input_buffer.record_input_snapshot(0, 1 if down else 0, [], false)
			fighter.combat.try_attack(attack_name, FighterInputBuffer.Direction.DOWN if down else FighterInputBuffer.Direction.NEUTRAL)
			fighter.animated_sprite.pause()
			var whoosh: AudioStreamPlayer = audio.whoosh_players[attack_name]
			var hit: AudioStreamPlayer = audio.hit_players[attack_name]
			var label := "%s %s" % [stance, attack_name]
			expect.call(fighter.combat.is_attacking and whoosh.playing and whoosh.stream.resource_path == contracts[attack_name][0], label + ": attacco reale avvia whoosh di Arianna")
			expect.call(not hit.playing and hit.stream.resource_path == contracts[attack_name][1], label + ": file hit corretto, silenzioso a vuoto")
			fighter.combat.attack_connected.emit(attack_name, FighterCombat.DamageResult.IGNORED)
			fighter.combat.attack_connected.emit(attack_name, FighterCombat.DamageResult.BLOCKED)
			expect.call(not hit.playing and not audio._hit_played, label + ": nessun impatto per colpo ignorato o parato")
			fighter.combat.attack_connected.emit(attack_name, FighterCombat.DamageResult.HIT)
			expect.call(hit.playing and audio._hit_played, label + ": contatto riuscito avvia hit")
			hit.stop()
			fighter.combat.attack_connected.emit(attack_name, FighterCombat.DamageResult.KNOCKOUT)
			expect.call(not hit.playing, label + ": un solo suono per attacco")
			fighter.combat.cancel_current_action()
			fighter.combat.attack_connected.emit(attack_name, FighterCombat.DamageResult.HIT)
			expect.call(not whoosh.playing and not hit.playing, label + ": cancellazione ferma whoosh e ignora eventi tardivi")
			fighter.reset_fighter(Vector2(1000.0, movement.FLOOR_Y))
			expect.call(not whoosh.playing and not hit.playing and not audio._hit_played, label + ": reset ripulisce audio")
	# Direct state interruption must also silence an action before its timer ends.
	fighter.combat.try_attack(&"light_punch")
	fighter.change_state(Fighter.State.HIT)
	expect.call(not audio.whoosh_players[&"light_punch"].playing, "Mangler: hurt interrompe whoosh")
	fighter.reset_fighter(Vector2(1000.0, movement.FLOOR_Y))
	fighter.velocity = Vector2(0.0, 1.0)
	fighter.move_and_slide()
	fighter.input_buffer.clear()
	fighter.combat.try_attack(&"light_punch")
	fighter.combat.cancel_current_action()
	fighter.combat.attack_connected.emit(&"light_punch", FighterCombat.DamageResult.KNOCKOUT)
	expect.call(audio.hit_players[&"light_punch"].playing, "Mangler: colpo KO riproduce hit anche dopo cancellazione sincrona di fine round")
	fighter.reset_fighter(Vector2(-5000.0, movement.FLOOR_Y))
	for node in movement._fighters:
		node.combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true
