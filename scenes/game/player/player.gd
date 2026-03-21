extends CharacterBody2D
const SPEED = 80
var current_direction 
var time = 0.0
enum direction{
	UP,
	UP_RIGHT,
	UP_LEFT,
	DOWN,
	DOWN_RIGHT,
	DOWN_LEFT,
	LEFT,
	RIGHT,
	IDLE
}
var KEY_UP = false
var KEY_DOWN = false
var KEY_LEFT = false
var KEY_RIGHT = false

func _process(delta: float) -> void:
	time += delta
	get_input()
	set_direction()
	move()
	
func get_input():
	if Input.is_action_pressed("ui_up"): KEY_UP = true
	else : KEY_UP = false
	
	if Input.is_action_pressed("ui_down"): KEY_DOWN = true
	else : KEY_DOWN = false
	
	if Input.is_action_pressed("ui_left"): KEY_LEFT = true
	else : KEY_LEFT = false
	
	if Input.is_action_pressed("ui_right"): KEY_RIGHT = true
	else : KEY_RIGHT = false

func set_direction():
	if KEY_UP:
		if KEY_LEFT:
			current_direction = direction.UP_LEFT
		elif KEY_RIGHT:
			current_direction = direction.UP_RIGHT
		else:
			current_direction = direction.UP
			
	elif KEY_DOWN:
		if KEY_LEFT:
			current_direction = direction.DOWN_LEFT
		elif KEY_RIGHT:
			current_direction = direction.DOWN_RIGHT
		else:
			current_direction = direction.DOWN
			
	elif KEY_LEFT :
		current_direction = direction.LEFT
	elif KEY_RIGHT:
		current_direction = direction.RIGHT
		
	else: current_direction = direction.IDLE

var was_up = false
var was_down = false
var was_left = false
var was_right = false
var was_up_left = false
var was_up_right = false
var was_down_left = false
var was_down_right = false


var FREQUENCY = 3.0
var INTENSITY =20.0

func move():
	match current_direction:
		direction.UP:
			if not was_up:
				time = 0.0
				was_up = true
			self.velocity = Vector2(0, -SPEED)
			$AnimatedSprite2D.position.x = sin(time * FREQUENCY) * INTENSITY
			$AnimatedSprite2D.play("up")
		direction.DOWN : 
			if not was_down:
				time = 0.0
				was_down = true
			self.velocity = Vector2(0, SPEED)
			$AnimatedSprite2D.position.x = sin(time * FREQUENCY) * INTENSITY
			$AnimatedSprite2D.play("down")
		direction.LEFT : 
			if not was_left:
				time = 0.0
				was_left = true
			self.velocity = Vector2(-SPEED, 0)
			$AnimatedSprite2D.position.y = sin(time * FREQUENCY) * INTENSITY
			$AnimatedSprite2D.play("left")
		direction.RIGHT : 
			if not was_right:
				time = 0.0
				was_right = true
			self.velocity = Vector2(SPEED, 0)
			$AnimatedSprite2D.position.y = sin(time * FREQUENCY) * INTENSITY
			$AnimatedSprite2D.play("right")
		direction.UP_LEFT :
			if not was_up_left:
				time = 0.0
				was_up_left = true
			self.velocity = cartesian_to_isometric(Vector2(-SPEED,0))
			$AnimatedSprite2D.position.x = sin(time * FREQUENCY) * INTENSITY
			$AnimatedSprite2D.position.y = -sin(time * FREQUENCY) * INTENSITY
			$AnimatedSprite2D.play("up_left")
		direction.UP_RIGHT :
			if not was_up_right:
				time = 0.0
				was_up_right = true
			self.velocity = cartesian_to_isometric(Vector2(0, -SPEED))
			$AnimatedSprite2D.position.x = sin(time * FREQUENCY) * INTENSITY
			$AnimatedSprite2D.position.y = sin(time * FREQUENCY) * INTENSITY
			$AnimatedSprite2D.play("up_right")
		direction.DOWN_LEFT : 
			if not was_down_left:
				time = 0.0
				was_down_left = true
			self.velocity = cartesian_to_isometric(Vector2(0, SPEED))
			$AnimatedSprite2D.position.x = -sin(time * FREQUENCY) * INTENSITY
			$AnimatedSprite2D.position.y = -sin(time * FREQUENCY) * INTENSITY
			$AnimatedSprite2D.play("down_left")
		direction.DOWN_RIGHT : 
			if not was_down_right:
				time = 0.0
				was_down_right = true
			self.velocity = cartesian_to_isometric(Vector2(SPEED, 0))
			$AnimatedSprite2D.position.x = -sin(time * FREQUENCY) * INTENSITY
			$AnimatedSprite2D.position.y = sin(time * FREQUENCY) * INTENSITY
			$AnimatedSprite2D.position.x = 0.0
			$AnimatedSprite2D.play("down_right")
		direction.IDLE :
			was_up = false
			was_down = false
			was_left = false
			was_right = false
			was_up_left = false
			was_up_right = false
			was_down_left = false
			was_down_right = false
			self.velocity = Vector2(0,0)
			$AnimatedSprite2D.position.x = lerp($AnimatedSprite2D.position.x, 0.0, 0.01)
			$AnimatedSprite2D.position.y = lerp($AnimatedSprite2D.position.y, 0.0, 0.01)
			$AnimatedSprite2D.play("idle")
	move_and_slide()

func cartesian_to_isometric(cartesian):
	return Vector2(cartesian.x - cartesian.y, (cartesian.x + cartesian.y) / 2)
