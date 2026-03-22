extends Node

@export var character_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var move_speed: float = 15.0
@export var camera: Camera2D

var _timer: float = 0.0

func _get_camera_rect() -> Rect2:
	var screen_size = get_viewport().get_visible_rect().size
	var cam_pos = camera.global_position
	return Rect2(cam_pos - screen_size / 2, screen_size)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		_spawn_character()

func _spawn_character() -> void:
	var character = character_scene.instantiate()

	var rect = _get_camera_rect()
	var edge = randi() % 4
	var pos: Vector2
	var direction: Vector2

	match edge:
		0:  # Left
			pos = Vector2(rect.position.x - 50, randf_range(rect.position.y, rect.end.y))
			direction = Vector2(randf()-0.5,randf()-0.5).normalized()
		1:  # Right
			pos = Vector2(rect.end.x + 50, randf_range(rect.position.y, rect.end.y))
			direction = Vector2(randf()-0.5,randf()-0.5).normalized()
		2:  # Top
			pos = Vector2(randf_range(rect.position.x, rect.end.x), rect.position.y - 50)
			direction = Vector2(randf()-0.5,randf()-0.5).normalized()
		3:  # Bottom
			pos = Vector2(randf_range(rect.position.x, rect.end.x), rect.end.y + 50)
			direction = Vector2(randf()-0.5,randf()-0.5).normalized()

	var id = randi()%5
	character.global_position = pos
	character.camera = camera
	add_child(character)
	character.setup(direction, move_speed, id)
