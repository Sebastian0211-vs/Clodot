extends GridContainer
class_name Inventory

@onready var slots = get_children()

func add_item(item : Item):
	for slot in slots:
		if slot.item == null:
			slot.item = item
			return
	print("Can't add any more item...")
	
func remove_item(item : Item):
	for slot in slots:
		if slot.item == item:
			slot.item = null
			return
	print("Item not found")
func use_item(item: Item):
	if item.id == 1:
		print("Binch! Yippi!")
	elif item.id == 2:
		print("Fumer tue.")
	elif item.id == 3:
		print("Samdvich :>")
	elif item.id == 4:
		print("Mmmm croquescooby!")
	elif item.id == 5:
		print("Lets go gambling!")
