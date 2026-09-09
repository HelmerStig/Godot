extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	print("-- Arena")
	var arena_scene := load("res://scenes/MainArena.tscn") as PackedScene
	var arena := arena_scene.instantiate() as MainArena
	var player1 := arena.get_node("Player1")
	var player2 := arena.get_node("Player2")
	expect.call(
		player1 is Arianna and player2 is Mangler and not (player2 is Arianna),
		"MainArena assegna Arianna al Player 1 e Mangler al Player 2"
	)
	expect.call(
		player1 is Fighter and player2 is Fighter,
		"i nodi dell'arena rispettano il contratto Fighter"
	)
	tree.root.add_child(arena)
	await tree.process_frame
	expect.call(
		arena.player1.opponent == arena.player2 and arena.player2.opponent == arena.player1,
		"MainArena collega reciprocamente gli avversari"
	)
	expect.call(
		not arena.player1.controls_enabled and not arena.player2.controls_enabled,
		"l'arena blocca i controlli durante il countdown"
	)
	arena.request_screen_shake(7.0, 0.18)
	arena._update_screen_shake(0.01)
	expect.call(
		arena.screen_shake_time_left > 0.0 and arena.camera.offset != Vector2.ZERO,
		"la camera applica e smorza gli impulsi di screen shake"
	)
	var mangler := arena.player2 as Mangler
	mangler.start_direct_grab()
	expect.call(
		mangler.current_state == Fighter.State.IDLE
		and not mangler.grab_succeeded and mangler.grabbed_target == null
		and not mangler.grab_front_sprite.visible,
		"la presa di Mangler è disattivata"
	)
	arena.queue_free()
	await tree.process_frame

	var character_selection := tree.root.get_node_or_null("CharacterSelection")
	var previous_player1_id: String = character_selection.player1_id
	var previous_player2_id: String = character_selection.player2_id
	character_selection.player1_id = "mangler"
	character_selection.player2_id = "arianna"
	var selected_arena := arena_scene.instantiate() as MainArena
	tree.root.add_child(selected_arena)
	await tree.process_frame
	var selected_mangler := selected_arena.player1 as Mangler
	selected_arena.round_ended.emit(1)
	expect.call(
		selected_mangler != null
		and selected_mangler.current_state == Fighter.State.VICTORY
		and selected_mangler.animated_sprite.animation == &"victory"
		and selected_mangler.animated_sprite.is_playing(),
		"Mangler scelto come Player 1 riceve il round vinto e avvia victory"
	)
	selected_arena.queue_free()
	await tree.process_frame
	character_selection.player1_id = previous_player1_id
	character_selection.player2_id = previous_player2_id
	return true
