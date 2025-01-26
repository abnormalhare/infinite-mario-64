extends AnimatedSprite3D

var timer: int;
var base_pos: float;
var y_vel: float;
var stop: bool = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	timer = Time.get_ticks_msec()
	position.y += 1
	base_pos = position.y
	y_vel = 0.1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Time.get_ticks_msec() > timer + 1000:
		queue_free()
	
	if stop == false:
		y_vel -= 0.4 * delta
		position.y += y_vel;
	if position.y <= base_pos:
		var curr_time = Time.get_ticks_msec()
		if curr_time < timer + 750:
			y_vel = ((timer + 1600) - Time.get_ticks_msec()) / 200 * delta
		else:
			stop = true
