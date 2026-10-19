extends RefCounted

const Contact := preload("res://tests/support/hitbox_contact.gd")


static func airborne(fighter: IdleRosterFighter, origin: Vector2) -> void:
	fighter.reset_fighter(origin)
	fighter.velocity = Vector2(0.0, -1.0)
	fighter.move_and_slide()
	fighter.change_state(Fighter.State.JUMPING)
	fighter.opponent = null


static func run(tree: SceneTree, expect: Callable) -> bool:
	var movement := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(movement)
	for tick in 4:
		await tree.physics_frame
	movement.set_physics_process(false)
	var fighters: Array[IdleRosterFighter] = []
	for node in movement._fighters:
		node.set_physics_process(false)
		node.is_player_controlled = false
		node.position.x = -5000.0
		if node is IdleRosterFighter:
			fighters.append(node)
	var contracts := {&"oscare": [34,13,20,60], &"mileto": [31,15,20,60], &"torpe": [33,15,21,60], &"peiro": [23,9,15,48], &"bue": [26,12,17,48]}
	for fighter in fighters:
		var spec: Array = contracts[fighter.fighter_id]
		var frames := fighter.animated_sprite.sprite_frames
		var exact := frames.get_frame_count(&"jump_strong_punch") == int(spec[0]) and frames.get_animation_speed(&"jump_strong_punch") == float(spec[3]) and not frames.get_animation_loop(&"jump_strong_punch")
		for i in int(spec[0]):
			var texture := frames.get_frame_texture(&"jump_strong_punch", i) as AtlasTexture
			exact = exact and texture.atlas == fighter.jump_strong_punch_sheet and texture.region == Rect2(Vector2(i % 7, i / 7) * 512.0, Vector2(512.0,512.0))
		expect.call(exact and fighter.jump_strong_punch_sheet.resource_path.ends_with("/jump_strong_punch.png"), fighter.name + ": sequenza solo avanti, frame e FPS esatti")
		for facing in [true, false]:
			airborne(fighter, Vector2(1000.0, movement.FLOOR_Y - 300.0))
			fighter.is_facing_right = facing
			fighter.velocity = Vector2(120.0 if facing else -120.0, -100.0)
			var initial_velocity := fighter.velocity
			fighter.input_buffer.record_input_snapshot(0, 0, [&"heavy_punch"], true)
			fighter._physics_process(1.0 / 60.0)
			fighter.animated_sprite.pause()
			expect.call(fighter.combat.is_airborne_heavy_punch and fighter.aerial_attack_used and fighter.velocity.x == initial_velocity.x and fighter.velocity.y > initial_velocity.y, fighter.name + ": input aereo preserva traiettoria e gravita")
			expect.call(fighter.combat.hitbox.scale.x == (1.0 if facing else -1.0), fighter.name + ": hitbox specchiata")
			expect.call(fighter._strong_punch_whoosh_audio.playing and fighter._strong_punch_whoosh_audio.stream == load("res://assets/sounds/sfx/swosh.wav"), fighter.name + ": whoosh di Arianna")
			var active_exact := true
			for i in int(spec[0]):
				fighter.animated_sprite.frame = i
				fighter._update_jump_strong_punch_hitbox()
				active_exact = active_exact and fighter.combat.hitbox_shape.disabled == not (i >= int(spec[1])-1 and i <= int(spec[2])-1)
			expect.call(active_exact, fighter.name + ": finestra inclusiva hitbox esatta")
			fighter._on_animation_finished()
			expect.call(fighter.current_state == Fighter.State.JUMPING and fighter.animated_sprite.animation == &"jump_pose" and not fighter.animated_sprite.is_playing() and not fighter.combat.is_attacking and fighter.combat.hitbox_shape.disabled, fighter.name + ": termina in jump pose ferma in aria")
			fighter.update_animation()
			fighter._start_jump_strong_punch()
			expect.call(not fighter.combat.is_attacking and fighter.animated_sprite.animation == &"jump_pose", fighter.name + ": nessuna ripetizione del pugno nello stesso salto")
		# Real overlap against Arianna and a roster defender, in both stances/guards.
		var roster_target := fighters[(fighters.find(fighter) + 1) % fighters.size()]
		for target_node in [movement._fighters[0] as Fighter, roster_target]:
			var target := target_node as Fighter
			for crouched in [false, true]:
				for guarded in [false, true]:
					airborne(fighter, Vector2(1000.0, movement.FLOOR_Y - (15.0 if crouched else 50.0)))
					fighter.is_facing_right = true
					target.reset_fighter(Vector2(1120.0, movement.FLOOR_Y))
					target.is_facing_right = false
					target.opponent = fighter
					target.velocity = Vector2(0.0, 1.0)
					target.move_and_slide()
					if crouched:
						target.return_to_crouch_pose()
					target.input_buffer.record_input_snapshot(1 if guarded else 0, 1 if crouched else 0, [], false)
					target.combat.set_guarding(guarded)
					for tick in 2:
						await tree.physics_frame
					target.velocity = Vector2(0.0, 1.0)
					target.move_and_slide()
					fighter._start_jump_strong_punch()
					fighter.animated_sprite.pause()
					fighter.animated_sprite.frame = int(spec[1])-1
					fighter._update_jump_strong_punch_hitbox()
					var will_hit := Contact.will_connect(fighter,target,&"jump_strong_punch",int(spec[1]),int(spec[1]))
					var expected: StringName = &"hurt_crouched" if crouched else &"hurt_high"
					if guarded:
						expected = target.get_block_animation(AttackData.HitHeight.LOW if crouched else AttackData.HitHeight.HIGH, crouched)
					if not will_hit:
						expected = &"crouch" if crouched else &"idle"
					expect.call(target.animated_sprite.animation == expected and target.combat.current_health == (100 if guarded or not will_hit else 85), "%s -> %s: reazione %s e danno corretti" % [fighter.name, target.name, expected])
					expect.call(fighter._strong_punch_hit_sound_played == (will_hit and not guarded) and fighter._strong_punch_hit_audio.stream == load("res://assets/sounds/sfx/strong-punch.wav"), fighter.name + ": hit audio di Arianna solo a segno")
					fighter._update_jump_strong_punch_hitbox()
					expect.call(target.combat.current_health == (100 if guarded or not will_hit else 85), fighter.name + ": singolo impatto per mossa")
					fighter.combat.cancel_current_action()
					target.reset_fighter(Vector2(-5000.0, movement.FLOOR_Y))
		# Actual animation playback finishes in air without reversing.
		airborne(fighter, Vector2(1000.0, movement.FLOOR_Y - 300.0))
		fighter._start_jump_strong_punch()
		await tree.create_timer(float(spec[0]) / float(spec[3]) + 0.05).timeout
		expect.call(fighter.current_state == Fighter.State.JUMPING and fighter.animated_sprite.animation == &"jump_pose", fighter.name + ": fine playback reale torna alla posa")
		# Landing after completion and during startup/active/recovery must cancel damage.
		for phase in [-1, 0, int(spec[1])-1, int(spec[2])]:
			airborne(fighter, Vector2(1000.0, movement.FLOOR_Y - 100.0))
			fighter._start_jump_strong_punch()
			fighter.animated_sprite.pause()
			if phase == -1:
				fighter._on_animation_finished()
			else:
				fighter.animated_sprite.frame = phase
			fighter.position.y = movement.FLOOR_Y - 1.0
			fighter.velocity = Vector2(100.0, 200.0)
			for tick in 3:
				await tree.physics_frame
				fighter._physics_process(1.0 / 60.0)
			expect.call(fighter.is_on_floor() and fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle" and not fighter.combat.is_attacking and fighter.combat.hitbox_shape.disabled and not fighter.aerial_attack_used, fighter.name + ": atterraggio interrompe fase %d e torna idle" % phase)
		airborne(fighter, Vector2(1000.0, movement.FLOOR_Y - 300.0))
		fighter._start_jump_strong_punch()
		fighter.change_state(Fighter.State.HIT)
		fighter._on_animation_finished()
		expect.call(not fighter.combat.is_attacking and fighter.combat.hitbox_shape.disabled and not fighter._strong_punch_whoosh_audio.playing and not fighter._holding_jump_pose, fighter.name + ": interruzione annulla attacco e ritorno tardivo")
		fighter.reset_fighter(Vector2(-5000.0, movement.FLOOR_Y))
		expect.call(not fighter._holding_jump_pose and not fighter.aerial_attack_used and fighter.combat.hitbox_shape.disabled, fighter.name + ": reset ripulisce stato aereo")
	for node in movement._fighters:
		node.combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true
