extends Panel

enum MODE {
	INVENTORY,
	SHOP
} 

func _ready():
	visible = false

func _input(event):
	if event.is_action_pressed("inventory") and visible == false:
		open_mode(MODE.INVENTORY)
	elif event.is_action_pressed("inventory") and visible == true:
		close_mode()
	#testing
	#if event.is_action_pressed("interact"):
		#open_mode(MODE.SHOP)

func open_mode(mode, force_open := true):
	visible = force_open
	
	match mode:
		MODE.INVENTORY:
			%Shop.visible = false
			if visible:
				print("Inventory mode.")
				
		MODE.SHOP:
			%Shop.visible = true
			if visible:
				print("Shop mode")

func close_mode():
	visible = false
	%Shop.visible = false
