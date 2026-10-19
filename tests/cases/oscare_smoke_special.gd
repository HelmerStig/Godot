extends RefCounted

const Smoke := preload("res://scripts/OscareSmokeBreathProjectile.gd")
const Helpers := preload("res://tests/cases/oscare_cigarette_special.gd")


static func motion(actor: Oscare, right: bool, button: StringName, mode: int) -> void:
	var back := -1 if right else 1
	actor.is_facing_right = right
	actor.animated_sprite.flip_h = not right
	actor.input_buffer.record_input_snapshot(0,1,[],right)
	if mode != 2:
		actor.input_buffer.record_input_snapshot(back,1,[],right)
	actor.input_buffer.record_input_snapshot(back,1 if mode == 1 else 0,[button],right)


static func run(tree: SceneTree, expect: Callable) -> bool:
	var arena := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(arena)
	for tick in 4:
		await tree.physics_frame
	arena.set_physics_process(false)
	var actor: Oscare
	var target: Fighter
	for f: Fighter in arena._fighters:
		f.set_physics_process(false)
		f.is_player_controlled = false
		f.position.x = -10000
		if f is Oscare:
			actor = f
		elif f is IdleRosterFighter and target == null:
			target = f
	var frames := actor.animated_sprite.sprite_frames
	var exact := frames.get_frame_count(actor.SMOKE_ANIMATION) == 49
	for index in 49:
		var texture := frames.get_frame_texture(actor.SMOKE_ANIMATION,index) as AtlasTexture
		exact = exact and texture.atlas == actor.SMOKE_SHEET and texture.region == Rect2(index%7*512,index/7*512,512,512)
	expect.call(exact and frames.get_animation_speed(actor.SMOKE_ANIMATION) == 60.0 and not frames.get_animation_loop(actor.SMOKE_ANIMATION), "Soffio: 49 frame esatti a 60 FPS, dalla posa accesa, senza loop")
	for right in [true,false]:
		for button in [&"light_punch",&"medium_punch",&"heavy_punch"]:
			for mode in 3:
				await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
				motion(actor,right,button,mode)
				actor._physics_process(1.0/60.0)
				expect.call(actor.smoke_special_active and not actor.cigarette_special_active and actor.animated_sprite.animation == actor.LIGHT_ANIMATION, "Soffio: QCB parte dall'accensione facing=%s pugno=%s tolleranza=%d" % [right,button,mode])
				actor.animated_sprite.pause()
				actor.animated_sprite.frame = 4
				expect.call(not actor._ignition_audio.playing and not actor._smoke_audio.playing, "Special 2: nessun audio anticipato")
				actor.animated_sprite.frame = 5
				expect.call(actor._ignition_audio.playing and actor._ignition_audio.stream == actor.IGNITION_SOUND and not actor._smoke_audio.playing, "Special 2: stesso suono di accensione al frame 6")
				actor._on_animation_finished()
				actor.animated_sprite.pause()
				expect.call(actor.animated_sprite.animation == actor.SMOKE_ANIMATION and actor.current_state == Fighter.State.ATTACKING and not actor.smoke_spawned, "Special 2: accensione continua nel soffio senza idle o lancio sigaretta")
				actor.animated_sprite.frame = 19
				expect.call(not actor.smoke_spawned and actor.combat.hitbox_shape.disabled, "Soffio: prima del frame 21 nessun fumo o hitbox corpo a corpo")
				actor.animated_sprite.frame = 20
				var smoke := actor._smoke_projectile as OscareSmokeBreathProjectile
				expect.call(is_instance_valid(smoke), "Soffio: frame 21 genera il proiettile")
				if not is_instance_valid(smoke):
					arena.queue_free()
					return false
				smoke.set_physics_process(false)
				expect.call(actor._smoke_audio.playing and actor._smoke_audio.stream == load("res://assets/sounds/sfx/soffio.wav"), "Special 2: soffio.wav parte con la comparsa del fumo")
				var smoke_frames := smoke.sprite.sprite_frames
				var valid := smoke_frames.get_frame_count(&"breath") == 26
				for index in 26:
					var texture := smoke_frames.get_frame_texture(&"breath",index) as AtlasTexture
					valid = valid and texture.atlas == Smoke.SHEET and texture.region == Rect2(index%7*512,index/7*512,512,512)
				expect.call(valid and smoke_frames.get_animation_speed(&"breath") == 60 and not smoke_frames.get_animation_loop(&"breath"), "Fumo: solo frame sorgente 1-26 a 60 FPS, nessuna cella tagliata")
				expect.call(smoke.global_position.is_equal_approx(actor.get_smoke_mouth_global_position()) and smoke.sprite.flip_h == not right and smoke.sprite.frame == 0, "Fumo: origine alla bocca e orientamento corretti")
				var old_position := smoke.global_position
				actor.animated_sprite.frame = 28
				expect.call(smoke.sprite.frame == 8 and smoke.global_position.is_equal_approx(actor.get_smoke_mouth_global_position()) and not smoke.global_position.is_equal_approx(old_position), "Fumo: segue la bocca mentre il busto si piega, senza deriva temporale")
				var sign_x := 1.0 if right else -1.0
				expect.call(smoke.hit_shape.points.size() >= 8 and smoke.hit_shape.points[0].x*sign_x >= -5, "Fumo: collisione convessa speculare segue la sagoma")
				actor.opponent = target
				target.position.x = actor.position.x - sign_x*500
				actor.update_facing_direction()
				expect.call(actor.is_facing_right == right, "Soffio: non si gira durante la mossa")
				actor.animated_sprite.frame = 45
				expect.call(smoke.sprite.frame == 25 and not smoke.active and smoke.modulate.a < 0.25, "Fumo: ultimo frame 26 sfuma e non infligge un colpo invisibile")
				actor.animated_sprite.frame = 46
				expect.call(smoke.is_queued_for_deletion(), "Fumo: scade dopo i 26 frame")
				actor._on_animation_finished()
				expect.call(actor.current_state == Fighter.State.IDLE and not actor.combat.is_attacking and not actor.smoke_special_active, "Soffio: recupero torna idle e riabilita il movimento")
				expect.call(actor._smoke_audio.playing, "Soffio: fine naturale lascia completare la registrazione")
	# Actual playback must finish without manual completion callbacks.
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor._start_smoke_special()
	await tree.create_timer(1.3).timeout
	expect.call(actor.current_state == Fighter.State.IDLE and not actor.smoke_special_active and tree.get_nodes_in_group("oscare_smoke_projectile").is_empty(), "Soffio: riproduzione reale completa a 60 FPS e libera il fumo")
	for interrupt in ["hit_before","hit_after","reset","disable","state","knockout"]:
		await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
		actor._start_smoke_special()
		actor.animated_sprite.pause()
		actor.animated_sprite.frame = 5
		if interrupt != "hit_before":
			actor._on_animation_finished()
			actor.animated_sprite.pause()
		actor.animated_sprite.frame = 10 if interrupt == "hit_before" else 28
		match interrupt:
			"hit_before", "hit_after", "knockout":
				if interrupt == "knockout":
					actor.combat.current_health = 1
				actor.combat.take_damage(10,target,0.3,0.1,AttackData.HitHeight.HIGH)
			"reset":
				actor.reset_fighter(Vector2(1000,arena.FLOOR_Y))
			"disable":
				actor.controls_enabled = false
			"state":
				actor.change_state(Fighter.State.IDLE)
		for tick in 2:
			await tree.physics_frame
		expect.call(tree.get_nodes_in_group("oscare_smoke_projectile").is_empty(), "Soffio: interruzione elimina il fumo: " + interrupt)
		if interrupt != "disable":
			expect.call(not actor.smoke_special_active, "Soffio: interruzione azzera lo stato: " + interrupt)
			expect.call(not actor._smoke_audio.playing and not actor._ignition_audio.playing, "Soffio: interruzione ferma i suoni: " + interrupt)
	# Real physics queries, including crouched guards, misses, and mirrored hits.
	for right in [true,false]:
		for scenario in ["standing","crouched","guard","crouched_guard","far","above","knockout"]:
			await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
			actor.is_facing_right = right
			actor.animated_sprite.flip_h = not right
			var sign_x := 1 if right else -1
			target.position.x = actor.position.x + sign_x*(800 if scenario == "far" else 250)
			target.is_facing_right = not right
			target.animated_sprite.flip_h = right
			var crouched: bool = scenario in ["crouched","crouched_guard"]
			var guarded: bool = scenario in ["guard","crouched_guard"]
			target.input_buffer.record_input_snapshot(sign_x if guarded else 0,1 if crouched else 0,[],not right)
			if crouched:
				target.return_to_crouch_pose()
			target.combat.set_guarding(guarded)
			if scenario == "above":
				target.position.y -= 400
			if scenario == "knockout":
				target.combat.current_health = 5
			actor._start_smoke_special()
			actor.animated_sprite.pause()
			actor._on_animation_finished()
			actor.animated_sprite.pause()
			actor.animated_sprite.frame = 28
			var smoke := actor._smoke_projectile as OscareSmokeBreathProjectile
			smoke.set_physics_process(false)
			for tick in 2:
				await tree.physics_frame
			smoke._physics_process(1.0/60.0)
			var miss: bool = scenario in ["far","above"]
			var expected_health := 100 if miss or guarded else (0 if scenario == "knockout" else 90)
			expect.call(target.combat.current_health == expected_health and actor.combat.current_health == 100, "Fumo: collisione reale e nessun autocolpo facing=%s %s" % [right,scenario])
			if not miss:
				var reaction: StringName = (&"block_low" if crouched else &"block_mid") if guarded else (&"hurt_crouched" if crouched else &"hurt_mid")
				if scenario == "knockout":
					reaction = &"ko"
				expect.call(target.animated_sprite.animation == reaction, "Fumo: reazione " + scenario)
				smoke._physics_process(1.0/60.0)
				expect.call(target.combat.current_health == expected_health and smoke.hit_targets.size() == 1 and not smoke.is_queued_for_deletion(), "Fumo: un solo impatto per bersaglio, il cono resta visibile")
			var audio := tree.get_nodes_in_group("oscare_cigarette_impact_audio")
			expect.call(audio.is_empty(), "Fumo: nessun suono di impatto, anche su HIT/KO " + scenario)
			if scenario in ["crouched","guard","crouched_guard","knockout"]:
				var before := target.combat.action_generation
				actor.animated_sprite.frame = 34
				smoke._physics_process(1.0/60.0)
				expect.call(target.combat.action_generation == before and target.combat.current_health == expected_health, "Fumo: raffica medium esclusa per " + scenario)
	# One damage event, several medium reactions while still intersecting smoke.
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor.is_facing_right = true
	actor.animated_sprite.flip_h = false
	target.position.x = 1250
	actor._start_smoke_special()
	actor._on_animation_finished()
	actor.animated_sprite.pause()
	actor.animated_sprite.frame = 20
	var repeating := actor._smoke_projectile as OscareSmokeBreathProjectile
	repeating.set_physics_process(false)
	for tick in 2:
		await tree.physics_frame
	repeating._physics_process(1.0/60.0)
	var hit_generation := target.combat.action_generation
	for frame in [25,26,32]:
		actor.animated_sprite.frame = frame
		repeating._physics_process(1.0/60.0)
		expect.call(target.combat.current_health == 90 and target.animated_sprite.animation == &"hurt_mid", "Fumo: serie hurt_medium mantiene 10 danni complessivi al frame " + str(frame+1))
		var expected_generation: int = hit_generation + (int(frame)-20)/Smoke.HURT_REPEAT_FRAMES
		expect.call(target.combat.action_generation == expected_generation, "Fumo: una reazione ogni 6 frame, senza duplicati da piu hurtbox")
	var before_exit := target.combat.action_generation
	target.position.x = 1800
	actor.animated_sprite.frame = 38
	for tick in 2:
		await tree.physics_frame
	repeating._physics_process(1.0/60.0)
	expect.call(target.combat.action_generation == before_exit, "Fumo: uscire dal cono interrompe subito le nuove reazioni")
	target.position.x = 1250
	actor.animated_sprite.frame = 44
	for tick in 2:
		await tree.physics_frame
	repeating._physics_process(1.0/60.0)
	expect.call(target.combat.action_generation == before_exit+1 and target.combat.current_health == 90, "Fumo: rientrare riprende la reazione senza nuovo danno o raffiche arretrate")
	var final_generation := target.combat.action_generation
	actor.animated_sprite.frame = 45
	repeating._physics_process(1.0/60.0)
	expect.call(target.combat.action_generation == final_generation and not repeating.active, "Fumo: fine dissolvenza ferma la raffica")
	actor._on_animation_finished()
	await tree.create_timer(0.55).timeout
	expect.call(target.current_state == Fighter.State.IDLE and target.combat.current_health == 90, "Fumo: ultimo hurt si conclude senza loop o danni residui")
	arena.queue_free()
	await tree.process_frame
	return true
