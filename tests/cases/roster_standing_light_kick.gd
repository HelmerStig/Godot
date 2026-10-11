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
	for fighter in fighters:
		var contracts := {
			&"oscare": [25, 48.0, 10, 12],
			&"mileto": [21, 48.0, 9, 11],
			&"torpe": [14, 24.0, 8, 10],
			&"peiro": [23, 40.0, 11, 13],
			&"bue": [26, 48.0, 10, 12],
		}
		var contract: Array = contracts[fighter.fighter_id]
		var count: int = contract[0]
		var fps: float = contract[1]
		var first: int = contract[2]
		var last: int = contract[3]
		var frames := fighter.animated_sprite.sprite_frames
		var exact := frames.get_frame_count(&"light_kick") == count and frames.get_animation_speed(&"light_kick") == fps and not frames.get_animation_loop(&"light_kick")
		for index in count:
			var texture := frames.get_frame_texture(&"light_kick", index) as AtlasTexture
			exact = exact and texture.atlas == fighter.light_kick_sheet and texture.region == Rect2(Vector2(index % 7, index / 7) * 512.0, Vector2(512.0, 512.0))
		expect.call(exact and fighter.light_kick_sheet.resource_path.ends_with("/light_kick.png"), fighter.name + ": foglio, slicing e FPS del calcio leggero in piedi")
		fighter.opponent = null
		fighter.position.x = -10000.0
		for facing in [true, false]:
			fighter.is_facing_right = facing
			fighter._start_light_kick()
			fighter.animated_sprite.pause()
			var phases := fighter.combat.get_attack_phase_durations(fighter.combat.current_attack)
			expect.call(is_equal_approx(phases.x + phases.y + phases.z, float(count) / fps), fighter.name + ": durata completa senza ritorno")
			expect.call(not fighter.combat.is_crouched_light_kick and fighter.combat.hitbox.scale.x == (1.0 if facing else -1.0), fighter.name + ": attacco standing e hitbox orientata")
			var active_exact := true
			var profile_exact := true
			for index in count:
				fighter.animated_sprite.frame = index
				fighter._update_light_kick_hitbox()
				fighter.update_collision_profile()
				active_exact = active_exact and fighter.combat.hitbox_shape.disabled == not (index >= first - 1 and index <= last - 1)
				profile_exact = profile_exact and fighter.get_crouch_progress() == 0.0 and fighter.collision_shape.shape.size == Fighter.STANDING_COLLISION_SIZE
			expect.call(active_exact, fighter.name + ": soltanto i frame attivi richiesti")
			expect.call(profile_exact, fighter.name + ": profilo eretto durante tutta la mossa")
			fighter._on_animation_finished()
			expect.call(fighter.current_state == Fighter.State.IDLE and not fighter.combat.is_attacking and fighter.combat.hitbox_shape.disabled and fighter.animated_sprite.animation == &"idle", fighter.name + ": fine mossa torna in idle")
		var duration := float(count) / fps
		for scenario in ["standing", "crouched", "guard", "standing_guard", "crouched_attack"]:
			target = (fighters[(fighters.find(fighter) + 1) % fighters.size()] as Fighter) if scenario == "crouched_attack" else movement._fighters[0] as Fighter
			var guarded: bool = scenario == "guard" or (scenario == "standing_guard" and fighter.fighter_id == &"torpe")
			var crouched: bool = scenario in ["crouched", "guard", "crouched_attack"]
			fighter.reset_fighter(Vector2(1000.0, movement.FLOOR_Y))
			target.reset_fighter(Vector2(1130.0, movement.FLOOR_Y))
			fighter.is_facing_right = true
			target.is_facing_right = false
			target.opponent = fighter
			if crouched:
				target.return_to_crouch_pose()
			if scenario == "crouched_attack":
				(target as IdleRosterFighter)._start_low_light_kick()
				target.animated_sprite.pause()
			target.input_buffer.record_input_snapshot(1 if scenario in ["guard", "standing_guard"] else 0, 1 if crouched else 0, [], false)
			target.combat.set_guarding(scenario in ["guard", "standing_guard"])
			for tick in 3:
				await tree.physics_frame
			target.velocity = Vector2(0.0, 1.0)
			target.move_and_slide()
			fighter._start_light_kick()
			expect.call(fighter._standing_light_kick_whoosh_audio.playing and fighter._standing_light_kick_whoosh_audio.stream == load("res://sound-libraries/kick_short_whoosh_12.wav"), fighter.name + ": whoosh alla partenza")
			await tree.create_timer(float(first - 1) / fps + 0.025).timeout
			var reaction: StringName = target.get_block_animation(AttackData.HitHeight.LOW if crouched else fighter.light_kick_hit_height, crouched) if guarded else (&"hurt_crouched" if crouched else (&"hurt_mid" if fighter.fighter_id == &"torpe" else &"hurt_low"))
			expect.call(target.animated_sprite.animation == reaction and target.combat.current_health == (100 if guarded else 92), fighter.name + ": contatto reale " + scenario)
			expect.call(fighter._light_kick_hit_sound_played == not guarded and fighter._standing_light_kick_hit_audio.stream == load("res://sound-libraries/body_hit_small_11.wav"), fighter.name + ": impatto audio solo sul colpo entrato")
			await tree.create_timer(duration + 0.05).timeout
			expect.call(fighter.current_state == Fighter.State.IDLE and target.combat.current_health == (100 if guarded else 92), fighter.name + ": un solo danno e ritorno in idle")
			fighter.position.x = -5000.0
			target.reset_fighter(Vector2(-5000.0, movement.FLOOR_Y))
		target = movement._fighters[0] as Fighter
		fighter.reset_fighter(Vector2(1000.0, movement.FLOOR_Y))
		target.reset_fighter(Vector2(2000.0, movement.FLOOR_Y))
		await tree.physics_frame
		fighter.velocity = Vector2(0.0, 1.0)
		fighter.move_and_slide()
		fighter.input_buffer.record_input_snapshot(0, 0, [&"light_kick"], true)
		fighter._physics_process(1.0 / 60.0)
		expect.call(fighter.animated_sprite.animation == &"light_kick" and fighter.combat.is_attacking, fighter.name + ": light kick senza basso avvia la mossa")
		await tree.create_timer(duration + 0.05).timeout
		expect.call(fighter.current_state == Fighter.State.IDLE and target.combat.current_health == 100 and not fighter._light_kick_hit_sound_played, fighter.name + ": a vuoto torna in idle senza impatto audio")
		fighter._start_light_kick()
		fighter.combat.cancel_current_action()
		fighter.change_state(Fighter.State.HIT)
		fighter.animated_sprite.pause()
		await tree.create_timer(duration + 0.05).timeout
		expect.call(fighter.current_state == Fighter.State.HIT and not fighter.combat.is_attacking and fighter.combat.hitbox_shape.disabled and not fighter._standing_light_kick_whoosh_audio.playing, fighter.name + ": interruzione non forza un ritorno tardivo in idle")
		fighter._start_light_kick()
		fighter.reset_fighter(Vector2(-5000.0, movement.FLOOR_Y))
		expect.call(not fighter.combat.is_attacking and not fighter.combat.is_crouched_light_kick and fighter.combat.hitbox_shape.disabled and fighter.current_state == Fighter.State.IDLE, fighter.name + ": reset cancella il calcio leggero in piedi")
	for node in movement._fighters:
		node.combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true
