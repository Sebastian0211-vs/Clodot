extends PanelContainer
class_name itemUse

var _player = null

func get_player():
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		print("Found player: ", _player)
	return _player

@onready  var texture_rect = $TextureRect


@export var item : Item = null:
	set(value):
		item = value
		if not is_node_ready():
			return
		if value != null:
			texture_rect.texture = value.icon
		else:
			texture_rect.texture = null
			
func _ready():
	if item != null:
		texture_rect.texture = item.icon

func get_preview():
	var preview_texture = TextureRect.new()
	preview_texture.texture = texture_rect.texture
	
	var preview = Control.new()
	preview.add_child(preview_texture)
	
	return preview

func _can_drop_data(_pos, data):
	return data is Slot and data.get_parent().name == "Inventory"

func _get_drag_data(_at_position):
	set_drag_preview(get_preview())
	return self

func _drop_data(_at_position, data):
	using(data)

func using(data):
	var p = get_player()
	if p == null: return
	match data.item.id:
		1:
			_player.thirsty += 50
			print("beers")
		2:
			_player.stamina += 50
			print("cigs")
		3:
			_player.hungry += 50
			print("sandvitch")
		4:
			_player.thirsty += 33
			_player.stamina += 33
			_player.hungry += 33
			print("scoobysnack")
		5:
			var chance = randi() % 100
			if chance > 94:
				_player.moneyIndicator += 500			
			print("gambling")
		6:
			_player.thirsty += 75
			print("watah")
	data.item = null 
	item = null
