extends RefCounted

const Profiles := preload("res://scripts/FighterHitboxProfiles.gd")
const Catalog := preload("res://data/hitboxes/AttackHitboxData.gd")


static func place_probe(target: Fighter, point: Vector2) -> void:
	target.reset_fighter(point)
	target.combat.set_guarding(false)
	(target.head_hurtbox.shape as RectangleShape2D).size = Vector2(4,4)
	target.head_hurtbox.position = Vector2.ZERO
	target.head_hurtbox.disabled = false
	target.torso_hurtbox.disabled = true
	target.legs_hurtbox.disabled = true


static func run(tree: SceneTree, expect: Callable) -> bool:
	var arena := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(arena)
	for tick in 4:
		await tree.physics_frame
	arena.set_physics_process(false)
	var fighters := {}
	for f: Fighter in arena._fighters:
		f.set_physics_process(false)
		f.is_player_controlled = false
		f.opponent = null
		f.position.x = -10000
		fighters[String(f.name)] = f
	var actor: Fighter = fighters["Bue"]
	# Exercise every calibrated cell in the real node hierarchy with both facings.
	# A detached animation controller avoids triggering attack/FX callbacks here.
	var real_sprite := actor.animated_sprite
	var sample_sprite := AnimatedSprite2D.new()
	actor.add_child(sample_sprite)
	sample_sprite.position = Vector2(0,-115)
	sample_sprite.scale = Vector2(0.73,0.73)
	var frames := SpriteFrames.new()
	frames.add_frame(&"default", null)
	sample_sprite.sprite_frames = frames
	actor.animated_sprite = sample_sprite
	var cells := 0
	for source_path in Catalog.SHEETS:
		var texture := load(source_path) as Texture2D
		var source_image := texture.get_image()
		if source_image.is_compressed(): source_image.decompress()
		for region_key in Catalog.SHEETS[source_path]:
			var values: PackedStringArray = String(region_key).split(",")
			var region := Rect2(float(values[0]),float(values[1]),float(values[2]),float(values[3]))
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = region
			frames.set_frame(&"default",0,atlas)
			var spec: Array = Catalog.SHEETS[source_path][region_key]
			var alpha := source_image.get_pixel(roundi(region.position.x + spec[0]),roundi(region.position.y + spec[1])).a
			expect.call(alpha >= 0.5, "%s [%s]: centro della hitbox sulla sagoma solida" % [source_path.get_file(),region_key])
			sample_sprite.flip_h = false
			actor.combat.hitbox.scale.x = 1
			Profiles.apply(actor.combat)
			var right_center := actor.to_local(actor.combat.hitbox_shape.global_position)
			var right_size: Vector2 = actor.combat.hitbox_shape.shape.size
			sample_sprite.flip_h = true
			actor.combat.hitbox.scale.x = -1
			Profiles.apply(actor.combat)
			var left_center := actor.to_local(actor.combat.hitbox_shape.global_position)
			expect.call(left_center.is_equal_approx(Vector2(-right_center.x,right_center.y)) and actor.combat.hitbox_shape.shape.size.is_equal_approx(right_size), "%s [%s]: scala e facing specchiano il contatto" % [source_path.get_file(),region_key])
			cells += 1
	actor.animated_sprite = real_sprite
	sample_sprite.queue_free()
	expect.call(cells >= 500, "catalogo copre tutte le celle calibrate e le pose mantenute/inverse")
	# Independent contact landmarks from the visual review. A tiny hurtbox probe
	# distinguishes the visible limb from the old empty-space collision region.
	var fixtures := [
		["Mangler","standing","heavy_punch",40,Vector2(195,-180),Vector2(200,-105)],
		["Mangler","crouched","heavy_punch",11,Vector2(80,-240),Vector2(90,-440)],
		["Bue","standing","medium_punch",23,Vector2(150,-190),Vector2(150,-250)],
		["Bue","standing","medium_kick",10,Vector2(125,-180),Vector2(150,-105)],
		["Oscare","airborne","medium_kick",19,Vector2(145,-245),Vector2(140,-105)],
		["Peirolo","airborne","heavy_kick",18,Vector2(-165,-165),Vector2(110,-105)],
		["Torpe","standing","heavy_punch",17,Vector2(115,-135),Vector2(170,-240)],
		["Mileto","crouched","light_kick",17,Vector2(90,-5),Vector2(170,-80)],
		["Arianna","crouched","medium_kick",12,Vector2(150,-5),Vector2(160,-80)],
	]
	for spec in fixtures:
		var f: Fighter = fighters[spec[0]]
		var target: Fighter = fighters["Arianna"] if spec[0] != "Arianna" else fighters["Mangler"]
		for facing in [true,false]:
			f.reset_fighter(Vector2(1000,arena.FLOOR_Y-(350 if spec[1]=="airborne" else 0)))
			if f.is_facing_right != facing: f.flip_character()
			f.velocity = Vector2(0,-1 if spec[1]=="airborne" else 1)
			f.move_and_slide()
			if spec[1]=="airborne": f.change_state(Fighter.State.JUMPING)
			elif spec[1]=="crouched": f.return_to_crouch_pose()
			f.input_buffer.record_input_snapshot(0,1 if spec[1]=="crouched" else 0,[],false)
			# Reset disables collision deferred; flush it before activating the move.
			for tick in 2: await tree.physics_frame
			if f is Mangler:
				f.combat.try_attack(spec[2],FighterInputBuffer.Direction.DOWN if spec[1]=="crouched" else FighterInputBuffer.Direction.NEUTRAL)
			else:
				var method: String = "_start_"+("jump_" if spec[1]=="airborne" else ("low_" if spec[1]=="crouched" else ""))+String(spec[2]).replace("heavy","strong")
				f.call(method)
			f.animated_sprite.pause()
			f.animated_sprite.frame = spec[3]-1
			f.combat.enable_hitbox()
			var mirror := Vector2(1 if facing else -1,1)
			place_probe(target,f.global_position+spec[5]*mirror)
			for tick in 2: await tree.physics_frame
			f.combat.resolve_attack_overlap_immediately()
			expect.call(target.combat.current_health==100,"%s %s: nessun danno nella vecchia zona vuota, facing=%s" % [spec[0],spec[2],facing])
			place_probe(target,f.global_position+spec[4]*mirror)
			for tick in 2: await tree.physics_frame
			f.combat.resolve_attack_overlap_immediately()
			expect.call(target.combat.current_health<100,"%s %s: contatto sull'arto visibile, facing=%s" % [spec[0],spec[2],facing])
			f.combat.cancel_current_action()
			f.position.x = -10000
			target.reset_fighter(Vector2(-12000,arena.FLOOR_Y))
	# Explicit moving contact: the spinning leg crosses behind the character.
	var peiro: Fighter = fighters["Peirolo"]
	peiro.reset_fighter(Vector2(1000,arena.FLOOR_Y-350))
	if not peiro.is_facing_right: peiro.flip_character()
	peiro.velocity = Vector2(0,-1)
	peiro.move_and_slide()
	peiro.change_state(Fighter.State.JUMPING)
	peiro.call("_start_jump_strong_kick")
	peiro.animated_sprite.pause()
	peiro.animated_sprite.frame = 11
	var first_x := peiro.combat.hitbox_shape.position.x
	peiro.animated_sprite.frame = 17
	expect.call(first_x>100 and peiro.combat.hitbox_shape.position.x < -100,"Peirolo: frame_changed sposta la hitbox insieme alla gamba rotante")
	var tornado := AriannaTornadoProjectile.new()
	tornado.setup(fighters["Arianna"],true)
	tree.root.add_child(tornado)
	tornado.set_physics_process(false)
	var shape: RectangleShape2D = tornado.get_node("CollisionShape2D").shape
	expect.call(shape.size.is_equal_approx(AriannaTornadoProjectile.HITBOX_SIZE/6.0),"tornado appena comparso: collisione ridotta insieme allo sprite")
	tornado.tornado_sprite.scale = AriannaTornadoProjectile.SPRITE_SCALE
	tornado._update_hitbox_growth()
	expect.call(shape.size.is_equal_approx(AriannaTornadoProjectile.HITBOX_SIZE),"tornado cresciuto: ripristina la dimensione finale prevista")
	tornado.queue_free()
	for f: Fighter in arena._fighters: f.combat.cancel_current_action()
	arena.queue_free()
	await tree.process_frame
	return true
