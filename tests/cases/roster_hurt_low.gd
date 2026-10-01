extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	var scene := load("res://scenes/MovementTest.tscn") as PackedScene
	var movement_test := scene.instantiate()
	tree.root.add_child(movement_test)
	for _tick in 4:
		await tree.physics_frame
	var fighters: Array[IdleRosterFighter] = []
	for node in movement_test._fighters:
		if node is IdleRosterFighter:
			var fighter := node as IdleRosterFighter
			fighters.append(fighter)
			fighter.controls_enabled = false
			var frames := fighter.animated_sprite.sprite_frames
			var atlas_path := "res://assets/sprites/characters/%s/hurt_low_spritesheet.png" % ("peirolo" if fighter.fighter_id == &"peiro" else fighter.fighter_id)
			var exact_regions := true
			for animation in [&"hurt_low", &"hurt_low_reverse"]:
				expect.call(frames.get_frame_count(animation) == (11 if animation == &"hurt_low" else 10)
					and is_equal_approx(frames.get_animation_speed(animation), 48.0)
					and not frames.get_animation_loop(animation), "%s: %s frame/FPS/loop" % [fighter.fighter_id, animation])
				for index in frames.get_frame_count(animation):
					var source := index if animation == &"hurt_low" else 9 - index
					var texture := frames.get_frame_texture(animation, index) as AtlasTexture
					exact_regions = exact_regions and texture.atlas.resource_path == atlas_path and texture.region == Rect2((source % 5) * 512, int(source / 5) * 512, 512, 512)
				expect.call(exact_regions, "%s: atlas 1-11 poi 10-1" % fighter.fighter_id)
			expect.call(is_equal_approx(fighter.start_hit_reaction(AttackData.HitHeight.LOW, null, 4, false), 21.0 / 48.0)
				and fighter.animated_sprite.frame == 0, "%s: LOW parte dal primo frame e include il ritorno" % fighter.fighter_id)
			fighter.combat.take_damage(1, null, 0.0, 0.0, AttackData.HitHeight.LOW, false, 4, 0, false, true)
			expect.call(fighter.current_state == Fighter.State.HIT and fighter.animated_sprite.animation == &"hurt_low"
				and fighter.combat.current_health == fighter.combat.max_health - 1, "%s: danno LOW attiva hurt_low" % fighter.fighter_id)
	await tree.create_timer(0.29).timeout
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.HIT and fighter.animated_sprite.animation == &"hurt_low_reverse", "%s: il ritorno resta in HIT" % fighter.fighter_id)
	await tree.create_timer(0.23).timeout
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle", "%s: hurt_low termina in idle" % fighter.fighter_id)
		fighter.combat.take_damage(1, null, 0.0, 0.0, AttackData.HitHeight.LOW, false, 0, 0, false, true)
		fighter.reset_fighter(fighter.position)
	await tree.create_timer(0.5).timeout
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle"
			and fighter.combat.current_health == fighter.combat.max_health, "%s: reset interrompe hurt_low" % fighter.fighter_id)
	for order in [[KEY_H, KEY_L], [KEY_L, KEY_H]]:
		for key in order:
			var event := InputEventKey.new()
			event.keycode = key
			event.pressed = true
			movement_test._unhandled_input(event)
		await tree.process_frame
		for fighter in fighters:
			expect.call(fighter.animated_sprite.animation == &"hurt_low" and fighter.current_state == Fighter.State.HIT,
				"%s: H+L mostra hurt_low con ordine %s" % [fighter.fighter_id, order])
		for key in order:
			var event := InputEventKey.new()
			event.keycode = key
			movement_test._unhandled_input(event)
	movement_test.queue_free()
	await tree.process_frame
	return true
