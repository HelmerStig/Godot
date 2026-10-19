extends RefCounted

const Projectile := preload("res://scripts/OscareCigaretteProjectile.gd")


static func settle(tree: SceneTree, actor: Fighter, target: Fighter, floor_y: float) -> void:
	actor.reset_fighter(Vector2(1000,floor_y))
	target.reset_fighter(Vector2(1600,floor_y))
	actor.controls_enabled = true
	target.controls_enabled = true
	actor.opponent = null
	target.opponent = actor
	for tick in 3:
		await tree.physics_frame
	for f in [actor,target]:
		f.velocity = Vector2(0,1)
		f.move_and_slide()


static func motion(actor: Fighter, facing_right: bool, button: StringName, mode: int = 0) -> void:
	var axis := 1 if facing_right else -1
	actor.is_facing_right = facing_right
	actor.animated_sprite.flip_h = not facing_right
	actor.input_buffer.record_input_snapshot(0,1,[],facing_right)
	if mode != 2:
		actor.input_buffer.record_input_snapshot(axis,1,[],facing_right)
	if mode == 1:
		actor.input_buffer.record_input_snapshot(axis,1,[button],facing_right)
	else:
		actor.input_buffer.record_input_snapshot(axis,0,[button],facing_right)


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
	expect.call(actor != null, "Oscare: controller specializzato nella scena reale")
	if actor == null:
		arena.queue_free()
		return false
	var frames := actor.animated_sprite.sprite_frames
	for spec in [[actor.LIGHT_ANIMATION,20,actor.LIGHT_CIGARETTE_SHEET], [actor.FLICK_ANIMATION,29,actor.FLICK_SHEET]]:
		var valid: bool = frames.get_frame_count(spec[0]) == spec[1]
		for index in int(spec[1]):
			var source_index: int = 19 if spec[0] == actor.FLICK_ANIMATION and index == 18 else index
			var texture := frames.get_frame_texture(spec[0],index) as AtlasTexture
			valid = valid and texture.atlas == spec[2] and texture.region == Rect2(source_index%7*512,source_index/7*512,512,512)
		expect.call(valid and frames.get_animation_speed(spec[0]) == 60.0 and not frames.get_animation_loop(spec[0]), "Oscare: atlas esatto, 60 FPS, non loop " + str(spec[0]))
	for facing_right in [true,false]:
		for spec in [[&"light_punch",&"light",520.0], [&"medium_punch",&"medium",720.0], [&"heavy_punch",&"heavy",920.0]]:
			for mode in 3:
				await settle(tree,actor,target,arena.FLOOR_Y)
				motion(actor,facing_right,spec[0],mode)
				actor._physics_process(1.0/60.0)
				expect.call(actor.cigarette_special_active and actor.animated_sprite.animation == actor.LIGHT_ANIMATION and actor.cigarette_strength == spec[1], "Oscare: QCF prioritario, facing=%s pugno=%s tolleranza=%d" % [facing_right,spec[0],mode])
				actor.animated_sprite.pause()
				expect.call(tree.get_nodes_in_group("oscare_cigarette_projectile").is_empty() and actor.combat.hitbox_shape.disabled and actor.velocity.x == 0, "Oscare: preparazione ferma, senza hitbox o proiettile prematuro")
				actor._on_animation_finished()
				actor.animated_sprite.pause()
				expect.call(actor.animated_sprite.animation == actor.FLICK_ANIMATION and actor.combat.is_attacking, "Oscare: accensione continua nel lancio senza idle")
				actor.animated_sprite.frame = 17
				expect.call(not actor.cigarette_spawned, "Oscare: prima del rilascio nessun proiettile")
				actor.animated_sprite.frame = 18
				var projectiles := tree.get_nodes_in_group("oscare_cigarette_projectile")
				expect.call(projectiles.size() == 1, "Oscare: un proiettile al frame 19 del lancio")
				var projectile = projectiles[0]
				projectile.set_physics_process(false)
				var sign_x := 1.0 if facing_right else -1.0
				expect.call(projectile.movement_speed == spec[2] and projectile.travel_direction == sign_x and is_equal_approx(projectile.position.x - actor.position.x,123.28*sign_x), "Oscare: velocita e posizione alla mano speculari")
				expect.call(projectile.sprite.sprite_frames.get_frame_count(&"fly") == 25 and projectile.sprite.sprite_frames.get_animation_speed(&"fly") == 60.0 and projectile.sprite.flip_h == not facing_right, "Sigaretta: 25 frame a 60 FPS e facing corretto")
				actor.animated_sprite.frame = 20
				actor.animated_sprite.frame = 18
				expect.call(tree.get_nodes_in_group("oscare_cigarette_projectile").size() == 1, "Oscare: nessun doppio lancio da callback ripetute")
				actor._on_animation_finished()
				expect.call(not actor.combat.is_attacking and actor.current_state == Fighter.State.IDLE, "Oscare: fine sequenza torna idle")
	# Real animation playback, not only simulated callbacks.
	await settle(tree,actor,target,arena.FLOOR_Y)
	actor._start_cigarette_special()
	actor.animated_sprite.pause()
	actor.animated_sprite.frame = 4
	expect.call(not actor._ignition_audio.playing and not actor._ignition_sound_played, "Oscare: frame 1-5 accensione senza suono anticipato")
	actor.animated_sprite.frame = 5
	expect.call(actor._ignition_audio.playing and actor._ignition_sound_played and actor._ignition_audio.stream == load("res://assets/sounds/sfx/siga-accensione.wav"), "Oscare: frame 6 avvia siga-accensione.wav")
	actor._ignition_audio.stop()
	actor.animated_sprite.frame = 6
	actor.animated_sprite.frame = 5
	expect.call(not actor._ignition_audio.playing, "Oscare: callback ripetute non riavviano l'accensione")
	actor.reset_fighter(Vector2(1000,arena.FLOOR_Y))
	actor._start_cigarette_special()
	actor.animated_sprite.pause()
	actor.animated_sprite.frame = 5
	expect.call(actor._ignition_audio.playing, "Oscare: nuova esecuzione riproduce di nuovo l'accensione")
	actor._on_animation_finished()
	actor.animated_sprite.pause()
	actor._on_animation_finished()
	expect.call(actor._ignition_audio.playing, "Oscare: fine naturale della mossa lascia completare il suono")
	actor.reset_fighter(Vector2(1000,arena.FLOOR_Y))
	expect.call(not actor._ignition_audio.playing and not actor._ignition_sound_played, "Oscare: reset ferma e riabilita l'audio di accensione")
	await settle(tree,actor,target,arena.FLOOR_Y)
	actor.return_to_crouch_pose()
	actor.change_state(Fighter.State.STANDING_UP)
	motion(actor,true,&"medium_punch")
	expect.call(actor._try_start_character_special() and actor.cigarette_special_active, "Oscare: quarto di luna puo interrompere il rialzarsi")
	await settle(tree,actor,target,arena.FLOOR_Y)
	actor.input_buffer.record_input_snapshot(0,1,[],true)
	actor.input_buffer.record_input_snapshot(1,1,[],true)
	actor.input_buffer.record_input_snapshot(0,1,[&"light_punch"],true)
	actor._physics_process(1.0/60.0)
	expect.call(not actor.cigarette_special_active and actor.animated_sprite.animation == &"crouched_light_punch", "Oscare: una diagonale vecchia non consuma il normale pugno basso")
	await settle(tree,actor,target,arena.FLOOR_Y)
	actor.input_buffer.record_input_snapshot(0,1,[],true)
	for tick in 25:
		await tree.physics_frame
	actor.input_buffer.record_input_snapshot(1,1,[],true)
	actor.input_buffer.record_input_snapshot(1,0,[&"heavy_punch"],true)
	expect.call(actor._try_start_character_special(), "Oscare: quarto di luna lento entro 600 ms accettato")
	await settle(tree,actor,target,arena.FLOOR_Y)
	motion(actor,true,&"light_punch")
	actor._physics_process(1.0/60.0)
	await tree.create_timer(0.9).timeout
	expect.call(actor.current_state == Fighter.State.IDLE and not actor.cigarette_special_active and tree.get_nodes_in_group("oscare_cigarette_projectile").size() == 1, "Oscare: riproduzione reale completa a 60 FPS e singolo proiettile")
	for phase in [actor.LIGHT_ANIMATION,actor.FLICK_ANIMATION]:
		await settle(tree,actor,target,arena.FLOOR_Y)
		actor._start_cigarette_special()
		actor.animated_sprite.play(phase)
		actor.animated_sprite.pause()
		if phase == actor.LIGHT_ANIMATION:
			actor.animated_sprite.frame = 5
		actor.combat.take_damage(1,target,0.3,0.1,AttackData.HitHeight.MID)
		actor._on_animation_finished()
		expect.call(not actor.cigarette_special_active and tree.get_nodes_in_group("oscare_cigarette_projectile").is_empty(), "Oscare: danno interrompe " + str(phase) + " senza lancio tardivo")
		expect.call(not actor._ignition_audio.playing, "Oscare: interruzione ferma l'audio di accensione")
	await settle(tree,actor,target,arena.FLOOR_Y)
	actor.controls_enabled = false
	motion(actor,true,&"light_punch")
	expect.call(not actor._try_start_character_special(), "Oscare: controlli disabilitati impediscono la Special")
	actor.controls_enabled = true
	actor.position.y -= 300
	actor.velocity.y = -1
	actor.move_and_slide()
	expect.call(not actor._try_start_character_special(), "Oscare: Special non eseguibile in aria")
	# The motion must expire, while a plain forward+punch stays a normal attack.
	await settle(tree,actor,target,arena.FLOOR_Y)
	actor.input_buffer.record_input_snapshot(0,1,[],true)
	actor.input_buffer.record_input_snapshot(1,1,[],true)
	for tick in 38:
		await tree.physics_frame
	actor.input_buffer.record_input_snapshot(1,0,[&"light_punch"],true)
	expect.call(not actor._try_start_character_special(), "Oscare: quarto di luna scaduto non genera Special")
	await settle(tree,actor,target,arena.FLOOR_Y)
	actor.input_buffer.record_input_snapshot(1,0,[&"light_punch"],true)
	actor._physics_process(1.0/60.0)
	expect.call(actor.animated_sprite.animation == &"light_punch" and not actor.cigarette_special_active, "Oscare: avanti+LP senza quarto di luna resta pugno normale")
	# Sweep through an entire hurtbox in one step, including guard and duck whiff.
	for scenario in ["hit","hit_during_low_punch","block","crouched_hit","crouched_block","above_crouch","knockout"]:
		await settle(tree,actor,target,arena.FLOOR_Y)
		target.position.x = 1200
		target.is_facing_right = false
		target.animated_sprite.flip_h = true
		var crouched: bool = scenario in ["crouched_hit","crouched_block","above_crouch"]
		var guarded: bool = scenario in ["block","crouched_block"]
		var knockout: bool = scenario == "knockout"
		if knockout:
			target.combat.current_health = 5
		if crouched:
			target.input_buffer.record_input_snapshot(1 if guarded else 0,1,[],false)
			target.return_to_crouch_pose()
		else:
			target.input_buffer.record_input_snapshot(1 if guarded else 0,0,[],false)
		target.combat.set_guarding(guarded)
		if scenario == "hit_during_low_punch":
			actor._start_low_light_punch()
			actor.animated_sprite.pause()
		for tick in 2:
			await tree.physics_frame
		var p := Projectile.new()
		p.setup(actor,true,&"heavy")
		arena.add_child(p)
		p.set_physics_process(false)
		p.position = Vector2(1050,arena.FLOOR_Y - (225 if scenario == "above_crouch" else 170))
		var previous_effects := tree.get_nodes_in_group("hurt_colored_explosion")
		var previous_blue_count := tree.get_nodes_in_group("hurt_blue_explosion").size()
		p._physics_process(0.3)
		var miss: bool = scenario == "above_crouch"
		var expected_health := 100 if guarded or miss else (0 if knockout else 90)
		expect.call(target.combat.current_health == expected_health and p.has_hit == not miss, "Sigaretta: sweep reale, collisione e danno " + scenario)
		var impact_audio := tree.get_nodes_in_group("oscare_cigarette_impact_audio")
		expect.call(impact_audio.size() == (0 if guarded or miss else 1), "Sigaretta: crepitio solo a segno " + scenario)
		var new_effects := tree.get_nodes_in_group("hurt_colored_explosion").filter(func(fx): return not previous_effects.has(fx))
		expect.call(new_effects.size() == (0 if guarded or miss else 1) and tree.get_nodes_in_group("hurt_blue_explosion").size() == previous_blue_count, "Sigaretta: solo esplosione arancione su HIT/KO " + scenario)
		for fx in new_effects:
			var sparks := fx.get_node("BlueSparks") as CPUParticles2D
			var flash := fx.get_node("BlueFlash") as Sprite2D
			var glow := flash.texture as GradientTexture2D
			expect.call(sparks.color == Projectile.IMPACT_COLOR and glow.gradient.get_color(1) == Color(1.0,0.42,0.06,0.58), "Sigaretta: scintille e bagliore realmente arancioni " + scenario)
		if not miss:
			var expected: StringName = (&"block_low" if crouched else &"block_mid") if guarded else (&"hurt_crouched" if crouched else &"hurt_high")
			if knockout:
				expected = &"ko"
			expect.call(target.animated_sprite.animation == expected, "Sigaretta: reazione reale " + scenario)
			p._physics_process(0.3)
			expect.call(target.combat.current_health == expected_health and tree.get_nodes_in_group("oscare_cigarette_impact_audio").size() == impact_audio.size(), "Sigaretta: un solo impatto e un solo crepitio anche su piu hurtbox")
			if not guarded:
				for tick in 2:
					await tree.physics_frame
				expect.call(not is_instance_valid(p) and impact_audio[0].playing and impact_audio[0].stream == load("res://assets/sounds/sfx/crepitio.wav"), "Sigaretta: crepitio continua dopo la scomparsa del proiettile")
		else:
			p.elapsed = p.MAX_LIFETIME
			p._physics_process(0.01)
			expect.call(p.is_queued_for_deletion(), "Sigaretta: scadenza libera un proiettile a vuoto")
	await settle(tree,actor,target,arena.FLOOR_Y)
	expect.call(tree.get_nodes_in_group("oscare_cigarette_projectile").is_empty(), "Oscare: reset elimina tutti i propri proiettili")
	target.position.x = 1200
	var left_projectile := Projectile.new()
	left_projectile.setup(actor,false,&"heavy")
	arena.add_child(left_projectile)
	left_projectile.set_physics_process(false)
	left_projectile.position = Vector2(1400,arena.FLOOR_Y-170)
	for tick in 2:
		await tree.physics_frame
	left_projectile._physics_process(0.3)
	expect.call(left_projectile.has_hit and target.combat.current_health == 90, "Sigaretta: sweep veloce colpisce anche verso sinistra")
	await settle(tree,actor,target,arena.FLOOR_Y)
	expect.call(tree.get_nodes_in_group("oscare_cigarette_impact_audio").is_empty(), "Sigaretta: reset elimina il proprio audio di impatto")
	var expiring_audio_projectile := Projectile.new()
	expiring_audio_projectile.setup(actor,true)
	arena.add_child(expiring_audio_projectile)
	expiring_audio_projectile.set_physics_process(false)
	expiring_audio_projectile._play_impact_sound()
	expiring_audio_projectile.queue_free()
	await tree.create_timer(1.1).timeout
	expect.call(tree.get_nodes_in_group("oscare_cigarette_impact_audio").is_empty(), "Sigaretta: fine del crepitio libera il player audio")
	# All fighter overrides must forward the per-hit tint; subsequent normal
	# attacks on the same victim must still use the unchanged blue palette.
	var mirror_victim := (load("res://scenes/Oscare.tscn") as PackedScene).instantiate() as Fighter
	arena.add_child(mirror_victim)
	mirror_victim.set_physics_process(false)
	mirror_victim.is_player_controlled = false
	var victims: Array = arena._fighters.duplicate()
	victims.append(mirror_victim)
	for victim: Fighter in victims:
		if victim == actor:
			continue
		await settle(tree,actor,victim,arena.FLOOR_Y)
		var old_orange := tree.get_nodes_in_group("hurt_colored_explosion")
		var p := Projectile.new()
		p.setup(actor,true)
		arena.add_child(p)
		p.set_physics_process(false)
		p._hit_area(victim.get_node("Hurtbox"))
		var orange := tree.get_nodes_in_group("hurt_colored_explosion").filter(func(fx): return not old_orange.has(fx))
		expect.call(orange.size() == 1 and (orange[0].get_node("BlueSparks") as CPUParticles2D).color == Projectile.IMPACT_COLOR, str(victim.name) + ": impatto sigaretta arancione")
		var old_blue := tree.get_nodes_in_group("hurt_blue_explosion")
		victim.combat.take_damage(1,actor,0.3,0.1,AttackData.HitHeight.HIGH)
		var blue := tree.get_nodes_in_group("hurt_blue_explosion").filter(func(fx): return not old_blue.has(fx))
		expect.call(blue.size() == 1 and (blue[0].get_node("BlueSparks") as CPUParticles2D).color == Color(0.24,0.76,1.0,0.94), str(victim.name) + ": il colpo successivo conserva il blu normale")
	arena.queue_free()
	await tree.process_frame
	return true
