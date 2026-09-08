extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	print("-- Guardia per altezza del colpo")
	var arena := (load("res://scenes/MainArena.tscn") as PackedScene).instantiate() as MainArena
	tree.root.add_child(arena)
	await tree.create_timer(3.1).timeout
	arena.set_process(false)
	var fighters: Array[Fighter] = [arena.player1, arena.player2]
	for fighter in fighters:
		fighter.set_physics_process(false)
	var no_attacks: Array[StringName] = []
	for defender in fighters:
		var attacker := defender.opponent
		for facing_right in [true, false]:
			for crouching in [false, true]:
				for height in [AttackData.HitHeight.HIGH, AttackData.HitHeight.MID, AttackData.HitHeight.LOW]:
					defender.reset_fighter(Vector2(1100.0, MainArena.FLOOR_Y))
					attacker.reset_fighter(Vector2(1500.0 if facing_right else 700.0, MainArena.FLOOR_Y))
					defender.is_facing_right = facing_right
					defender.velocity = Vector2(0.0, 1.0)
					defender.move_and_slide()
					defender.change_state(Fighter.State.CROUCHING if crouching else Fighter.State.IDLE)
					defender.input_buffer.record_input_snapshot(-1 if facing_right else 1, 1 if crouching else 0, no_attacks, facing_right)
					defender.combat.set_guarding(true)
					var should_block: bool = height != AttackData.HitHeight.LOW or crouching
					defender.combat.take_damage(10, attacker, 0.3, 0.15, height)
					expect.call(
						defender.is_on_floor()
						and defender.combat.current_health == (100 if should_block else 90)
						and defender.current_state == (Fighter.State.BLOCKING if should_block else Fighter.State.HIT),
						"%s facing=%s crouch=%s altezza=%s: danno e reazione rispettano la guardia" % [defender.name, facing_right, crouching, height]
					)
		# L'input corrente conta anche se il fighter è già nell'animazione di parata.
		for down_held in [false, true]:
			defender.reset_fighter(Vector2(1100.0, MainArena.FLOOR_Y))
			attacker.reset_fighter(Vector2(1500.0, MainArena.FLOOR_Y))
			defender.is_facing_right = true
			defender.velocity = Vector2(0.0, 1.0)
			defender.move_and_slide()
			defender.change_state(Fighter.State.BLOCKING)
			defender.input_buffer.record_input_snapshot(-1, 1 if down_held else 0, no_attacks, true)
			defender.combat.take_damage(10, attacker, 0.3, 0.15, AttackData.HitHeight.LOW)
			expect.call(
				defender.combat.current_health == (100 if down_held else 90)
				and defender.current_state == (Fighter.State.BLOCKING if down_held else Fighter.State.HIT),
				"%s: durante BLOCKING il LOW verifica giù all'impatto (%s)" % [defender.name, down_held]
			)
		for scenario in ["senza indietro", "da dietro", "in aria"]:
			defender.reset_fighter(Vector2(1100.0, MainArena.FLOOR_Y - 100.0 if scenario == "in aria" else MainArena.FLOOR_Y))
			attacker.reset_fighter(Vector2(700.0 if scenario == "da dietro" else 1500.0, MainArena.FLOOR_Y))
			defender.is_facing_right = true
			defender.velocity = Vector2(0.0, 1.0)
			defender.move_and_slide()
			defender.input_buffer.record_input_snapshot(0 if scenario == "senza indietro" else -1, 1, no_attacks, true)
			defender.combat.set_guarding(true)
			defender.combat.take_damage(10, attacker, 0.3, 0.15, AttackData.HitHeight.LOW)
			expect.call(defender.combat.current_health == 90, "%s: LOW non parabile %s" % [defender.name, scenario])
		defender.combat.cancel_current_action()
	for fighter in fighters:
		fighter.combat.cancel_current_action()
	arena.queue_free()
	await tree.process_frame
	return true
