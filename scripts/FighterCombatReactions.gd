extends RefCounted

## Reazioni condivise al danno.
##
## Riceve FighterCombat come contesto per mantenere una sola sorgente dello
## stato del combattimento, separando però i flussi asincroni di parata,
## hitstun, knockdown e KO dal ciclo degli attacchi.


static func take_damage(
	combat: FighterCombat,
	damage: int,
	attacker: Fighter,
	hitstun: float,
	blockstun: float,
	hit_height: AttackData.HitHeight,
	causes_knockdown: bool,
	hit_reaction_start_frame: int,
	ko_start_frame: int,
	apply_pushback: bool,
	force_grounded_reaction: bool
) -> FighterCombat.DamageResult:
	if combat.fighter.current_state in [Fighter.State.KNOCKDOWN_RECOVERY, Fighter.State.KNOCKED_DOWN]:
		return FighterCombat.DamageResult.IGNORED
	var was_airborne := not combat.fighter.is_on_floor() and not force_grounded_reaction

	var attack_was_blocked := combat.can_block_attack(attacker, hit_height)
	if attack_was_blocked:
		damage = 0
		print("Attacco bloccato! Nessun danno subito.")

	combat.current_health = clampi(combat.current_health - damage, 0, combat.max_health)
	combat.health_changed.emit(combat.current_health, combat.max_health)
	print("Vita rimanente: %d/%d" % [combat.current_health, combat.max_health])

	if combat.current_health <= 0:
		die(combat, ko_start_frame)
		return FighterCombat.DamageResult.KNOCKOUT
	if attack_was_blocked:
		block_reaction(combat, blockstun, hit_height, attacker)
		return FighterCombat.DamageResult.BLOCKED
	if causes_knockdown:
		sweep_knockdown_reaction(combat, attacker)
	elif was_airborne:
		airborne_knockdown_reaction(combat, attacker)
	else:
		if hit_height == AttackData.HitHeight.MID:
			hit_reaction_start_frame = 4
		hit_reaction(combat, hitstun, hit_height, attacker, hit_reaction_start_frame, apply_pushback)
	return FighterCombat.DamageResult.HIT


static func block_reaction(
	combat: FighterCombat,
	duration: float,
	hit_height: AttackData.HitHeight,
	attacker: Fighter = null
) -> void:
	var started_crouched := combat.fighter.current_state == Fighter.State.CROUCHING
	combat.cancel_current_action()
	var block_generation := combat.action_generation
	var animation_duration := combat.fighter.start_block_reaction(hit_height, started_crouched)
	var reaction_duration := maxf(duration, animation_duration)

	await combat.get_tree().create_timer(reaction_duration).timeout
	if not _is_active(combat) or block_generation != combat.action_generation or combat.current_health <= 0:
		return
	while (
		attacker != null
		and is_instance_valid(attacker)
		and attacker.combat != null
		and attacker.combat.is_attacking
	):
		var frame_count := combat.fighter.animated_sprite.sprite_frames.get_frame_count(
			combat.fighter.animated_sprite.animation
		)
		if frame_count > 0:
			combat.fighter.animated_sprite.frame = frame_count - 1
			combat.fighter.animated_sprite.pause()
		await combat.get_tree().process_frame
		if not _is_active(combat) or block_generation != combat.action_generation or combat.current_health <= 0:
			return
	if hit_height == AttackData.HitHeight.LOW and combat.fighter.is_holding_low_guard():
		combat.fighter.return_to_crouch_after_low_block()
		return
	var recovery_duration := combat.fighter.start_block_recovery()
	await combat.get_tree().create_timer(recovery_duration).timeout
	if not _is_active(combat) or block_generation != combat.action_generation or combat.current_health <= 0:
		return
	combat.fighter.change_state(Fighter.State.IDLE)


static func hit_reaction(
	combat: FighterCombat,
	duration: float,
	hit_height: AttackData.HitHeight,
	attacker: Fighter,
	hit_reaction_start_frame: int,
	apply_pushback: bool
) -> void:
	combat.cancel_current_action()
	var hit_generation := combat.action_generation
	var animation_duration := combat.fighter.start_hit_reaction(
		hit_height,
		attacker,
		hit_reaction_start_frame,
		apply_pushback
	)
	var reaction_duration := maxf(duration, animation_duration)

	await combat.get_tree().create_timer(reaction_duration).timeout
	if not _is_active(combat) or hit_generation != combat.action_generation or combat.current_health <= 0:
		return
	combat.fighter.velocity.x = 0.0
	combat.fighter.change_state(Fighter.State.IDLE)


static func airborne_knockdown_reaction(combat: FighterCombat, attacker: Fighter) -> void:
	combat.cancel_current_action()
	var knockdown_generation := combat.action_generation
	combat.fighter.start_airborne_hit_knockdown(attacker)
	while not combat.fighter.is_on_floor():
		await combat.get_tree().physics_frame
		if not _is_active(combat) or knockdown_generation != combat.action_generation or combat.current_health <= 0:
			return
	combat.fighter.hold_airborne_hit_landing_pose()
	await combat.get_tree().create_timer(1.0).timeout
	if not _is_active(combat) or knockdown_generation != combat.action_generation or combat.current_health <= 0:
		return
	var recovery_duration := combat.fighter.start_knockdown_recovery()
	await combat.get_tree().create_timer(recovery_duration).timeout
	if not _is_active(combat) or knockdown_generation != combat.action_generation or combat.current_health <= 0:
		return
	combat.fighter.change_state(Fighter.State.IDLE)


static func sweep_knockdown_reaction(combat: FighterCombat, attacker: Fighter) -> void:
	combat.cancel_current_action()
	var knockdown_generation := combat.action_generation
	var animation_duration := combat.fighter.start_sweep_knockdown(attacker)
	var grounded_hold := combat.fighter.get_sweep_grounded_hold_duration()
	await combat.get_tree().create_timer(animation_duration + grounded_hold).timeout
	if not _is_active(combat) or knockdown_generation != combat.action_generation or combat.current_health <= 0:
		return
	var recovery_duration := combat.fighter.start_knockdown_recovery()
	await combat.get_tree().create_timer(recovery_duration).timeout
	if not _is_active(combat) or knockdown_generation != combat.action_generation or combat.current_health <= 0:
		return
	combat.fighter.change_state(Fighter.State.IDLE)


static func die(combat: FighterCombat, start_frame: int = 0) -> void:
	combat.cancel_current_action()
	combat.fighter.change_state(Fighter.State.KNOCKED_DOWN)
	if combat.fighter.animated_sprite.sprite_frames.has_animation(&"ko"):
		combat.fighter.animated_sprite.play(&"ko")
		var final_frame := combat.fighter.animated_sprite.sprite_frames.get_frame_count(&"ko") - 1
		combat.fighter.animated_sprite.frame = clampi(start_frame, 0, final_frame)
	combat.knocked_out.emit()
	print("KO!")


static func _is_active(combat: Variant) -> bool:
	return is_instance_valid(combat) and is_instance_valid(combat.fighter)
