extends RefCounted

const UIConfig := preload("res://scripts/ArenaUIConfig.gd")


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
	var arena_ui := arena.get_node("CanvasLayer/UI") as ArenaUI
	arena_ui._play_damage_glow(arena_ui.player1_health_bar)
	var first_glow_tween := arena_ui.health_glow_tweens.get(arena_ui.player1_health_bar) as Tween
	arena_ui._play_damage_glow(arena_ui.player1_health_bar)
	var replacement_glow_tween := arena_ui.health_glow_tweens.get(
		arena_ui.player1_health_bar
	) as Tween
	expect.call(
		first_glow_tween != null
		and not first_glow_tween.is_valid()
		and replacement_glow_tween != null
		and replacement_glow_tween.is_valid()
		and UIConfig.HEALTH_BAR_SIZE == Vector2(350.0, 47.0)
		and is_equal_approx(UIConfig.HEALTH_ANIMATION_DURATION, 0.34),
		"il bagliore danno sostituisce il tween precedente senza riutilizzarlo"
	)
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
	var arianna := arena.player1 as Arianna
	await tree.physics_frame
	await tree.physics_frame
	arena.round_ended.emit(1)
	var arianna_grounded_victory_started := (
		arianna.current_state == Fighter.State.VICTORY
		and arianna.animated_sprite.animation == &"victory"
		and arianna.animated_sprite.is_playing()
	)
	arianna.change_state(Fighter.State.IDLE, true)
	arianna.reset_airborne_combat_state()
	arianna.position = Vector2(arianna.position.x, MainArena.FLOOR_Y - 300.0)
	arianna.change_state(Fighter.State.JUMPING)
	arianna.velocity = Vector2(0.0, 160.0)
	await tree.physics_frame
	await tree.physics_frame
	arena.round_active = true
	arena.end_round_ko(1)
	var arianna_airborne_victory_was_deferred := (
		arianna.victory_pending_until_landing
		and arianna.current_state != Fighter.State.VICTORY
	)
	for _physics_step in 60:
		arianna._physics_process(1.0 / 60.0)
		if arianna.current_state == Fighter.State.VICTORY:
			break
	var arianna_victory_landing_ok := (
		arianna_grounded_victory_started
		and arianna_airborne_victory_was_deferred
		and arianna.is_on_floor()
		and arianna.current_state == Fighter.State.VICTORY
		and arianna.animated_sprite.animation == &"victory"
		and arianna.animated_sprite.is_playing()
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
	var grounded_victory_started := (
		selected_mangler != null
		and selected_mangler.current_state == Fighter.State.VICTORY
		and selected_mangler.animated_sprite.animation == &"victory"
		and selected_mangler.animated_sprite.is_playing()
	)
	selected_mangler.change_state(Fighter.State.IDLE, true)
	selected_mangler.reset_airborne_combat_state()
	selected_mangler.position = Vector2(selected_mangler.position.x, MainArena.FLOOR_Y - 300.0)
	selected_mangler.change_state(Fighter.State.JUMPING)
	selected_mangler.velocity = Vector2(0.0, 160.0)
	await tree.physics_frame
	await tree.physics_frame
	selected_arena.round_active = true
	selected_arena.end_round_ko(1)
	var airborne_victory_was_deferred := (
		selected_mangler.victory_pending_until_landing
		and selected_mangler.current_state != Fighter.State.VICTORY
	)
	await tree.create_timer(0.7).timeout
	expect.call(
		arianna_victory_landing_ok
		and grounded_victory_started
		and airborne_victory_was_deferred
		and selected_mangler.is_on_floor()
		and selected_mangler.current_state == Fighter.State.VICTORY
		and selected_mangler.animated_sprite.animation == &"victory"
		and selected_mangler.animated_sprite.is_playing(),
		"Arianna e Mangler avviano victory al suolo o dopo l'atterraggio"
	)
	selected_arena.queue_free()
	await tree.process_frame
	character_selection.player1_id = previous_player1_id
	character_selection.player2_id = previous_player2_id
	return true
