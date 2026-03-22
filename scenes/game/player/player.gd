extends CharacterBody2D
const SPEED = 80
var current_direction 
var time = 0.0

@onready var thirstyBar = $PlayerUi/ThirstyBar
@onready var hungryBar = $PlayerUi/HungryBar
@onready var staminaBar = $PlayerUi/StaminaBar
@onready var moneyLabel = $PlayerUi/money/money_label
@onready var moneyBackground = $PlayerUi/money/money_background
@onready var camera = $camera

var thirsty = 0
var hungry = 0
var stamina = 0
var moneyIndicator = 0.0

func _ready():
	add_to_group("player")
	thirsty = 100
	hungry = 100
	stamina = 100
	moneyIndicator = 100.0
	hungryBar.init_hungry(hungry)
	staminaBar.init_stamina(stamina)
	thirstyBar.init_thirsty(thirsty)
	InputManager.phoneme_played.connect(_on_phoneme_played)
	camera.add_to_group("camera")
	ConversationManager.conversation_started.connect(_on_conv_started)
	ConversationManager.conversation_ended.connect(_on_conv_ended)

const FloatingLabel = preload("res://scenes/game/player/FloatingLabel.tscn")


func _on_phoneme_played(label: String):
	var fl = FloatingLabel.instantiate()
	get_tree().current_scene.add_child(fl)
	fl.global_position = global_position + Vector2(randf_range(-20, 20), -40)
	fl.init(label)
	
#PER SECONDS
var THIRSTFACTOR = 0.1
var HUNGERFACTOR = 0.1
var STAMINAFACTOR = 0.1
	
var locked = false

func _on_conv_started(_pnj):
	locked = true

func _on_conv_ended():
	locked = false

func _process(delta):
	if locked:
		return
	time += delta
	update_attributes(delta)
	get_input()
	set_direction()
	move(delta)

func update_attributes(delta: float):
	_set_thirsty(delta)
	_set_hungry(delta)
	_set_stamina(delta)
	_set_money(delta)

func _set_thirsty(delta: float):
	thirsty -= THIRSTFACTOR * delta
	thirstyBar.set_thirsty(thirsty)
	thirstyBar.thirsty = thirsty
	
func _set_hungry(delta: float):
	hungry -= HUNGERFACTOR * delta
	hungryBar.set_hungry(hungry)
	hungryBar.hungry = hungry
	
func _set_stamina(delta: float):
	stamina -= STAMINAFACTOR * delta
	staminaBar.set_stamina(stamina)
	staminaBar.stamina = stamina
	
func _set_money(delta: float):
	#moneyIndicator += 1
	moneyLabel.text = str(moneyIndicator)
	moneyBackground.text = str(moneyIndicator)

enum direction{
	UP,
	UP_RIGHT,
	UP_LEFT,
	DOWN,
	DOWN_RIGHT,
	DOWN_LEFT,
	LEFT,
	RIGHT,
	IDLE_UP,
	IDLE_DOWN,
	IDLE_UP_LEFT,
	IDLE_DOWN_LEFT
}
var KEY_UP = false
var KEY_DOWN = false
var KEY_LEFT = false
var KEY_RIGHT = false

func get_input():
	if Input.is_action_pressed("up"): KEY_UP = true
	else : KEY_UP = false
	if Input.is_action_pressed("down"): KEY_DOWN = true
	else : KEY_DOWN = false
	if Input.is_action_pressed("left"): KEY_LEFT = true
	else : KEY_LEFT = false
	if Input.is_action_pressed("right"): KEY_RIGHT = true
	else : KEY_RIGHT = false

var up = false
var down = false
var left = false
var right = false

func set_direction():
	if KEY_UP:
		up = true
		down = false
		if KEY_LEFT:
			left = true
			right = false
			current_direction = direction.UP_LEFT
		elif KEY_RIGHT:
			left = false
			right = true
			current_direction = direction.UP_RIGHT
		else:
			current_direction = direction.UP
	elif KEY_DOWN:
		up = false
		down = true
		if KEY_LEFT:
			left = true
			right = false
			current_direction = direction.DOWN_LEFT
		elif KEY_RIGHT:
			left = false
			right = true
			current_direction = direction.DOWN_RIGHT
		else:
			current_direction = direction.DOWN
	elif KEY_LEFT:
		left = true
		right = false
		current_direction = direction.LEFT
	elif KEY_RIGHT:
		left = false
		right = true
		current_direction = direction.RIGHT
	else:
		if up:
			if left:
				current_direction = direction.IDLE_UP_LEFT
			else:
				current_direction = direction.IDLE_UP
		elif down:
			if left:
				current_direction = direction.IDLE_DOWN_LEFT
			else:
				current_direction = direction.IDLE_DOWN
		else:
			if left:
				current_direction = direction.IDLE_DOWN_LEFT
			else:
				current_direction = direction.IDLE_DOWN

var was_up = false
var was_down = false
var was_left = false
var was_right = false
var was_up_left = false
var was_up_right = false
var was_down_left = false
var was_down_right = false

var phase_offset_x = 0.0
var phase_offset_y = 0.0

var FREQUENCY = 3.0
var INTENSITY = 10.0

func _calc_phase_x():
	phase_offset_x = asin(clamp($AnimatedSprite2D.position.x / INTENSITY, -1.0, 1.0)) - time * FREQUENCY

func _calc_phase_y():
	phase_offset_y = asin(clamp($AnimatedSprite2D.position.y / INTENSITY, -1.0, 1.0)) - time * FREQUENCY

# Remplace tous les was_up/was_down/was_left/was_right/was_up_left/etc.
var was_moving_x = false  # oscillation sur X (composante verticale du mouvement)
var was_moving_y = false  # oscillation sur Y (composante horizontale du mouvement)

var sign_x = 1
var sign_y = 1

func _ensure_phase_x(new_sign: int):
	if not was_moving_x:
		phase_offset_x = asin(clamp($AnimatedSprite2D.position.x / (new_sign * INTENSITY), -1.0, 1.0)) - time * FREQUENCY
	elif new_sign != sign_x:
		phase_offset_x += PI
	sign_x = new_sign

func _ensure_phase_y(new_sign: int):
	if not was_moving_y:
		phase_offset_y = asin(clamp($AnimatedSprite2D.position.y / (new_sign * INTENSITY), -1.0, 1.0)) - time * FREQUENCY
	elif new_sign != sign_y:
		phase_offset_y += PI
	sign_y = new_sign

func _reset():
	was_moving_x = false
	was_moving_y = false
	sign_x = 1
	sign_y = 1
	self.velocity = Vector2(0, 0)

func move(delta: float):
	var moving_x = false
	var moving_y = false

	match current_direction:
		direction.UP:
			moving_x = true
			_ensure_phase_x(1)
			self.velocity = Vector2(0, -SPEED)
			$AnimatedSprite2D.position.x = sin(time * FREQUENCY + phase_offset_x) * INTENSITY
			$AnimatedSprite2D.position.y = lerp($AnimatedSprite2D.position.y, 0.0, 10.0 * delta)
			$AnimatedSprite2D.play("up")

		direction.DOWN:
			moving_x = true
			_ensure_phase_x(1)
			self.velocity = Vector2(0, SPEED)
			$AnimatedSprite2D.position.x = sin(time * FREQUENCY + phase_offset_x) * INTENSITY
			$AnimatedSprite2D.position.y = lerp($AnimatedSprite2D.position.y, 0.0, 10.0 * delta)
			$AnimatedSprite2D.play("down")

		direction.LEFT:
			moving_y = true
			_ensure_phase_y(1)
			self.velocity = Vector2(-SPEED, 0)
			$AnimatedSprite2D.position.y = sin(time * FREQUENCY + phase_offset_y) * INTENSITY
			$AnimatedSprite2D.position.x = lerp($AnimatedSprite2D.position.x, 0.0, 10.0 * delta)
			$AnimatedSprite2D.play("left")

		direction.RIGHT:
			moving_y = true
			_ensure_phase_y(1)
			self.velocity = Vector2(SPEED, 0)
			$AnimatedSprite2D.position.y = sin(time * FREQUENCY + phase_offset_y) * INTENSITY
			$AnimatedSprite2D.position.x = lerp($AnimatedSprite2D.position.x, 0.0, 10.0 * delta)
			$AnimatedSprite2D.play("right")

		direction.UP_LEFT:
			moving_x = true; moving_y = true
			_ensure_phase_x(1); _ensure_phase_y(-1)
			self.velocity = cartesian_to_isometric(Vector2(-SPEED, 0))
			$AnimatedSprite2D.position.x =  sin(time * FREQUENCY + phase_offset_x) * INTENSITY
			$AnimatedSprite2D.position.y = -sin(time * FREQUENCY + phase_offset_y) * INTENSITY
			$AnimatedSprite2D.play("up_left")

		direction.UP_RIGHT:
			moving_x = true; moving_y = true
			_ensure_phase_x(1); _ensure_phase_y(1)
			self.velocity = cartesian_to_isometric(Vector2(0, -SPEED))
			$AnimatedSprite2D.position.x = sin(time * FREQUENCY + phase_offset_x) * INTENSITY
			$AnimatedSprite2D.position.y = sin(time * FREQUENCY + phase_offset_y) * INTENSITY
			$AnimatedSprite2D.play("up_right")

		direction.DOWN_LEFT:
			moving_x = true; moving_y = true
			_ensure_phase_x(-1); _ensure_phase_y(-1)
			self.velocity = cartesian_to_isometric(Vector2(0, SPEED))
			$AnimatedSprite2D.position.x = -sin(time * FREQUENCY + phase_offset_x) * INTENSITY
			$AnimatedSprite2D.position.y = -sin(time * FREQUENCY + phase_offset_y) * INTENSITY
			$AnimatedSprite2D.play("down_left")

		direction.DOWN_RIGHT:
			moving_x = true; moving_y = true
			_ensure_phase_x(-1); _ensure_phase_y(1)
			self.velocity = cartesian_to_isometric(Vector2(SPEED, 0))
			$AnimatedSprite2D.position.x = -sin(time * FREQUENCY + phase_offset_x) * INTENSITY
			$AnimatedSprite2D.position.y =  sin(time * FREQUENCY + phase_offset_y) * INTENSITY
			$AnimatedSprite2D.play("down_right")

		direction.IDLE_UP:
			_reset(); $AnimatedSprite2D.play("idle_up")
		direction.IDLE_UP_LEFT:
			_reset(); $AnimatedSprite2D.play("idle_up_left")
		direction.IDLE_DOWN:
			_reset(); $AnimatedSprite2D.play("idle_down")
		direction.IDLE_DOWN_LEFT:
			_reset(); $AnimatedSprite2D.play("idle_down_left")

	was_moving_x = moving_x
	was_moving_y = moving_y
	move_and_slide()

func cartesian_to_isometric(cartesian):
	return Vector2(cartesian.x - cartesian.y, (cartesian.x + cartesian.y) / 2)
