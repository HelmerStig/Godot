extends Node2D

## Overlay provvisorio per verificare collisioni, hurtbox e hitbox attive.

@onready var fighter := get_parent() as Fighter
var hurtbox_shapes: Array[CollisionShape2D] = []


func _ready():
	var hurtbox_area := fighter.get_node("Hurtbox") as Area2D
	for child in hurtbox_area.get_children():
		if child is CollisionShape2D:
			hurtbox_shapes.append(child)


func _process(_delta):
	queue_redraw()


func _draw():
	if fighter == null or not fighter.show_debug_boxes:
		return

	# Corpo fisico: blu.
	draw_collision_box(fighter.collision_shape, Vector2.ONE, Color(0.1, 0.55, 1.0, 0.12), Color(0.2, 0.7, 1.0, 0.9))
	# Zone vulnerabili: rosse.
	for hurtbox_shape in hurtbox_shapes:
		draw_collision_box(hurtbox_shape, Vector2.ONE, Color(1.0, 0.15, 0.15, 0.12), Color(1.0, 0.25, 0.25, 0.9))
	# Zona offensiva: verde, visibile soltanto durante i frame attivi.
	if fighter.combat.hitbox_shape and not fighter.combat.hitbox_shape.disabled:
		draw_collision_box(
			fighter.combat.hitbox_shape,
			fighter.combat.hitbox.scale,
			Color(0.2, 1.0, 0.25, 0.28),
			Color(0.3, 1.0, 0.35, 1.0)
		)


func draw_collision_box(shape_node: CollisionShape2D, box_scale: Vector2, fill_color: Color, outline_color: Color):
	if shape_node == null:
		return
	var rectangle = shape_node.shape as RectangleShape2D
	if rectangle == null:
		return

	var size = rectangle.size * box_scale.abs()
	var center = shape_node.position * box_scale
	var box = Rect2(center - size * 0.5, size)
	draw_rect(box, fill_color, true)
	draw_rect(box, outline_color, false, 2.0)
