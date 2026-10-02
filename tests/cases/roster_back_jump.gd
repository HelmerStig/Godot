extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	var movement := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(movement)
	for _tick in 4:
		await tree.physics_frame
	movement.set_physics_process(false)
	for node in movement._fighters:
		(node as Fighter).set_physics_process(false)
		(node as Fighter).position.x = -5000.0
	var opponent := movement._dummy_opponent as Fighter
	for node in movement._fighters:
		if not (node is IdleRosterFighter):
			continue
		var fighter := node as IdleRosterFighter
		fighter.is_player_controlled = false
		fighter.controls_enabled = true
		var frames := fighter.animated_sprite.sprite_frames
		var regions := true
		for index in 20:
			var texture := frames.get_frame_texture(&"back_jump", index) as AtlasTexture
			regions = regions and texture.atlas == fighter.back_jump_sheet and texture.region == Rect2((index % 5) * 512, int(index / 5) * 512, 512, 512)
		expect.call(frames.get_frame_count(&"back_jump") == 20 and is_equal_approx(frames.get_animation_speed(&"back_jump"), 24.0)
			and not frames.get_animation_loop(&"back_jump") and regions, "%s: back_jump 1-20 a 24 FPS" % fighter.name)
		for facing_right in [true, false]:
			fighter.reset_fighter(Vector2(1200.0, 600.0))
			fighter.stage_left_limit = 100.0
			fighter.stage_right_limit = 2200.0
			fighter.is_facing_right = facing_right
			fighter.collision_mask = Fighter.GROUND_COLLISION_LAYER
			opponent.position.x = 2000.0 if facing_right else 400.0
			fighter.velocity.y = 1.0
			fighter.move_and_slide()
			var back_axis := -1 if facing_right else 1
			fighter.input_buffer.record_input_snapshot(back_axis, 0, [], facing_right)
			fighter._physics_process(1.0 / 60.0)
			expect.call(not fighter._back_jump_active, "%s: primo indietro non avvia back_jump" % fighter.name)
			fighter.input_buffer.record_input_snapshot(0, 0, [], facing_right)
			fighter._physics_process(1.0 / 60.0)
			await tree.physics_frame
			fighter.input_buffer.record_input_snapshot(back_axis, 0, [], facing_right)
			fighter._physics_process(1.0 / 60.0)
			var start := fighter.position
			expect.call(fighter.current_state == Fighter.State.BACK_HOP_STARTUP and fighter.animated_sprite.animation == &"back_jump",
				"%s: doppio indietro relativo al facing avvia la mossa" % fighter.name)
			fighter.animated_sprite.frame = 3
			fighter._physics_process(1.0 / 60.0)
			expect.call(fighter.position == start and not fighter._back_jump_moving, "%s: frame 1-4 senza spostamento" % fighter.name)
			fighter.animated_sprite.frame = 4
			fighter._physics_process(1.0 / 60.0)
			expect.call(fighter._back_jump_moving and signf(fighter.position.x - start.x) == back_axis
				and is_equal_approx(absf(fighter.velocity.x), Arianna.ARIANNA_BACK_JUMP_SPEED), "%s: movimento parte al frame 5 con velocita Arianna" % fighter.name)
			fighter._physics_process(0.5)
			expect.call(is_equal_approx(fighter.position.x, start.x + back_axis * Arianna.ARIANNA_BACK_JUMP_DISTANCE)
				and is_equal_approx(fighter.position.y, start.y) and fighter.current_state == Fighter.State.BACK_HOP,
				"%s: 80 pixel in 0.5s poi attende la fine animazione" % fighter.name)
			fighter.animated_sprite.frame = 19
			await tree.create_timer(0.1).timeout
			expect.call(fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle"
				and not fighter._back_jump_active and fighter.collision_layer == Fighter.FIGHTER_COLLISION_LAYER,
				"%s: fine animazione torna in idle e ripristina collisioni" % fighter.name)
		fighter.reset_fighter(Vector2(120.0, 600.0))
		fighter.is_facing_right = true
		fighter._start_back_jump()
		fighter.animated_sprite.frame = 4
		fighter._physics_process(0.5)
		expect.call(is_equal_approx(fighter.position.x, 100.0), "%s: back_jump rispetta limite stage" % fighter.name)
		fighter.combat.take_damage(1, null, 0.0, 0.0, AttackData.HitHeight.MID, false, 0, 0, false, true)
		var interrupted_position := fighter.position
		fighter._physics_process(1.0 / 60.0)
		expect.call(not fighter._back_jump_active and fighter.current_state == Fighter.State.HIT
			and is_equal_approx(fighter.position.x, interrupted_position.x), "%s: colpo interrompe back_jump" % fighter.name)
		fighter.reset_fighter(Vector2(1200.0, 600.0))
		fighter._start_back_jump()
		fighter.reset_fighter(Vector2(1200.0, 600.0))
		expect.call(not fighter._back_jump_active and fighter.current_state == Fighter.State.IDLE
			and fighter.collision_layer == Fighter.FIGHTER_COLLISION_LAYER, "%s: reset cancella back_jump" % fighter.name)
		fighter.controls_enabled = false
		fighter.input_buffer.record_input_snapshot(-1, 0, [], true)
		fighter._physics_process(1.0 / 60.0)
		fighter.input_buffer.record_input_snapshot(0, 0, [], true)
		fighter._physics_process(1.0 / 60.0)
		fighter.input_buffer.record_input_snapshot(-1, 0, [], true)
		fighter._physics_process(1.0 / 60.0)
		expect.call(not fighter._back_jump_active, "%s: controlli disabilitati impediscono back_jump" % fighter.name)
		fighter.position.x = -5000.0
	for node in movement._fighters:
		(node as Fighter).combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true
