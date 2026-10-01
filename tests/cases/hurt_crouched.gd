extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	var movement := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(movement)
	for _tick in 4:
		await tree.physics_frame
	var fighters: Array[Fighter] = []
	for node in movement._fighters:
		var fighter := node as Fighter
		fighters.append(fighter)
		fighter.set_physics_process(false)
		fighter.is_player_controlled = false
		var frames := fighter.animated_sprite.sprite_frames
		var exact_regions := true
		for index in 12:
			var texture := frames.get_frame_texture(&"hurt_crouched", index) as AtlasTexture
			exact_regions = exact_regions and texture.atlas == fighter.hurt_crouched_sheet and texture.region == Rect2((index % 5) * 512, int(index / 5) * 512, 512, 512)
		expect.call(frames.get_frame_count(&"hurt_crouched") == 12 and is_equal_approx(frames.get_animation_speed(&"hurt_crouched"), 24.0)
			and is_equal_approx(fighter.get_animation_duration(&"hurt_crouched"), 0.5)
			and not frames.get_animation_loop(&"hurt_crouched") and exact_regions, "%s: hurt_crouched 1-12 a 24 FPS senza loop" % fighter.name)
		fighter.input_buffer.record_input_snapshot(0, 1, [], fighter.is_facing_right)
		fighter.return_to_crouch_pose()
		var effects_before := tree.get_nodes_in_group("hurt_blue_explosion").size()
		var result := fighter.combat.take_damage(1, null, 0.8, 0.0, AttackData.HitHeight.LOW, false, 4, 0, false, true)
		expect.call(result == FighterCombat.DamageResult.HIT and fighter.animated_sprite.animation == &"hurt_crouched"
			and fighter.animated_sprite.frame == 0 and is_equal_approx(fighter.get_crouch_progress(), 1.0), "%s: LOW accovacciato attiva la reazione completa" % fighter.name)
		var effects := tree.get_nodes_in_group("hurt_blue_explosion")
		expect.call(effects.size() == effects_before + 1 and (effects.back() as Node2D).global_position == fighter.global_position + Fighter.HURT_LOW_EFFECT_OFFSET,
			"%s: esplosione particellare LOW" % fighter.name)
	await tree.create_timer(0.56).timeout
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.CROUCHING and fighter.animated_sprite.animation == &"crouch"
			and not fighter.animated_sprite.is_playing() and fighter.animated_sprite.frame == fighter.animated_sprite.sprite_frames.get_frame_count(&"crouch") - 1,
			"%s: giu mantenuto torna nella posa crouched" % fighter.name)
	await tree.create_timer(0.3).timeout
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.CROUCHING, "%s: timer tardivo non annulla crouched" % fighter.name)
		fighter.combat.take_damage(1, null, 0.0, 0.0, AttackData.HitHeight.LOW, false, 0, 0, false, true)
		fighter.input_buffer.record_input_snapshot(0, 0, [], fighter.is_facing_right)
	await tree.create_timer(0.56).timeout
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle", "%s: giu rilasciato torna in idle" % fighter.name)
		fighter.combat.take_damage(1, null, 0.0, 0.0, AttackData.HitHeight.LOW, false, 0, 0, false, true)
		expect.call(fighter.animated_sprite.animation == &"hurt_low", "%s: LOW in piedi resta hurt_low" % fighter.name)
		fighter.reset_fighter(fighter.position)
		fighter.return_to_crouch_pose()
		fighter.combat.take_damage(1, null, 0.0, 0.0, AttackData.HitHeight.MID, false, 0, 0, false, true)
		expect.call(fighter.animated_sprite.animation != &"hurt_crouched", "%s: MID non usa hurt_crouched" % fighter.name)
		fighter.reset_fighter(fighter.position)
		if not fighter.is_facing_right:
			fighter.flip_character()
		fighter.input_buffer.record_input_snapshot(-1, 1, [], true)
		fighter.return_to_crouch_pose()
		fighter.combat.set_guarding(true)
		var attacker := movement._dummy_opponent as Fighter
		attacker.position.x = fighter.position.x + 200.0
		var blocked := fighter.combat.take_damage(1, attacker, 0.0, 0.0, AttackData.HitHeight.LOW, false, 0, 0, false, true)
		expect.call(blocked == FighterCombat.DamageResult.BLOCKED and fighter.animated_sprite.animation != &"hurt_crouched", "%s: parata LOW evita hurt_crouched" % fighter.name)
		fighter.reset_fighter(fighter.position)
		fighter.return_to_crouch_pose()
		fighter.combat.take_damage(1, null, 0.0, 0.0, AttackData.HitHeight.LOW, true, 0, 0, false, true)
		expect.call(fighter.current_state == Fighter.State.HIT and fighter.animated_sprite.animation == &"hurt_crouched", "%s: LOW accovacciato usa hurt_crouched anche per una sweep" % fighter.name)
		fighter.reset_fighter(fighter.position)
		fighter.return_to_crouch_pose()
		fighter.combat.take_damage(1, null, 0.0, 0.0, AttackData.HitHeight.LOW, false, 0, 0, false, true)
		fighter.reset_fighter(fighter.position)
	await tree.create_timer(0.56).timeout
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.IDLE and not fighter.hurt_started_crouched, "%s: reset invalida hurt_crouched" % fighter.name)
		fighter.return_to_crouch_pose()
		fighter.combat.take_damage(fighter.combat.max_health, null, 0.0, 0.0, AttackData.HitHeight.LOW, false, 0, 0, false, true)
		expect.call(fighter.current_state == Fighter.State.KNOCKED_DOWN and not fighter.hurt_started_crouched, "%s: colpo letale mantiene KO" % fighter.name)
		fighter.combat.cancel_current_action()
	for order in [[KEY_H, KEY_G], [KEY_G, KEY_H]]:
		for fighter in fighters:
			fighter.reset_fighter(fighter.position)
		for key in order:
			var event := InputEventKey.new()
			event.keycode = key
			event.pressed = true
			movement._unhandled_input(event)
		await tree.process_frame
		for fighter in fighters:
			expect.call(fighter.current_state == Fighter.State.HIT and fighter.animated_sprite.animation == &"hurt_crouched",
				"%s: H+G mostra hurt_crouched con ordine %s" % [fighter.name, order])
		for key in order:
			var event := InputEventKey.new()
			event.keycode = key
			movement._unhandled_input(event)
		await tree.create_timer(0.56).timeout
		for fighter in fighters:
			expect.call(fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle",
				"%s: preview H+G termina in idle" % fighter.name)
	var arianna := fighters[0] as Arianna
	for fighter in fighters:
		if fighter is Arianna:
			arianna = fighter as Arianna
	arianna.reset_fighter(arianna.position)
	arianna._start_medium_punch()
	expect.call(arianna.medium_punch_active, "Arianna: attacco H attivo prima della preview")
	movement._preview_hurt(AttackData.HitHeight.LOW, true)
	expect.call(not arianna.medium_punch_active and not arianna.combat.is_attacking,
		"Arianna: H+G annulla attacco e flag residui")
	await tree.create_timer(0.56).timeout
	arianna.input_buffer.record_input_snapshot(0, 1, [], arianna.is_facing_right)
	arianna._physics_process(1.0 / 60.0)
	expect.call(arianna.current_state == Fighter.State.CROUCHING and arianna.animated_sprite.animation == &"crouch",
		"Arianna: dopo H+G puo accovacciarsi di nuovo")
	movement.queue_free()
	await tree.process_frame
	return true
