# ConversationManager.gd — Autoload
extends Node

signal conversation_started(pnj)
signal conversation_ended

var in_conversation = false
var current_pnj = null
var player = null
var camera = null

const DIALOGUES = {
	0: ["Bonjour !", "Belle journée !", "Tu as vu mes clés ?", "J'aime les chats", "Sympa par ici"],
	1: ["...", "Blah blah", "Requin en peluche", "Doux et bleu", "Serre-moi fort"],
	2: ["Ni hao !", "Ça roule ?", "T'as faim ?", "On mange quoi ?", "Bonne chance !"],
	3: ["Jobelin !", "Sacré jobelin", "Jobelinade", "Jobelos", "Jobeline forever"],
	4: ["Bienvenue !", "On a tout ce qu'il faut", "Bonne affaire aujourd'hui", "Revenez vite", "Soldes !"],
}

var _current_npc = null
var _line_index: int = 0


func start_conversation(pnj) -> void:
	if in_conversation:
		return
	in_conversation = true
	current_pnj = pnj
	player = get_tree().get_first_node_in_group("player")
	camera = get_tree().get_first_node_in_group("camera")
	
	var pt = player.create_tween()
	pt.tween_property(player, "position:y", player.position.y - 8, 0.1).set_ease(Tween.EASE_OUT)
	pt.tween_property(player, "position:y", player.position.y, 0.15).set_ease(Tween.EASE_IN)
	
	var mid = (player.global_position + pnj.global_position) / 2.0
	var ct = camera.create_tween().set_parallel(true)
	ct.tween_property(camera, "zoom", Vector2(2.5, 2.5), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	ct.tween_property(camera, "global_position", mid, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	_current_npc = pnj
	_line_index = 0
	conversation_started.emit(pnj)
	_show_line()
	
	emit_signal("conversation_started", pnj)

func advance() -> void:
	_line_index += 1
	if _line_index >= _current_npc.dialogue_lines.size():
		end_conversation()
	else:
		_show_line()

func _show_line() -> void:
	var line = _current_npc.dialogue_lines[_line_index]
	_current_npc.show_dialogue_line(line)

func end_conversation() -> void:
	if not in_conversation:
		return
	_current_npc.hide_dialogue_bubble() 
	in_conversation = false
	
	var ct = camera.create_tween().set_parallel(true)
	ct.tween_property(camera, "zoom", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_IN_OUT)
	ct.tween_property(camera, "global_position", player.global_position, 0.3)
	
	_current_npc = null
	conversation_ended.emit()
