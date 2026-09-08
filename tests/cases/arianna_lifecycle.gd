extends RefCounted

## Verifica il contratto pubblico delle mosse, oltre agli atlas della suite storica.
static func run(tree: SceneTree, expect: Callable) -> bool:
	print("-- Ciclo delle mosse di Arianna")
	var arena := (load("res://scenes/MainArena.tscn") as PackedScene).instantiate() as MainArena
	tree.root.add_child(arena)
	await tree.create_timer(3.1).timeout
	arena.set_process(false)
	var arianna := arena.player1 as Arianna
	var opponent := arena.player2
	arianna.set_physics_process(false)
	opponent.set_physics_process(false)
	var events := {"started": [], "finished": 0, "cancelled": 0, "states": []}
	arianna.attack_started.connect(func(attack_name: StringName): events.started.append(attack_name))
	arianna.attack_finished.connect(func(): events.finished += 1)
	arianna.attack_cancelled.connect(func(): events.cancelled += 1)
	arianna.state_changed.connect(func(_previous: int, current: int): events.states.append(current))
	var moves := {
		"_start_light_punch": "light_punch_active",
		"_start_low_light_punch": "low_light_punch_active",
		"_start_medium_punch": "medium_punch_active",
		"_start_low_medium_punch": "low_medium_punch_active",
		"_start_strong_punch": "strong_punch_active",
		"_start_crouched_strong_punch": "crouched_strong_punch_active",
		"_start_light_kick": "light_kick_active",
		"_start_low_light_kick": "low_light_kick_active",
		"_start_medium_kick": "medium_kick_active",
		"_start_low_medium_kick": "low_medium_kick_active",
		"_start_strong_kick": "strong_kick_active",
		"_start_low_strong_kick": "low_strong_kick_active",
		"_start_jump_light_punch": "jump_light_punch_active",
		"_start_jump_medium_punch": "jump_medium_punch_active",
		"_start_jump_strong_punch": "jump_strong_punch_active",
		"_start_jump_light_kick": "jump_light_kick_active",
		"_start_jump_medium_kick": "jump_medium_kick_active",
		"_start_jump_strong_kick": "jump_strong_kick_active",
		"_start_baseball_special": "baseball_special_active",
		"_start_whistle_special": "whistle_special_active",
		"_start_points_forward_super": "points_forward_super_active",
	}
	for method in moves:
		arianna.reset_fighter(Vector2(800.0, MainArena.FLOOR_Y))
		opponent.reset_fighter(Vector2(1400.0, MainArena.FLOOR_Y))
		opponent.controls_enabled = true
		opponent.can_move = true
		arianna.combat.set_guarding(true)
		var starts_before: int = events.started.size()
		var finishes_before: int = events.finished
		var cancels_before: int = events.cancelled
		arianna.call(method)
		expect.call(
			events.started.size() == starts_before + 1
			and arianna.combat.is_attacking and not arianna.combat.is_blocking
			and arianna.current_state == Fighter.State.ATTACKING and not arianna.can_move
			and bool(arianna.get(moves[method])),
			"%s: avvio unico, stato ATTACKING e guardia disattivata" % method
		)
		var generation := arianna.combat.action_generation
		arianna.combat.cancel_current_action()
		arianna.combat.cancel_current_action()
		# Simula notifiche tardive della vecchia animazione dopo l'annullamento.
		arianna._on_animation_frame_changed()
		arianna._on_animation_finished()
		await tree.physics_frame
		expect.call(
			events.cancelled == cancels_before + 1 and events.finished == finishes_before
			and not bool(arianna.get(moves[method])) and not arianna.combat.is_attacking
			and arianna.combat.current_attack == null and arianna.combat.current_variant == null
			and arianna.combat.hitbox_shape.disabled and arianna.combat.action_generation > generation
			and arianna.z_index == arianna.default_z_index,
			"%s: annullamento unico, cleanup e nessuna riattivazione tardiva" % method
		)
		expect.call(opponent.controls_enabled and opponent.can_move, "%s: l'annullamento libera l'avversario" % method)

	arianna.reset_fighter(Vector2(800.0, MainArena.FLOOR_Y))
	var completed_before: int = events.finished
	var cancelled_before: int = events.cancelled
	arianna._start_light_punch()
	await tree.create_timer(0.6).timeout
	expect.call(
		events.finished == completed_before + 1 and events.cancelled == cancelled_before
		and not arianna.light_punch_active and not arianna.combat.is_attacking
		and arianna.current_state == Fighter.State.IDLE and arianna.can_move,
		"la recovery naturale termina una volta e restituisce il movimento"
	)

	var combo_start: int = events.started.size()
	completed_before = events.finished
	arianna._start_light_punch()
	arianna.lp_mp_combo_active = true
	arianna._start_lp_mp_combo_medium()
	arianna._start_lp_mp_mk_combo_kick()
	arianna._finish_lp_mp_combo()
	expect.call(
		events.started.slice(combo_start) == [&"light_punch", &"medium_punch", &"medium_kick"]
		and events.finished == completed_before + 3 and not arianna.lp_mp_combo_active
		and not arianna.combat.is_attacking and arianna.current_state == Fighter.State.IDLE,
		"LP-MP-MK pubblica un avvio e una conclusione per ogni colpo"
	)

	arianna.reset_fighter(Vector2(800.0, 350.0))
	arianna.velocity = Vector2(140.0, -250.0)
	arianna._start_jump_light_punch()
	expect.call(arianna.velocity == Vector2(140.0, -250.0), "l'avvio aereo conserva la traiettoria")
	completed_before = events.finished
	arianna._finish_jump_light_punch(true)
	expect.call(
		events.finished == completed_before + 1 and not arianna.jump_light_punch_active
		and not arianna.combat.is_airborne_light_punch and arianna.velocity == Vector2.ZERO
		and arianna.current_state == Fighter.State.IDLE,
		"l'atterraggio conclude l'attacco aereo e ne azzera il contesto"
	)

	arianna.reset_fighter(Vector2(800.0, MainArena.FLOOR_Y))
	arianna.velocity = Vector2(0.0, 1.0)
	arianna.move_and_slide()
	arianna._start_medium_punch()
	cancelled_before = events.cancelled
	completed_before = events.finished
	arianna.combat.take_damage(10, opponent)
	await tree.create_timer(0.9).timeout
	arianna._physics_process(1.0 / 60.0)
	expect.call(
		events.cancelled == cancelled_before + 1 and events.finished == completed_before
		and not arianna.medium_punch_active and not arianna.combat.is_attacking
		and arianna.current_state == Fighter.State.IDLE,
		"dopo l'hitstun una mossa interrotta non riparte dai flag residui"
	)
	arianna._start_strong_punch()
	cancelled_before = events.cancelled
	arianna.reset_fighter(Vector2(800.0, MainArena.FLOOR_Y))
	expect.call(
		events.cancelled == cancelled_before + 1 and not arianna.strong_punch_active
		and arianna.current_state == Fighter.State.IDLE and arianna.can_move,
		"il reset annulla la mossa attiva e ripristina il fighter"
	)
	expect.call(events.states.has(Fighter.State.ATTACKING) and events.states.has(Fighter.State.IDLE), "le transizioni delle mosse emettono state_changed")
	arianna.combat.cancel_current_action()
	opponent.combat.cancel_current_action()
	arena.queue_free()
	await tree.process_frame
	return true
