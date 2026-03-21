extends Sprite2D

enum State { OFFSCREEN_INITIAL, ONSCREEN, OFFSCREEN_FINAL }

@export var camera: Camera2D
@export var offscreen_timeout: float = 1.5

var _velocity: Vector2 = Vector2.ZERO
var _state: State = State.OFFSCREEN_INITIAL
var _offscreen_timer: float = 0.0


func _ready() -> void:
	visible = false


func setup(velocity: Vector2) -> void:
	_velocity = velocity
	visible = true


func _process(delta: float) -> void:
	global_position += _velocity * delta
	_update_state(delta)


func _update_state(delta: float) -> void:
	var on_screen = _is_on_screen()

	match _state:
		State.OFFSCREEN_INITIAL:
			if on_screen:
				_state = State.ONSCREEN

		State.ONSCREEN:
			if not on_screen:
				_state = State.OFFSCREEN_FINAL
				_offscreen_timer = 0.0

		State.OFFSCREEN_FINAL:
			_offscreen_timer += delta
			if _offscreen_timer >= offscreen_timeout:
				queue_free()


func _is_on_screen() -> bool:
	var screen_size = get_viewport().get_visible_rect().size / camera.zoom
	var cam_pos = camera.global_position 
	var margin = 64.0
	var rect = Rect2(
		cam_pos - screen_size / 2 - Vector2(margin, margin),
		screen_size + Vector2(margin * 2, margin * 2)
	)
	return rect.has_point(global_position)
