extends ProgressBar

@onready var timer = $Timer

var hungry = 0 : set = set_hungry

func set_hungry(new_hungry):
	hungry = min(max_value, new_hungry)
	value = hungry
	
	if hungry <= 0:
		print("IL A FAIM")
		
func init_hungry(_hungry):
	hungry = _hungry
	max_value = hungry
	value = hungry
	
func _on_timer_timeout() -> void:
	max_value = hungry
