extends Node2D

@export var duration = 1.0
var elapsed = 0.0
var velocity_x = 0.0
var velocity_y = 0.0
var rotation_speed = 0.0

func init(text: String):
	$Label.text = text
	velocity_x = randf_range(-40.0, 40.0)
	velocity_y = randf_range(-60.0, -20.0)  
	rotation_speed = randf_range(-2.0, 2.0)

func _process(delta):
	elapsed += delta
	var t = elapsed / duration
	
	velocity_y += 20.0 * delta
	position.x += velocity_x * delta
	position.y += velocity_y * delta
	rotation += rotation_speed * delta
	
	modulate.a = 1.0 - t
	if elapsed >= duration:
		queue_free()
