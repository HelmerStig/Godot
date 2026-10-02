extends RefCounted


class LoadingStub:
	extends "res://scripts/LoadingScreen.gd"

	var request_result: Error = OK
	var load_status := ResourceLoader.THREAD_LOAD_IN_PROGRESS
	var loaded_resource: Resource
	var scene_result: Error = OK
	var request_count := 0
	var arena_open_count := 0
	var title_open_count := 0

	func _request_arena_load() -> Error:
		request_count += 1
		return request_result

	func _get_arena_load_status() -> int:
		return load_status

	func _get_loaded_arena() -> Resource:
		return loaded_resource

	func _open_arena(_packed: PackedScene) -> Error:
		arena_open_count += 1
		return scene_result

	func _open_title() -> Error:
		title_open_count += 1
		return scene_result


static func run(tree: SceneTree, expect: Callable) -> bool:
	print("-- Loading screen failure and recovery")
	var screen := LoadingStub.new()
	screen.request_result = ERR_CANT_OPEN
	tree.root.add_child(screen)
	screen.set_process(false)
	expect.call(
		screen.loading_failed and screen.error_panel.visible and not screen.loading_label.visible,
		"un errore iniziale mostra le azioni di recupero invece di LOADING"
	)
	await tree.process_frame
	expect.call(screen.retry_button.has_focus(), "il recupero riceve il focus per tastiera e gamepad")
	screen._process(1.0)
	expect.call(screen.arena_open_count == 0, "un caricamento fallito non tenta di aprire l'arena")

	screen.request_result = OK
	screen.retry_button.pressed.emit()
	expect.call(
		screen.request_count == 2 and not screen.loading_failed and not screen.loading_done
		and not screen.error_panel.visible and screen.loading_label.visible
		and screen.loading_label.text == "LOADING",
		"riprova avvia una nuova richiesta e ripristina la schermata di caricamento"
	)
	screen._process(0.5)
	expect.call(
		not screen.loading_failed and screen.loading_label.text == "LOADING.",
		"un caricamento in corso continua ad animare il messaggio"
	)

	for status in [ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:
		screen._start_loading()
		screen.load_status = status
		screen._process(0.0)
		expect.call(screen.loading_failed and screen.error_panel.visible, "stato loader %d mostra il recupero" % status)

	screen.load_status = ResourceLoader.THREAD_LOAD_LOADED
	for invalid_resource in [null, Resource.new(), PackedScene.new()]:
		screen._start_loading()
		screen.loaded_resource = invalid_resource
		screen._process(0.0)
		expect.call(
			screen.loading_failed and screen.arena_open_count == 0,
			"una risorsa nulla, errata o senza scena non viene aperta"
		)

	var packed := PackedScene.new()
	var arena := Node2D.new()
	packed.pack(arena)
	arena.free()
	screen.loaded_resource = packed
	screen.scene_result = ERR_CANT_CREATE
	screen._start_loading()
	screen._process(0.0)
	expect.call(
		screen.loading_failed and not screen.loading_done and screen.arena_open_count == 1,
		"un errore nel cambio scena mantiene disponibili le azioni di recupero"
	)
	screen.error_panel.get_child(2).pressed.emit()
	expect.call(
		screen.title_open_count == 1 and screen.loading_failed,
		"il pulsante titolo tenta il ritorno e gestisce un eventuale errore"
	)
	screen.scene_result = OK
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	screen._unhandled_input(cancel)
	expect.call(screen.title_open_count == 2, "Escape o annulla del gamepad torna al titolo dopo un errore")

	screen.retry_button.pressed.emit()
	screen._process(0.0)
	expect.call(
		screen.loading_done and not screen.loading_failed and screen.arena_open_count == 2,
		"riprova apre correttamente una scena valida"
	)
	screen._process(1.0)
	expect.call(screen.arena_open_count == 2, "il cambio scena riuscito viene eseguito una sola volta")
	screen.queue_free()
	await tree.process_frame
	return true
