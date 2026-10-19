extends Node

## Audio comune ai sei attacchi base, indipendente dalla variante di posizione.
const SOUNDS := {
	&"light_punch": [preload("res://sound-libraries/punch_short_whoosh_30.wav"), preload("res://assets/sounds/sfx/light-punch.wav")],
	&"medium_punch": [preload("res://assets/sounds/sfx/swosh.wav"), preload("res://assets/sounds/sfx/light-punch.wav")],
	&"heavy_punch": [preload("res://assets/sounds/sfx/swosh.wav"), preload("res://assets/sounds/sfx/strong-punch.wav")],
	&"light_kick": [preload("res://sound-libraries/kick_short_whoosh_12.wav"), preload("res://sound-libraries/body_hit_small_11.wav")],
	&"medium_kick": [preload("res://sound-libraries/kick_short_whoosh_23.wav"), preload("res://sound-libraries/body_hit_large_44.wav")],
	&"heavy_kick": [preload("res://sound-libraries/kick_long_whoosh_19.wav"), preload("res://sound-libraries/body_hit_large_76.wav")],
}

var whoosh_players: Dictionary = {}
var hit_players: Dictionary = {}
var _combat: FighterCombat
var _active_attack: StringName = &""
var _last_attack: StringName = &""
var _generation := -1
var _hit_played := false


func setup(combat: FighterCombat) -> void:
	_combat = combat
	for attack_name in SOUNDS:
		var whoosh := AudioStreamPlayer.new()
		whoosh.name = String(attack_name) + "Whoosh"
		whoosh.stream = SOUNDS[attack_name][0]
		whoosh.volume_db = -4.0
		add_child(whoosh)
		whoosh_players[attack_name] = whoosh
		var hit := AudioStreamPlayer.new()
		hit.name = String(attack_name) + "Hit"
		hit.stream = SOUNDS[attack_name][1]
		hit.volume_db = -3.0 if attack_name == &"heavy_punch" else (-5.0 if attack_name == &"heavy_kick" else -7.0)
		add_child(hit)
		hit_players[attack_name] = hit
	combat.attack_started.connect(_on_attack_started)
	combat.attack_connected.connect(_on_attack_connected)
	combat.attack_cancelled.connect(_stop_whooshes)
	combat.attack_finished.connect(_stop_whooshes)
	combat.fighter.state_changed.connect(_on_state_changed)


func _on_attack_started(attack_name: StringName) -> void:
	_stop_whooshes()
	if not whoosh_players.has(attack_name):
		return
	_active_attack = attack_name
	_last_attack = attack_name
	_generation = _combat.action_generation
	_hit_played = false
	whoosh_players[attack_name].play()


func _on_attack_connected(attack_name: StringName, result: int) -> void:
	# A knockout can synchronously end the round and cancel the winning attack
	# before FighterCombat emits attack_connected for that same contact.
	var knockout_contact := result == FighterCombat.DamageResult.KNOCKOUT and attack_name == _last_attack
	var active_contact := attack_name == _active_attack and _combat.is_attacking and _generation == _combat.action_generation
	if _hit_played or not (active_contact or knockout_contact):
		return
	if result in [FighterCombat.DamageResult.HIT, FighterCombat.DamageResult.KNOCKOUT]:
		_hit_played = true
		hit_players[attack_name].play()


func _on_state_changed(_previous: int, next: int) -> void:
	if next != Fighter.State.ATTACKING:
		_stop_whooshes()


func _stop_whooshes() -> void:
	_active_attack = &""
	for player in whoosh_players.values():
		player.stop()


func reset() -> void:
	_stop_whooshes()
	_last_attack = &""
	_hit_played = false
	for player in hit_players.values():
		player.stop()
