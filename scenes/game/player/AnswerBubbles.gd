extends Node2D

@export var duration = 1.0
var elapsed = 0.0
var velocity_x = 0.0
var velocity_y = 0.0
var rotation_speed = 0.0

func init_static(text: String):
	$Label.text = text
	set_process(false)

func _process(delta):	
	velocity_y += 20.0 * delta
	position.x += velocity_x * delta
	position.y += velocity_y * delta
	rotation += rotation_speed * delta
	
