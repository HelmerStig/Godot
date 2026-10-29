extends RefCounted
const Helpers := preload("res://tests/cases/oscare_cigarette_special.gd")
const Singer := preload("res://scripts/BueSingerProjectile.gd")

static func run(tree: SceneTree, expect: Callable) -> bool:
	var arena := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(arena)
	for tick in 4:
		await tree.physics_frame
	arena.set_physics_process(false)
	var actor: Bue
	var target: Fighter
	for f: Fighter in arena._fighters:
		f.set_physics_process(false)
		f.is_player_controlled = false
		f.position.x = -10000
		if f is Bue:
			actor = f
		elif f is Oscare:
			target = f
	var frames := actor.animated_sprite.sprite_frames
	var correct := frames.get_frame_count(actor.SUMMON_ANIMATION) == 30
	for index in 30:
		var tex := frames.get_frame_texture(actor.SUMMON_ANIMATION,index) as AtlasTexture
		correct = correct and tex.atlas == actor.SUMMON_SHEET and tex.region == Rect2(index%7*512,index/7*512,512,512)
	expect.call(correct and frames.get_animation_speed(actor.SUMMON_ANIMATION) == 60 and not frames.get_animation_loop(actor.SUMMON_ANIMATION),"Bue: Summon 30 frame esatti a 60 FPS")
	for facing in [true,false]:
		for button in [&"light_punch",&"medium_punch",&"heavy_punch"]:
			for mode in 3:
				await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
				Helpers.motion(actor,facing,button,mode)
				actor._physics_process(1.0/60)
				expect.call(actor.summon_active,"Bue: QCF %s facing=%s tolleranza=%d" % [button,facing,mode])
				expect.call(actor._summon_audio.playing and actor._summon_audio.stream == load("res://assets/sounds/sfx/scossa.wav"),"Bue: scossa parte subito all'attivazione")
				actor.animated_sprite.pause()
				actor.animated_sprite.frame = 8
				expect.call(tree.get_nodes_in_group("bue_singer_projectile").is_empty(),"Bue: nessuna evocazione prima del frame 10")
				actor.animated_sprite.frame = 9
				actor._on_animation_frame_changed()
				var projectiles := tree.get_nodes_in_group("bue_singer_projectile")
				expect.call(projectiles.size() == 1,"Bue: evocazione unica al frame 10")
				if projectiles.size() != 1:
					continue
				var singer = projectiles[0]
				singer.set_physics_process(false)
				singer.sprite.pause()
				expect.call(singer.materialize_audio == actor._summon_audio and singer.materialize_audio.get_parent() == singer and singer.materialize_audio.playing and not singer.singing_audio.playing,"Tom: stessa scossa continua dopo evocazione, senza riavvio")
				expect.call(singer.position == actor.position+Vector2(170 if facing else -170,26) and singer.sprite.flip_h == not facing,"Bue: Tom davanti e specchiato, piedi allineati a Bue")
				for spec in [[&"materialize",30,60.0,false,Singer.MATERIALIZE],[&"run",49,48.0,true,Singer.RUN],[&"slaps",49,60.0,false,Singer.SLAPS]]:
					var sf: SpriteFrames = singer.sprite.sprite_frames
					var valid: bool = sf.get_frame_count(spec[0]) == spec[1]
					for index in int(spec[1]):
						var tex := sf.get_frame_texture(spec[0],index) as AtlasTexture
						valid = valid and tex.atlas == spec[4] and tex.region == Rect2(index%7*512,index/7*512,512,512)
					expect.call(valid and sf.get_animation_speed(spec[0]) == spec[2] and sf.get_animation_loop(spec[0]) == spec[3],"Tom: slicing/FPS/loop " + str(spec[0]))
				var before: Vector2 = singer.position
				singer._physics_process(.05)
				expect.call(singer.position == before,"Tom: materializzazione ferma")
				singer._on_animation_finished()
				expect.call(not singer.materialize_audio.playing and singer.singing_audio.playing and not singer.singing_audio.stream_paused and singer.singing_audio.stream == load("res://assets/sounds/tom waits.mp3"),"Tom: fine materializzazione ferma scossa e avvia brano")
				expect.call(absf(singer.singing_audio.get_playback_position()-25.0) < .1,"Tom: brano parte dal secondo 25")
				singer._physics_process(.05)
				expect.call(is_equal_approx(singer.position.x-before.x,(1 if facing else -1)*Singer.SPEED*.05),"Tom: Run Singing avanza con velocita comune")
				actor._on_animation_finished()
				expect.call(actor.current_state == Fighter.State.IDLE and not singer.is_queued_for_deletion(),"Bue: idle dopo Summon, Tom indipendente")
	for facing in [true,false]:
		for scenario in ["hit","block","crouched_hit","crouched_block","knockout","miss","escaped"]:
			await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
			var dir := 1 if facing else -1
			target.position.x = actor.position.x + dir*400
			target.is_facing_right = not facing
			var crouched: bool = scenario.begins_with("crouched")
			var guarded: bool = "block" in scenario
			target.input_buffer.record_input_snapshot(dir if guarded else 0,1 if crouched else 0,[],not facing)
			if crouched:
				target.return_to_crouch_pose()
			target.combat.set_guarding(guarded)
			if scenario == "knockout":
				target.combat.current_health = 4
			if scenario == "miss":
				target.position.y -= 500
			for tick in 2:
				await tree.physics_frame
			var singer := Singer.new()
			singer.setup(actor,facing)
			arena.add_child(singer)
			singer.position = actor.position + Vector2(dir*170,26)
			singer.set_physics_process(false)
			singer._on_animation_finished()
			singer._physics_process(.6)
			if scenario == "miss":
				expect.call(singer.phase == Singer.Phase.APPROACHING and target.combat.current_health == 100,"Tom: nessun colpo senza intersezione hurtbox")
				continue
			expect.call(singer.phase == Singer.Phase.SLAPPING and target.combat.current_health == (4 if scenario == "knockout" else 100),"Tom: contatto avvia Hat slaps, nessun danno prima del cappello")
			expect.call(singer.singing_audio.playing and not singer.singing_audio.stream_paused,"Tom: brano continua durante Hat slaps")
			var cycles := 0
			var previous_generation := target.combat.action_generation
			for tick in 150:
				await tree.physics_frame
				singer._physics_process(1.0/60)
				if target.combat.action_generation != previous_generation:
					previous_generation = target.combat.action_generation
					cycles += 1
					expect.call(singer.singing_audio.playing and not singer.singing_audio.stream_paused,"Tom: musica sovrapposta ad ogni hit")
					if scenario != "knockout":
						expect.call(target.animated_sprite.animation == ((&"block_low" if crouched else &"block_high") if guarded else (&"hurt_crouched" if crouched else &"hurt_high")),"Tom: reazione corretta ad ogni colpo " + scenario)
					if scenario == "escaped":
						target.position.x += dir*500
				if singer.phase == Singer.Phase.EXITING:
					break
			var hp := 100 if guarded else (0 if scenario == "knockout" else (95 if scenario == "escaped" else 85))
			expect.call(target.combat.current_health == hp,"Tom: danno finale " + scenario + str(facing))
			expect.call(singer.hit_sound_count == (0 if guarded else (1 if scenario in ["knockout","escaped"] else 3)),"Tom: un hit del pugno leggero per colpo riuscito")
			for audio in tree.get_nodes_in_group("bue_singer_hit_audio"):
				expect.call(audio.stream == load("res://assets/sounds/sfx/light-punch.wav") and (audio.playing or audio.is_queued_for_deletion()),"Tom: hit audio condiviso con pugno leggero e rimosso a fine suono")
			expect.call(cycles == (1 if scenario in ["knockout","escaped"] else 3),"Tom: tre reazioni distinte sincronizzate ai colpi " + scenario)
			expect.call(singer.phase == Singer.Phase.EXITING and singer.sprite.animation == &"run","Tom: dopo Hat slaps torna Run Singing")
			expect.call(singer.singing_audio.playing and not singer.singing_audio.stream_paused,"Tom: musica continua in uscita")
			expect.call(singer.singing_audio.get_playback_position() > 25.1,"Tom: brano avanza durante i colpi senza ripartire da 25")
			if scenario not in ["knockout","escaped"]:
				expect.call(singer.strikes == 3 and not singer._slaps_finished,"Tom: riparte al terzo colpo senza attendere fine Hat slaps o hurt")
				expect.call(singer.elapsed - .6 < .8,"Tom: nessuna pausa aggiuntiva, uscita entro 800 ms dal contatto")
			var health := target.combat.current_health
			var departure := singer.position.x
			var already_outside := singer.is_queued_for_deletion()
			singer._physics_process(.5)
			expect.call(is_equal_approx(singer.position.x-departure,0.0 if already_outside else dir*Singer.SPEED*.5),"Tom: Run Singing avanza subito finche rimane nello schermo")
			expect.call(target.combat.current_health == health,"Tom: uscita non colpisce di nuovo")
			singer.position.x = actor.stage_right_limit+500 if facing else actor.stage_left_limit-500
			singer._physics_process(.01)
			expect.call(singer.is_queued_for_deletion(),"Tom: rimosso fuori campo")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor._start_summon()
	actor.animated_sprite.frame = 5
	actor.combat.take_damage(1,target)
	actor._on_animation_frame_changed()
	expect.call(not actor.summon_active and tree.get_nodes_in_group("bue_singer_projectile").is_empty(),"Bue: hurt annulla evocazione prima del frame 10")
	expect.call(not actor._summon_audio.playing,"Bue: hurt prima dell'evocazione ferma scossa")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor._start_summon()
	actor.animated_sprite.frame = 9
	actor.combat.take_damage(1,target)
	expect.call(tree.get_nodes_in_group("bue_singer_projectile").size() == 1,"Bue: Tom gia evocato continua dopo hurt del proprietario")
	expect.call(actor._summon_audio.playing,"Bue: scossa gia trasferita continua con Tom dopo hurt")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	expect.call(tree.get_nodes_in_group("bue_singer_projectile").is_empty(),"Bue: reset elimina evocazione")
	expect.call(tree.get_nodes_in_group("bue_singer_hit_audio").is_empty(),"Bue: reset elimina anche gli audio di impatto")
	# The lock follows Tom's lifetime, not just Bue's short summon animation.
	actor._start_summon()
	actor.animated_sprite.frame = 9
	var active_singer = actor._summoned_singer
	active_singer.set_physics_process(false)
	active_singer.sprite.pause()
	actor._on_animation_finished()
	for phase in [Singer.Phase.MATERIALIZING,Singer.Phase.APPROACHING,Singer.Phase.SLAPPING,Singer.Phase.EXITING]:
		active_singer.phase = phase
		for button in [&"light_punch",&"medium_punch",&"heavy_punch"]:
			actor.input_buffer.clear()
			Helpers.motion(actor,true,button)
			expect.call(not actor._try_start_character_special() and not actor.summon_active and tree.get_nodes_in_group("bue_singer_projectile").size() == 1,"Bue: nessuna nuova evocazione con Tom attivo, fase=%d pulsante=%s" % [phase,button])
	actor._start_summon()
	expect.call(not actor.summon_active and actor._summoned_singer == active_singer,"Bue: anche avvio diretto rispetta il blocco")
	active_singer.queue_free()
	expect.call(not actor._try_start_character_special(),"Bue: blocco fino all'effettiva scomparsa di Tom")
	await tree.process_frame
	actor.input_buffer.clear()
	Helpers.motion(actor,true,&"light_punch")
	expect.call(actor._try_start_character_special() and actor.summon_active,"Bue: special nuovamente disponibile dopo uscita di Tom")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor.controls_enabled = false
	Helpers.motion(actor,true,&"light_punch")
	expect.call(not actor._try_start_character_special(),"Bue: controlli disabilitati impediscono special")
	actor.controls_enabled = true
	actor.position.y -= 300
	actor.velocity.y = -1
	actor.move_and_slide()
	expect.call(not actor._try_start_character_special(),"Bue: special solo a terra")
	arena.queue_free()
	await tree.process_frame
	return true
