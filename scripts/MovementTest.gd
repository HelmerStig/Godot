extends Node2D

const FLOOR_Y := 600.0
const STAGE_LEFT := 100.0
const STAGE_RIGHT := 2200.0
const FIGHTER_SPACING := 380.0
const CAMERA_Y_OFFSET := -260.0
const CAMERA_ZOOM := Vector2(0.5, 0.5)

var _fighters: Array = []
var _entries: Array = []
var _name_labels: Array = []
var _camera: Camera2D
var _hint_label: Label
var _dummy_opponent: Fighter
var _block_mode := 0  # 0=off  1=high  2=low


func _ready() -> void:
	_build_background()
	_build_floor()
	_spawn_fighters()
	_create_dummy_opponent()
	_build_camera()
	_build_hud()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.z_index = -10
	bg.position = Vector2(-200.0, -300.0)
	bg.size = Vector2(STAGE_RIGHT + 400.0, 1000.0)
	bg.color = Color(0.06, 0.06, 0.10)
	add_child(bg)


func _build_floor() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Fighter.GROUND_COLLISION_LAYER
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(STAGE_RIGHT - STAGE_LEFT + 400.0, 60.0)
	shape.shape = rect
	shape.position = Vector2((STAGE_LEFT + STAGE_RIGHT) / 2.0, FLOOR_Y + 30.0)
	body.add_child(shape)
	add_child(body)
	var vis := ColorRect.new()
	vis.z_index = -1
	vis.color = Color(0.22, 0.22, 0.30)
	vis.position = Vector2(STAGE_LEFT - 200.0, FLOOR_Y)
	vis.size = Vector2(STAGE_RIGHT - STAGE_LEFT + 400.0, 60.0)
	add_child(vis)


func _spawn_fighters() -> void:
	var valid: Array = []
	for e in CharacterSelection.ROSTER:
		if e["scene"] != "":
			valid.append(e)
	var count := valid.size()
	if count == 0:
		return
	var start_x := (STAGE_LEFT + STAGE_RIGHT) / 2.0 - (count - 1) * FIGHTER_SPACING / 2.0
	for i in count:
		var packed := load(valid[i]["scene"]) as PackedScene
		if packed == null:
			continue
		var fighter := packed.instantiate() as Fighter
		if fighter == null:
			continue
		fighter.player_number = 1
		fighter.is_player_controlled = true
		add_child(fighter)
		fighter.reset_fighter(Vector2(start_x + i * FIGHTER_SPACING, FLOOR_Y))
		if not fighter.is_facing_right:
			fighter.flip_character()
		fighter.stage_left_limit = STAGE_LEFT
		fighter.stage_right_limit = STAGE_RIGHT
		_fighters.append(fighter)
		_entries.append(valid[i])


func _create_dummy_opponent() -> void:
	var first_scene := ""
	for e in CharacterSelection.ROSTER:
		if e["scene"] != "":
			first_scene = e["scene"]
			break
	if first_scene == "":
		return
	var packed := load(first_scene) as PackedScene
	if packed == null:
		return
	_dummy_opponent = packed.instantiate() as Fighter
	if _dummy_opponent == null:
		return
	_dummy_opponent.player_number = 2
	_dummy_opponent.is_player_controlled = false
	_dummy_opponent.controls_enabled = false
	add_child(_dummy_opponent)
	_dummy_opponent.set_physics_process(false)
	_dummy_opponent.global_position = Vector2(STAGE_RIGHT + 500.0, FLOOR_Y)
	_dummy_opponent.visible = false
	for f in _fighters:
		(f as Fighter).opponent = _dummy_opponent


func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.name = "Camera2D"
	_camera.zoom = CAMERA_ZOOM
	_camera.position_smoothing_enabled = false
	_camera.position = _fighters_center() + Vector2(0.0, CAMERA_Y_OFFSET)
	add_child(_camera)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_hint_label = Label.new()
	_hint_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.offset_top = 10.0
	_hint_label.offset_bottom = 40.0
	_hint_label.add_theme_font_size_override("font_size", 18)
	_update_hint_text()
	layer.add_child(_hint_label)

	for i in _fighters.size():
		var lbl := Label.new()
		lbl.text = _entries[i]["label"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(150.0, 30.0)
		lbl.add_theme_font_size_override("font_size", 20)
		_name_labels.append(lbl)
		layer.add_child(lbl)


func _update_hint_text() -> void:
	if _hint_label == null:
		return
	match _block_mode:
		1:
			_hint_label.text = "[ BLOCK HIGH ]   ·   Tab: basso   ·   F3: hitbox   ·   F2: titolo"
			_hint_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
		2:
			_hint_label.text = "[ BLOCK LOW ]   ·   Tab: disattiva   ·   F3: hitbox   ·   F2: titolo"
			_hint_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
		_:
			_hint_label.text = "MOVEMENT TEST   ·   Tab: block   ·   H: hurt_high   ·   F3: hitbox   ·   F2: titolo"
			_hint_label.remove_theme_color_override("font_color")


func _fighters_center() -> Vector2:
	if _fighters.is_empty():
		return Vector2((STAGE_LEFT + STAGE_RIGHT) / 2.0, FLOOR_Y)
	var sum := Vector2.ZERO
	for f in _fighters:
		if is_instance_valid(f):
			sum += (f as Fighter).global_position
	return sum / _fighters.size()


func _physics_process(_delta: float) -> void:
	if _block_mode == 0:
		return
	var v_axis := 1 if _block_mode == 2 else 0  # down per il blocco basso
	var block_height := (
		AttackData.HitHeight.LOW if _block_mode == 2 else AttackData.HitHeight.HIGH
	)
	for f in _fighters:
		var fighter := f as Fighter
		if not is_instance_valid(fighter):
			continue
		# Inietta la direzione nel buffer prima che il fighter legga l'input.
		fighter.input_buffer.record_input_snapshot(-1, v_axis, [], true)
		# Forza is_blocking=true per i fighter che lo leggono via update_state (es. Mangler).
		fighter.combat.set_guarding(true)
		if fighter.current_state not in [
			Fighter.State.BLOCKING, Fighter.State.BLOCK_RECOVERY, Fighter.State.ATTACKING
		]:
			fighter.received_block_height = block_height
			fighter.block_started_crouched = false
			fighter.change_state(Fighter.State.BLOCKING)
		elif fighter.current_state == Fighter.State.BLOCKING:
			# change_state stesso-stato chiama update_animation, aggiornando l'animazione.
			fighter.received_block_height = block_height
			fighter.block_started_crouched = false
			fighter.change_state(Fighter.State.BLOCKING)


func _process(_delta: float) -> void:
	if _fighters.is_empty():
		return
	_camera.position = _fighters_center() + Vector2(0.0, CAMERA_Y_OFFSET)
	var ct := get_viewport().get_canvas_transform()
	for i in _fighters.size():
		if i >= _name_labels.size():
			break
		var f := _fighters[i] as Fighter
		if is_instance_valid(f):
			var world_pos := f.global_position + Vector2(-75.0, 50.0)
			_name_labels[i].position = ct * world_pos


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_boxes"):
		var show := not (_fighters.is_empty() or (_fighters[0] as Fighter).show_debug_boxes)
		for f in _fighters:
			(f as Fighter).show_debug_boxes = show
			(f as Fighter).queue_redraw()
	elif event is InputEventKey and event.keycode == KEY_TAB and event.pressed and not event.echo:
		_block_mode = (_block_mode + 1) % 3
		var active := _block_mode != 0
		if is_instance_valid(_dummy_opponent):
			_dummy_opponent.combat.is_attacking = active
		for f in _fighters:
			var fighter := f as Fighter
			if not is_instance_valid(fighter):
				continue
			fighter.is_player_controlled = not active
			if not active:
				fighter.combat.set_guarding(false)
				fighter.input_buffer.clear()
				fighter.change_state(Fighter.State.IDLE)
		_update_hint_text()
	elif event is InputEventKey and event.keycode == KEY_H and event.pressed and not event.echo:
		for f in _fighters:
			var fighter := f as Fighter
			if not is_instance_valid(fighter):
				continue
			fighter.start_hit_reaction(AttackData.HitHeight.HIGH, null, 0, false)
			# IdleRosterFighter usa _on_animation_finished; Arianna/Mangler usano questo timer.
			get_tree().create_timer(2.0).timeout.connect(func():
				if is_instance_valid(fighter) and fighter.current_state == Fighter.State.HIT:
					fighter.change_state(Fighter.State.IDLE)
			)
	elif event is InputEventKey and event.keycode == KEY_F2 and event.pressed and not event.echo:
		get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
