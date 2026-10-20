extends Node

const TITLE := "res://scenes/TitleScreen.tscn"
const CHARACTER_SELECT := "res://scenes/CharacterSelect.tscn"
const LOADING := "res://scenes/LoadingScreen.tscn"
const GAME := "res://scenes/MainArena.tscn"
const FALLBACKS := {
	CHARACTER_SELECT: TITLE,
	LOADING: CHARACTER_SELECT,
	"res://scenes/MovementTest.tscn": TITLE,
}

var _history: Array[String] = []
var _current_path := ""
var _returning_to := ""


func _ready() -> void:
	get_tree().scene_changed.connect(_sync_scene)
	_sync_scene()


func _sync_scene() -> void:
	var scene := get_tree().current_scene
	if scene != null:
		_remember_scene(scene.scene_file_path)


func _remember_scene(path: String) -> void:
	if path.is_empty() or path == _current_path:
		return
	if path == _returning_to:
		_returning_to = ""
	elif path == TITLE:
		_history.clear()
	elif not _current_path.is_empty():
		_history.append(_current_path)
	_current_path = path


func previous_scene_path() -> String:
	if _current_path == TITLE or _current_path == GAME:
		return ""
	if not _history.is_empty():
		return _history[-1]
	return FALLBACKS.get(_current_path,"")


func _input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed(&"menu_back"):
		return
	_sync_scene()
	if _current_path == GAME or get_tree().current_scene == null:
		return
	get_viewport().set_input_as_handled()
	go_back()


func go_back() -> Error:
	var path := previous_scene_path()
	if path.is_empty() or not _returning_to.is_empty():
		return OK
	var scene := get_tree().current_scene
	var was_processing := false
	# Stop the loader immediately, before its next process tick can enter combat.
	if is_instance_valid(scene) and _current_path == LOADING:
		was_processing = scene.is_processing()
		scene.set_process(false)
	_returning_to = path
	var error := _open_scene(path)
	if error == OK:
		if not _history.is_empty():
			_history.pop_back()
	else:
		_returning_to = ""
		if is_instance_valid(scene) and _current_path == LOADING:
			scene.set_process(was_processing)
	return error


func _open_scene(path: String) -> Error:
	return get_tree().change_scene_to_file(path)
