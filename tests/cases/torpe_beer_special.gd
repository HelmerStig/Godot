extends RefCounted

const Helpers := preload("res://tests/cases/oscare_cigarette_special.gd")
const Projectile := preload("res://scripts/TorpeBeerBottleProjectile.gd")


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
	expect.call(actor != null, "Torpe: scena reale con controller Special 1")
	if actor == null:
		arena.queue_free()
		return false
	var frames := actor.animated_sprite.sprite_frames
	var animation := actor.BEER_ANIMATION
	expect.call(frames.get_frame_count(animation) == 64 and frames.get_animation_speed(animation) == 64 and not frames.get_animation_loop(animation), "Torpe: 64 frame, 64 FPS, un secondo non loop")
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/characters/torpe/special_1_beer_throw_candidate.autosprite.json"))
	var valid := true
	for index in 64:
		var texture := frames.get_frame_texture(animation,index) as AtlasTexture
		var source_index: int = int(metadata.localSequence.sourceFrames1Based[index]) - 1
		var region := Rect2(source_index % 8 * 512, source_index / 8 * 512, 512, 512)
		if index in [37,38]:
			region.position.y += 40
			region.size.y -= 40
			valid = valid and texture.margin == Rect2(0,40,0,40)
		valid = valid and texture.atlas.resource_path.ends_with("special_1_beer_throw_candidate.png") and texture.region == region and texture.get_size() == Vector2(512,512)
	expect.call(valid, "Torpe: atlas esatto e ritaglio del doppione senza spostare il corpo")
	for facing in [true,false]:
		for spec in [[&"light_punch",&"light",520.0], [&"medium_punch",&"medium",720.0], [&"heavy_punch",&"heavy",920.0]]:
			for mode in 3:
				await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
				Helpers.motion(actor,facing,spec[0],mode)
				actor._physics_process(1.0/60)
				expect.call(actor.beer_special_active and actor.beer_strength == spec[1] and actor.combat.is_attacking and actor.combat.hitbox_shape.disabled, "Torpe: QCF %s facing=%s tolleranza=%d" % [spec[0],facing,mode])
				actor.animated_sprite.pause()
				actor.animated_sprite.frame = 36
				expect.call(not actor.beer_spawned and tree.get_nodes_in_group("torpe_beer_projectile").is_empty(), "Torpe: nessuna bottiglia prima dell'apertura della mano")
				actor.animated_sprite.frame = 37
				var bottles := tree.get_nodes_in_group("torpe_beer_projectile")
				expect.call(bottles.size() == 1, "Torpe: singolo rilascio al frame 38")
				if bottles.size() != 1:
					continue
				var bottle = bottles[0]
				bottle.set_physics_process(false)
				expect.call(bottle.flight_audio.stream == load("res://assets/sounds/sfx/sibilo.wav") and bottle.flight_audio.playing, "Birra: sibilo avviato al rilascio")
				var direction := 1.0 if facing else -1.0
				expect.call(bottle.velocity.x == direction * spec[2] and bottle.velocity.y < 0 and signf(bottle.angular_velocity) == direction, "Birra: forza e rotazione coerenti con pugno/facing")
				var visible: Vector2 = bottle.sprite.texture.get_size() * bottle.sprite.scale
				expect.call(is_equal_approx(visible.y, 81.6 * absf(actor.animated_sprite.global_scale.y)) and visible.x < 25 and visible.y < 85, "Birra: bottiglia ingrandita del 20%, senza margini trasparenti")
				var hand := Vector2(134 * direction,-194)
				var expected := actor.animated_sprite.to_global(hand + actor.animated_sprite.offset) + Vector2(direction * bottle.visible_length * .45,0)
				expect.call(bottle.global_position.is_equal_approx(expected), "Birra: nasce dalle dita anche specchiata")
				actor.animated_sprite.frame = 38
				actor.animated_sprite.frame = 37
				expect.call(tree.get_nodes_in_group("torpe_beer_projectile").size() == 1, "Torpe: callback ripetute non duplicano il proiettile")
				var before: Vector2 = bottle.global_position
				var before_rotation: float = bottle.global_rotation
				bottle._physics_process(.1)
				expect.call(is_equal_approx(bottle.global_position.x - before.x, direction * spec[2] * .1) and is_equal_approx(bottle.global_position.y - before.y,-12) and not is_equal_approx(before_rotation,bottle.global_rotation), "Birra: volo ad arco e rotazione indipendente dallo sprite")
				expect.call(bottle.trail.points.size() == 2 and bottle.trail.to_global(bottle.trail.points[0]).is_equal_approx(before) and bottle.trail.to_global(bottle.trail.points[1]).is_equal_approx(bottle.global_position), "Birra: scia segue il percorso mondiale senza ruotare con la bottiglia")
				actor._on_animation_finished()
				expect.call(not actor.beer_special_active and actor.current_state == Fighter.State.IDLE, "Torpe: fine lancio torna idle")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor._start_beer_special()
	await tree.create_timer(1.2).timeout
	expect.call(actor.current_state == Fighter.State.IDLE and not actor.beer_special_active and tree.get_nodes_in_group("torpe_beer_projectile").size() == 1, "Torpe: playback reale completo, rilascio singolo e recupero")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor._start_beer_special()
	actor.animated_sprite.pause()
	actor.combat.take_damage(1,target,.3,.1,AttackData.HitHeight.MID)
	actor.animated_sprite.frame = 37
	expect.call(not actor.beer_special_active and tree.get_nodes_in_group("torpe_beer_projectile").is_empty(), "Torpe: interruzione prima del rilascio impedisce il lancio tardivo")
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	actor.controls_enabled = false
	Helpers.motion(actor,true,&"light_punch")
	expect.call(not actor._try_start_character_special(), "Torpe: nessun lancio a round finito")
	actor.controls_enabled = true
	actor.position.y -= 300
	actor.velocity.y = -1
	actor.move_and_slide()
	expect.call(not actor._try_start_character_special(), "Torpe: Special solo a terra")
	# Real shape sweep, both spin directions and a complete hurtbox crossed in one step.
	for facing in [true,false]:
		for scenario in ["hit","block","crouched_hit","crouched_block","above_crouch","knockout","ground"]:
			await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
			var direction := 1.0 if facing else -1.0
			target.position.x = actor.position.x + 200 * direction
			target.is_facing_right = not facing
			target.animated_sprite.flip_h = facing
			var crouched: bool = scenario in ["crouched_hit","crouched_block","above_crouch"]
			var guarded: bool = scenario in ["block","crouched_block"]
			var miss: bool = scenario in ["above_crouch","ground"]
			if crouched:
				target.input_buffer.record_input_snapshot(int(direction) if guarded else 0,1,[],not facing)
				target.return_to_crouch_pose()
			else:
				target.input_buffer.record_input_snapshot(int(direction) if guarded else 0,0,[],not facing)
			target.combat.set_guarding(guarded)
			if scenario == "knockout":
				target.combat.current_health = 5
			for tick in 2:
				await tree.physics_frame
			var bottle := Projectile.new()
			bottle.setup(actor,facing,&"heavy")
			arena.add_child(bottle)
			bottle.set_physics_process(false)
			bottle.position = actor.position + Vector2(50 * direction,-(250 if scenario == "above_crouch" else 170))
			if scenario == "ground":
				bottle.position = Vector2(actor.position.x,arena.FLOOR_Y-80)
				bottle.velocity = Vector2(direction*100,600)
			bottle._physics_process(.3)
			var expected_health := 100 if guarded or miss else (0 if scenario == "knockout" else 90)
			expect.call(target.combat.current_health == expected_health and bottle.has_hit == (scenario != "above_crouch"), "Birra: sweep ruotato, collisione e danno %s facing=%s" % [scenario,facing])
			var effects := tree.get_nodes_in_group("torpe_beer_shatter")
			expect.call(effects.size() == (0 if scenario == "above_crouch" else 1), "Birra: una sola esplosione anche se parata o sul terreno")
			if not effects.is_empty():
				var audio := tree.get_nodes_in_group("torpe_beer_break_audio")
				expect.call(not bottle.flight_audio.playing and audio.size() == 1 and audio[0].playing and audio[0].stream == load("res://assets/sounds/sfx/bottiglia-rotta.wav") and audio[0].get_parent() == arena, "Birra: impatto ferma sibilo e avvia una rottura indipendente dal proiettile")
				var effect = effects[0]
				var shards := effect.get_children().filter(func(child): return child is RigidBody2D)
				var correct: bool = shards.size() == 12
				for shard in shards:
					var polygon := shard.get_child(0) as Polygon2D
					correct = correct and shard.collision_mask == 1 and shard.collision_layer == 0 and polygon.texture == Projectile.TEXTURE and polygon.uv.size() == 3
				expect.call(correct and effect.get_node("BeerSpray").emitting, "Birra: dodici frammenti della texture con fisica e spruzzo di birra")
				if scenario == "ground":
					expect.call(effect.global_position.y < arena.FLOOR_Y-5, "Birra: frantumazione sopra il terreno")
			bottle._physics_process(.1)
			expect.call(target.combat.current_health == expected_health and tree.get_nodes_in_group("torpe_beer_shatter").size() == effects.size(), "Birra: nessun danno/esplosione duplicata")
			if not miss and not guarded and scenario != "knockout":
				expect.call(target.animated_sprite.animation == (&"hurt_crouched" if crouched else &"hurt_high"), "Birra: reazione coerente con la postura del bersaglio")
	# Shards must actually move and expire; round reset removes owned objects.
	await Helpers.settle(tree,actor,target,arena.FLOOR_Y)
	var bottle := Projectile.new()
	bottle.setup(actor,true)
	arena.add_child(bottle)
	bottle.set_physics_process(false)
	bottle.position = Vector2(1300,450)
	bottle._shatter()
	var effect = tree.get_nodes_in_group("torpe_beer_shatter")[0]
	var shard = effect.get_child(0)
	var before: Vector2 = shard.global_position
	await tree.create_timer(.2).timeout
	expect.call(not shard.global_position.is_equal_approx(before), "Birra: i frammenti si muovono nella fisica reale")
	expect.call(tree.get_nodes_in_group("torpe_beer_trail").is_empty(), "Birra: scia svanisce dopo la frantumazione")
	await tree.create_timer(1.4).timeout
	expect.call(tree.get_nodes_in_group("torpe_beer_shatter").is_empty(), "Birra: esplosione decorativa eliminata a fine effetto")
	actor._start_beer_special()
	actor.animated_sprite.frame = 37
	actor.reset_fighter(Vector2(1000,arena.FLOOR_Y))
	for tick in 2:
		await tree.physics_frame
	expect.call(tree.get_nodes_in_group("torpe_beer_projectile").is_empty() and tree.get_nodes_in_group("torpe_beer_shatter").is_empty() and tree.get_nodes_in_group("torpe_beer_trail").is_empty() and tree.get_nodes_in_group("torpe_beer_break_audio").is_empty() and not actor.beer_special_active, "Torpe: reset elimina proiettile, scia, suoni ed effetti senza danni tardivi")
	arena.queue_free()
	await tree.process_frame
	await tree.process_frame
	return true
