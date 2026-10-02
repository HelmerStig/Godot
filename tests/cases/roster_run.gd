extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	var movement := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(movement)
	for _tick in 4:
		await tree.physics_frame
	var fighters: Array[IdleRosterFighter] = []
	var observed: Dictionary = {}
	var loops: Dictionary = {}
	var counts := {&"bue": 31, &"oscare": 31, &"peiro": 33, &"torpe": 30, &"mileto": 32}
	for node in movement._fighters:
		node.is_player_controlled = false
		if not node is IdleRosterFighter:
			continue
		var fighter := node as IdleRosterFighter
		fighters.append(fighter)
		fighter.set_physics_process(false)
		fighter.opponent = null
		observed[fighter] = []
		loops[fighter] = 0
		fighter.animated_sprite.frame_changed.connect(func() -> void:
			if fighter.animated_sprite.animation == &"run":
				observed[fighter].append(fighter.animated_sprite.frame)
		)
		fighter.animated_sprite.animation_looped.connect(func() -> void:
			if fighter.animated_sprite.animation == &"run":
				loops[fighter] += 1
		)
		var frames := fighter.animated_sprite.sprite_frames
		var exact: bool = frames.get_frame_count(&"run") == counts[fighter.fighter_id]
		for index in frames.get_frame_count(&"run"):
			var texture := frames.get_frame_texture(&"run", index) as AtlasTexture
			exact = exact and texture.atlas == fighter.run_sheet
			exact = exact and texture.region == Rect2((index % 7) * 512, int(index / 7) * 512, 512, 512)
		expect.call(exact and frames.get_animation_loop(&"run")
			and is_equal_approx(frames.get_animation_speed(&"run"), 24.0),
			"%s: run con frame esatti, slicing, loop e 24 FPS" % fighter.fighter_id)
	expect.call(fighters.size() == 5, "corsa configurata per tutti i cinque fighter")
	for facing_right in [true, false]:
		var forward := 1 if facing_right else -1
		for fighter in fighters:
			fighter.reset_fighter(fighter.position)
			fighter.is_facing_right = facing_right
			_sample(fighter, forward)
			expect.call(fighter.current_state == Fighter.State.WALKING
				and is_equal_approx(fighter.velocity.x, forward * fighter.character_data.walk_speed),
				"%s: primo avanti cammina, facing=%s" % [fighter.fighter_id, facing_right])
			_sample(fighter, 0)
		await tree.physics_frame
		for fighter in fighters:
			_sample(fighter, forward)
			expect.call(fighter.current_state == Fighter.State.RUNNING and fighter.animated_sprite.animation == &"run"
				and is_equal_approx(fighter.velocity.x, forward * fighter.character_data.run_speed),
				"%s: doppio avanti corre, facing=%s" % [fighter.fighter_id, facing_right])
		for _tick in 4:
			await tree.physics_frame
			for fighter in fighters:
				_sample(fighter, forward)
		await tree.create_timer(1.5).timeout
		for fighter in fighters:
			var complete := true
			for index in counts[fighter.fighter_id]:
				complete = complete and observed[fighter].has(index)
			expect.call(complete and loops[fighter] > 0 and fighter.current_state == Fighter.State.RUNNING,
				"%s: tutti i frame e loop senza riavvio a ogni tick" % fighter.fighter_id)
			_sample(fighter, 0)
			expect.call(fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle"
				and is_zero_approx(fighter.velocity.x), "%s: rilascio avanti termina la corsa" % fighter.fighter_id)
			fighter.reset_fighter(fighter.position)
			_sample(fighter, forward)
			_sample(fighter, 0)
		for _tick in Fighter.RUN_DOUBLE_TAP_WINDOW_FRAMES + 2:
			await tree.physics_frame
		for fighter in fighters:
			_sample(fighter, forward)
			expect.call(fighter.current_state == Fighter.State.WALKING, "%s: tap distanti non avviano run" % fighter.fighter_id)
			fighter.reset_fighter(fighter.position)
			_sample(fighter, -forward)
			_sample(fighter, 0)
		await tree.physics_frame
		for fighter in fighters:
			_sample(fighter, -forward)
			expect.call(fighter.current_state != Fighter.State.RUNNING, "%s: doppio indietro non avvia run" % fighter.fighter_id)
	# Corsa e movimento devono cedere alle reazioni e agli altri stati.
	for fighter in fighters:
		fighter.change_state(Fighter.State.RUNNING)
		_sample(fighter, -1, 1)
		expect.call(fighter.current_state == Fighter.State.CROUCHING, "%s: accovacciarsi interrompe run" % fighter.fighter_id)
		fighter.reset_fighter(fighter.position)
		fighter.change_state(Fighter.State.RUNNING)
		fighter.combat.take_damage(10, null, 0.0, 0.0, AttackData.HitHeight.HIGH)
		_sample(fighter, -1)
		expect.call(fighter.current_state == Fighter.State.HIT and fighter.animated_sprite.animation != &"run",
			"%s: un colpo interrompe run" % fighter.fighter_id)
		fighter.reset_fighter(fighter.position)
		expect.call(fighter.current_state == Fighter.State.IDLE
			and fighter.last_forward_tap_frame < -Fighter.RUN_DOUBLE_TAP_WINDOW_FRAMES,
			"%s: reset cancella run e doppio tap" % fighter.fighter_id)
		fighter.change_state(Fighter.State.RUNNING)
	Input.action_press("p1_jump")
	await tree.physics_frame
	for fighter in fighters:
		_sample(fighter, -1)
		expect.call(fighter.current_state == Fighter.State.JUMP_STARTUP or fighter.current_state == Fighter.State.JUMPING,
			"%s: salto interrompe run" % fighter.fighter_id)
	Input.action_release("p1_jump")
	for fighter in fighters:
		fighter.combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true


static func _sample(fighter: IdleRosterFighter, axis: int, down := 0) -> void:
	fighter.input_buffer.record_input_snapshot(axis, down, [], fighter.is_facing_right)
	fighter._physics_process(1.0 / 60.0)
