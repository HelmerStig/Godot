extends RefCounted

const Helpers := preload("res://tests/cases/oscare_cigarette_special.gd")
const Projectile := preload("res://scripts/MiletoGuitarProjectile.gd")

static func motion(actor: Fighter, facing: bool, button: StringName, mode: int) -> void:
	var back := -1 if facing else 1
	actor.is_facing_right = facing
	actor.animated_sprite.flip_h = not facing
	actor.input_buffer.record_input_snapshot(0,1,[],facing)
	if mode != 2:
		actor.input_buffer.record_input_snapshot(back,1,[],facing)
	actor.input_buffer.record_input_snapshot(back,1 if mode == 1 else 0,[button],facing)

static func run(tree: SceneTree, expect: Callable) -> bool:
	var arena := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(arena)
	for tick in 4:
		await tree.physics_frame
	arena.set_physics_process(false)
	var actor: Mileto
	var target: Fighter
	for f: Fighter in arena._fighters:
		f.set_physics_process(false)
		f.is_player_controlled = false
		f.position.x = -10000
		if f is Mileto:
			actor = f
		elif f is Oscare:
			target = f
	var frames := actor.animated_sprite.sprite_frames
	for spec in [[actor.GUITAR_WINDUP_ANIMATION,45,actor.GUITAR_WINDUP_SHEET],[actor.GUITAR_THROW_ANIMATION,23,actor.GUITAR_THROW_SHEET]]:
		var valid: bool = frames.get_frame_count(spec[0]) == spec[1]
		for index in int(spec[1]):
			var texture := frames.get_frame_texture(spec[0],index) as AtlasTexture
			valid = valid and texture.atlas == spec[2] and texture.region == Rect2(index%8*512,index/8*512,512,512)
		var expected_fps := 100.0 if spec[0] == actor.GUITAR_WINDUP_ANIMATION else 60.0
		expect.call(valid and frames.get_animation_speed(spec[0]) == expected_fps and not frames.get_animation_loop(spec[0]),"Guitar: atlas esatto e FPS " + str(spec[0]))
	for facing in [true,false]:
		for spec in [[&"light_punch",&"light",600.0],[&"medium_punch",&"medium",800.0],[&"heavy_punch",&"heavy",1000.0]]:
			for mode in 3:
				await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
				motion(actor,facing,spec[0],mode)
				actor._physics_process(1.0/60)
				expect.call(actor.guitar_special_active and not actor.shoulder_active and actor.guitar_strength == spec[1],"Guitar: QCB %s facing=%s tolleranza=%d" % [spec[0],facing,mode])
				expect.call(tree.get_nodes_in_group("mileto_guitar_projectile").is_empty(),"Guitar: nessun proiettile nel caricamento")
				actor.animated_sprite.frame = 10
				expect.call(not actor._guitar_materialize_audio.playing,"Guitar: silenzio prima della materializzazione")
				actor.animated_sprite.frame = 11
				expect.call(actor._guitar_materialize_audio.playing and actor._guitar_materialize_audio.stream == load("res://assets/sounds/sfx/chitarra-electricity.wav"),"Guitar: elettricita al frame 12")
				actor._on_animation_finished()
				actor.animated_sprite.pause()
				actor.animated_sprite.frame = 19
				expect.call(tree.get_nodes_in_group("mileto_guitar_projectile").is_empty(),"Guitar: nessun proiettile prima del frame 21")
				actor.animated_sprite.frame = 20
				actor._on_animation_frame_changed()
				var projectiles := tree.get_nodes_in_group("mileto_guitar_projectile")
				expect.call(projectiles.size() == 1,"Guitar: un solo rilascio al frame 21")
				if projectiles.size() != 1:
					continue
				var p = projectiles[0]
				expect.call(not actor._guitar_materialize_audio.playing and p._throw_audio.playing and p._throw_audio.stream == load("res://assets/sounds/sfx/boomerang.wav"),"Guitar: boomerang al rilascio interrompe elettricita")
				expect.call(p.sprite.scale == Vector2.ONE * 2.0,"Guitar: proiettile ingrandito del 14 percento")
				p.set_physics_process(false)
				p.sprite.pause()
				var direction := 1.0 if facing else -1.0
				expect.call(p.movement_speed == spec[2] and p.position.is_equal_approx(actor.position+Vector2(direction*118,-170)),"Guitar: velocita e punto di rilascio specchiati")
				var atlas_valid := true
				for index in 25:
					var tex := p.sprite.sprite_frames.get_frame_texture(&"fly",index) as AtlasTexture
					atlas_valid = atlas_valid and tex.region == Rect2(index%5*256,index/5*256,256,256)
				expect.call(atlas_valid and p.sprite.sprite_frames.get_animation_speed(&"fly") == 100 and p.sprite.sprite_frames.get_animation_loop(&"fly"),"Guitar: 25 frame proiettile 100 FPS in loop")
				var before: Vector2 = p.position
				p._physics_process(.05)
				expect.call(p.position.is_equal_approx(before+Vector2(direction*spec[2]*.05,0)) and p.trails[0].get_point_count() >= 2,"Guitar: movimento e scia nello spazio mondo")
				var wide: Vector2 = p.sweep.shape.size
				p.sprite.frame = 13
				expect.call(p.sweep.shape.size.x < wide.x*.4,"Guitar: collisione segue rotazione dello sprite")
				actor._on_animation_finished()
				expect.call(not actor.guitar_special_active and actor.current_state == Fighter.State.IDLE and not p.is_queued_for_deletion(),"Guitar: fine lancio torna idle senza rimuovere proiettile")
	for facing in [true,false]:
		for scenario in ["hit","block","crouched_hit","crouched_block","knockout","above_crouch","behind"]:
			await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
			var direction := 1.0 if facing else -1.0
			target.position.x = actor.position.x + direction*350
			target.is_facing_right = not facing
			var crouched: bool = scenario.begins_with("crouched") or scenario == "above_crouch"
			var guard: bool = "block" in scenario
			target.input_buffer.record_input_snapshot(int(direction) if guard else 0,1 if crouched else 0,[],not facing)
			if crouched:
				target.return_to_crouch_pose()
			target.combat.set_guarding(guard)
			if scenario == "knockout":
				target.combat.current_health = 5
			for tick in 2:
				await tree.physics_frame
			var p := Projectile.new()
			p.setup(actor,facing,&"heavy")
			arena.add_child(p)
			p.set_physics_process(false)
			p.sprite.pause()
			p.position = actor.position + Vector2(direction*(600 if scenario == "behind" else 118),-260 if scenario == "above_crouch" else -170)
			p._physics_process(.4)
			var miss: bool = scenario in ["above_crouch","behind"]
			expect.call(p._throw_audio.playing == miss,"Guitar: contatto interrompe boomerang, mancato contatto lo mantiene")
			var hit_audio := tree.get_nodes_in_group("mileto_guitar_hit_audio")
			expect.call(hit_audio.size() == (0 if guard or miss else 1),"Guitar: hit calcio potente solo a segno o KO")
			if not guard and not miss:
				expect.call(hit_audio[0].playing and hit_audio[0].stream == load("res://sound-libraries/body_hit_large_76.wav"),"Guitar: suono condiviso hit calcio potente")
			var hp := 100 if guard or miss else (0 if scenario == "knockout" else 85)
			expect.call(target.combat.current_health == hp and p.has_hit == not miss,"Guitar: collisione reale e danno " + scenario + str(facing))
			if not miss:
				var expected: StringName = (&"block_low" if crouched else &"block_mid") if guard else (&"hurt_crouched" if crouched else &"hurt_high")
				if scenario == "knockout":
					expected = &"ko"
				expect.call(target.animated_sprite.animation == expected,"Guitar: reazione " + scenario)
				expect.call(tree.get_nodes_in_group("mileto_guitar_explosion").size() == 1,"Guitar: esplosione all'impatto")
				p._physics_process(.4)
				expect.call(target.combat.current_health == hp,"Guitar: danno una sola volta")
				expect.call(tree.get_nodes_in_group("mileto_guitar_hit_audio").size() == hit_audio.size(),"Guitar: nessun doppio suono hit")
				if not guard:
					for tick in 2:
						await tree.physics_frame
					expect.call(not is_instance_valid(p) and hit_audio[0].playing,"Guitar: hit continua dopo la scomparsa del proiettile")
			else:
				p.elapsed = p.MAX_LIFETIME
				p._physics_process(.01)
				expect.call(p.is_queued_for_deletion(),"Guitar: scadenza o contatto rimuovono il proiettile")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor._start_guitar_special()
	await tree.create_timer(.95).timeout
	expect.call(actor.current_state == Fighter.State.IDLE and not actor.guitar_special_active,"Guitar: sequenza reale 45+23 frame termina senza timer di attacco anticipato")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor._start_guitar_special()
	actor.animated_sprite.frame = 11
	actor.combat.take_damage(1,target,.3,.1,AttackData.HitHeight.MID)
	actor._on_animation_finished()
	expect.call(not actor.guitar_special_active and tree.get_nodes_in_group("mileto_guitar_projectile").is_empty() and actor.current_state == Fighter.State.HIT,"Guitar: hurt interrompe prima del lancio")
	expect.call(not actor._guitar_materialize_audio.playing,"Guitar: hurt interrompe elettricita")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	Helpers.motion(actor,true,&"light_punch")
	expect.call(actor._try_start_character_special() and actor.shoulder_active and not actor.guitar_special_active,"Guitar: QCF mantiene la special 1")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	motion(actor,true,&"light_punch",0)
	actor.controls_enabled = false
	expect.call(not actor._try_start_character_special(),"Guitar: controlli disabilitati impediscono attivazione")
	actor.controls_enabled = true
	actor.position.y -= 300
	actor.velocity.y = -1
	actor.move_and_slide()
	expect.call(not actor._try_start_character_special(),"Guitar: solo a terra")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	expect.call(tree.get_nodes_in_group("mileto_guitar_projectile").is_empty() and tree.get_nodes_in_group("mileto_guitar_trail").is_empty() and tree.get_nodes_in_group("mileto_guitar_explosion").is_empty(),"Guitar: reset elimina proiettili, scie ed esplosioni")
	expect.call(tree.get_nodes_in_group("mileto_guitar_audio").is_empty() and not actor._guitar_materialize_audio.playing,"Guitar: reset ferma e rimuove tutti i suoni")
	arena.queue_free()
	await tree.process_frame
	return true
