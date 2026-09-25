extends Node

const ROSTER: Array = [
	{"id": "arianna", "label": "Arianna", "scene": "res://scenes/Arianna.tscn"},
	{"id": "mangler", "label": "Mangler", "scene": "res://scenes/Mangler.tscn"},
	{"id": "bue", "label": "Bue", "scene": ""},
	{"id": "peiro", "label": "Peirò", "scene": ""},
	{"id": "oscare", "label": "Oscare", "scene": ""},
	{"id": "torpe", "label": "Torpe", "scene": ""},
	{"id": "mileto", "label": "Mileto", "scene": ""},
]

var player1_id := "arianna"
var player2_id := "mangler"


func get_scene_for(id: String) -> String:
	for entry in ROSTER:
		if entry["id"] == id:
			return entry["scene"]
	return ROSTER[0]["scene"]


func get_label_for(id: String) -> String:
	for entry in ROSTER:
		if entry["id"] == id:
			return entry["label"]
	return ROSTER[0]["label"]
