extends RefCounted

const Helpers := preload("res://tests/cases/oscare_cigarette_special.gd")
const Sparks := preload("res://scripts/TorpeWeldingSparks.gd")


static func motion(actor: Fighter, right: bool, button: StringName, mode := 0) -> void:
	var back := -1 if right else 1
	actor.is_facing_right = right
	actor.animated_sprite.flip_h = not right
	actor.input_buffer.record_input_snapshot(0,1,[],right)
	if mode != 2:
		actor.input_buffer.record_input_snapshot(back,1,[],right)
	actor.input_buffer.record_input_snapshot(back,1 if mode == 1 else 0,[button],right)


static func ignite(actor: Torpe, strength: StringName = &"light") -> TorpeWeldingSparks:
	actor._start_welding_special(strength)
	actor.animated_sprite.pause()
	actor.animated_sprite.frame = 42
	var effect := actor._welding_sparks as TorpeWeldingSparks
	effect.set_physics_process(false)
	return effect


static func run(tree: SceneTree, expect: Callable) -> bool:
	var arena := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(arena)
	for tick in 4:
		await tree.physics_frame
	arena.set_physics_process(false)
	var actor: Torpe
	var target: Fighter
	for fighter: Fighter in arena._fighters:
		fighter.set_physics_process(false)
		fighter.is_player_controlled = false
		fighter.position.x = -10000
		if fighter is Torpe:
			actor = fighter
		elif fighter is IdleRosterFighter and target == null:
			target = fighter
	expect.call(actor != null, "Saldatura: Torpe specializzato nella scena reale")
	if actor == null:
		arena.queue_free()
		return false
	var frames := actor.animated_sprite.sprite_frames
	var animation := actor.WELDING_ANIMATION
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/characters/torpe/special_2_welding_candidate.autosprite.json"))
	var valid := frames.get_frame_count(animation) == 64 and frames.get_animation_speed(animation) == 60 and not frames.get_animation_loop(animation)
	for index in 64:
		var source: int = int(metadata.localSequence.sourceFrames1Based[index]) - 1
		var texture := frames.get_frame_texture(animation,index) as AtlasTexture
		valid = valid and texture.atlas.resource_path.ends_with("special_2_welding_candidate.png") and texture.region == Rect2(source%8*512,source/8*512,512,512)
	expect.call(valid, "Saldatura: sequenza 64 frame esatta a 60 FPS senza loop")
	for right in [true,false]:
		for spec in [[&"light_punch",&"light",10,600.0], [&"medium_punch",&"medium",15,1000.0], [&"heavy_punch",&"heavy",20,1400.0]]:
			for mode in 3:
				await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
				motion(actor,right,spec[0],mode)
				actor._physics_process(1.0/60.0)
				expect.call(actor.welding_special_active and not actor.beer_special_active and actor.welding_strength == spec[1] and actor.animated_sprite.animation == animation, "Saldatura: QCB prioritario facing=%s pugno=%s tolleranza=%d" % [right,spec[0],mode])
				actor.animated_sprite.pause()
				actor.animated_sprite.frame = 41
				expect.call(not actor.welding_spawned and tree.get_nodes_in_group("torpe_welding_sparks").is_empty() and actor.combat.hitbox_shape.disabled, "Saldatura: maschera e preparazione senza getto o audio anticipato")
				actor.animated_sprite.frame = 42
				var effect := actor._welding_sparks as TorpeWeldingSparks
				expect.call(is_instance_valid(effect) and tree.get_nodes_in_group("torpe_welding_sparks").size() == 1, "Saldatura: primo arco AutoSprite al frame 43 avvia un solo getto")
				if effect == null:
					arena.queue_free()
					return false
				effect.set_physics_process(false)
				expect.call(effect.damage == spec[2] and effect.emission_rate == spec[3] and effect.audio.playing and effect.audio.stream.data == Sparks.SOUND.data, "Saldatura: danno e densita crescenti, saldatore.wav durante il getto")
				var particles_valid := effect.particle_emitters.size() == 3
				for particles in effect.particle_emitters:
					particles_valid = particles_valid and particles.emitting and not particles.local_coords and particles.amount >= 60 and particles.gravity.y > 0 and particles.direction.x == (1 if right else -1) and particles.initial_velocity_max * particles.lifetime <= 300.01
				expect.call(particles_valid, "Saldatura: tre emettitori luminosi blu/rossi/gialli, gravita e portata 300 px")
				var direction := 1.0 if right else -1.0
				var expected := actor.animated_sprite.to_global(Vector2(92*direction,-115) + actor.animated_sprite.offset)
				expect.call(effect.emitter_position.is_equal_approx(expected), "Saldatura: scintille ancorate alla punta e specchiate")
				for tick in 3:
					effect._physics_process(1.0/60.0)
				var colors: Array[Color] = []
				var falling := true
				for spark in effect.sparks:
					if not colors.has(spark.color):
						colors.append(spark.color)
					falling = falling and signf(spark.velocity.x) == direction and spark.velocity.y > -15 and absf(spark.position.x-spark.origin.x) <= 300
				expect.call(colors.size() == 3 and falling, "Saldatura: alternanza blu/rosso/giallo, avanzamento e gravita entro 300 px")
				var old_particle: Vector2 = effect.sparks[0].position
				actor.position.x += 12
				actor.animated_sprite.frame = 45
				expect.call(effect.emitter_position.is_equal_approx(actor.get_welding_tip_global_position()) and effect.sparks[0].position == old_particle, "Saldatura: punta segue la posa, scintille gia emesse continuano nel mondo")
				actor.animated_sprite.frame = 42
				expect.call(tree.get_nodes_in_group("torpe_welding_sparks").size() == 1, "Saldatura: callback ripetute non duplicano il getto")
				actor.animated_sprite.frame = 63
				expect.call(effect.emitting and effect.audio.playing, "Saldatura: emissione e audio restano fino all'ultimo arco AutoSprite")
				actor._on_animation_finished()
				expect.call(actor.current_state == Fighter.State.IDLE and not actor.welding_special_active and not effect.emitting and not effect.audio.playing, "Saldatura: fine mossa torna idle, interrompe emissione e suono")
				for tick in 20:
					effect._physics_process(1.0/60.0)
				expect.call(effect.sparks.is_empty() and effect.is_queued_for_deletion(), "Saldatura: particelle residue esauriscono volo e portata senza restare attive")
	# Actual ray collisions, with the target 110px in front of the torch.
	for right in [true,false]:
		for strength in [&"light",&"medium",&"heavy"]:
			for scenario in ["hit","long_range","overlap","block","crouched_hit","crouched_block","far","behind","above","invulnerable","knockout"]:
				await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
				actor.is_facing_right = right
				actor.animated_sprite.flip_h = not right
				var direction := 1.0 if right else -1.0
				target.is_facing_right = not right
				target.animated_sprite.flip_h = right
				target.position.x = actor.position.x + direction * 200
				var crouched: bool = scenario in ["crouched_hit","crouched_block"]
				var guarded: bool = scenario in ["block","crouched_block"]
				var miss: bool = scenario in ["far","behind","above","invulnerable"]
				if crouched:
					target.input_buffer.record_input_snapshot(int(direction) if guarded else 0,1,[],not right)
					target.return_to_crouch_pose()
				else:
					target.input_buffer.record_input_snapshot(int(direction) if guarded else 0,0,[],not right)
				target.combat.set_guarding(guarded)
				if scenario == "far":
					target.position.x = actor.position.x + direction * 500
				elif scenario == "long_range":
					target.position.x = actor.position.x + direction * 410
				elif scenario == "behind":
					target.position.x = actor.position.x - direction * 200
				elif scenario == "above":
					target.position.y -= 300
				elif scenario == "overlap":
					target.position.x = actor.position.x + direction * 90
				elif scenario == "invulnerable":
					target.current_state = Fighter.State.KNOCKDOWN_RECOVERY
				elif scenario == "knockout":
					target.combat.current_health = 5
				for tick in 2:
					await tree.physics_frame
				var effect := ignite(actor,strength)
				for tick in 18:
					effect._physics_process(1.0/60.0)
				var expected_health := 100 if guarded or miss else (0 if scenario == "knockout" else 100-int(Sparks.DAMAGE[strength]))
				expect.call(target.combat.current_health == expected_health and effect.hit_targets.has(target) == not miss, "Saldatura: collisioni reali %s facing=%s forza=%s" % [scenario,right,strength])
				for tick in 8:
					effect._physics_process(1.0/60.0)
				expect.call(target.combat.current_health == expected_health, "Saldatura: il numero di scintille non moltiplica il danno")
				expect.call(actor.combat.current_health == 100, "Saldatura: nessun danno al proprietario")
				if not miss and scenario != "knockout":
					var expected: StringName = (&"block_low" if crouched else &"block_mid") if guarded else &"hurt_high"
					expect.call(target.animated_sprite.animation == expected, "Saldatura: hurt_high su HIT, parata coerente con la postura")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor._start_welding_special()
	await tree.create_timer(1.15).timeout
	expect.call(actor.current_state == Fighter.State.IDLE and not actor.welding_special_active, "Saldatura: playback reale di 64 frame a 60 FPS torna idle")
	await tree.create_timer(.4).timeout
	expect.call(tree.get_nodes_in_group("torpe_welding_sparks").is_empty(), "Saldatura: il getto reale si esaurisce dopo l'emissione")
	for phase in [20,50]:
		await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
		actor._start_welding_special()
		actor.animated_sprite.pause()
		actor.animated_sprite.frame = phase
		var effect := actor._welding_sparks as TorpeWeldingSparks
		actor.combat.take_damage(1,target,.3,.1,AttackData.HitHeight.MID)
		actor.animated_sprite.frame = 63
		expect.call(not actor.welding_special_active and (effect == null or (effect.is_queued_for_deletion() and not effect.audio.playing)), "Saldatura: hurt interrompe preparazione/getto senza scintille tardive")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	motion(actor,true,&"light_punch")
	actor.controls_enabled = false
	expect.call(not actor._try_start_character_special(), "Saldatura: round concluso impedisce QCB")
	actor.controls_enabled = true
	actor.position.y -= 200
	actor.velocity.y = -1
	actor.move_and_slide()
	expect.call(not actor._try_start_character_special(), "Saldatura: non parte in aria")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor.input_buffer.record_input_snapshot(0,1,[],true)
	actor.input_buffer.record_input_snapshot(-1,1,[],true)
	for tick in 38:
		await tree.physics_frame
	actor.input_buffer.record_input_snapshot(-1,0,[&"light_punch"],true)
	expect.call(not actor._try_start_character_special(), "Saldatura: QCB scaduto non consuma il pugno")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	var effect := ignite(actor)
	actor.reset_fighter(Vector2(1000,arena.FLOOR_Y))
	for tick in 2:
		await tree.physics_frame
	expect.call(tree.get_nodes_in_group("torpe_welding_sparks").is_empty() and not actor.welding_special_active, "Saldatura: reset elimina getto, danni e audio")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor.is_facing_right = true
	actor.animated_sprite.flip_h = false
	target.position.x = 1200
	for tick in 2:
		await tree.physics_frame
	var old_jet := ignite(actor)
	for tick in 10:
		old_jet._physics_process(1.0/60.0)
	expect.call(target.combat.current_health == 90, "Saldatura: contatto prima del reset del difensore")
	target.reset_fighter(Vector2(1200,arena.FLOOR_Y))
	for tick in 10:
		old_jet._physics_process(1.0/60.0)
	expect.call(target.combat.current_health == 100 and target.current_state == Fighter.State.IDLE, "Saldatura: nessun hurt o danno tardivo dopo il reset del difensore")
	target._start_light_punch()
	old_jet._hit_area(target.get_node("Hurtbox"))
	expect.call(target.animated_sprite.animation == &"light_punch", "Saldatura: la ripetizione del vecchio hurt non sovrascrive una nuova azione")
	target.reset_fighter(Vector2(-10000,arena.FLOOR_Y))
	for tick in 2:
		await tree.physics_frame
	# Real animation and physics on every defender, including Oscare's short hurt.
	var defenders: Array[Fighter] = []
	for fighter: Fighter in arena._fighters:
		if fighter != actor:
			defenders.append(fighter)
	var torpe_defender := (load("res://scenes/Torpe.tscn") as PackedScene).instantiate() as Fighter
	arena.add_child(torpe_defender)
	torpe_defender.is_player_controlled = false
	torpe_defender.set_physics_process(false)
	defenders.append(torpe_defender)
	for defender in defenders:
		await Helpers.settle(tree,actor,defender,arena.FLOOR_Y)
		actor.is_facing_right = true
		actor.animated_sprite.flip_h = false
		defender.position.x = 1200
		defender.is_facing_right = false
		defender.animated_sprite.flip_h = true
		var observed: Array[int] = []
		var reverse_observed: Array[int] = []
		var record := func():
			if defender.animated_sprite.animation == &"hurt_high":
				if observed.is_empty() or observed[-1] != defender.animated_sprite.frame:
					observed.append(defender.animated_sprite.frame)
			elif defender.animated_sprite.animation == &"hurt_high_reverse":
				reverse_observed.append(defender.animated_sprite.frame)
		# Idle frame 0 -> hurt frame 0 changes the animation without necessarily
		# emitting frame_changed, so record its reset after animation_changed too.
		var record_start := func():
			if defender.animated_sprite.animation == &"hurt_high":
				record.call_deferred()
		defender.animated_sprite.frame_changed.connect(record)
		defender.animated_sprite.animation_changed.connect(record_start)
		actor.set_physics_process(true)
		defender.set_physics_process(true)
		actor._start_welding_special()
		await tree.create_timer(1.25 + defender.get_animation_duration(&"hurt_high")).timeout
		actor.set_physics_process(false)
		defender.set_physics_process(false)
		var complete := true
		for index in defender.animated_sprite.sprite_frames.get_frame_count(&"hurt_high"):
			complete = complete and observed.has(index)
		if defender.animated_sprite.sprite_frames.has_animation(&"hurt_high_reverse"):
			for index in defender.animated_sprite.sprite_frames.get_frame_count(&"hurt_high_reverse"):
				complete = complete and reverse_observed.has(index)
		expect.call(defender.combat.current_health == 90 and not observed.is_empty(), "%s: scintille reali infliggono danno e avviano hurt_high" % defender.name)
		expect.call(complete, "%s: tutti i fotogrammi hurt_high realmente riprodotti con fisica attiva" % defender.name)
		if defender is Oscare:
			var full_cycles := 0
			for offset in range(0,observed.size()-7,8):
				var full_cycle := true
				for frame in 8:
					full_cycle = full_cycle and observed[offset+frame] == frame
				if full_cycle:
					full_cycles += 1
			expect.call(full_cycles >= 2, "Oscare: il getto mantiene almeno due hurt_high completi senza danno aggiuntivo")
		print("WELDING_REACTION: %s frames=%s state=%s animation=%s" % [defender.name,observed,defender.current_state,defender.animated_sprite.animation])
		defender.animated_sprite.frame_changed.disconnect(record)
		defender.animated_sprite.animation_changed.disconnect(record_start)
		defender.position.x = -10000
	arena.queue_free()
	await tree.process_frame
	await tree.process_frame
	# KO in the real arena cancels the source action synchronously during a ray hit.
	var selection := tree.root.get_node("CharacterSelection")
	var previous := [selection.player1_id,selection.player2_id]
	selection.player1_id = "torpe"
	selection.player2_id = "oscare"
	var main := (load("res://scenes/MainArena.tscn") as PackedScene).instantiate() as MainArena
	tree.root.add_child(main)
	await tree.create_timer(3.15).timeout
	var real_actor := main.player1 as Torpe
	var real_defender := main.player2 as Oscare
	real_actor.position = Vector2(876,main.FLOOR_Y)
	real_defender.position = Vector2(1076,main.FLOOR_Y)
	var high_end_frames: Array[int] = []
	var record_high_end := func():
		if real_defender.animated_sprite.animation == &"hurt_high" and real_defender.animated_sprite.frame == 7:
			high_end_frames.append(7)
	real_defender.animated_sprite.frame_changed.connect(record_high_end)
	Input.action_press(&"p1_crouch")
	for tick in 4:
		await tree.physics_frame
	Input.action_press(&"p1_move_left")
	for tick in 4:
		await tree.physics_frame
	Input.action_release(&"p1_crouch")
	Input.action_press(&"p1_light_punch")
	for tick in 2:
		await tree.physics_frame
	Input.action_release(&"p1_light_punch")
	Input.action_release(&"p1_move_left")
	await tree.create_timer(1.5).timeout
	expect.call(real_defender.combat.current_health == 90 and high_end_frames.size() >= 2, "Arena Torpe contro Oscare: QCB reale produce piu hurt_high completi con un solo danno")
	real_defender.animated_sprite.frame_changed.disconnect(record_high_end)
	main.set_physics_process(false)
	(load("res://tests/cases/roster_victory.gd") as GDScript).reset_round(main)
	var winner := main.player1 as Torpe
	var loser := main.player2
	for fighter in [winner,loser]:
		fighter.set_physics_process(false)
		fighter.is_player_controlled = false
	loser.position = winner.position + Vector2(200,0)
	loser.combat.current_health = 5
	for tick in 3:
		await tree.physics_frame
	winner.is_facing_right = true
	winner.animated_sprite.flip_h = false
	var winning_sparks := ignite(winner)
	for tick in 18:
		winning_sparks._physics_process(1.0/60.0)
		if winning_sparks.is_queued_for_deletion():
			break
	expect.call(not main.round_active and winner.current_state == Fighter.State.VICTORY and not winner.welding_special_active and winning_sparks.is_queued_for_deletion() and not winning_sparks.audio.playing, "Saldatura: KO reale cancella getto/audio e avvia Victory senza callback tardive")
	main.queue_free()
	await tree.process_frame
	await tree.process_frame
	selection.player1_id = previous[0]
	selection.player2_id = previous[1]
	return true
