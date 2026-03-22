extends AnimatedSprite2D

enum State { OFFSCREEN_INITIAL, ONSCREEN, OFFSCREEN_FINAL }

@export var camera: Camera2D
@export var offscreen_timeout: float = 1.5
@onready var textbox = $Text
@onready var dialogtext = $Dialog/PanelContainer/Label
@onready var dialogPanel = $Dialog/PanelContainer
@export var items : Array[Item] = [
	preload("res://Resources/Item1.tres"),
	preload("res://Resources/Item2.tres"),
	preload("res://Resources/Item3.tres"),
	preload("res://Resources/Item4.tres"),
	preload("res://Resources/Item5.tres")
]


const DIALOGUES = {
	0: ["Bonjour !", "Belle journée !", "Tu as besoin d'argent ?", "Ne m'approche pas !", "C'était sympa, jusqu'à que t'arrives."],
	1: ["...", "Blah blah", "Requin en peluche", "Doux et bleu", "Serre-moi fort"],
	2: ["Tchao !", "Ça va ou quoi ?", "T'as où le chalet ?", "Tu veux graille un truc ?", "Ca roule"],
	3: ["Salut !", "C'est moi, le jobelin !", "Entrain de jobeliner et toi ?", "Oui ?", "Rejoins les jobelins !"],
	4: ["Bienvenue !", "On a tout ce qu'il faut", "Bonne affaire aujourd'hui", "Venez !", "Soldes !"],
	5: ["Shalom !", "C'est compliqué...", "Hamas, Hamas !", "J'ai le droit de me défendre", "Bibi out"],
	6: ["Ina ina ina !", "Takoooo !", "*bloop*", "T'as vu mon tentacule ?", "Je dessine, donc je suis"],
	7: ["Sus...", "*vent*", "C'était pas moi", "T'es l'imposteur", "Emergency meeting !"],
}

var sprites = {
	0: "allan.tres",
	1: "blahaj.tres",
	2: "chingchong.tres",
	3: "jobelin.tres",
	4: "shop.tres",
	5: "bigN.tres",
	6: "tako.tres",
	7: "sus.tres"
}

var player_nearby = false
var _is_shopping = false
var _velocity: Vector2 = Vector2.ZERO
var _state: State = State.OFFSCREEN_INITIAL
var _offscreen_timer: float = 0.0
var textbox_tween: Tween
var shake_time: float = 0.0
var shake_time_dialog: float = 0.0
var base_textbox_pos: Vector2
var base_dialogtext_pos : Vector2 = Vector2(0.0,-13.0)
var direction: Vector2 = Vector2.ZERO
var id = 0
var _speed = 0.0

func _ready() -> void:
	add_child(textbox)
	textbox.visible = false
	
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	visible = false
	dialogtext.visible = false 
	dialogPanel.position = dialogtext.position
	ConversationManager.conversation_ended.connect(_on_conv_ended)
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if id == 4:
		return
	var other = area.get_parent()
	if other == self:
		return
	if other.has_method("setup") and !player_nearby:
		var push = (global_position - other.global_position).normalized()
		_velocity = push * _speed
		direction = push

func _shop_time():
	Ui.open_mode(Ui.MODE.SHOP,items)
	_is_shopping = true

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		_show_textbox()

func show_dialogue_line(line: String) -> void:
	dialogtext.text = line
	dialogtext.visible = true
	dialogPanel.visible = true
	dialogPanel.modulate.a = 0.0


	var tween = create_tween()
	tween.tween_property(dialogPanel, "modulate:a", 1.0, 0.2)


func hide_dialogue_bubble() -> void:
	dialogtext.visible = false
	dialogPanel.visible = false

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		_hide_textbox()

func _show_textbox():
	textbox.visible = true
	textbox.modulate.a = 0.0
	textbox.position = base_textbox_pos + Vector2(-30, 0)
	if textbox_tween:
		textbox_tween.kill()
	textbox_tween = create_tween().set_parallel(true)
	textbox_tween.tween_property(textbox, "position:x", base_textbox_pos.x, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	textbox_tween.tween_property(textbox, "modulate:a", 1.0, 0.2)

func _hide_textbox():
	if textbox_tween:
		textbox_tween.kill()
	textbox_tween = create_tween().set_parallel(true)
	textbox_tween.tween_property(textbox, "position:x", base_textbox_pos.x - 30, 0.2).set_ease(Tween.EASE_IN)
	textbox_tween.tween_property(textbox, "modulate:a", 0.0, 0.2)
	await textbox_tween.finished
	textbox.visible = false

func _process(delta: float) -> void:
	global_position += _velocity * delta
	_update_state(delta)
	if player_nearby and textbox.visible:
		shake_time += delta * 15.0
		textbox.position = base_textbox_pos + Vector2(
			sin(shake_time) * 1.0,
			cos(shake_time * 1.1) * 1.0
		)
	if player_nearby and dialogtext.visible:
		shake_time_dialog += delta * 15.0
		var new_pos = base_dialogtext_pos + Vector2(
			sin(shake_time_dialog) * 0.2,
			cos(shake_time_dialog * 0.3) * 1.0
		)
		dialogPanel.position = new_pos + Vector2(0.0,-12.0)
	
		
var start = false
func _input(event):
	if not player_nearby:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE and start == false:
			start = true
			_start_discussion()
		elif event.keycode == KEY_SPACE and start == true:
			start = false
			if id != 4:
				_velocity = direction*10
			_show_textbox()
			ConversationManager.advance()
		

func _on_conv_ended():
	start = false
	if id != 4:
		_velocity = direction * _speed
	else:
		_is_shopping = false
		Ui.close_mode()
	_show_textbox()

func _start_discussion():
	print("STARTED CONVERSATION")
	_velocity = Vector2(0.0,0.0)
	_hide_textbox()
	_bounce_both()
	if id == 4 and _is_shopping == false:
		_shop_time()

func _bounce_both():
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 8, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y, 0.15).set_ease(Tween.EASE_IN)
	
	ConversationManager.start_conversation(self)

var dialogue_lines: Array = []
var _line_index: int = 0

func setup(dir: Vector2, velocity: float, iD) -> void:
	_speed = velocity
	id = iD
	direction = dir.normalized()
	_velocity = direction * velocity
	visible = true

	var pool = DIALOGUES[id].duplicate()
	pool.shuffle()
	dialogue_lines = pool.slice(0, 1)

	var path = "res://assets/pnj/" + sprites[id]
	var frames = load(path)
	if frames and frames is SpriteFrames:
		sprite_frames = frames
		play("default")
	if iD == 4:
		_velocity = Vector2(0, 0)

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
	var margin = 300.0
	var rect = Rect2(
		cam_pos - screen_size / 2 - Vector2(margin, margin),
		screen_size + Vector2(margin * 2, margin * 2)
	)
	return rect.has_point(global_position)
	
	
