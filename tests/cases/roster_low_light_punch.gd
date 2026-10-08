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
		var count := 11 if fighter.fighter_id == &"peiro" else 7
		var first := 6 if fighter.fighter_id == &"peiro" else 3
		var last := first + 1
		var frames := fighter.animated_sprite.sprite_frames
		var exact := frames.get_frame_count(&"crouched_light_punch") == count and frames.get_animation_speed(&"crouched_light_punch") == 24.0 and not frames.get_animation_loop(&"crouched_light_punch")
		for index in count:
			var texture := frames.get_frame_texture(&"crouched_light_punch", index) as AtlasTexture
			exact = exact and texture.atlas == fighter.low_light_punch_sheet and texture.region == Rect2(Vector2(index % 5, index / 5) * 512.0, Vector2(512.0, 512.0))
		expect.call(exact and fighter.low_light_punch_sheet.resource_path.ends_with("/light_punch_low.png"), fighter.name + ": foglio, slicing e FPS del pugno basso")
		fighter.opponent = null
		fighter.position.x = -10000.0
		for facing in [true, false]:
			fighter.is_facing_right = facing
			fighter._start_low_light_punch()
			fighter.animated_sprite.pause()
			expect.call(fighter.combat.is_crouched_light_punch and fighter.combat.hitbox.scale.x == (1.0 if facing else -1.0), fighter.name + ": attacco crouched e hitbox orientata")
			var active_exact := true
			var profile_exact := true
			for index in count:
				fighter.animated_sprite.frame = index
				fighter._update_low_light_punch_hitbox()
				fighter.update_collision_profile()
				active_exact = active_exact and fighter.combat.hitbox_shape.disabled == not (index >= first - 1 and index <= last - 1)
				profile_exact = profile_exact and fighter.get_crouch_progress() == 1.0 and fighter.collision_shape.shape.size == Fighter.CROUCH_COLLISION_SIZE
			expect.call(active_exact, fighter.name + ": soltanto i due frame attivi richiesti")
			expect.call(profile_exact, fighter.name + ": profilo basso durante tutta la mossa")
			fighter._on_animation_finished()
			expect.call(fighter.current_state == Fighter.State.CROUCHING and not fighter.combat.is_attacking and fighter.combat.hitbox_shape.disabled and fighter.animated_sprite.animation == &"crouch" and fighter.animated_sprite.frame == frames.get_frame_count(&"crouch") - 1 and not fighter.animated_sprite.is_playing(), fighter.name + ": fine mossa torna alla stance crouched ferma")
		var duration := float(count) / 24.0
		for scenario in ["standing", "crouched", "guard", "standing_guard"]:
			var guarded: bool = scenario in ["guard", "standing_guard"]
			var crouched: bool = scenario in ["crouched", "guard"]
			fighter.reset_fighter(Vector2(1000.0, movement.FLOOR_Y))
			target.reset_fighter(Vector2(1130.0, movement.FLOOR_Y))
			fighter.is_facing_right = true
			target.is_facing_right = false
			target.opponent = fighter
			if crouched:
				target.return_to_crouch_pose()
			target.input_buffer.record_input_snapshot(1 if scenario in ["guard", "standing_guard"] else 0, 1 if crouched else 0, [], false)
			target.combat.set_guarding(scenario in ["guard", "standing_guard"])
			for tick in 3:
				await tree.physics_frame
			target.velocity = Vector2(0.0, 1.0)
			target.move_and_slide()
			fighter._start_low_light_punch()
			expect.call(fighter._light_punch_whoosh_audio.playing, fighter.name + ": whoosh alla partenza")
			await tree.create_timer(float(first - 1) / 24.0 + 0.025).timeout
			var reaction: StringName = (&"block_low" if crouched else &"block_high") if guarded else (&"hurt_crouched" if crouched else &"hurt_mid")
			expect.call(target.animated_sprite.animation == reaction and target.combat.current_health == (100 if guarded else 95), fighter.name + ": contatto reale " + scenario)
			expect.call(fighter._light_punch_hit_sound_played == not guarded, fighter.name + ": impatto audio solo sul colpo entrato")
			await tree.create_timer(duration + 0.05).timeout
			expect.call(fighter.current_state == Fighter.State.CROUCHING and target.combat.current_health == (100 if guarded else 95), fighter.name + ": un solo danno e ritorno accovacciato")
			fighter.position.x = -5000.0
		fighter.reset_fighter(Vector2(1000.0, movement.FLOOR_Y))
		target.reset_fighter(Vector2(2000.0, movement.FLOOR_Y))
		await tree.physics_frame
		fighter.velocity = Vector2(0.0, 1.0)
		fighter.move_and_slide()
		fighter.input_buffer.record_input_snapshot(0, 1, [&"light_punch"], true)
		fighter._physics_process(1.0 / 60.0)
		expect.call(fighter.animated_sprite.animation == &"crouched_light_punch" and fighter.combat.is_attacking, fighter.name + ": basso piu light punch avvia la mossa")
		await tree.create_timer(duration + 0.05).timeout
		expect.call(fighter.current_state == Fighter.State.CROUCHING and target.combat.current_health == 100 and not fighter._light_punch_hit_sound_played, fighter.name + ": a vuoto resta crouched senza impatto audio")
		fighter.input_buffer.record_input_snapshot(0, 0, [], true)
		fighter._physics_process(1.0 / 60.0)
		expect.call(fighter.current_state == Fighter.State.STANDING_UP, fighter.name + ": rilascio basso permette di rialzarsi")
		fighter._start_low_light_punch()
		fighter.combat.cancel_current_action()
		fighter.change_state(Fighter.State.HIT)
		await tree.create_timer(duration + 0.05).timeout
		expect.call(fighter.current_state != Fighter.State.CROUCHING and not fighter.combat.is_attacking and fighter.combat.hitbox_shape.disabled, fighter.name + ": interruzione non forza un ritorno tardivo in crouch")
		fighter._start_low_light_punch()
		fighter.reset_fighter(Vector2(-5000.0, movement.FLOOR_Y))
		expect.call(not fighter.combat.is_attacking and not fighter.combat.is_crouched_light_punch and fighter.combat.hitbox_shape.disabled and fighter.current_state == Fighter.State.IDLE, fighter.name + ": reset cancella il pugno basso")
	for node in movement._fighters:
		node.combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true
