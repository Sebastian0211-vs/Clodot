extends ProgressBar

@onready var timer = $Timer

var thirsty = 0 : set = set_thirsty
const EndScreen = preload("res://scenes/end/end_screen.gd")

func set_thirsty(new_thirsty):
	thirsty = min(max_value, new_thirsty)
	value = thirsty
	
	if thirsty <= 0:
		EndScreen.go(InputManager)
		return
		
func init_thirsty(_thirsty):
	thirsty = _thirsty
	max_value = thirsty
	value = thirsty

func _on_timer_timeout() -> void:
	max_value = thirsty
