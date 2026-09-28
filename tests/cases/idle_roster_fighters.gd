extends RefCounted

const FIGHTERS := [
	{"id": &"bue", "scene": "res://scenes/Bue.tscn", "sheet": "res://assets/sprites/characters/bue/idle-spritesheet.png", "walk": "res://assets/sprites/characters/bue/walk-spritesheet.png", "frames": 63, "columns": 8},
	{"id": &"mileto", "scene": "res://scenes/Mileto.tscn", "sheet": "res://assets/sprites/characters/mileto/idle-spritesheet.png", "walk": "res://assets/sprites/characters/mileto/walk-spritesheet.png", "frames": 63, "columns": 8},
	{"id": &"oscare", "scene": "res://scenes/Oscare.tscn", "sheet": "res://assets/sprites/characters/oscare/idle-spritesheet.png", "walk": "res://assets/sprites/characters/oscare/walk-spritesheet.png", "frames": 63, "columns": 8},
	{"id": &"peiro", "scene": "res://scenes/Peirolo.tscn", "sheet": "res://assets/sprites/characters/peirolo/idle_spritesheet.png", "walk": "res://assets/sprites/characters/peirolo/walk-spritesheet.png", "frames": 63, "columns": 8},
	{"id": &"torpe", "scene": "res://scenes/Torpe.tscn", "sheet": "res://assets/sprites/characters/torpe/idle-spritesheet.png", "walk": "res://assets/sprites/characters/torpe/walk-spritesheet.png", "frames": 61, "columns": 8},
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
	movement_test.queue_free()
	await tree.process_frame
	return true
