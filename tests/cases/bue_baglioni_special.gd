extends RefCounted
const Shared := preload("res://tests/cases/bue_singer_special.gd")

static func run(tree: SceneTree, expect: Callable) -> bool:
	return await Shared.run(tree,expect,2)
