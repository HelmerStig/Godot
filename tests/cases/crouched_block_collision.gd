extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	for character in ["Arianna", "Mangler", "Bue", "Peirolo", "Oscare", "Torpe", "Mileto"]:
		var fighter := (load("res://scenes/%s.tscn" % character) as PackedScene).instantiate() as Fighter
		tree.root.add_child(fighter)
		fighter.set_physics_process(false)
		fighter.is_player_controlled = false
		await tree.process_frame
		for height in [AttackData.HitHeight.HIGH, AttackData.HitHeight.MID, AttackData.HitHeight.LOW]:
			fighter.reset_fighter(Vector2.ZERO)
			fighter.change_state(Fighter.State.CROUCHING)
			fighter.animated_sprite.frame = fighter.animated_sprite.sprite_frames.get_frame_count(&"crouch") - 1
			fighter.animated_sprite.pause()
			fighter.update_collision_profile()
			var shapes := [fighter.collision_shape, fighter.head_hurtbox, fighter.torso_hurtbox, fighter.legs_hurtbox]
			var profiles: Array = []
			for shape in shapes:
				profiles.append([shape.position, (shape.shape as RectangleShape2D).size])
			fighter.start_block_reaction(height, true)
			expect.call(_matches(shapes, profiles), "%s: parata %s conserva corpo e hurtbox accovacciati" % [character, height])
			fighter.start_block_reaction(height, false)
			expect.call(_matches(shapes, profiles), "%s: colpo successivo conserva il profilo basso" % character)
			fighter.start_block_recovery()
			expect.call(_matches(shapes, profiles), "%s: recovery della parata conserva il profilo basso" % character)
			fighter.change_state(Fighter.State.IDLE)
			expect.call(fighter.get_crouch_progress() == 0.0 and (fighter.collision_shape.shape as RectangleShape2D).size == Fighter.STANDING_COLLISION_SIZE, "%s: idle ripristina il profilo in piedi" % character)
			fighter.start_block_reaction(height, false)
			expect.call(fighter.get_crouch_progress() == 0.0, "%s: una nuova parata in piedi non eredita il crouch" % character)
		fighter.reset_fighter(Vector2.ZERO)
		expect.call(fighter.get_crouch_progress() == 0.0, character + ": reset ripristina collisioni in piedi")
		fighter.queue_free()
		await tree.process_frame
	return true


static func _matches(shapes: Array, profiles: Array) -> bool:
	for index in shapes.size():
		if shapes[index].position != profiles[index][0] or (shapes[index].shape as RectangleShape2D).size != profiles[index][1]:
			return false
	return true
