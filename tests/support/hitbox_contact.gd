extends RefCounted

const Profiles := preload("res://scripts/FighterHitboxProfiles.gd")

## Previsione geometrica indipendente dal risultato del danno. I test di
## reazione devono aspettarsi un whiff quando l'arto non raggiunge la hurtbox,
## anziché dipendere dalle vecchie dimensioni generiche delle hitbox.
static func will_connect(fighter: Fighter, target: Fighter, animation: StringName, first: int, last: int) -> bool:
	if fighter.combat.current_attack == null:
		return false
	if fighter.combat.get_effective_hit_height(fighter.combat.current_attack) == AttackData.HitHeight.HIGH and fighter.combat.get_current_variant_id() == &"standing" and target.get_crouch_progress() >= 0.5:
		return false
	var source := fighter.animated_sprite
	var preview := AnimatedSprite2D.new()
	preview.sprite_frames = source.sprite_frames
	preview.animation = animation
	var rectangle := RectangleShape2D.new()
	var hit := false
	for frame in range(first-1,last):
		preview.frame = frame
		var spec := Profiles.get_profile(preview)
		var transform := fighter.combat.hitbox_shape.global_transform
		if spec.is_empty():
			rectangle.size = fighter.combat.hitbox_shape.shape.size
		else:
			var texture := source.sprite_frames.get_frame_texture(animation,frame)
			var center := Vector2(spec[0],spec[1]) - (texture.get_size()*0.5 if source.centered else Vector2.ZERO)
			var axis := Vector2.RIGHT.rotated(deg_to_rad(spec[4]))
			var perpendicular := Vector2(-axis.y,axis.x)
			if source.flip_h:
				center.x = -center.x
				axis.x = -axis.x
				perpendicular.x = -perpendicular.x
			if source.flip_v:
				center.y = -center.y
				axis.y = -axis.y
				perpendicular.y = -perpendicular.y
			rectangle.size = Vector2(spec[2],spec[3])
			transform = source.global_transform * Transform2D(axis,perpendicular,center+source.offset)
		for vulnerable in [target.head_hurtbox,target.torso_hurtbox,target.legs_hurtbox]:
			if not vulnerable.disabled and rectangle.collide(transform,vulnerable.shape,vulnerable.global_transform):
				hit = true
	preview.free()
	return hit
