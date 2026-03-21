extends Inventory

#region Testing
@export var items : Array[Item]

func _ready():
	load_items(items)
#endregion

func load_items(items):
	reset()
	for item in items:
		add_item(item)

func reset():
	for slot in get_children():
		slot.item = null
