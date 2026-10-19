extends Node2D
class_name OscareSmokeBreathProjectile

const SHEET := preload("res://assets/sprites/characters/oscare/special_2_smoke_candidate.png")
const Hulls := preload("res://data/hitboxes/OscareSmokeHitboxData.gd")
const Impact := preload("res://scripts/OscareCigaretteProjectile.gd")
const Reactions := preload("res://scripts/FighterCombatReactions.gd")
const FRAME_COUNT := 26
const START_FRAME := 20 # Fighter visual frame 21.
const OUTLET := Vector2(23,256)
const SIZE_RATIO := 0.7
const HURT_REPEAT_FRAMES := 6 # 100 ms on the 60 FPS smoke timeline.

var source_fighter: Fighter
var facing_right := true
var sprite: AnimatedSprite2D
var hit_shape := ConvexPolygonShape2D.new()
var hit_targets: Array[Fighter] = []
var active := false
var _last_hurt_frame: Dictionary = {}


func setup(fighter: Fighter, direction_right: bool) -> void:
	source_fighter = fighter
	facing_right = direction_right


func _ready() -> void:
	add_to_group("oscare_smoke_projectile")
	z_index = 10
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"breath")
	frames.set_animation_speed(&"breath", 60.0)
	frames.set_animation_loop(&"breath", false)
	for index in FRAME_COUNT:
		var texture := AtlasTexture.new()
		texture.atlas = SHEET
		texture.region = Rect2(index%7*512,index/7*512,512,512)
		frames.add_frame(&"breath",texture)
	sprite.sprite_frames = frames
	sprite.animation = &"breath"
	add_child(sprite)
	sync_from_fighter()


func sync_from_fighter() -> void:
	active = false
	if not is_instance_valid(source_fighter) or not source_fighter.controls_enabled or source_fighter.get("smoke_special_active") != true or source_fighter.current_state != Fighter.State.ATTACKING:
		queue_free()
		return
	var index := source_fighter.animated_sprite.frame - START_FRAME
	if index < 0 or index >= FRAME_COUNT:
		queue_free()
		return
	global_position = source_fighter.call(&"get_smoke_mouth_global_position")
	global_scale = Vector2.ONE
	var art_scale := source_fighter.animated_sprite.global_scale.abs() * SIZE_RATIO
	var sign_x := 1.0 if facing_right else -1.0
	sprite.scale = art_scale
	sprite.flip_h = not facing_right
	sprite.position = Vector2((256.0-OUTLET.x)*art_scale.x*sign_x, (256.0-OUTLET.y)*art_scale.y)
	sprite.frame = index
	# Drive the smoke from the fighter's frame instead of a second drifting clock.
	sprite.pause()
	modulate.a = minf(minf(float(index+1)/3.0,float(FRAME_COUNT-index)/6.0),1.0)
	var points := PackedVector2Array()
	for point: Vector2 in Hulls.POLYGONS[index]:
		points.append((point-OUTLET)*art_scale*Vector2(sign_x,1))
	hit_shape.points = points
	active = modulate.a >= 0.25


func _physics_process(_delta: float) -> void:
	sync_from_fighter()
	if not active or is_queued_for_deletion():
		return
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hit_shape
	query.transform = global_transform
	query.collision_mask = 4
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for contact in get_world_2d().direct_space_state.intersect_shape(query,32):
		var area := contact["collider"] as Area2D
		if area != null:
			_hit_area(area)


func _hit_area(area: Area2D) -> void:
	if not active or is_queued_for_deletion() or not area.is_in_group("hurtbox"):
		return
	var target := area.get_parent() as Fighter
	if target == null or target == source_fighter:
		return
	var crouched := target.get_crouch_progress() >= 0.5 or target.is_holding_low_guard()
	if hit_targets.has(target):
		_refresh_standing_hurt(target, crouched)
		return
	var guard_height := AttackData.HitHeight.LOW if crouched else AttackData.HitHeight.MID
	var hurt_height := AttackData.HitHeight.LOW if crouched else AttackData.HitHeight.MID
	var result := target.combat.take_damage(Impact.DAMAGE,source_fighter,0.3,0.18,guard_height,false,0,0,true,false,hurt_height,Impact.IMPACT_COLOR)
	if result != FighterCombat.DamageResult.IGNORED:
		hit_targets.append(target)
		if result == FighterCombat.DamageResult.HIT and not crouched and target.is_on_floor():
			_last_hurt_frame[target.get_instance_id()] = sprite.frame


func _refresh_standing_hurt(target: Fighter, crouched: bool) -> void:
	var id := target.get_instance_id()
	if (
		not _last_hurt_frame.has(id) or crouched or not target.is_on_floor()
		or not target.controls_enabled or target.combat.current_health <= 0
		or target.current_state in [Fighter.State.KNOCKED_DOWN, Fighter.State.KNOCKDOWN_RECOVERY, Fighter.State.BLOCKING, Fighter.State.BLOCK_RECOVERY]
		or sprite.frame - int(_last_hurt_frame[id]) < HURT_REPEAT_FRAMES
	):
		return
	_last_hurt_frame[id] = sprite.frame
	# Refresh only the reaction and its generation-protected hitstun. The move
	# still deals damage once; blocks and airborne/crouched hits never enter here.
	Reactions.hit_reaction(target.combat,0.3,AttackData.HitHeight.MID,source_fighter,4,false,Impact.IMPACT_COLOR)
