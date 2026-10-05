extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	var movement := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(movement)
	for tick in 4:
		await tree.physics_frame
	movement.set_physics_process(false)
	var fighters: Array[IdleRosterFighter] = []
	var target := movement._fighters[0] as Fighter
	for node in movement._fighters:
		node.set_physics_process(false)
		node.is_player_controlled = false
		node.position.x = -5000.0
		if node is IdleRosterFighter:
			fighters.append(node)
	var contracts := {&"oscare": [22,48.0,96.0,22,22], &"mileto": [24,48.0,0.0,13,15], &"torpe": [14,30.0,30.0,14,14], &"peiro": [15,48.0,48.0,15,15], &"bue": [11,24.0,24.0,11,11]}
	for fighter in fighters:
		var contract: Array = contracts[fighter.fighter_id]
		var frames := fighter.animated_sprite.sprite_frames
		var exact: bool = frames.get_frame_count(&"medium_punch") == contract[0] and frames.get_animation_speed(&"medium_punch") == contract[1] and not frames.get_animation_loop(&"medium_punch")
		for animation in [&"medium_punch", &"medium_punch_recovery"]:
			if animation == &"medium_punch_recovery" and contract[2] == 0.0:
				exact = exact and not frames.has_animation(animation)
				continue
			if animation == &"medium_punch_recovery":
				exact = exact and frames.get_frame_count(animation) == contract[0] - 1 and frames.get_animation_speed(animation) == contract[2] and not frames.get_animation_loop(animation)
			for index in frames.get_frame_count(animation):
				var source_index: int = index if animation == &"medium_punch" else int(contract[0]) - 2 - index
				var texture := frames.get_frame_texture(animation,index) as AtlasTexture
				exact = exact and texture.atlas == fighter.medium_punch_sheet and texture.region == Rect2(Vector2(source_index % fighter.medium_punch_columns, source_index / fighter.medium_punch_columns) * 512.0,Vector2(512.0,512.0))
		expect.call(exact, fighter.name + ": medium punch slicing, andata e ritorno esatti")
		fighter.opponent = null
		fighter.position.x = -10000.0
		fighter._start_medium_punch()
		fighter.animated_sprite.pause()
		var active_exact := true
		for index in int(contract[0]):
			fighter.animated_sprite.frame = index
			fighter._update_medium_punch_hitbox()
			active_exact = active_exact and fighter.combat.hitbox_shape.disabled == not (index >= int(contract[3])-1 and index <= int(contract[4])-1)
		expect.call(active_exact and fighter.combat.get_effective_hit_height(fighter.combat.current_attack) == AttackData.HitHeight.HIGH, fighter.name + ": frame attivi esatti e altezza HIGH")
		fighter._on_animation_finished()
		if contract[2] > 0.0:
			expect.call(fighter.combat.hitbox_shape.disabled and fighter.animated_sprite.animation == &"medium_punch_recovery" and fighter.combat.is_attacking, fighter.name + ": ritorno senza hitbox mantiene attacco attivo")
			fighter._on_animation_finished()
		expect.call(fighter.current_state == Fighter.State.IDLE and not fighter.combat.is_attacking, fighter.name + ": sequenza completa torna in idle")
		var duration: float = float(contract[0]) / float(contract[1]) + (float(contract[0]-1)/float(contract[2]) if contract[2] > 0.0 else 0.0)
		for guarded in [false,true]:
			fighter.reset_fighter(Vector2(1000.0, movement.FLOOR_Y))
			target.reset_fighter(Vector2(1130.0, movement.FLOOR_Y))
			fighter.is_facing_right = true
			target.is_facing_right = false
			target.opponent = fighter
			target.velocity = Vector2(0.0,1.0)
			target.move_and_slide()
			target.input_buffer.record_input_snapshot(1 if guarded else 0,0,[],false)
			target.combat.set_guarding(guarded)
			for tick in 3:
				await tree.physics_frame
			target.velocity = Vector2(0.0, 1.0)
			target.move_and_slide()
			fighter._start_medium_punch()
			await tree.create_timer(0.22).timeout
			expect.call(fighter._medium_punch_whoosh_audio.playing and fighter._medium_punch_whoosh_audio.stream == load("res://assets/sounds/sfx/swosh.wav"), fighter.name + ": whoosh del medio di Arianna")
			await tree.create_timer((float(contract[3])-1)/float(contract[1]) - 0.22 + 0.03).timeout
			expect.call(target.animated_sprite.animation == (&"block_high" if guarded else &"hurt_high") and target.combat.current_health == (100 if guarded else 90), fighter.name + ": contatto reale genera hurt_high o block_high")
			expect.call(fighter._medium_punch_hit_sound_played == not guarded and (guarded or fighter._light_punch_hit_audio.stream == load("res://assets/sounds/sfx/light-punch.wav")), fighter.name + ": audio impatto solo se il colpo entra")
			await tree.create_timer(duration + 0.05).timeout
			expect.call(fighter.current_state == Fighter.State.IDLE and target.combat.current_health == (100 if guarded else 90), fighter.name + ": nessun secondo colpo nel ritorno")
			fighter.position.x = -5000.0
		fighter.reset_fighter(Vector2(1000.0, movement.FLOOR_Y))
		target.reset_fighter(Vector2(2000.0, movement.FLOOR_Y))
		await tree.physics_frame
		fighter.velocity = Vector2(0.0, 1.0)
		fighter.move_and_slide()
		fighter.input_buffer.record_input_snapshot(0, 0, [&"medium_punch"], true)
		fighter._physics_process(1.0 / 60.0)
		expect.call(fighter.combat.is_attacking and fighter.animated_sprite.animation == &"medium_punch", fighter.name + ": input medium punch avvia la mossa a terra")
		await tree.create_timer(0.22).timeout
		expect.call(fighter._medium_punch_whoosh_audio.playing, fighter.name + ": whoosh anche senza bersaglio a portata")
		await tree.create_timer(duration).timeout
		expect.call(target.combat.current_health == 100 and not fighter._medium_punch_hit_sound_played, fighter.name + ": colpo fuori hurtbox non causa danno o audio impatto")
		target.reset_fighter(Vector2(1130.0, movement.FLOOR_Y))
		target.change_state(Fighter.State.CROUCHING)
		target.animated_sprite.frame = target.animated_sprite.sprite_frames.get_frame_count(&"crouch") - 1
		target.animated_sprite.pause()
		target.update_collision_profile()
		await tree.physics_frame
		fighter._start_medium_punch()
		await tree.create_timer(duration + 0.05).timeout
		expect.call(target.combat.current_health == 100 and not fighter._medium_punch_hit_sound_played, fighter.name + ": pugno alto passa sopra la hurtbox accovacciata")
		fighter._start_medium_punch()
		fighter.combat.cancel_current_action()
		fighter.change_state(Fighter.State.HIT)
		await tree.create_timer(0.22).timeout
		expect.call(fighter.combat.hitbox_shape.disabled and not fighter._medium_punch_whoosh_audio.playing, fighter.name + ": interruzione annulla hitbox e whoosh ritardato")
		fighter.reset_fighter(Vector2(-5000.0, movement.FLOOR_Y))
	for node in movement._fighters:
		node.combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true

