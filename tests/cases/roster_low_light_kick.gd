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
			&"oscare": [28, 48.0, 10, 12, false],
			&"mileto": [28, 48.0, 16, 18, false],
			&"torpe": [28, 48.0, 10, 12, false],
			&"peiro": [28, 48.0, 17, 19, false],
			&"bue": [28, 48.0, 10, 12, false],
		}
		var contract: Array = contracts[fighter.fighter_id]
		var count: int = contract[0]
		var fps: float = contract[1]
		var first: int = contract[2]
		var last: int = contract[3]
		var reverse: bool = contract[4]
		var frames := fighter.animated_sprite.sprite_frames
		var exact := frames.get_frame_count(&"crouched_light_kick") == count and frames.get_animation_speed(&"crouched_light_kick") == fps and not frames.get_animation_loop(&"crouched_light_kick")
		for index in count:
			var texture := frames.get_frame_texture(&"crouched_light_kick", index) as AtlasTexture
			exact = exact and texture.atlas == fighter.low_light_kick_sheet and texture.region == Rect2(Vector2(index % 7, index / 7) * 512.0, Vector2(512.0, 512.0))
		expect.call(exact and fighter.low_light_kick_sheet.resource_path.ends_with("/light_kick_low_v2.png"), fighter.name + ": foglio, slicing e FPS del calcio basso")
		fighter.opponent = null
		fighter.position.x = -10000.0
		for facing in [true, false]:
			fighter.is_facing_right = facing
			fighter._start_low_light_kick()
			fighter.animated_sprite.pause()
			var phases := fighter.combat.get_attack_phase_durations(fighter.combat.current_attack)
			expect.call(is_equal_approx(phases.x + phases.y + phases.z, float(count + (count - 1 if reverse else 0)) / fps), fighter.name + ": durata attacco include tutto il ritorno")
			expect.call(fighter.combat.is_crouched_light_kick and fighter.combat.hitbox.scale.x == (1.0 if facing else -1.0), fighter.name + ": attacco crouched e hitbox orientata")
			var active_exact := true
			var profile_exact := true
			for index in count:
				fighter.animated_sprite.frame = index
				fighter._update_low_light_kick_hitbox()
				fighter.update_collision_profile()
				active_exact = active_exact and fighter.combat.hitbox_shape.disabled == not (index >= first - 1 and index <= last - 1)
				profile_exact = profile_exact and fighter.get_crouch_progress() == 1.0 and fighter.collision_shape.shape.size == Fighter.CROUCH_COLLISION_SIZE
			expect.call(active_exact, fighter.name + ": soltanto i frame attivi richiesti")
			expect.call(profile_exact, fighter.name + ": profilo basso durante tutta la mossa")
			fighter._on_animation_finished()
			if reverse:
				fighter.animated_sprite.pause()
				var recovery_exact := fighter.animated_sprite.animation == &"crouched_light_kick_recovery" and fighter.current_state == Fighter.State.ATTACKING and fighter.combat.is_attacking
				recovery_exact = recovery_exact and frames.get_frame_count(&"crouched_light_kick_recovery") == count - 1 and frames.get_animation_speed(&"crouched_light_kick_recovery") == fps and not frames.get_animation_loop(&"crouched_light_kick_recovery")
				for index in count - 1:
					var texture := frames.get_frame_texture(&"crouched_light_kick_recovery", index) as AtlasTexture
					var source := count - 2 - index
					fighter.animated_sprite.frame = index
					fighter._update_low_light_kick_hitbox()
					fighter.update_collision_profile()
					recovery_exact = recovery_exact and texture.atlas == fighter.low_light_kick_sheet and texture.region == Rect2(Vector2(source % 7, source / 7) * 512.0, Vector2(512.0, 512.0)) and fighter.combat.hitbox_shape.disabled and fighter.get_crouch_progress() == 1.0
				expect.call(recovery_exact, fighter.name + ": ritorno N-1 fino a 1 a 48 FPS, senza hitbox o duplicazione del picco")
				fighter._on_animation_finished()
			expect.call(fighter.current_state == Fighter.State.CROUCHING and not fighter.combat.is_attacking and fighter.combat.hitbox_shape.disabled and fighter.animated_sprite.animation == &"crouch" and fighter.animated_sprite.frame == frames.get_frame_count(&"crouch") - 1 and not fighter.animated_sprite.is_playing(), fighter.name + ": fine mossa torna alla stance crouched ferma")
		var duration := float(count + (count - 1 if reverse else 0)) / fps
		for scenario in ["standing", "crouched", "guard", "standing_guard", "standing_low_input"]:
			var guarded: bool = scenario == "guard"
			var crouched: bool = scenario in ["crouched", "guard"]
			fighter.reset_fighter(Vector2(1000.0, movement.FLOOR_Y))
			target.reset_fighter(Vector2(1130.0, movement.FLOOR_Y))
			fighter.is_facing_right = true
			target.is_facing_right = false
			target.opponent = fighter
			if crouched:
				target.return_to_crouch_pose()
			target.input_buffer.record_input_snapshot(1 if scenario in ["guard", "standing_guard", "standing_low_input"] else 0, 1 if crouched or scenario == "standing_low_input" else 0, [], false)
			target.combat.set_guarding(scenario in ["guard", "standing_guard", "standing_low_input"])
			for tick in 3:
				await tree.physics_frame
			target.velocity = Vector2(0.0, 1.0)
			target.move_and_slide()
			fighter._start_low_light_kick()
			expect.call(fighter._light_kick_whoosh_audio.playing and fighter._light_kick_whoosh_audio.stream == load("res://sound-libraries/kick_short_whoosh_23.wav"), fighter.name + ": whoosh alla partenza")
			await tree.create_timer(float(first - 1) / fps + 0.025).timeout
			var reaction: StringName = target.get_block_animation(AttackData.HitHeight.LOW, true) if guarded else (&"hurt_crouched" if crouched else &"hurt_low")
			expect.call(target.animated_sprite.animation == reaction and target.combat.current_health == (100 if guarded else 92), fighter.name + ": contatto reale " + scenario)
			expect.call(fighter._light_kick_hit_sound_played == not guarded and fighter._light_kick_hit_audio.stream == load("res://sound-libraries/body_hit_large_44.wav"), fighter.name + ": impatto audio solo sul colpo entrato")
			await tree.create_timer(duration + 0.05).timeout
			expect.call(fighter.current_state == Fighter.State.CROUCHING and target.combat.current_health == (100 if guarded else 92), fighter.name + ": un solo danno e ritorno accovacciato")
			fighter.position.x = -5000.0
		fighter.reset_fighter(Vector2(1000.0, movement.FLOOR_Y))
		target.reset_fighter(Vector2(2000.0, movement.FLOOR_Y))
		await tree.physics_frame
		fighter.velocity = Vector2(0.0, 1.0)
		fighter.move_and_slide()
		fighter.input_buffer.record_input_snapshot(0, 1, [&"light_kick"], true)
		fighter._physics_process(1.0 / 60.0)
		expect.call(fighter.animated_sprite.animation == &"crouched_light_kick" and fighter.combat.is_attacking, fighter.name + ": basso piu light kick avvia la mossa")
		await tree.create_timer(duration + 0.05).timeout
		expect.call(fighter.current_state == Fighter.State.CROUCHING and target.combat.current_health == 100 and not fighter._light_kick_hit_sound_played, fighter.name + ": a vuoto resta crouched senza impatto audio")
		fighter.input_buffer.record_input_snapshot(0, 0, [], true)
		fighter._physics_process(1.0 / 60.0)
		expect.call(fighter.current_state == Fighter.State.STANDING_UP, fighter.name + ": rilascio basso permette di rialzarsi")
		fighter._start_low_light_kick()
		fighter.combat.cancel_current_action()
		fighter.change_state(Fighter.State.HIT)
		await tree.create_timer(duration + 0.05).timeout
		expect.call(fighter.current_state != Fighter.State.CROUCHING and not fighter.combat.is_attacking and fighter.combat.hitbox_shape.disabled and not fighter._light_kick_whoosh_audio.playing, fighter.name + ": interruzione non forza un ritorno tardivo in crouch")
		fighter._start_low_light_kick()
		fighter.reset_fighter(Vector2(-5000.0, movement.FLOOR_Y))
		expect.call(not fighter.combat.is_attacking and not fighter.combat.is_crouched_light_kick and fighter.combat.hitbox_shape.disabled and fighter.current_state == Fighter.State.IDLE, fighter.name + ": reset cancella il calcio basso")
	for node in movement._fighters:
		node.combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true
