extends RefCounted


static func reset_round(arena: MainArena) -> void:
	# Invalidate countdown callbacks from a preceding training reset.
	arena.round_generation += 1
	arena.round_active = true
	for f: Fighter in [arena.player1,arena.player2]:
		f.reset_fighter(Vector2(876 if f.player_number == 1 else 1428,arena.FLOOR_Y))
		f.controls_enabled = true


static func run(tree: SceneTree, expect: Callable) -> bool:
	var selection := tree.root.get_node("CharacterSelection")
	var previous := [selection.player1_id,selection.player2_id]
	for id in ["bue","peiro","oscare","torpe","mileto"]:
		selection.player1_id = id
		selection.player2_id = id
		var arena := (load("res://scenes/MainArena.tscn") as PackedScene).instantiate() as MainArena
		tree.root.add_child(arena)
		await tree.create_timer(3.15).timeout
		for slot in [1,2]:
			reset_round(arena)
			var winner := (arena.player1 if slot == 1 else arena.player2) as IdleRosterFighter
			var loser := arena.player2 if slot == 1 else arena.player1
			var frames := winner.animated_sprite.sprite_frames
			var exact := frames.get_frame_count(&"victory") == 49
			var folder: String = "peirolo" if id == "peiro" else id
			for index in 49:
				var tex := frames.get_frame_texture(&"victory",index) as AtlasTexture
				exact = exact and tex.atlas.resource_path == "res://assets/sprites/characters/%s/victory.png" % folder and tex.region == Rect2(index%7*512,index/7*512,512,512)
			expect.call(exact and frames.get_animation_speed(&"victory") == 24 and not frames.get_animation_loop(&"victory"), "%s P%d: Victory 1-49, celle 512, 24 FPS senza loop" % [id,slot])
			var observed: Array[int] = [0]
			var record := func():
				if winner.animated_sprite.animation == &"victory":
					observed.append(winner.animated_sprite.frame)
			winner.animated_sprite.frame_changed.connect(record)
			for tick in 3:
				await tree.physics_frame
			winner._start_light_punch()
			loser.combat.take_damage(100,winner,0.3,0.18,AttackData.HitHeight.HIGH)
			expect.call(not arena.round_active and winner.current_state == Fighter.State.VICTORY and winner.animated_sprite.animation == &"victory" and not winner.combat.is_attacking and winner.combat.hitbox_shape.disabled, "%s P%d: KO reale avvia Victory e cancella l'attacco" % [id,slot])
			expect.call(loser.current_state == Fighter.State.KNOCKED_DOWN and loser.animated_sprite.animation != &"victory" and not winner.controls_enabled, "%s P%d: solo il vincitore festeggia, controlli bloccati" % [id,slot])
			await tree.create_timer(2.2).timeout
			var all_frames := true
			for index in 49:
				all_frames = all_frames and observed.has(index)
			expect.call(all_frames and winner.animated_sprite.frame == 48 and not winner.animated_sprite.is_playing() and winner.current_state == Fighter.State.VICTORY, "%s P%d: tutti i frame reali e mantiene il 49" % [id,slot])
			winner.change_state(Fighter.State.IDLE)
			arena.end_round_ko(slot)
			winner._physics_process(1.0/60.0)
			expect.call(winner.current_state == Fighter.State.VICTORY and winner.animated_sprite.frame == 48 and winner.velocity == Vector2.ZERO, "%s P%d: callback tardive non riavviano o interrompono Victory" % [id,slot])
			winner.animated_sprite.frame_changed.disconnect(record)
			reset_round(arena)
			winner.position.y = arena.FLOOR_Y-250
			winner.change_state(Fighter.State.JUMPING)
			winner.velocity = Vector2(200,120)
			for tick in 2:
				await tree.physics_frame
			loser.combat.take_damage(100,winner,0.3,0.18,AttackData.HitHeight.HIGH)
			expect.call(winner.victory_pending_until_landing and winner.current_state != Fighter.State.VICTORY and winner.velocity.x == 0, "%s P%d: vittoria in aria attende l'atterraggio" % [id,slot])
			for tick in 90:
				await tree.physics_frame
				if winner.current_state == Fighter.State.VICTORY:
					break
			expect.call(winner.is_on_floor() and winner.current_state == Fighter.State.VICTORY and not winner.victory_pending_until_landing and winner.animated_sprite.animation == &"victory", "%s P%d: atterra e avvia Victory a terra" % [id,slot])
			arena.start_round()
			expect.call(winner.current_state == Fighter.State.IDLE and winner.animated_sprite.animation == &"idle" and winner.combat.current_health == 100 and not winner.victory_pending_until_landing, "%s P%d: reset training esce da Victory" % [id,slot])
			reset_round(arena)
			winner.position.y = arena.FLOOR_Y-300
			winner.velocity.y = 80
			winner.change_state(Fighter.State.JUMPING)
			for tick in 2:
				await tree.physics_frame
			loser.combat.take_damage(100,winner,0.3,0.18,AttackData.HitHeight.HIGH)
			arena.start_round()
			for tick in 3:
				await tree.physics_frame
			expect.call(not winner.victory_pending_until_landing and winner.current_state == Fighter.State.IDLE, "%s P%d: reset annulla anche la vittoria ancora in attesa" % [id,slot])
		arena.queue_free()
		await tree.process_frame
	selection.player1_id = previous[0]
	selection.player2_id = previous[1]
	return true
