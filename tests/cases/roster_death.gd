extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	print("-- Roster death and F2 preview")
	var movement := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(movement)
	for _tick in 4:
		await tree.physics_frame
	var fighters: Array[IdleRosterFighter] = []
	var observed: Dictionary = {}
	for node in movement._fighters:
		if not node is IdleRosterFighter:
			continue
		var fighter := node as IdleRosterFighter
		fighters.append(fighter)
		observed[fighter] = [0]
		fighter.animated_sprite.frame_changed.connect(func() -> void:
			if fighter.animated_sprite.animation == &"ko":
				observed[fighter].append(fighter.animated_sprite.frame)
		)
		var frames := fighter.animated_sprite.sprite_frames
		var folder := "peirolo" if fighter.fighter_id == &"peiro" else String(fighter.fighter_id)
		var exact := true
		for index in frames.get_frame_count(&"ko"):
			var texture := frames.get_frame_texture(&"ko", index) as AtlasTexture
			exact = exact and texture.atlas.resource_path == "res://assets/sprites/characters/%s/death.png" % folder
			exact = exact and texture.region == Rect2((index % 7) * 512, int(index / 7) * 512, 512, 512)
		expect.call(frames.get_frame_count(&"ko") == 49 and exact
			and is_equal_approx(frames.get_animation_speed(&"ko"), 24.0) and not frames.get_animation_loop(&"ko"),
			"%s: death 1-49, atlas 7x7, 24 FPS senza loop" % fighter.fighter_id)
		fighter.combat.set_guarding(false)
		var result := fighter.combat.take_damage(fighter.combat.max_health, null, 0.0, 0.0,
			AttackData.HitHeight.HIGH, false, 0, 11, false, true)
		expect.call(result == FighterCombat.DamageResult.KNOCKOUT and fighter.combat.current_health == 0
			and fighter.current_state == Fighter.State.KNOCKED_DOWN and fighter.animated_sprite.animation == &"ko"
			and fighter.animated_sprite.frame == 0 and not fighter.can_move,
			"%s: vita zero avvia death dal primo frame anche con ko_start_frame=11" % fighter.fighter_id)
	expect.call(fighters.size() == 5, "death è configurata per tutti i cinque fighter richiesti")
	await tree.create_timer(2.2).timeout
	for fighter in fighters:
		expect.call(_saw_all_frames(observed[fighter]) and fighter.animated_sprite.frame == 48
			and not fighter.animated_sprite.is_playing() and fighter.current_state == Fighter.State.KNOCKED_DOWN,
			"%s: KO riproduce tutti i frame e mantiene il 49" % fighter.fighter_id)
		fighter.change_state(Fighter.State.KNOCKED_DOWN)
	await tree.create_timer(0.15).timeout
	for fighter in fighters:
		expect.call(fighter.animated_sprite.frame == 48 and not fighter.animated_sprite.is_playing(),
			"%s: aggiornare lo stato KO non riavvia la posa finale" % fighter.fighter_id)
		fighter.reset_fighter(fighter.position)
		expect.call(fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle"
			and fighter.combat.current_health == fighter.combat.max_health, "%s: reset esce dal KO" % fighter.fighter_id)
		observed[fighter] = [0]
	var extra_fighters: Array[Fighter] = []
	for node in movement._fighters:
		if node is Arianna or node is Mangler:
			var fighter := node as Fighter
			extra_fighters.append(fighter)
			observed[fighter] = [0]
			fighter.animated_sprite.frame_changed.connect(func() -> void:
				if fighter.animated_sprite.animation == &"ko":
					observed[fighter].append(fighter.animated_sprite.frame)
			)
	expect.call(extra_fighters.size() == 2, "la scena F2 include Arianna e Mangler")
	var death_key := InputEventKey.new()
	death_key.keycode = KEY_D
	death_key.pressed = true
	Input.action_press("p1_move_right")
	movement._unhandled_input(death_key)
	expect.call(not Input.is_action_pressed("p1_move_right"), "D nella scena F2 non attiva il movimento verso destra")
	var preview_duration := 2.2
	for fighter in extra_fighters:
		preview_duration = maxf(preview_duration, fighter.get_animation_duration(&"ko") + 0.15)
		expect.call(fighter.current_state == Fighter.State.KNOCKED_DOWN and fighter.animated_sprite.animation == &"ko"
			and fighter.animated_sprite.frame == 0 and fighter.combat.current_health == fighter.combat.max_health,
			"%s: D avvia anche il KO originale senza danno" % fighter.name)
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.KNOCKED_DOWN and fighter.animated_sprite.animation == &"ko"
			and fighter.combat.current_health == fighter.combat.max_health, "%s: D avvia preview senza danno" % fighter.fighter_id)
	await tree.create_timer(preview_duration).timeout
	for fighter in extra_fighters:
		expect.call(_saw_all_frames(observed[fighter], fighter.animated_sprite.sprite_frames.get_frame_count(&"ko"))
			and fighter.current_state == Fighter.State.IDLE and fighter.animated_sprite.animation == &"idle" and fighter.can_move,
			"%s: mostra tutto il KO e ritorna in idle" % fighter.name)
	for fighter in fighters:
		expect.call(_saw_all_frames(observed[fighter]) and fighter.current_state == Fighter.State.IDLE
			and fighter.animated_sprite.animation == &"idle" and fighter.can_move,
			"%s: preview completa 49 frame in circa 2 secondi e torna in idle" % fighter.fighter_id)
	expect.call(movement._death_previews.is_empty(), "fine preview rimuove i callback temporanei")
	movement._unhandled_input(death_key)
	await tree.create_timer(0.1).timeout
	movement._unhandled_input(death_key)
	expect.call(movement._death_previews.size() == 7, "D ripetuto riavvia le sette preview senza duplicare i callback")
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	movement._unhandled_input(tab)
	movement._physics_process(1.0 / 60.0)
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.BLOCKING and fighter.animated_sprite.animation == &"block_high",
			"%s: Tab interrompe death e avvia la guardia" % fighter.fighter_id)
	movement._unhandled_input(death_key)
	expect.call(movement._block_mode == 0 and not movement._dummy_opponent.combat.is_attacking,
		"D disattiva la guardia forzata prima della preview")
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.KNOCKED_DOWN and fighter.animated_sprite.animation == &"ko",
			"%s: death sostituisce la guardia" % fighter.fighter_id)
	var reset_fighter := fighters[0]
	reset_fighter.reset_fighter(reset_fighter.position)
	await tree.process_frame
	await tree.process_frame
	expect.call(not movement._death_previews.has(reset_fighter) and reset_fighter.is_player_controlled
		and reset_fighter.controls_enabled and reset_fighter.current_state == Fighter.State.IDLE,
		"reset durante death rimuove la preview e conserva i controlli")
	movement._preview_hurt(AttackData.HitHeight.HIGH)
	expect.call(movement._death_previews.is_empty(), "hurt interrompe le preview death")
	for fighter in fighters:
		expect.call(fighter.current_state == Fighter.State.HIT and fighter.animated_sprite.animation == &"hurt_high",
			"%s: hurt sostituisce death senza ripristini tardivi" % fighter.fighter_id)
	for node in movement._fighters:
		(node as Fighter).combat.cancel_current_action()
	movement.queue_free()
	await tree.process_frame
	return true


static func _saw_all_frames(observed: Array, frame_count := 49) -> bool:
	for index in frame_count:
		if not observed.has(index):
			return false
	return true
