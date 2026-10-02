extends RefCounted

const SWEEP_TIME := 42.0 / 24.0
const HOLD_TIME := 0.5
const RECOVERY_TIME := 34.0 / 24.0


static func run(tree: SceneTree, expect: Callable) -> bool:
	print("-- Roster sweep, hold, recovery and S+K")
	var movement := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(movement)
	for _tick in 4:
		await tree.physics_frame
	var fighters: Array[IdleRosterFighter] = []
	var observed: Dictionary = {}
	var attacker: Fighter
	for node in movement._fighters:
		if node is Mangler:
			attacker = node
		if not node is IdleRosterFighter:
			continue
		var fighter := node as IdleRosterFighter
		fighters.append(fighter)
		fighter.is_player_controlled = false
		observed[fighter] = {&"sweep_knockdown": [0], &"knockdown_recovery": []}
		fighter.animated_sprite.frame_changed.connect(func() -> void:
			var animation := fighter.animated_sprite.animation
			if observed[fighter].has(animation):
				observed[fighter][animation].append(fighter.animated_sprite.frame)
		)
		var folder := "peirolo" if fighter.fighter_id == &"peiro" else String(fighter.fighter_id)
		for animation in [&"sweep_knockdown", &"knockdown_recovery"]:
			var count := 42 if animation == &"sweep_knockdown" else 34
			var columns := 7 if animation == &"sweep_knockdown" else 6
			var frames := fighter.animated_sprite.sprite_frames
			var exact := frames.get_frame_count(animation) == count
			for index in frames.get_frame_count(animation):
				var texture := frames.get_frame_texture(animation, index) as AtlasTexture
				exact = exact and texture.atlas.resource_path == "res://assets/sprites/characters/%s/%s.png" % [folder, animation]
				exact = exact and texture.region == Rect2((index % columns) * 512, int(index / columns) * 512, 512, 512)
			expect.call(exact and is_equal_approx(frames.get_animation_speed(animation), 24.0)
				and not frames.get_animation_loop(animation), "%s: %s slicing, frame e 24 FPS" % [fighter.fighter_id, animation])
		expect.call(is_equal_approx(fighter.get_sweep_grounded_hold_duration(), HOLD_TIME), "%s: pausa sweep di 0.5 secondi" % fighter.fighter_id)
	expect.call(fighters.size() == 5, "sweep e recovery configurate per tutti i cinque fighter")
	var attack := attacker.character_data.get_attack(&"heavy_kick")
	var variant := attack.get_variant(&"crouched")
	# Usa il contatto della hitbox e la variante reale del calcio forte basso.
	for fighter in fighters:
		attacker.combat.begin_animation_attack(&"crouched_heavy_kick", attack, variant)
		attacker.combat._on_hitbox_area_entered(fighter.get_node("Hurtbox"))
		expect.call(fighter.combat.current_health == fighter.combat.max_health - attack.damage
			and fighter.current_state == Fighter.State.SWEEP_KNOCKDOWN
			and fighter.animated_sprite.animation == &"sweep_knockdown" and fighter.animated_sprite.frame == 0,
			"%s: contatto del calcio forte basso avvia sweep" % fighter.fighter_id)
		attacker.combat.cancel_current_action()
	await tree.create_timer(SWEEP_TIME + 0.1).timeout
	for fighter in fighters:
		expect.call(_saw_frames(observed[fighter][&"sweep_knockdown"], 42)
			and fighter.current_state == Fighter.State.SWEEP_KNOCKDOWN
			and fighter.animated_sprite.frame == 41 and not fighter.animated_sprite.is_playing(),
			"%s: tutti i 42 frame, poi posa finale" % fighter.fighter_id)
	await tree.create_timer(0.25).timeout
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.SWEEP_KNOCKDOWN and fighter.animated_sprite.frame == 41
			and not fighter.animated_sprite.is_playing(), "%s: mantiene il frame 42 durante la pausa" % fighter.fighter_id)
	await tree.create_timer(0.25).timeout
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.KNOCKDOWN_RECOVERY
			and fighter.animated_sprite.animation == &"knockdown_recovery" and not fighter.can_move,
			"%s: dopo 0.5s passa alla recovery" % fighter.fighter_id)
	await tree.create_timer(RECOVERY_TIME).timeout
	for fighter in fighters:
		expect.call(_saw_frames(observed[fighter][&"knockdown_recovery"], 34)
			and fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle" and fighter.can_move,
			"%s: tutti i 34 frame recovery e ritorno in idle" % fighter.fighter_id)
		fighter.reset_fighter(fighter.position)
	# Una guardia bassa riuscita e un colpo letale conservano le reazioni esistenti.
	attacker.set_physics_process(false)
	attacker.position = Vector2(4000.0, 600.0)
	for fighter in fighters:
		fighter.is_facing_right = true
		fighter.input_buffer.record_input_snapshot(-1, 1, [], true)
		fighter.combat.set_guarding(true)
		var result := fighter.combat.take_damage(attack.damage, attacker, 0.0, 0.0, AttackData.HitHeight.LOW, true)
		expect.call(result == FighterCombat.DamageResult.BLOCKED and fighter.current_state == Fighter.State.BLOCKING,
			"%s: parata bassa impedisce sweep" % fighter.fighter_id)
		fighter.reset_fighter(fighter.position)
		fighter.combat.set_guarding(false)
		result = fighter.combat.take_damage(fighter.combat.max_health, null, 0.0, 0.0, AttackData.HitHeight.LOW, true)
		expect.call(result == FighterCombat.DamageResult.KNOCKOUT and fighter.animated_sprite.animation == &"ko",
			"%s: un calcio letale avvia KO invece di recovery" % fighter.fighter_id)
		fighter.reset_fighter(fighter.position)
		fighter.is_player_controlled = true
	attacker.set_physics_process(true)
	for order in [[KEY_S, KEY_K], [KEY_K, KEY_S]]:
		_press_chord(movement, order)
		for fighter in fighters:
			expect.call(fighter.current_state == Fighter.State.SWEEP_KNOCKDOWN and fighter.combat.current_health == fighter.combat.max_health,
				"%s: shortcut %s prova sweep senza danno" % [fighter.fighter_id, order])
		expect.call(not Input.is_action_pressed("p1_crouch") and not Input.is_action_pressed("p1_light_kick"), "S+K consuma gli input crouch e kick")
		var generation := fighters[0].combat.action_generation
		var echo := InputEventKey.new()
		echo.keycode = KEY_K
		echo.pressed = true
		echo.echo = true
		movement._unhandled_input(echo)
		expect.call(generation == fighters[0].combat.action_generation, "mantenere S+K non riavvia la sequenza")
		await tree.create_timer(SWEEP_TIME + HOLD_TIME + RECOVERY_TIME + 0.15).timeout
		for fighter in fighters:
			expect.call(fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle" and fighter.can_move,
				"%s: preview completa torna in idle" % fighter.fighter_id)
	# Il reset durante la pausa e il KO durante sweep invalidano le vecchie attese.
	movement._preview_sweep()
	await tree.create_timer(SWEEP_TIME + 0.1).timeout
	for fighter in fighters:
		fighter.reset_fighter(fighter.position)
	await tree.create_timer(HOLD_TIME + RECOVERY_TIME + 0.1).timeout
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.IDLE and fighter.can_move, "%s: reset nella pausa impedisce recovery tardive" % fighter.fighter_id)
	movement._preview_sweep()
	for fighter in fighters:
		fighter.combat.take_damage(fighter.combat.max_health, null)
	await tree.create_timer(SWEEP_TIME + HOLD_TIME + RECOVERY_TIME + 0.1).timeout
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.KNOCKED_DOWN and fighter.animated_sprite.animation == &"ko"
			and fighter.combat.current_health == 0, "%s: KO interrompe sweep senza rialzata tardiva" % fighter.fighter_id)
		fighter.reset_fighter(fighter.position)
	# Passare alle altre preview invalida anche i timer della prova sweep.
	movement._preview_sweep()
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	movement._unhandled_input(tab)
	movement._physics_process(1.0 / 60.0)
	await tree.create_timer(SWEEP_TIME + HOLD_TIME + RECOVERY_TIME + 0.1).timeout
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.BLOCKING, "%s: Tab interrompe sweep senza recovery tardiva" % fighter.fighter_id)
	movement._preview_sweep()
	expect.call(movement._block_mode == 0 and not movement._dummy_opponent.combat.is_attacking, "sweep disattiva la guardia forzata")
	movement._preview_death()
	await tree.create_timer(SWEEP_TIME + HOLD_TIME + RECOVERY_TIME + 0.1).timeout
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle",
			"%s: D sostituisce sweep e non subisce recovery tardive" % fighter.fighter_id)
	for node in movement._fighters:
		(node as Fighter).combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true


static func _saw_frames(observed: Array, count: int) -> bool:
	for index in count:
		if not observed.has(index):
			return false
	return true


static func _press_chord(movement: Node, order: Array) -> void:
	for key in [KEY_S, KEY_K]:
		var release := InputEventKey.new()
		release.keycode = key
		movement._unhandled_input(release)
	Input.action_press("p1_crouch")
	Input.action_press("p1_light_kick")
	for key in order:
		var press := InputEventKey.new()
		press.keycode = key
		press.pressed = true
		movement._unhandled_input(press)
