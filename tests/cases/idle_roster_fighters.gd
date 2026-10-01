extends RefCounted

const FIGHTERS := [
	{"id": &"bue", "scene": "res://scenes/Bue.tscn", "sheet": "res://assets/sprites/characters/bue/idle-spritesheet.png", "walk": "res://assets/sprites/characters/bue/walk-spritesheet.png", "crouch": "res://assets/sprites/characters/bue/crouch-spritesheet.png", "hurt_mid": "res://assets/sprites/characters/bue/hurt_medium_spritesheet.png", "crouch_frames": 7, "frames": 63, "columns": 8},
	{"id": &"mileto", "scene": "res://scenes/Mileto.tscn", "sheet": "res://assets/sprites/characters/mileto/idle-spritesheet.png", "walk": "res://assets/sprites/characters/mileto/walk-spritesheet.png", "crouch": "res://assets/sprites/characters/mileto/crouch-spritesheet.png", "hurt_mid": "res://assets/sprites/characters/mileto/hurt_medium_spritesheet.png", "crouch_frames": 13, "frames": 63, "columns": 8},
	{"id": &"oscare", "scene": "res://scenes/Oscare.tscn", "sheet": "res://assets/sprites/characters/oscare/idle-spritesheet.png", "walk": "res://assets/sprites/characters/oscare/walk-spritesheet.png", "crouch": "res://assets/sprites/characters/oscare/crouch-spritesheet.png", "hurt_mid": "res://assets/sprites/characters/oscare/hurt_medium_spritesheet.png", "crouch_frames": 9, "frames": 63, "columns": 8},
	{"id": &"peiro", "scene": "res://scenes/Peirolo.tscn", "sheet": "res://assets/sprites/characters/peirolo/idle_spritesheet.png", "walk": "res://assets/sprites/characters/peirolo/walk-spritesheet.png", "crouch": "res://assets/sprites/characters/peirolo/crouch-spritesheet.png", "hurt_mid": "res://assets/sprites/characters/peirolo/hurt_medium_spritesheet.png", "crouch_frames": 11, "frames": 63, "columns": 8},
	{"id": &"torpe", "scene": "res://scenes/Torpe.tscn", "sheet": "res://assets/sprites/characters/torpe/idle-spritesheet.png", "walk": "res://assets/sprites/characters/torpe/walk-spritesheet.png", "crouch": "res://assets/sprites/characters/torpe/crouch-spritesheet.png", "hurt_mid": "res://assets/sprites/characters/torpe/hurt_medium_spritesheet.png", "crouch_frames": 7, "frames": 61, "columns": 8},
]


static func run(tree: SceneTree, expect: Callable) -> bool:
	print("-- Idle roster fighters")
	for entry in FIGHTERS:
		var packed := load(entry["scene"]) as PackedScene
		var fighter := packed.instantiate() as IdleRosterFighter
		tree.root.add_child(fighter)
		await tree.process_frame
		var frames := fighter.animated_sprite.sprite_frames
		var first := frames.get_frame_texture(&"idle", 0) as AtlasTexture
		var last_index: int = entry["frames"] - 1
		var last := frames.get_frame_texture(&"idle", last_index) as AtlasTexture
		var cell: float = entry.get("cell", 512.0)
		var columns: int = entry.get("columns", 7)
		expect.call(
			fighter.fighter_id == entry["id"]
			and frames.get_frame_count(&"idle") == entry["frames"]
			and is_equal_approx(frames.get_animation_speed(&"idle"), 18.0)
			and frames.get_animation_loop(&"idle")
			and fighter.animated_sprite.animation == &"idle"
			and fighter.animated_sprite.is_playing()
			and first.atlas.resource_path == entry["sheet"]
			and first.region == Rect2(0.0, 0.0, cell, cell)
			and last.region == Rect2(
				float(last_index % columns) * cell,
				float(last_index / columns) * cell,
				cell,
				cell
			),
			"%s usa tutti i frame idle a 18 FPS in loop" % entry["id"]
		)
		var walk_first := frames.get_frame_texture(&"walk", 0) as AtlasTexture
		var walk_last := frames.get_frame_texture(&"walk", 48) as AtlasTexture
		var back_first := frames.get_frame_texture(&"backwalk", 0) as AtlasTexture
		var back_last := frames.get_frame_texture(&"backwalk", 48) as AtlasTexture
		expect.call(
			frames.get_frame_count(&"walk") == 49
			and frames.get_frame_count(&"backwalk") == 49
			and is_equal_approx(frames.get_animation_speed(&"walk"), 24.0)
			and is_equal_approx(frames.get_animation_speed(&"backwalk"), 24.0)
			and frames.get_animation_loop(&"walk")
			and frames.get_animation_loop(&"backwalk")
			and walk_first.atlas.resource_path == entry["walk"]
			and back_first.atlas.resource_path == entry["walk"]
			and walk_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
			and walk_last.region == Rect2(3072.0, 3072.0, 512.0, 512.0)
			and back_first.region == walk_last.region
			and back_last.region == walk_first.region,
			"%s usa 49 frame walk a 24 FPS e backwalk inverso" % entry["id"]
		)
		var crouch_count: int = entry["crouch_frames"]
		var crouch_first := frames.get_frame_texture(&"crouch", 0) as AtlasTexture
		var crouch_last := frames.get_frame_texture(&"crouch", crouch_count - 1) as AtlasTexture
		expect.call(
			frames.get_frame_count(&"crouch") == crouch_count
			and is_equal_approx(frames.get_animation_speed(&"crouch"), 24.0)
			and not frames.get_animation_loop(&"crouch")
			and crouch_first.atlas.resource_path == entry["crouch"]
			and crouch_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
			and crouch_last.region == Rect2(
				float((crouch_count - 1) % 5) * 512.0,
				float((crouch_count - 1) / 5) * 512.0,
				512.0, 512.0
			),
			"%s usa %d frame crouch a 24 FPS senza loop" % [entry["id"], crouch_count]
		)
		var mid_first := frames.get_frame_texture(&"hurt_mid", 0) as AtlasTexture
		var mid_last := frames.get_frame_texture(&"hurt_mid", 10) as AtlasTexture
		var mid_reverse_first := frames.get_frame_texture(&"hurt_mid_reverse", 0) as AtlasTexture
		var mid_reverse_last := frames.get_frame_texture(&"hurt_mid_reverse", 9) as AtlasTexture
		expect.call(
			frames.get_frame_count(&"hurt_mid") == 11
			and frames.get_frame_count(&"hurt_mid_reverse") == 10
			and is_equal_approx(frames.get_animation_speed(&"hurt_mid"), 24.0)
			and is_equal_approx(frames.get_animation_speed(&"hurt_mid_reverse"), 24.0)
			and not frames.get_animation_loop(&"hurt_mid")
			and not frames.get_animation_loop(&"hurt_mid_reverse")
			and mid_first.atlas.resource_path == entry["hurt_mid"]
			and mid_first.region == Rect2(0.0, 0.0, 512.0, 512.0)
			and mid_last.region == Rect2(0.0, 1024.0, 512.0, 512.0)
			and mid_reverse_first.region == Rect2(2048.0, 512.0, 512.0, 512.0)
			and mid_reverse_last.region == mid_first.region,
			"%s usa hurt medium 1-11 e recovery 10-1 a 24 FPS" % entry["id"]
		)
		fighter.queue_free()
		await tree.process_frame

	var movement_test := (load("res://scenes/MovementTest.tscn") as PackedScene).instantiate()
	tree.root.add_child(movement_test)
	await tree.process_frame
	var ids: Array[StringName] = []
	for fighter_node in movement_test._fighters:
		if fighter_node is IdleRosterFighter:
			ids.append(fighter_node.fighter_id)
	expect.call(
		movement_test._fighters.size() == CharacterSelection.ROSTER.size()
		and ids.has(&"bue")
		and ids.has(&"mileto")
		and ids.has(&"oscare")
		and ids.has(&"peiro")
		and ids.has(&"torpe"),
		"MovementTest istanzia tutti i sette personaggi del roster"
	)
	for _frame in 4:
		await tree.physics_frame
	var start_positions: Dictionary = {}
	for fighter_node in movement_test._fighters:
		if fighter_node is IdleRosterFighter:
			fighter_node.stage_left_limit = -100.0
			fighter_node.stage_right_limit = 3000.0
			start_positions[fighter_node.fighter_id] = fighter_node.position.x
	Input.action_press(&"p1_move_right")
	for _frame in 4:
		await tree.physics_frame
	Input.action_release(&"p1_move_right")
	for fighter_node in movement_test._fighters:
		if fighter_node is IdleRosterFighter:
			expect.call(
				fighter_node.position.x > start_positions[fighter_node.fighter_id]
				and fighter_node.current_state == Fighter.State.WALKING
				and fighter_node.animated_sprite.animation == &"walk",
				"%s avanza con l'animazione walk" % fighter_node.fighter_id
			)
	for _frame in 2:
		await tree.physics_frame
	for fighter_node in movement_test._fighters:
		if fighter_node is IdleRosterFighter:
			expect.call(
				fighter_node.current_state == Fighter.State.IDLE
				and fighter_node.animated_sprite.animation == &"idle",
				"%s torna in idle al rilascio" % fighter_node.fighter_id
			)
	Input.action_press(&"p1_move_left")
	for _frame in 3:
		await tree.physics_frame
	Input.action_release(&"p1_move_left")
	for fighter_node in movement_test._fighters:
		if fighter_node is IdleRosterFighter:
			expect.call(
				fighter_node.current_state == Fighter.State.WALKING
				and fighter_node.animated_sprite.animation == &"backwalk",
				"%s arretra con l'animazione backwalk" % fighter_node.fighter_id
			)
	for _frame in 2:
		await tree.physics_frame
	var p2_fighter: IdleRosterFighter = null
	for fighter_node in movement_test._fighters:
		if fighter_node is IdleRosterFighter:
			p2_fighter = fighter_node
			break
	if p2_fighter != null:
		p2_fighter.player_number = 2
		p2_fighter.input_buffer = FighterInputBuffer.new(2)
		var p2_start_x := p2_fighter.position.x
		Input.action_press(&"p2_move_right")
		for _frame in 3:
			await tree.physics_frame
		Input.action_release(&"p2_move_right")
		expect.call(
			p2_fighter.position.x > p2_start_x
			and p2_fighter.animated_sprite.animation == &"walk",
			"gli input Player 2 muovono il fighter idle-only"
		)
		p2_fighter.player_number = 1
		p2_fighter.input_buffer = FighterInputBuffer.new(1)
	for _frame in 3:
		await tree.physics_frame
	Input.action_press(&"p1_crouch")
	for _frame in 40:
		await tree.physics_frame
	for fighter_node in movement_test._fighters:
		if fighter_node is IdleRosterFighter:
			var crouch_frames: int = fighter_node.animated_sprite.sprite_frames.get_frame_count(&"crouch")
			expect.call(
				fighter_node.current_state == Fighter.State.CROUCHING
				and fighter_node.animated_sprite.animation == &"crouch"
				and fighter_node.animated_sprite.frame == crouch_frames - 1,
				"%s resta nell'ultima posa crouch mentre si tiene premuto giù" % fighter_node.fighter_id
			)
	Input.action_release(&"p1_crouch")
	for _frame in 2:
		await tree.physics_frame
	for fighter_node in movement_test._fighters:
		if fighter_node is IdleRosterFighter:
			expect.call(
				fighter_node.current_state == Fighter.State.STANDING_UP
				and fighter_node.animated_sprite.animation == &"crouch"
				and fighter_node.animated_sprite.get_playing_speed() < 0.0,
				"%s riproduce crouch all'indietro al rilascio" % fighter_node.fighter_id
			)
	for _frame in 40:
		await tree.physics_frame
	for fighter_node in movement_test._fighters:
		if fighter_node is IdleRosterFighter:
			expect.call(
				fighter_node.current_state == Fighter.State.IDLE
				and fighter_node.animated_sprite.animation == &"idle",
				"%s torna in idle dopo la risalita" % fighter_node.fighter_id
			)
	for fighter_node in movement_test._fighters:
		if fighter_node is IdleRosterFighter:
			var reaction_duration: float = fighter_node.start_hit_reaction(AttackData.HitHeight.MID, null, 4, false)
			expect.call(
				fighter_node.current_state == Fighter.State.HIT
				and fighter_node.get_hit_animation(AttackData.HitHeight.MID) == &"hurt_mid"
				and fighter_node.animated_sprite.animation == &"hurt_mid"
				and fighter_node.animated_sprite.frame == 0
				and is_equal_approx(reaction_duration, 21.0 / 24.0),
				"%s riceve hurt medium dal primo frame e mantiene l'hitstun fino alla fine" % fighter_node.fighter_id
			)
	for _frame in 33:
		await tree.physics_frame
	for fighter_node in movement_test._fighters:
		if fighter_node is IdleRosterFighter:
			expect.call(
				fighter_node.current_state == Fighter.State.HIT
				and fighter_node.animated_sprite.animation == &"hurt_mid_reverse",
				"%s riproduce il ritorno 10-1 di hurt medium" % fighter_node.fighter_id
			)
	for _frame in 34:
		await tree.physics_frame
	for fighter_node in movement_test._fighters:
		if fighter_node is IdleRosterFighter:
			expect.call(
				fighter_node.current_state == Fighter.State.IDLE
				and fighter_node.animated_sprite.animation == &"idle",
				"%s torna in idle dopo hurt medium" % fighter_node.fighter_id
			)
	var h_down := InputEventKey.new()
	h_down.keycode = KEY_H
	h_down.pressed = true
	var h_up := InputEventKey.new()
	h_up.keycode = KEY_H
	h_up.pressed = false
	var m_down := InputEventKey.new()
	m_down.keycode = KEY_M
	m_down.pressed = true
	var m_up := InputEventKey.new()
	m_up.keycode = KEY_M
	m_up.pressed = false
	movement_test._unhandled_input(m_down)
	for fighter_node in movement_test._fighters:
		var fighter := fighter_node as Fighter
		expect.call(
			fighter.current_state == Fighter.State.IDLE,
			"%s non reagisce a M da sola nel test" % fighter.name
		)
	movement_test._unhandled_input(h_down)
	var longest_standard_hurt := 0.0
	var idle_at_hurt_finish := {}
	for fighter_node in movement_test._fighters:
		var fighter := fighter_node as Fighter
		expect.call(
			fighter.current_state == Fighter.State.HIT
			and fighter.animated_sprite.animation == &"hurt_mid",
			"%s mostra hurt_medium con M poi H" % fighter.name
		)
		if fighter is Arianna or fighter is Mangler:
			longest_standard_hurt = maxf(
				longest_standard_hurt, fighter.get_animation_duration(&"hurt_mid")
			)
			var observed_fighter := fighter
			var observed_name := String(fighter.name)
			var on_hurt_finished := func() -> void:
				idle_at_hurt_finish[observed_name] = (
					observed_fighter.current_state == Fighter.State.IDLE
					and observed_fighter.animated_sprite.animation == &"idle"
				)
			fighter.animated_sprite.animation_finished.connect(on_hurt_finished, CONNECT_ONE_SHOT)
	movement_test._unhandled_input(h_up)
	movement_test._unhandled_input(m_up)
	await tree.create_timer(longest_standard_hurt + 0.12).timeout
	for fighter_node in movement_test._fighters:
		var fighter := fighter_node as Fighter
		if fighter is Arianna or fighter is Mangler:
			expect.call(
				fighter.current_state == Fighter.State.IDLE
				and fighter.animated_sprite.animation == &"idle"
				and idle_at_hurt_finish.get(String(fighter.name), false),
				"%s torna in idle sul segnale finale di hurt_medium" % fighter.name
			)
	for fighter_node in movement_test._fighters:
		(fighter_node as Fighter).change_state(Fighter.State.IDLE)
	movement_test._unhandled_input(h_down)
	movement_test._unhandled_input(m_down)
	await tree.process_frame
	for fighter_node in movement_test._fighters:
		var fighter := fighter_node as Fighter
		expect.call(
			fighter.current_state == Fighter.State.HIT
			and fighter.animated_sprite.animation == &"hurt_mid",
			"%s mostra hurt_medium con H poi M senza passare da hurt_high" % fighter.name
		)
	movement_test._unhandled_input(h_up)
	movement_test._unhandled_input(m_up)
	for fighter_node in movement_test._fighters:
		(fighter_node as Fighter).change_state(Fighter.State.IDLE)
	movement_test._unhandled_input(h_down)
	await tree.process_frame
	for fighter_node in movement_test._fighters:
		var fighter := fighter_node as Fighter
		expect.call(
			fighter.current_state == Fighter.State.HIT
			and fighter.animated_sprite.animation == &"hurt_high",
			"%s conserva hurt_high con H da sola" % fighter.name
		)
	movement_test._unhandled_input(h_up)
	movement_test.queue_free()
	await tree.process_frame
	return true
