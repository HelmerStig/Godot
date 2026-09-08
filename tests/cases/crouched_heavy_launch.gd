extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	print("-- Lancio del pugno forte accovacciato")
	var arena := (load("res://scenes/MainArena.tscn") as PackedScene).instantiate() as MainArena
	tree.root.add_child(arena)
	await tree.create_timer(3.1).timeout
	arena.set_process(false)
	arena.round_active = false
	var attacker := arena.player2
	var mangler_target := (load("res://scenes/Mangler.tscn") as PackedScene).instantiate() as Fighter
	arena.add_child(mangler_target)
	mangler_target.opponent = attacker
	var defenders: Array[Fighter] = [arena.player1, mangler_target]
	for fighter in [attacker, arena.player1, mangler_target]:
		fighter.set_physics_process(false)
	var no_attacks: Array[StringName] = []
	for defender in defenders:
		for facing_right in [true, false]:
			for scenario in ["colpo", "parata alta", "parata accovacciata", "rialzata", "KO", "letale"]:
				# Allontana l'altro bersaglio per isolare il contatto sotto test.
				for other in defenders:
					other.position = Vector2(2000.0, MainArena.FLOOR_Y)
				attacker.reset_fighter(Vector2(700.0 if facing_right else 1500.0, MainArena.FLOOR_Y))
				defender.reset_fighter(Vector2(1100.0, MainArena.FLOOR_Y))
				attacker.opponent = defender
				attacker.is_facing_right = facing_right
				defender.is_facing_right = not facing_right
				defender.velocity = Vector2(0.0, 1.0)
				defender.move_and_slide()
				defender.velocity = Vector2.ZERO
				if scenario.begins_with("parata"):
					var crouching: bool = scenario == "parata accovacciata"
					defender.change_state(Fighter.State.CROUCHING if crouching else Fighter.State.IDLE)
					defender.input_buffer.record_input_snapshot(1 if facing_right else -1, 1 if crouching else 0, no_attacks, not facing_right)
					defender.combat.set_guarding(true)
				elif scenario == "rialzata":
					defender.change_state(Fighter.State.KNOCKDOWN_RECOVERY)
				elif scenario == "KO":
					defender.combat.current_health = 0
					defender.change_state(Fighter.State.KNOCKED_DOWN)
				elif scenario == "letale":
					defender.combat.current_health = 1
				var attack := attacker.character_data.get_attack(&"heavy_punch")
				attacker.combat.current_attack = attack
				attacker.combat.current_variant = attack.get_variant(&"crouched")
				attacker.combat.is_attacking = true
				attacker.combat.is_crouched_heavy_punch = true
				attacker.combat._apply_hit_to_area(defender.get_node("Hurtbox") as Area2D)
				if scenario == "colpo":
					expect.call(
						defender.combat.current_health == defender.combat.max_health - attack.damage
						and defender.current_state == Fighter.State.HIT
						and defender.velocity == Vector2(200.0 if facing_right else -200.0, -800.0),
						"%s facing=%s: il pugno forte a segno infligge danno e lancia" % [defender.name, facing_right]
					)
				else:
					var expected_state := Fighter.State.BLOCKING
					if scenario == "rialzata":
						expected_state = Fighter.State.KNOCKDOWN_RECOVERY
					elif scenario in ["KO", "letale"]:
						expected_state = Fighter.State.KNOCKED_DOWN
					expect.call(
						defender.combat.current_health == (0 if scenario in ["KO", "letale"] else defender.combat.max_health)
						and defender.current_state == expected_state
						and defender.velocity == Vector2.ZERO,
						"%s facing=%s: %s conserva danno e reazione corretti senza lancio" % [defender.name, facing_right, scenario]
					)
				attacker.combat.cancel_current_action()
				defender.combat.cancel_current_action()
	arena.queue_free()
	await tree.process_frame
	return true
