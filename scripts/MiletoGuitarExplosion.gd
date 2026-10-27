extends Node2D

var elapsed := 0.0


func _ready() -> void:
	add_to_group("mileto_guitar_explosion")
	z_index = 12
	var material_add := CanvasItemMaterial.new()
	material_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = material_add
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1,1,1,1),Color(.25,.75,1,.7),Color(.1,.4,1,0)])
	gradient.offsets = PackedFloat32Array([0,.3,1])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(.5,.5)
	texture.fill_to = Vector2(1,.5)
	texture.width = 128
	texture.height = 128
	var flash := Sprite2D.new()
	flash.texture = texture
	flash.material = material_add
	flash.scale = Vector2.ONE * .35
	add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash,"scale",Vector2.ONE*2.3,.16)
	tween.parallel().tween_property(flash,"modulate:a",0.0,.3)
	var sparks := CPUParticles2D.new()
	sparks.name = "ElectricSparks"
	sparks.amount = 80
	sparks.lifetime = .4
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.direction = Vector2.RIGHT
	sparks.spread = 180
	sparks.gravity = Vector2(0,150)
	sparks.initial_velocity_min = 110
	sparks.initial_velocity_max = 380
	sparks.scale_amount_min = 2
	sparks.scale_amount_max = 5
	sparks.color = Color(.25,.75,1,.95)
	sparks.material = material_add
	add_child(sparks)
	sparks.emitting = true


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= .5:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var alpha := maxf(0,1-elapsed/.32)
	draw_arc(Vector2.ZERO,15 + elapsed*280,0,TAU,48,Color(.5,.85,1,alpha),3,true)
	for index in 12:
		var angle := index * TAU / 12
		var direction := Vector2.from_angle(angle)
		var side := direction.orthogonal()
		var distance := 15 + elapsed*250
		var points := PackedVector2Array([direction*distance*.4,direction*distance*.75+side*8,direction*distance])
		draw_polyline(points,Color(.75,.9,1,alpha),2,true)
