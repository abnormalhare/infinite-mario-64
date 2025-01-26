class_name RedCoin extends Node3D

@onready var area_3d := $Area3D as Area3D
var coin_value : int = 2
var coin_sound : AudioStream = preload("res://mario/sfx/sm64_red_coin_1.wav")
@onready var animated_sprite_3d = $AnimatedSprite3D
@onready var intersect_cast = $IntersectCast
@onready var drop_to_ground_cast = $DropToGroundCast
var physics : bool = false
var velocity : Vector3 = Vector3.ZERO
var drop_to_ground : bool = false
var destroy_on_retry : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(0.1).timeout
	var intersecting = true
	animated_sprite_3d.play("default")
	intersect_cast.force_shapecast_update()
	if intersect_cast.is_colliding():
		queue_free()
		return
	if !physics and drop_to_ground:
		drop_to_ground_cast.force_shapecast_update()
		if drop_to_ground_cast.is_colliding():
			position = drop_to_ground_cast.get_collision_point(0) + Vector3(0, 0.5, 0)
		else:
			queue_free()
			return
	SOGlobal.total_red_coins += 1

func _set_physics_enabled(in_physics : bool) -> void:
	if in_physics:
		physics = true
		drop_to_ground_cast.target_position = Vector3(0, 0, 0)
		drop_to_ground_cast.shape.radius = 0.5
	else:
		physics = false
		drop_to_ground_cast.target_position = Vector3(0, -2.5, 0)
		drop_to_ground_cast.shape.radius = 0.1
	

func _physics_process(delta):
	if physics and visible:
		var radius : float = drop_to_ground_cast.shape.radius
		velocity += Vector3.DOWN * delta * 24
		position += velocity * delta
		drop_to_ground_cast.force_shapecast_update()
		if drop_to_ground_cast.is_colliding():
			var old_position := position
			for collision in drop_to_ground_cast.get_collision_count():
				var normal : Vector3 = drop_to_ground_cast.get_collision_normal(collision)
				var depth : float = radius - old_position.distance_to(drop_to_ground_cast.get_collision_point(collision))
				position += normal * depth
				velocity += normal * normal.dot(velocity) * -1.5

func _collect(num_red_coins : int):
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	SOGlobal.play_sound(coin_sound, 0, 2.0 ** (float(num_red_coins - 1) / 12.0))
	visible = false
	var new_shine := preload("res://mario/coin_shine.tscn").instantiate() as AnimatedSprite3D
	var num := preload("res://mario/num.tscn").instantiate() as AnimatedSprite3D
	new_shine.position = position
	num.position = position
	num.pause()
	num.frame = num_red_coins
	SOGlobal.add_child(new_shine)
	SOGlobal.add_child(num)

func _respawn():
	await get_tree().create_timer(0.1).timeout
	if destroy_on_retry:
		queue_free()
		return
	area_3d.monitorable = true
	area_3d.monitoring = true
	visible = true

func _on_area_3d_area_entered(area: Area3D):
	if !visible:
		return
	if area.get_parent() is SM64Mario:
		var collect_mario := area.get_parent() as SM64Mario
		collect_mario.heal(coin_value * 4)
		collect_mario.current_coin_count += coin_value
		collect_mario.current_red_coin_count += 1
		var required_coins : int = min(8, SOGlobal.total_red_coins)
		if collect_mario.current_red_coin_count == required_coins:
			var new_star := SOGlobal.generate_power_star("red", position, position + Vector3(0, 3, 0)) as PowerStar
			new_star.destroy_on_retry = true
		_collect(collect_mario.current_red_coin_count)
