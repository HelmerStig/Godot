extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	for character in ["Bue", "Peirolo", "Torpe", "Mileto", "Oscare"]:
		var fighter := (load("res://scenes/%s.tscn" % character) as PackedScene).instantiate() as IdleRosterFighter
		tree.root.add_child(fighter)
		fighter.set_physics_process(false)
		fighter.is_player_controlled = false
		await tree.process_frame
		var frames := fighter.animated_sprite.sprite_frames
		var exact := frames.get_frame_count(&"light_punch") == 13
		for index in 13:
			var source_index := index if index < 7 else 12 - index
			var texture := frames.get_frame_texture(&"light_punch", index) as AtlasTexture
			exact = exact and texture.atlas == fighter.light_punch_sheet and texture.region == Rect2(Vector2(source_index % 5, source_index / 5) * 512.0, Vector2(512.0, 512.0))
		expect.call(exact and frames.get_animation_speed(&"light_punch") == 24.0 and not frames.get_animation_loop(&"light_punch"), character + ": light punch 1-7, 6-1 a 24 FPS")
		for facing in [true, false]:
			fighter.is_facing_right = facing
			fighter._start_light_punch()
			expect.call(fighter._light_punch_whoosh_audio.playing and fighter._light_punch_whoosh_audio.stream == load("res://sound-libraries/punch_short_whoosh_30.wav") and not fighter._light_punch_hit_sound_played, character + ": pugno a vuoto avvia solo whoosh")
			fighter.animated_sprite.pause()
			expect.call(fighter.combat.is_attacking and fighter.current_state == Fighter.State.ATTACKING and fighter.combat.hitbox.scale.x == (1.0 if facing else -1.0), character + ": attacco e hitbox orientati")
			var active_exact := true
			for index in 13:
				fighter.animated_sprite.frame = index
				fighter._update_light_punch_hitbox()
				active_exact = active_exact and fighter.combat.hitbox_shape.disabled == not (index >= fighter.light_punch_active_start_frame - 1 and index <= 6)
			expect.call(active_exact, character + ": hitbox attiva soltanto nei frame richiesti di andata")
			fighter._on_light_punch_connected(&"light_punch", FighterCombat.DamageResult.BLOCKED)
			expect.call(not fighter._light_punch_hit_sound_played, character + ": la parata non genera suono hit")
			fighter._on_light_punch_connected(&"light_punch", FighterCombat.DamageResult.HIT)
			expect.call(fighter._light_punch_hit_sound_played and fighter._light_punch_hit_audio.stream == load("res://assets/sounds/sfx/light-punch.wav"), character + ": impatto usa il suono di Arianna")
			fighter._on_animation_finished()
			expect.call(fighter.current_state == Fighter.State.IDLE and not fighter.combat.is_attacking and fighter.combat.hitbox_shape.disabled, character + ": fine animazione ripristina idle e disattiva hitbox")
		fighter._start_light_punch()
		fighter.reset_fighter(Vector2.ZERO)
		await tree.process_frame
		expect.call(not fighter.combat.is_attacking and fighter.combat.hitbox_shape.disabled, character + ": reset interrompe light punch")
		fighter.queue_free()
		await tree.process_frame
	return true
