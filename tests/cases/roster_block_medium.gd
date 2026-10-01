extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	var movement := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(movement)
	for _tick in 4:
		await tree.physics_frame
	movement.set_physics_process(false)
	var fighters: Array[IdleRosterFighter] = []
	for node in movement._fighters:
		var fighter := node as Fighter
		fighter.set_physics_process(false)
		fighter.is_player_controlled = false
		if fighter is IdleRosterFighter:
			fighters.append(fighter)
	var attacker := movement._fighters[0] as Fighter
	var attack := AttackData.new()
	attack.attack_id = &"medium_height_test"
	attack.damage = 7
	attack.hit_height = AttackData.HitHeight.MID
	attack.hitbox_size = Vector2(100.0, 100.0)
	attack.hitbox_position = Vector2(-200.0, -130.0)
	for fighter in fighters:
		var frames := fighter.animated_sprite.sprite_frames
		var exact_regions := true
		for animation in [&"block_mid", &"block_mid_recovery"]:
			for index in frames.get_frame_count(animation):
				var source := index if animation == &"block_mid" else 4 - index
				var texture := frames.get_frame_texture(animation, index) as AtlasTexture
				exact_regions = exact_regions and texture.atlas == fighter.block_medium_sheet and texture.region == Rect2((source % 5) * 512, int(source / 5) * 512, 512, 512)
			expect.call(frames.get_frame_count(animation) == (6 if animation == &"block_mid" else 5)
				and is_equal_approx(frames.get_animation_speed(animation), 24.0) and not frames.get_animation_loop(animation)
				and exact_regions, "%s: %s slicing e 24 FPS" % [fighter.name, animation])
		fighter.reset_fighter(fighter.position)
		fighter.is_facing_right = true
		fighter.input_buffer.record_input_snapshot(-1, 0, [], true)
		fighter._physics_process(1.0 / 60.0)
		expect.call(fighter.combat.is_blocking and fighter.current_state != Fighter.State.BLOCKING,
			"%s: indietro prepara guardia senza reazione prima del contatto" % fighter.name)
		attacker.reset_fighter(fighter.position + Vector2(700.0, 0.0))
		attacker.is_facing_right = true
		attacker.combat.hitbox.scale.x = 1.0
		await tree.process_frame
		attacker.combat.begin_animation_attack(&"idle", attack)
		attacker.combat.configure_hitbox(attack)
		attacker.combat.enable_hitbox()
		for _tick in 3:
			await tree.physics_frame
		expect.call(fighter.current_state != Fighter.State.BLOCKING and fighter.combat.current_health == fighter.combat.max_health,
			"%s: colpo fuori hurtbox non attiva block_medium" % fighter.name)
		attacker.position = fighter.position + Vector2(200.0, 0.0)
		for _tick in 3:
			await tree.physics_frame
		expect.call(fighter.current_state == Fighter.State.BLOCKING and fighter.animated_sprite.animation == &"block_mid"
			and fighter.combat.current_health == fighter.combat.max_health, "%s: contatto MID parato attiva block_medium" % fighter.name)
		await tree.create_timer(0.32).timeout
		expect.call(fighter.animated_sprite.animation == &"block_mid" and fighter.animated_sprite.frame == 5
			and not fighter.animated_sprite.is_playing(), "%s: mantiene frame 6 durante parata" % fighter.name)
		attacker.combat.cancel_current_action()
		await tree.create_timer(0.05).timeout
		expect.call(fighter.current_state == Fighter.State.BLOCK_RECOVERY and fighter.animated_sprite.animation == &"block_mid_recovery",
			"%s: fine parata avvia 5-1" % fighter.name)
		await tree.create_timer(0.25).timeout
		expect.call(fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle", "%s: recovery medium torna in idle" % fighter.name)
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	for mode in [1, 2, 3, 0]:
		movement._unhandled_input(tab)
		movement._physics_process(1.0 / 60.0)
		expect.call(movement._block_mode == mode, "Tab seleziona modalita %d" % mode)
		if mode != 0:
			var animation: StringName = &"block_high" if mode == 1 else (&"block_mid" if mode == 2 else &"block_low")
			for fighter in fighters:
				expect.call(fighter.animated_sprite.animation == animation, "%s: Tab mostra %s" % [fighter.name, animation])
	for node in movement._fighters:
		(node as Fighter).combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true
