extends RefCounted

const Contact := preload("res://tests/support/hitbox_contact.gd")


static func run(tree: SceneTree, expect: Callable) -> bool:
	var movement := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(movement)
	for _tick in 4:
		await tree.physics_frame
	movement.set_physics_process(false)
	var fighters: Array[IdleRosterFighter] = []
	var contracts := {&"bue": [22, 9, 11], &"peiro": [24, 14, 16], &"torpe": [23, 14, 16], &"oscare": [33, 18, 20], &"mileto": [38, 18, 20]}
	for node in movement._fighters:
		node.set_physics_process(false)
		node.is_player_controlled = false
		node.opponent = null
		node.position.x = -5000.0 - 500.0 * movement._fighters.find(node)
		if node is IdleRosterFighter:
			fighters.append(node)
	for fighter in fighters:
		var contract: Array = contracts[fighter.fighter_id]
		var count: int = contract[0]
		var fps := 60.0 if fighter.fighter_id == &"mileto" else 48.0
		var first: int = contract[1]
		var last: int = contract[2]
		var frames := fighter.animated_sprite.sprite_frames
		var exact: bool = frames.get_frame_count(&"medium_kick") == count
		for index in count:
			var texture := frames.get_frame_texture(&"medium_kick", index) as AtlasTexture
			exact = exact and texture.atlas == fighter.medium_kick_sheet
			exact = exact and texture.region == Rect2((index % 7) * 512, int(index / 7) * 512, 512, 512)
		expect.call(exact and frames.get_animation_speed(&"medium_kick") == fps
			and not frames.get_animation_loop(&"medium_kick")
			and fighter.medium_kick_sheet.resource_path.ends_with("/medium_kick_standing.png"), fighter.name + ": slicing esatto e FPS richiesti solo avanti")
		for facing in [true, false]:
			fighter.is_facing_right = facing
			fighter._start_medium_kick()
			fighter.animated_sprite.pause()
			var phases := fighter.combat.get_attack_phase_durations(fighter.combat.current_attack)
			expect.call(is_equal_approx(phases.x + phases.y + phases.z, float(count) / fps)
				and fighter.combat.uses_target_stance_medium_reactions()
				and not fighter.combat.is_crouched_medium_kick
				and fighter.combat.hitbox.scale.x == (1.0 if facing else -1.0), fighter.name + ": variante standing, durata e orientamento")
			var active_exact := true
			var profile_exact := true
			for index in count:
				fighter.animated_sprite.frame = index
				fighter._update_medium_kick_hitbox()
				fighter.update_collision_profile()
				active_exact = active_exact and fighter.combat.hitbox_shape.disabled == not (index >= first - 1 and index <= last - 1)
				profile_exact = profile_exact and fighter.get_crouch_progress() == 0.0
			expect.call(active_exact, fighter.name + ": soltanto i tre frame attivi richiesti")
			expect.call(profile_exact, fighter.name + ": postura standing per tutta la mossa")
			fighter._on_animation_finished()
			expect.call(fighter.current_state == Fighter.State.IDLE and not fighter.combat.is_attacking
				and fighter.combat.hitbox_shape.disabled, fighter.name + ": fine mossa pulisce attacco e hitbox")
		var observed: Array[int] = [0]
		var observe := func() -> void:
			if fighter.animated_sprite.animation == &"medium_kick":
				observed.append(fighter.animated_sprite.frame)
		fighter.animated_sprite.frame_changed.connect(observe)
		fighter._start_medium_kick()
		await tree.create_timer(float(count) / fps + 0.08).timeout
		var complete := true
		for index in count:
			complete = complete and observed.has(index)
		expect.call(complete and fighter.current_state == Fighter.State.IDLE, fighter.name + ": tutti i frame in ordine e ritorno in idle")
		fighter.animated_sprite.frame_changed.disconnect(observe)
		# Contatti reali contro ogni altro personaggio, nelle quattro posture richieste.
		for target: Fighter in movement._fighters:
			if target == fighter:
				continue
			for scenario in ["standing", "standing_guard", "crouched", "crouched_guard"]:
				var crouched: bool = scenario.begins_with("crouched")
				var guarded: bool = scenario.ends_with("guard")
				fighter.reset_fighter(Vector2(1000.0, movement.FLOOR_Y))
				target.reset_fighter(Vector2(1130.0, movement.FLOOR_Y))
				fighter.is_facing_right = true
				target.is_facing_right = false
				target.opponent = fighter
				if crouched:
					target.return_to_crouch_pose()
				target.input_buffer.record_input_snapshot(1 if guarded else 0, 1 if crouched else 0, [], false)
				target.combat.set_guarding(guarded)
				target.velocity = Vector2(0.0, 1.0)
				target.move_and_slide()
				for tick in 2: await tree.physics_frame
				fighter._start_medium_kick()
				fighter.animated_sprite.pause()
				fighter.animated_sprite.frame = first - 1
				fighter._update_medium_kick_hitbox()
				await tree.physics_frame
				var will_hit := Contact.will_connect(fighter,target,&"medium_kick",first,first)
				var reaction: StringName = target.get_block_animation(AttackData.HitHeight.LOW if crouched else AttackData.HitHeight.MID, crouched) if guarded else (&"hurt_crouched" if crouched else &"hurt_mid")
				if not will_hit:
					reaction = &"crouch" if crouched else &"idle"
				var damage: int = fighter.character_data.get_attack(&"medium_kick").damage
				expect.call(target.animated_sprite.animation == reaction
					and target.combat.current_health == (100 if guarded or not will_hit else 100 - damage),
					"%s contro %s: %s produce %s" % [fighter.name, target.name, scenario, reaction])
				fighter.combat.resolve_attack_overlap_immediately()
				expect.call(target.combat.current_health == (100 if guarded or not will_hit else 100 - damage), fighter.name + ": un solo impatto per mossa")
				fighter.combat.cancel_current_action()
				fighter.reset_fighter(Vector2(-6000.0, movement.FLOOR_Y))
				target.reset_fighter(Vector2(-5000.0 - 500.0 * movement._fighters.find(target), movement.FLOOR_Y))
		fighter.reset_fighter(Vector2(1000.0, movement.FLOOR_Y))
		fighter.velocity = Vector2(0.0, 1.0)
		fighter.move_and_slide()
		fighter.input_buffer.record_input_snapshot(0, 0, [&"medium_kick"], true)
		fighter._physics_process(1.0 / 60.0)
		expect.call(fighter.animated_sprite.animation == &"medium_kick" and fighter.combat.is_attacking,
			fighter.name + ": tasto medium kick in piedi avvia la mossa")
		fighter.reset_fighter(fighter.position)
		fighter.return_to_crouch_pose()
		fighter.input_buffer.record_input_snapshot(0, 1, [&"medium_kick"], true)
		fighter._physics_process(1.0 / 60.0)
		expect.call(fighter.animated_sprite.animation == &"crouched_medium_kick",
			fighter.name + ": giu + medium kick conserva la variante accovacciata")
		fighter.reset_fighter(fighter.position)
		fighter._start_medium_kick()
		fighter.combat.take_damage(1, null, 2.0, 0.0, AttackData.HitHeight.HIGH, false, 0, 0, false, true)
		fighter.animated_sprite.pause()
		await tree.create_timer(float(count) / fps + 0.08).timeout
		expect.call(fighter.current_state == Fighter.State.HIT and not fighter.combat.is_attacking
			and fighter.combat.hitbox_shape.disabled, fighter.name + ": danno interrompe senza ritorno tardivo in idle")
		fighter._start_medium_kick()
		fighter.reset_fighter(Vector2(-5000.0 - 500.0 * movement._fighters.find(fighter), movement.FLOOR_Y))
		expect.call(fighter.current_state == Fighter.State.IDLE and not fighter.combat.is_attacking
			and fighter.combat.hitbox_shape.disabled, fighter.name + ": reset cancella la mossa")
	for node in movement._fighters:
		node.combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true
