extends RefCounted


static func run(tree: SceneTree, expect: Callable) -> bool:
	var fighter := (load("res://scenes/Arianna.tscn") as PackedScene).instantiate() as Arianna
	tree.root.add_child(fighter)
	fighter.set_physics_process(false)
	await tree.process_frame
	fighter._start_light_punch()
	expect.call(fighter.light_punch_whoosh_audio_player.playing and fighter.light_punch_whoosh_audio_player.stream == load("res://sound-libraries/punch_short_whoosh_30.wav") and not fighter.light_punch_hit_sound_played, "Arianna: light punch a vuoto avvia soltanto whoosh")
	fighter._on_combat_attack_connected(&"light_punch", FighterCombat.DamageResult.IGNORED)
	fighter._on_combat_attack_connected(&"light_punch", FighterCombat.DamageResult.BLOCKED)
	expect.call(not fighter.light_punch_hit_sound_played and not fighter.medium_punch_hit_audio_player.playing, "Arianna: colpo ignorato o parato non genera audio impatto")
	fighter._on_combat_attack_connected(&"light_punch", FighterCombat.DamageResult.HIT)
	expect.call(fighter.light_punch_hit_sound_played and fighter.medium_punch_hit_audio_player.playing, "Arianna: colpo riuscito aggiunge audio impatto")
	fighter.reset_fighter(Vector2.ZERO)
	expect.call(not fighter.light_punch_whoosh_audio_player.playing and not fighter.medium_punch_hit_audio_player.playing, "Arianna: reset interrompe entrambi i suoni del pugno")
	fighter.queue_free()
	await tree.process_frame
	return true
