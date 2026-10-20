extends RefCounted

const Helpers := preload("res://tests/cases/oscare_cigarette_special.gd")

static func run(tree: SceneTree, expect: Callable) -> bool:
	var arena := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(arena)
	for tick in 4:
		await tree.physics_frame
	arena.set_physics_process(false)
	var actor: Mileto
	var target: Fighter
	for fighter: Fighter in arena._fighters:
		fighter.set_physics_process(false)
		fighter.is_player_controlled = false
		fighter.position.x = -10000
		if fighter is Mileto:
			actor = fighter
		elif fighter is Oscare:
			target = fighter
	expect.call(actor != null,"Mileto controller presente nella scena reale")
	if actor == null:
		arena.queue_free()
		return false
	var frames := actor.animated_sprite.sprite_frames
	var valid := frames.get_frame_count(actor.SHOULDER_ANIMATION) == 40
	for index in 40:
		var texture := frames.get_frame_texture(actor.SHOULDER_ANIMATION,index) as AtlasTexture
		valid = valid and texture.atlas == actor.SHOULDER_SHEET and texture.region == Rect2(index%8*512,index/8*512,512,512)
	expect.call(valid and frames.get_animation_speed(actor.SHOULDER_ANIMATION) == 48 and not frames.get_animation_loop(actor.SHOULDER_ANIMATION),"Mileto: 40 frame aggiornati, atlas esatto, 48 FPS")
	for facing in [true,false]:
		for spec in [[&"light_punch",&"light",800.0],[&"medium_punch",&"medium",1100.0],[&"heavy_punch",&"heavy",1400.0]]:
			for mode in 3:
				await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
				Helpers.motion(actor,facing,spec[0],mode)
				actor._physics_process(1.0/60)
				expect.call(actor.shoulder_active and actor.shoulder_strength == spec[1],"Mileto QCF %s facing=%s tolleranza=%d" % [spec[0],facing,mode])
				expect.call(actor._shoulder_audio.stream == load("res://assets/sounds/sfx/scossa.wav") and actor._shoulder_audio.playing,"Mileto scossa all'attivazione per ogni forza e facing")
				var effect = actor._shoulder_aura
				expect.call(effect.tint == actor.COLORS[spec[1]] and effect.emitting,"Mileto colore aura per forza")
				actor.animated_sprite.frame = actor.HOLD_FRAME
				expect.call(not actor.animated_sprite.is_playing() and actor.animated_sprite.frame == 30,"Mileto mantiene il fotogramma originale 31")
				var before := actor.position.x
				actor._physics_process(1.0/60)
				var direction := 1.0 if facing else -1.0
				expect.call(is_equal_approx(actor.position.x-before,direction*spec[2]*actor.get_physics_process_delta_time()),"Mileto velocita Godot corretta e specchiata")
	# Actual swept contact at high speed, against standing/crouched/guard/KO.
	for facing in [true,false]:
		for scenario in ["hit","block","crouched_hit","crouched_block","knockout"]:
			await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
			var direction := 1.0 if facing else -1.0
			target.position.x = actor.position.x + direction * 320
			target.is_facing_right = not facing
			var crouched: bool = scenario.begins_with("crouched")
			var guard: bool = "block" in scenario
			target.input_buffer.record_input_snapshot(int(direction) if guard else 0,1 if crouched else 0,[],not facing)
			if crouched:
				target.return_to_crouch_pose()
			target.combat.set_guarding(guard)
			if scenario == "knockout":
				target.combat.current_health = 5
			for tick in 2:
				await tree.physics_frame
			actor.is_facing_right = facing
			actor.animated_sprite.flip_h = not facing
			actor._start_shoulder(&"heavy")
			actor.animated_sprite.frame = 30
			for tick in 30:
				actor._physics_process(1.0/60)
				if actor.shoulder_connected:
					break
			expect.call(actor.shoulder_connected and actor.velocity.x == 0,"Mileto sweep contatto e arresto: "+scenario)
			expect.call(actor.animated_sprite.frame == 31 and actor.animated_sprite.is_playing(),"Mileto riparte dal frame 32 dopo impatto")
			expect.call(absf(actor.position.x-target.position.x) >= 110,"Mileto non attraversa avversario")
			var expected_health := 100 if guard else (0 if scenario == "knockout" else 85)
			expect.call(target.combat.current_health == expected_health,"Mileto danno singolo/parata: "+scenario)
			expect.call(actor._shoulder_hit_audio.stream == load("res://assets/sounds/sfx/strong-punch.wav") and actor._shoulder_hit_audio.playing == not guard,"Mileto hit pugno forte solo a segno, incluso KO: "+scenario)
			var expected: StringName = (&"block_low" if crouched else &"block_mid") if guard else (&"hurt_crouched" if crouched else &"hurt_mid")
			if scenario == "knockout":
				expected = &"ko"
			expect.call(target.animated_sprite.animation == expected,"Mileto reazione corretta: "+scenario)
			actor._physics_process(.1)
			expect.call(target.combat.current_health == expected_health,"Mileto nessun secondo danno in recovery")
			await tree.create_timer(.3).timeout
			expect.call(not actor.shoulder_active and actor.current_state == Fighter.State.IDLE,"Mileto recovery torna idle")
			expect.call(not actor._shoulder_audio.playing,"Mileto fine recovery ferma scossa")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor._start_shoulder()
	target.combat.current_health = 1
	target.knocked_out.connect(func(): actor._start_victory_animation(),CONNECT_ONE_SHOT)
	actor._hit_shoulder_area(target.get_node("Hurtbox"))
	expect.call(actor._shoulder_hit_audio.playing and not actor.shoulder_active and actor.current_state == Fighter.State.VICTORY,"Mileto hit audio su KO anche dopo cancellazione sincrona del round")
	actor._release_shoulder()
	expect.call(actor.current_state == Fighter.State.VICTORY and actor.animated_sprite.animation == &"victory","Mileto recovery tardiva non sovrascrive vittoria")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor._start_shoulder()
	actor.animated_sprite.frame = 30
	actor.combat.take_damage(1,target,.3,.1,AttackData.HitHeight.MID)
	expect.call(not actor.shoulder_active and actor.current_state == Fighter.State.HIT and absf(actor.velocity.x) <= Fighter.HIT_PUSHBACK_SPEED,"Mileto colpito interrompe hold e corsa, conserva il normale pushback")
	expect.call(not actor._shoulder_audio.playing,"Mileto hurt interrompe scossa")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	expect.call(tree.get_nodes_in_group("mileto_shoulder_aura").is_empty(),"Mileto reset elimina aura e scie")
	expect.call(not actor._shoulder_audio.playing,"Mileto reset ferma scossa")
	expect.call(not actor._shoulder_hit_audio.playing,"Mileto reset ferma anche hit audio")
	actor.is_facing_right = true
	actor._start_shoulder()
	actor.animated_sprite.frame = 30
	actor.position.x = actor.stage_right_limit - 5
	target.position.x = -10000
	for tick in 2:
		await tree.physics_frame
	actor._physics_process(1.0/60)
	expect.call(actor.shoulder_connected and actor.animated_sprite.is_playing(),"Mileto al bordo recupera senza blocco infinito")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor.controls_enabled = false
	Helpers.motion(actor,true,&"light_punch")
	expect.call(not actor._try_start_character_special(),"Mileto non parte a controlli disabilitati")
	actor.controls_enabled = true
	actor.position.y -= 300
	actor.velocity.y = -1
	actor.move_and_slide()
	expect.call(not actor._try_start_character_special(),"Mileto special solo a terra")
	arena.queue_free()
	await tree.process_frame
	return true
