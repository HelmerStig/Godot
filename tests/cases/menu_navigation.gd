extends RefCounted

class SelectionStub:
	extends "res://scripts/CharacterSelect.gd"
	var launch_count := 0
	func _check_start() -> void:
		if p1_confirmed and p2_confirmed:
			launch_count += 1

class NavigationStub:
	extends "res://scripts/ScreenNavigation.gd"
	var destination := ""
	var result: Error = OK
	func _ready() -> void:
		pass
	func _open_scene(path: String) -> Error:
		destination = path
		return result

static func action(name: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	return event

static func button(device: int, index: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = index
	event.pressed = true
	return event

static func run(tree: SceneTree, expect: Callable) -> bool:
	var selection := SelectionStub.new()
	tree.root.add_child(selection)
	for index in 7:
		var down := mini((1-index/4)*4 + index%4,6)
		var up := down # Two rows: both directions wrap to the other row.
		expect.call(selection._navigated_index(index,Vector2i.DOWN) == down,"Griglia: giu da %d salta di riga senza celle vuote" % index)
		expect.call(selection._navigated_index(index,Vector2i.UP) == up,"Griglia: su da %d salta di riga senza celle vuote" % index)
	for player in [1,2]:
		selection.p1_confirmed = false
		selection.p2_confirmed = false
		selection.p1_index = 0
		selection.p2_index = 0
		selection.p1_nav_cooldown = 0
		selection.p2_nav_cooldown = 0
		var prefix := "p%d_" % player
		selection._unhandled_input(action(prefix+"crouch"))
		expect.call((selection.p1_index if player == 1 else selection.p2_index) == 4,"P%d scende nella riga inferiore" % player)
		selection._unhandled_input(action(prefix+"jump"))
		expect.call((selection.p1_index if player == 1 else selection.p2_index) == 4,"P%d rispetta cooldown tra input" % player)
		selection._process(.23)
		selection._unhandled_input(action(prefix+"jump"))
		expect.call((selection.p1_index if player == 1 else selection.p2_index) == 0,"P%d risale nella riga superiore" % player)
		selection._unhandled_input(action(prefix+"light_kick"))
		expect.call(selection.p1_confirmed if player == 1 else selection.p2_confirmed,"P%d LK conferma" % player)
		selection._process(.23)
		selection._unhandled_input(action(prefix+"move_right"))
		expect.call((selection.p1_index if player == 1 else selection.p2_index) == 0,"P%d confermato non si sposta" % player)
		selection._unhandled_input(action(prefix+"medium_kick"))
		expect.call(not (selection.p1_confirmed if player == 1 else selection.p2_confirmed),"P%d MK annulla conferma" % player)
		selection._unhandled_input(action(prefix+"move_right"))
		expect.call((selection.p1_index if player == 1 else selection.p2_index) == 1,"P%d dopo MK puo scegliere di nuovo" % player)
	# Real joypad bindings must remain separate despite Godot's shared ui_accept.
	selection.p1_confirmed = false
	selection.p2_confirmed = false
	selection._unhandled_input(button(1,JOY_BUTTON_A))
	expect.call(selection.p2_confirmed and not selection.p1_confirmed,"Joypad P2 LK non conferma anche P1")
	selection._unhandled_input(button(0,JOY_BUTTON_A))
	expect.call(selection.p1_confirmed and selection.p2_confirmed and selection.launch_count == 1,"Entrambi LK avviano una sola selezione completa")
	selection._unhandled_input(button(1,JOY_BUTTON_B))
	expect.call(selection.p1_confirmed and not selection.p2_confirmed,"Joypad P2 MK annulla solo P2")
	selection._unhandled_input(button(0,JOY_BUTTON_B))
	expect.call(not selection.p1_confirmed,"Joypad P1 MK annulla P1")
	selection.p1_nav_cooldown = 0
	selection.p2_nav_cooldown = 0
	selection.p1_index = 0
	selection.p2_index = 0
	selection._unhandled_input(button(1,JOY_BUTTON_DPAD_DOWN))
	expect.call(selection.p2_index == 4 and selection.p1_index == 0,"Dpad P2 giu muove solo P2")
	var stick := InputEventJoypadMotion.new()
	stick.device = 0
	stick.axis = JOY_AXIS_LEFT_Y
	stick.axis_value = 1.0
	selection._unhandled_input(stick)
	expect.call(selection.p1_index == 4,"Stick P1 verticale naviga nella griglia")
	var navigation := NavigationStub.new()
	tree.root.add_child(navigation)
	for device in [0,1,3]:
		expect.call(button(device,JOY_BUTTON_BACK).is_action_pressed("menu_back"),"Select mappato per controller %d" % device)
	expect.call(not button(0,JOY_BUTTON_B).is_action_pressed("menu_back"),"MK e Select rimangono distinti")
	navigation._remember_scene(navigation.TITLE)
	expect.call(navigation.previous_scene_path().is_empty(),"Titolo senza schermata precedente resta al titolo")
	navigation._remember_scene(navigation.CHARACTER_SELECT)
	expect.call(navigation.previous_scene_path() == navigation.TITLE,"Selezione torna al titolo")
	navigation._remember_scene(navigation.LOADING)
	expect.call(navigation.previous_scene_path() == navigation.CHARACTER_SELECT,"Loading torna alla selezione")
	navigation.go_back()
	expect.call(navigation.destination == navigation.CHARACTER_SELECT,"Indietro richiede scena precedente")
	navigation._remember_scene(navigation.CHARACTER_SELECT)
	expect.call(navigation.previous_scene_path() == navigation.TITLE,"Indietro non crea un ciclo nel percorso")
	navigation.result = ERR_CANT_OPEN
	navigation.go_back()
	expect.call(navigation.previous_scene_path() == navigation.TITLE and navigation._returning_to.is_empty(),"Errore cambio scena mantiene cronologia e permette riprova")
	navigation._remember_scene(navigation.GAME)
	expect.call(navigation.previous_scene_path().is_empty(),"Combattimento esclude il ritorno con Select")
	navigation._remember_scene("res://scenes/MovementTest.tscn")
	expect.call(navigation.previous_scene_path() == navigation.GAME,"Finestra test conserva la schermata da cui e stata aperta")
	selection.queue_free()
	navigation.queue_free()
	await tree.process_frame
	# Real transitions verify that loading cannot proceed to the arena after Select.
	tree.change_scene_to_file("res://scenes/TitleScreen.tscn")
	await tree.scene_changed
	tree.change_scene_to_file("res://scenes/CharacterSelect.tscn")
	await tree.scene_changed
	Input.parse_input_event(button(1,JOY_BUTTON_BACK))
	await tree.scene_changed
	expect.call(tree.current_scene.scene_file_path == "res://scenes/TitleScreen.tscn","Select P2 torna realmente dalla selezione al titolo")
	tree.change_scene_to_file("res://scenes/CharacterSelect.tscn")
	await tree.scene_changed
	Input.parse_input_event(button(0,JOY_BUTTON_A))
	for tick in 2:
		await tree.process_frame
	expect.call(tree.current_scene.p1_confirmed and not tree.current_scene.p2_confirmed,"Prima conferma reale resta nella selezione")
	Input.parse_input_event(button(1,JOY_BUTTON_A))
	await tree.scene_changed
	expect.call(tree.current_scene.scene_file_path == "res://scenes/LoadingScreen.tscn","Seconda conferma reale apre Loading senza accedere al viewport della scena rimossa")
	Input.parse_input_event(button(0,JOY_BUTTON_BACK))
	await tree.scene_changed
	expect.call(tree.current_scene.scene_file_path == "res://scenes/CharacterSelect.tscn","Select annulla Loading e torna alla selezione")
	for tick in 3:
		await tree.process_frame
	expect.call(tree.current_scene.scene_file_path == "res://scenes/CharacterSelect.tscn","Il loader annullato non apre l'arena in ritardo")
	# Finish the worker before the test process exits; the app normally stays open.
	var loaded := ResourceLoader.load_threaded_get("res://scenes/MainArena.tscn")
	expect.call(loaded is PackedScene,"Caricamento annullato puo completare senza cambiare schermata")
	# Repeat with player 2 confirming first, and allow loading to reach combat.
	Input.parse_input_event(button(1,JOY_BUTTON_A))
	for tick in 2:
		await tree.process_frame
	expect.call(tree.current_scene.p2_confirmed and not tree.current_scene.p1_confirmed,"P2 puo confermare per primo")
	Input.parse_input_event(button(0,JOY_BUTTON_A))
	await tree.scene_changed
	expect.call(tree.current_scene.scene_file_path == "res://scenes/LoadingScreen.tscn","Conferma finale P1 apre Loading")
	await tree.scene_changed
	expect.call(tree.current_scene.scene_file_path == "res://scenes/MainArena.tscn","Entrambe le conferme reali completano il percorso fino al combattimento")
	Input.parse_input_event(button(0,JOY_BUTTON_BACK))
	for tick in 3:
		await tree.process_frame
	expect.call(tree.current_scene.scene_file_path == "res://scenes/MainArena.tscn","Select durante combattimento non cambia scena")
	tree.unload_current_scene()
	await tree.process_frame
	return true
