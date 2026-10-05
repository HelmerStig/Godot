extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	var movement := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(movement)
	for tick in 4:
		await tree.physics_frame
	movement.set_physics_process(false)
	for fighter in movement._fighters:
		fighter.set_physics_process(false)
		fighter.is_player_controlled = false
	var attacker := movement._fighters[0] as Fighter
	for fighter in movement._fighters:
		if not fighter is IdleRosterFighter:
			continue
		var defender := fighter as IdleRosterFighter
		for height in [AttackData.HitHeight.MID, AttackData.HitHeight.LOW]:
			defender.reset_fighter(defender.position)
			defender.opponent = null
			defender.is_facing_right = true
			attacker.position = defender.position + Vector2(700.0, 0.0)
			defender.velocity = Vector2(0.0, 1.0)
			defender.move_and_slide()
			defender.change_state(Fighter.State.CROUCHING)
			defender.input_buffer.record_input_snapshot(-1, 1, [], true)
			defender.combat.set_guarding(true)
			var result := defender.combat.take_damage(7, attacker, 0.3, 0.15, height)
			expect.call(result == FighterCombat.DamageResult.BLOCKED and defender.animated_sprite.animation == &"block_low" and defender.combat.current_health == defender.combat.max_health, "%s: indietro+basso para %s con block_low" % [defender.name, height])
			expect.call(defender.get_block_recovery_animation(height) == &"block_low_recovery", defender.name + ": recovery usa la parata bassa anche sul medio")
			await tree.create_timer(0.65).timeout
			expect.call(defender.current_state == Fighter.State.CROUCHING and defender.get_crouch_progress() == 1.0, defender.name + ": mantiene crouch quando la guardia bassa resta premuta")
			defender.combat.set_guarding(true)
			defender.combat.take_damage(7, attacker, 0.3, 0.15, height)
			expect.call(defender.animated_sprite.animation == &"block_low", defender.name + ": nuovo colpo resta una parata bassa")
			defender.input_buffer.record_input_snapshot(0, 0, [], true)
			await tree.create_timer(0.65 + defender.get_animation_duration(&"block_low_recovery")).timeout
			expect.call(defender.current_state == Fighter.State.IDLE and defender.get_crouch_progress() == 0.0, defender.name + ": rilasciata la guardia termina recovery in idle")
		defender.reset_fighter(defender.position)
		defender.input_buffer.record_input_snapshot(-1, 1, [], true)
		defender.start_block_reaction(AttackData.HitHeight.MID, true)
		defender.input_buffer.record_input_snapshot(0, 1, [], true)
		defender.combat.block_reaction(0.15, AttackData.HitHeight.MID, attacker)
		await tree.create_timer(0.65 + defender.get_animation_duration(&"block_low_recovery")).timeout
		expect.call(defender.current_state == Fighter.State.CROUCHING and defender.get_crouch_progress() == 1.0, defender.name + ": rilasciare indietro mantenendo basso termina in crouch")
		defender.reset_fighter(defender.position)
		defender.input_buffer.record_input_snapshot(-1, 0, [], true)
		defender.start_block_reaction(AttackData.HitHeight.MID, false)
		expect.call(defender.animated_sprite.animation == &"block_mid", defender.name + ": guardia in piedi conserva block_medium")
		defender.reset_fighter(defender.position)
	for fighter in movement._fighters:
		fighter.combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true
