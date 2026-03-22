extends PanelContainer
class_name Slot

var _player = null

func get_player():
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		print("Found player: ", _player)
	return _player

@onready var texture_rect = $TextureRect
@export var item : Item = null:
	set(value):
		item = value
		
		if value != null:
			texture_rect.texture = value.icon 
		else:
			texture_rect.texture = null
				
func get_preview():
	var preview_texture = TextureRect.new()
	preview_texture.texture = texture_rect.texture
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.custom_minimum_size = Vector2(20,20)
	
	var preview = Control.new()
	preview.add_child(preview_texture)
	preview_texture.position = -0.5 * Vector2(20,20)
	
	return preview
	
func _can_drop_data(_pos, data):
	var source = data.get_parent().name
	var destination = get_parent().name
	
	if data is Slot:
		if destination == "itemUse" and source == "Inventory" and not item:
			return true
		elif destination == "Shop" and source == "Inventory" and not item:
			return true
		elif destination == "Inventory" and source == "Shop" and not item:
			var p = get_player()
			if p == null:
				return false
			return p.moneyIndicator >= data.item.cost
		elif destination == source:
			return true
			
	return false

func _get_drag_data(_at_position):
	set_drag_preview(get_preview())
	return self
	
func _drop_data(_at_position, data):
	var source = data.get_parent().name
	var destination = get_parent().name
	
	if destination == "Shop" and source == "Inventory":
		selling(data)
		return
	elif destination == "Inventory" and source == "Shop":
		buying(data)
		return
	
	var temp = item
	item = data.item
	data.item = temp

func selling(data):
	var p = get_player()
	if p == null: return
	print("Sold " + data.item.name)
	p.moneyIndicator += data.item.cost
	data.item = null

func buying(data):
	var p = get_player()
	if p == null: return
	print("Trying to buy: ", data.item.name, " | Money: ", p.moneyIndicator, " | Cost: ", data.item.cost)
	p.moneyIndicator -= data.item.cost
	item = data.item
