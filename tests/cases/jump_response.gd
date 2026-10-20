extends RefCounted

static func run(tree: SceneTree, expect: Callable) -> bool:
	var arena := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(arena)
	for tick in 4:
		await tree.physics_frame
	arena.set_physics_process(false)
	for fighter: Fighter in arena._fighters:
		fighter.set_physics_process(false)
		fighter.opponent = null
		fighter.position.x = -10000
	for actor: Fighter in arena._fighters:
		var takeoff: int
		if actor is Arianna:
			takeoff = Arianna.ARIANNA_JUMP_TAKEOFF_FRAME
		elif actor is Mangler:
			takeoff = Mangler.JUMP_TAKEOFF_FRAME
		else:
			takeoff = actor.jump_takeoff_frame - actor.jump_start_frame
		var frames := actor.animated_sprite.sprite_frames
		var fps := frames.get_animation_speed(&"jump")
		var duration := 0.0
		for index in takeoff:
			duration += frames.get_frame_duration(&"jump",index) / fps
		expect.call(is_equal_approx(duration,Fighter.JUMP_STARTUP_SECONDS),"%s: anticipazione totale 66.7ms" % actor.name)
		var flight_unchanged := true
		var original_mangler: SpriteFrames
		if actor is Mangler:
			original_mangler = ResourceLoader.load("res://assets/sprites/characters/mangler/idle_frames.tres","SpriteFrames",ResourceLoader.CACHE_MODE_IGNORE) as SpriteFrames
		for index in range(takeoff,frames.get_frame_count(&"jump")):
			var original_duration := original_mangler.get_frame_duration(&"jump",index) if original_mangler != null else 1.0
			flight_unchanged = flight_unchanged and is_equal_approx(frames.get_frame_duration(&"jump",index),original_duration)
		expect.call(flight_unchanged,"%s: timing dei frame in volo preservato" % actor.name)
		print("JUMP_BASELINE: ",actor.name," old_ms=",takeoff/fps*1000," new_ms=",duration*1000)
		for direction in [-1,0,1]:
			for input_action in InputMap.get_actions():
				Input.action_release(input_action)
			actor.reset_fighter(Vector2(1000,arena.FLOOR_Y))
			actor.controls_enabled = true
			actor.is_player_controlled = true
			actor.velocity = Vector2(0,1)
			actor.move_and_slide()
			actor.set_physics_process(true)
			for tick in 3:
				await tree.physics_frame
			if direction:
				Input.action_press(actor.get_input_action("move_right" if direction > 0 else "move_left"))
			var start_y := actor.position.y
			var pressed_at := Engine.get_physics_frames()
			Input.action_press(actor.get_input_action("jump"))
			var latency := -1
			for tick in 9:
				await tree.physics_frame
				if actor.position.y < start_y - .1 and actor.velocity.y < 0:
					latency = Engine.get_physics_frames() - pressed_at
					break
			Input.action_release(actor.get_input_action("jump"))
			expect.call(latency > 0 and latency <= 7,"%s: input reale -> stacco entro 7 tick, dir=%d (misurati %d)" % [actor.name,direction,latency])
			expect.call(signf(actor.velocity.x) == direction,"%s: direzione salto preservata dir=%d" % [actor.name,direction])
			if direction == 0:
				# Measure a full unassisted arc, keeping its original per-fighter physics.
				var peak := start_y - actor.position.y
				var airborne_ticks := 0
				for tick in 120:
					await tree.physics_frame
					peak = maxf(peak,start_y - actor.position.y)
					airborne_ticks += 1
					if actor.is_on_floor() and actor.velocity.y >= 0:
						break
				var impulse := absf(actor.character_data.jump_velocity) * (1.0 if actor is Arianna else 1.5)
				var gravity := Arianna.ARIANNA_JUMP_GRAVITY if actor is Arianna else 3150.0
				var expected_peak := impulse * impulse / (2 * gravity)
				expect.call(absf(peak-expected_peak) < 20 and actor.is_on_floor(),"%s: altezza e atterraggio preservati" % actor.name)
			actor.set_physics_process(false)
			actor.reset_fighter(Vector2(-10000,arena.FLOOR_Y))
	for input_action in InputMap.get_actions():
		Input.action_release(input_action)
	arena.queue_free()
	await tree.process_frame
	return true
