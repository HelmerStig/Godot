extends SceneTree

## Suite smoke senza dipendenze esterne.
## Esecuzione: Godot --headless --path . --script res://tests/smoke_tests.gd

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Engine.time_scale = 1.0
	print("=== SANMO HEADLESS SMOKE TESTS ===")
	_test_attack_data()
	await _test_input_buffer()
	await _test_combat_flow()
	_release_test_actions()

	if failures == 0:
		print("SMOKE_TESTS_OK")
		quit(0)
	else:
		push_error("SMOKE_TESTS_FAILED: %d assertion(s)" % failures)
		quit(1)


func _test_attack_data() -> void:
	print("-- AttackData")
	var character_data := CharacterData.create_default()
	var attack_ids: Array[StringName] = [
		&"light_punch",
		&"medium_punch",
		&"heavy_punch",
		&"light_kick",
		&"medium_kick",
		&"heavy_kick",
	]
	_expect(character_data.attacks.size() == 6, "il profilo predefinito contiene sei AttackData")
	for attack_id in attack_ids:
		var attack := character_data.get_attack(attack_id)
		_expect(attack != null, "risorsa caricata: " + str(attack_id))
		if attack != null:
			_expect(attack.is_valid(), "risorsa valida: " + str(attack_id))

	var light_punch := character_data.get_attack(&"light_punch")
	_expect(
		light_punch != null and is_equal_approx(light_punch.get_total_duration(), 0.3),
		"startup, active e recovery determinano la durata totale"
	)


func _test_input_buffer() -> void:
	print("-- FighterInputBuffer")
	var buffer := FighterInputBuffer.new(1)
	var light_punch: Array[StringName] = [&"light_punch"]
	var no_attacks: Array[StringName] = []

	buffer.record_input_snapshot(1, 0, light_punch, true)
	_expect(
		buffer.get_current_direction() == FighterInputBuffer.Direction.FORWARD,
		"direzione assoluta destra convertita in FORWARD"
	)
	_expect(
		buffer.consume_attack(&"light_punch") == FighterInputBuffer.Direction.FORWARD,
		"attacco memorizzato con la direzione di pressione"
	)
	_expect(
		buffer.consume_attack(&"light_punch") == FighterInputBuffer.NO_DIRECTION,
		"lo stesso attacco non può essere consumato due volte"
	)
	buffer.clear()
	buffer.record_input_snapshot(1, 0, no_attacks, false)
	_expect(
		buffer.get_current_direction() == FighterInputBuffer.Direction.BACK,
		"la direzione viene invertita quando il fighter guarda a sinistra"
	)
	buffer.clear()
	buffer.record_input_snapshot(0, 1, no_attacks, true)
	buffer.record_input_snapshot(1, 0, no_attacks, true)
	_expect(
		buffer.matches_recent_sequence([
			FighterInputBuffer.Direction.DOWN,
			FighterInputBuffer.Direction.FORWARD,
		]),
		"riconoscimento di una sequenza direzionale recente"
	)

func _test_combat_flow() -> void:
	print("-- Arena, combattimento e UI")
	var arena_scene := load("res://scenes/MainArena.tscn") as PackedScene
	var arena: Node = arena_scene.instantiate()
	root.add_child(arena)

	var player1 := arena.get_node("Player1") as Mangler
	var player2 := arena.get_node("Player2") as Mangler
	var player1_bar := arena.get_node("CanvasLayer/UI/Player1Health") as ProgressBar
	var player2_bar := arena.get_node("CanvasLayer/UI/Player2Health") as ProgressBar
	var round_label := arena.get_node("CanvasLayer/UI/RoundLabel") as Label

	_expect(player1_bar.value == 100.0, "vita iniziale Player 1 visualizzata")
	_expect(player2_bar.value == 100.0, "vita iniziale Player 2 visualizzata")
	await create_timer(3.1).timeout
	_expect(bool(arena.get("round_active")), "training attivo dopo il countdown")
	var light_punch := player1.character_data.get_attack(&"light_punch")
	player1.combat.try_attack(&"light_punch")
	_expect(player1.current_state == Mangler.State.ATTACKING, "AttackData avvia lo stato ATTACKING")
	_expect(player1.combat.current_attack == light_punch, "FighterCombat usa la risorsa selezionata")
	var attack_shape := player1.combat.hitbox_shape.shape as RectangleShape2D
	_expect(
		attack_shape.size == light_punch.hitbox_size
		and player1.combat.hitbox_shape.position == light_punch.hitbox_position,
		"AttackData configura geometria e posizione della hitbox"
	)
	await create_timer(light_punch.get_total_duration() + 0.05).timeout
	_expect(player1.current_state == Mangler.State.IDLE, "i timing AttackData completano l'attacco")

	player2.combat.take_damage(20, player1)
	_expect(player2.combat.current_health == 80, "danno normale applicato")
	_expect(player2.current_state == Mangler.State.HIT, "danno normale attiva HIT")
	_expect(player2_bar.value == 80.0, "segnale di danno aggiorna la UI")
	await create_timer(0.35).timeout
	_expect(player2.current_state == Mangler.State.IDLE, "hit-stun termina in IDLE")

	var health_before_guard := player2.combat.current_health
	Input.action_press(&"p2_move_right")
	await physics_frame
	await physics_frame
	player2.combat.take_damage(20, player1)
	Input.action_release(&"p2_move_right")
	_expect(
		player2.combat.current_health == health_before_guard,
		"la guardia riuscita non infligge danno"
	)
	_expect(player2.current_state == Mangler.State.BLOCKING, "guardia attiva BLOCKING")
	_expect(player2_bar.value == 80.0, "la barra non cala durante la guardia")
	await create_timer(0.2).timeout

	player2.combat.take_damage(player2.combat.current_health, player1)
	_expect(player2.combat.current_health == 0, "danno letale porta la vita a zero")
	_expect(player2.current_state == Mangler.State.KNOCKED_DOWN, "danno letale attiva KO")
	_expect(not bool(arena.get("round_active")), "KO ferma il training")
	_expect(not player1.controls_enabled and not player2.controls_enabled, "KO blocca i controlli")
	_expect(
		round_label.visible and round_label.text.begins_with("PLAYER 1 WINS"),
		"KO aggiorna il messaggio UI"
	)

	arena.call("start_round")
	_expect(player1.combat.current_health == player1.combat.max_health, "reset vita Player 1")
	_expect(player2.combat.current_health == player2.combat.max_health, "reset vita Player 2")
	_expect(player1.current_state == Mangler.State.IDLE, "reset stato Player 1")
	_expect(player2.current_state == Mangler.State.IDLE, "reset stato Player 2")
	_expect(player1_bar.value == 100.0 and player2_bar.value == 100.0, "reset barre UI")
	_expect(not player1.controls_enabled and not player2.controls_enabled, "controlli bloccati durante il countdown")
	await create_timer(2.1).timeout
	_expect(bool(arena.get("round_active")), "training riattivato dopo il reset")
	_expect(player1.controls_enabled and player2.controls_enabled, "controlli riattivati dopo il reset")

	arena.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
		return
	failures += 1
	push_error("FAIL: " + description)


func _release_test_actions() -> void:
	Input.action_release(&"p2_move_right")
