extends RefCounted


static func run(_tree: SceneTree, expect: Callable) -> bool:
	print("-- FighterInputBuffer")
	var buffer := FighterInputBuffer.new(1)
	var light_punch: Array[StringName] = [&"light_punch"]
	var no_attacks: Array[StringName] = []

	buffer.record_input_snapshot(1, 0, light_punch, true)
	expect.call(
		buffer.get_current_direction() == FighterInputBuffer.Direction.FORWARD,
		"direzione assoluta destra convertita in FORWARD"
	)
	expect.call(
		buffer.consume_attack(&"light_punch") == FighterInputBuffer.Direction.FORWARD,
		"attacco memorizzato con la direzione di pressione"
	)
	expect.call(
		buffer.consume_attack(&"light_punch") == FighterInputBuffer.NO_DIRECTION,
		"lo stesso attacco non può essere consumato due volte"
	)
	buffer.clear()
	buffer.record_input_snapshot(1, 0, no_attacks, false)
	expect.call(
		buffer.get_current_direction() == FighterInputBuffer.Direction.BACK,
		"la direzione viene invertita quando il fighter guarda a sinistra"
	)
	buffer.clear()
	buffer.record_input_snapshot(1, 0, no_attacks, true)
	expect.call(buffer.is_forward_just_pressed(), "il primo tap avanti viene rilevato")
	buffer.record_input_snapshot(1, 0, no_attacks, true)
	expect.call(not buffer.is_forward_just_pressed(), "mantenere avanti non genera nuovi tap")
	buffer.record_input_snapshot(0, 0, no_attacks, true)
	buffer.record_input_snapshot(1, 0, no_attacks, true)
	expect.call(buffer.is_forward_just_pressed(), "un secondo tap distinto viene rilevato")
	buffer.clear()
	buffer.record_input_snapshot(-1, 0, no_attacks, true)
	expect.call(buffer.is_back_just_pressed(), "il primo tap indietro viene rilevato")
	buffer.record_input_snapshot(-1, 0, no_attacks, true)
	expect.call(not buffer.is_back_just_pressed(), "mantenere indietro non genera nuovi tap")
	buffer.record_input_snapshot(0, 0, no_attacks, true)
	buffer.record_input_snapshot(-1, 0, no_attacks, true)
	expect.call(buffer.is_back_just_pressed(), "un secondo tap indietro distinto viene rilevato")
	buffer.clear()
	buffer.record_input_snapshot(0, 1, no_attacks, true)
	buffer.record_input_snapshot(1, 0, no_attacks, true)
	expect.call(
		buffer.matches_recent_sequence([
			FighterInputBuffer.Direction.DOWN,
			FighterInputBuffer.Direction.DOWN_FORWARD,
			FighterInputBuffer.Direction.FORWARD,
		]),
		"un quarto di luna analogico rapido ricostruisce la diagonale tra DOWN e FORWARD"
	)
	expect.call(
		buffer.matches_recent_sequence([
			FighterInputBuffer.Direction.DOWN,
			FighterInputBuffer.Direction.FORWARD,
		]),
		"riconoscimento di una sequenza direzionale recente"
	)
	buffer.clear()
	buffer.record_input_snapshot(-1, 0, no_attacks, true)
	buffer.record_input_snapshot(1, 1, no_attacks, true)
	buffer.record_input_snapshot(1, 0, no_attacks, true)
	expect.call(
		buffer.matches_recent_sequence([
			FighterInputBuffer.Direction.BACK,
			FighterInputBuffer.Direction.DOWN_BACK,
			FighterInputBuffer.Direction.DOWN,
			FighterInputBuffer.Direction.DOWN_FORWARD,
			FighterInputBuffer.Direction.FORWARD,
		]),
		"la mezzaluna ricostruisce diagonali e basso saltati dallo stick rapido"
	)
	expect.call(
		FighterInputBuffer.HISTORY_LIMIT == 60
		and FighterInputBuffer.DEFAULT_ATTACK_BUFFER_FRAMES == 10
		and FighterInputBuffer.DEFAULT_MOTION_WINDOW_FRAMES == 36
		and Mangler.SUPER_MOTION_WINDOW_FRAMES == 48,
		"quarti e mezze lune usano finestre temporali più tolleranti"
	)
	return true
