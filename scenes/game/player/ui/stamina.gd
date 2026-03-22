extends ProgressBar

@onready var timer = $Timer

var stamina = 0 : set = set_stamina
const EndScreen = preload("res://scenes/end/end_screen.gd")
func set_stamina(new_stamina):
	stamina = min(max_value, new_stamina)
	value = stamina
	
	if stamina <= 0:
		EndScreen.go(InputManager)
		return
		
func init_stamina(_stamina):
	stamina = _stamina
	max_value = stamina
	value = stamina
	
	


func _on_timer_timeout() -> void:
	max_value = stamina
