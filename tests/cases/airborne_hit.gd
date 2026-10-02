extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	var movement := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(movement)
	for _tick in 4:
		await tree.physics_frame
	var observed: Dictionary = {}
	var times: Dictionary = {}
	for fighter: Fighter in movement._fighters:
		fighter.is_player_controlled = false
		observed[fighter] = [0]
		times[fighter] = {}
		fighter.animated_sprite.frame_changed.connect(func() -> void:
			if fighter.animated_sprite.animation == &"hurted_in_jump":
				observed[fighter].append(fighter.animated_sprite.frame)
		)
		fighter.state_changed.connect(func(_previous: int, state: int) -> void:
			times[fighter][state] = Time.get_ticks_msec()
		)
		var frames := fighter.animated_sprite.sprite_frames
		var count := 20 if fighter is IdleRosterFighter else (17 if fighter is Arianna else 25)
		expect.call(frames.has_animation(&"hurted_in_jump")
			and frames.get_frame_count(&"hurted_in_jump") == count
			and is_equal_approx(frames.get_animation_speed(&"hurted_in_jump"), 24.0)
			and not frames.get_animation_loop(&"hurted_in_jump"),
			"%s: frame esatti della reazione aerea a 24 FPS" % fighter.name)
		if fighter is IdleRosterFighter:
			var exact := true
			for index in count:
				var texture := frames.get_frame_texture(&"hurted_in_jump", index) as AtlasTexture
				exact = exact and texture.region == Rect2((index % 7) * 512, int(index / 7) * 512, 512, 512)
			expect.call(exact, "%s: slicing di tutti i 20 frame fall" % fighter.name)
		_lift(fighter)
	await tree.physics_frame
	for fighter: Fighter in movement._fighters:
		# Anche un attacco con knockdown deve usare fall se la vittima è in aria.
		fighter.combat.take_damage(10, null, 0.0, 0.0, AttackData.HitHeight.LOW, true)
		expect.call(fighter.current_state == Fighter.State.HIT
			and fighter.animated_sprite.animation == &"hurted_in_jump" and fighter.animated_sprite.frame == 0,
			"%s: colpo in salto sostituisce jump con hurted_in_jump" % fighter.name)
	await tree.create_timer(0.2).timeout
	for fighter: Fighter in movement._fighters:
		expect.call(fighter.is_on_floor() and fighter.current_state == Fighter.State.HIT
			and fighter.animated_sprite.animation == &"hurted_in_jump" and fighter.animated_sprite.is_playing(),
			"%s: atterraggio precoce non salta frame" % fighter.name)
	await tree.create_timer(0.9).timeout
	for fighter: Fighter in movement._fighters:
		var count := fighter.animated_sprite.sprite_frames.get_frame_count(&"hurted_in_jump")
		var complete := true
		for index in count:
			complete = complete and observed[fighter].has(index)
		expect.call(complete, "%s: riproduce ogni frame aereo" % fighter.name)
	await tree.create_timer(1.8).timeout
	for fighter: Fighter in movement._fighters:
		var states: Dictionary = times[fighter]
		var pause := float(states.get(Fighter.State.KNOCKDOWN_RECOVERY, 0) - states.get(Fighter.State.SWEEP_KNOCKDOWN, 0)) / 1000.0
		expect.call(pause >= 0.28 and pause <= 0.36, "%s: posa finale sweep per 0.3s" % fighter.name)
		expect.call(fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle"
			and fighter.can_move and fighter.combat.current_health == 90,
			"%s: recovery completa e ritorno in idle" % fighter.name)
	for order in [[KEY_H, KEY_G], [KEY_G, KEY_H]]:
		for fighter: Fighter in movement._fighters:
			fighter.reset_fighter(fighter.position)
			fighter.is_player_controlled = false
			_lift(fighter)
		await tree.physics_frame
		for key in [KEY_H, KEY_G]:
			var release := InputEventKey.new()
			release.keycode = key
			movement._handle_hurt_shortcut(release)
		for key in order:
			var event := InputEventKey.new()
			event.keycode = key
			event.pressed = true
			movement._unhandled_input(event)
		await tree.process_frame
		for fighter: Fighter in movement._fighters:
			expect.call(fighter.current_state == Fighter.State.HIT
				and fighter.animated_sprite.animation == &"hurted_in_jump"
				and fighter.combat.current_health == fighter.combat.max_health,
				"%s: H+G in salto senza danno, ordine %s" % [fighter.name, order])
		await tree.create_timer(3.0).timeout
		for fighter: Fighter in movement._fighters:
			expect.call(fighter.current_state == Fighter.State.IDLE, "%s: H+G completa recovery" % fighter.name)
	# Se la caduta dura più del foglio, la posa finale resta fino all'atterraggio.
	for fighter: Fighter in movement._fighters:
		_lift(fighter)
		fighter.position.y = -3000.0
		fighter.move_and_slide()
	await tree.physics_frame
	for fighter: Fighter in movement._fighters:
		fighter.combat.take_damage(0, null)
	await tree.create_timer(1.12).timeout
	for fighter: Fighter in movement._fighters:
		expect.call(not fighter.is_on_floor() and fighter.current_state == Fighter.State.HIT
			and fighter.animated_sprite.animation == &"hurted_in_jump"
			and fighter.animated_sprite.frame == fighter.animated_sprite.sprite_frames.get_frame_count(&"hurted_in_jump") - 1
			and not fighter.animated_sprite.is_playing(), "%s: attende il terreno senza ripetere fall" % fighter.name)
	await tree.create_timer(2.6).timeout
	for fighter: Fighter in movement._fighters:
		expect.call(fighter.is_on_floor() and fighter.current_state == Fighter.State.IDLE,
			"%s: caduta lunga completa atterraggio e recovery" % fighter.name)
	# Reset e KO invalidano le attese della reazione aerea.
	for fighter: Fighter in movement._fighters:
		_lift(fighter)
	await tree.physics_frame
	for fighter: Fighter in movement._fighters:
		fighter.combat.take_damage(0, null)
		fighter.reset_fighter(Vector2(fighter.position.x, 600.0))
	await tree.create_timer(3.0).timeout
	for fighter: Fighter in movement._fighters:
		expect.call(fighter.current_state == Fighter.State.IDLE, "%s: reset annulla rialzate tardive" % fighter.name)
		_lift(fighter)
	await tree.physics_frame
	for fighter: Fighter in movement._fighters:
		fighter.combat.take_damage(0, null)
		fighter.combat.take_damage(fighter.combat.max_health, null)
	await tree.create_timer(3.0).timeout
	for fighter: Fighter in movement._fighters:
		expect.call(fighter.current_state == Fighter.State.KNOCKED_DOWN
			and fighter.animated_sprite.animation == &"ko", "%s: KO interrompe fall e recovery" % fighter.name)
		fighter.combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true


static func _lift(fighter: Fighter) -> void:
	fighter.input_buffer.clear()
	fighter.combat.set_guarding(false)
	fighter.change_state(Fighter.State.JUMPING)
	fighter.position.y = 575.0
	fighter.velocity = Vector2(0.0, 80.0)
	fighter.move_and_slide()
