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
	arena.queue_free()
	await tree.process_frame
	return true
