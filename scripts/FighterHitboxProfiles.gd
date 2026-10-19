extends RefCounted

## Rettangoli calibrati nel canvas del singolo fotogramma, indipendenti da
## scala, facing, alias/reverse dell'animazione e posizione del personaggio.
const Catalog := preload("res://data/hitboxes/AttackHitboxData.gd")


static func get_profile(sprite: AnimatedSprite2D) -> Array:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame) as AtlasTexture
	if texture == null or texture.atlas == null:
		return []
	var sheet: Dictionary = Catalog.SHEETS.get(texture.atlas.resource_path, {})
	var region := texture.region
	var key := "%d,%d,%d,%d" % [region.position.x, region.position.y, region.size.x, region.size.y]
	return sheet.get(key, [])


static func apply(combat: FighterCombat) -> bool:
	var sprite := combat.fighter.animated_sprite
	var profile := get_profile(sprite)
	if profile.is_empty():
		return false
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var point := Vector2(profile[0], profile[1])
	if sprite.centered:
		point -= texture.get_size() * 0.5
	var direction := Vector2.RIGHT.rotated(deg_to_rad(profile[4]))
	var perpendicular := direction.orthogonal()
	if sprite.flip_h:
		point.x = -point.x
		direction.x = -direction.x
		perpendicular.x = -perpendicular.x
	if sprite.flip_v:
		point.y = -point.y
		direction.y = -direction.y
		perpendicular.y = -perpendicular.y
	point += sprite.offset
	var sprite_to_hitbox := combat.hitbox.global_transform.affine_inverse() * sprite.global_transform
	var center := sprite_to_hitbox * point
	# Transform the basis directly: subtracting nearby world positions introduces
	# visible size jitter when a fighter is far along a large stage.
	var x_axis := sprite_to_hitbox.x * direction.x + sprite_to_hitbox.y * direction.y
	var y_axis := sprite_to_hitbox.x * perpendicular.x + sprite_to_hitbox.y * perpendicular.y
	var rectangle := combat.hitbox_shape.shape as RectangleShape2D
	rectangle.size = Vector2(profile[2] * x_axis.length(), profile[3] * y_axis.length())
	combat.hitbox_shape.position = center
	combat.hitbox_shape.rotation = x_axis.angle()
	return true
