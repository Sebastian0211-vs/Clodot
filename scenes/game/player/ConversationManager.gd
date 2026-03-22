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

const EXPECTED_ANSWERS = {
	0: {
		"Bonjour !":           { "answer": "bonjour",  "reward": 10 },
		"Belle journée !":     { "answer": "beau",     "reward": 5  },
		"Tu as vu mes clés ?": { "answer": "cle",      "reward": 15 },
		"J'aime les chats":    { "answer": "chat",     "reward": 8  },
		"Sympa par ici":       { "answer": "sympa",    "reward": 6  },
	},
	1: {
		"...":               { "answer": "silence",  "reward": 5  },
		"Blah blah":         { "answer": "blah",     "reward": 5  },
		"Requin en peluche": { "answer": "requin",   "reward": 20 },
		"Doux et bleu":      { "answer": "doux",     "reward": 10 },
		"Serre-moi fort":    { "answer": "fort",     "reward": 15 },
	},
	2: {
		"Ni hao !":      { "answer": "nihao",   "reward": 12 },
		"Ça roule ?":    { "answer": "roule",   "reward": 8  },
		"T'as faim ?":   { "answer": "faim",    "reward": 10 },
		"On mange quoi ?":{ "answer": "manger", "reward": 10 },
		"Bonne chance !":{ "answer": "chance",  "reward": 7  },
	},
	3: {
		"Jobelin !":          { "answer": "jobelin",   "reward": 20 },
		"Sacré jobelin":      { "answer": "sacre",     "reward": 15 },
		"Jobelinade":         { "answer": "jobelinade","reward": 25 },
		"Jobelos":            { "answer": "jobelo",    "reward": 15 },
		"Jobeline forever":   { "answer": "forever",   "reward": 10 },
	},
	4: {
		"Bienvenue !":              { "answer": "merci",    "reward": 5  },
		"On a tout ce qu'il faut":  { "answer": "super",    "reward": 8  },
		"Bonne affaire aujourd'hui":{ "answer": "affaire",  "reward": 15 },
		"Revenez vite":             { "answer": "revenir",  "reward": 10 },
		"Soldes !":                 { "answer": "solde",    "reward": 20 },
	},
}

var _current_npc = null
var _line_index: int = 0

# Dans ConversationManager
var _spoken_buffer: String = ""

func _ready() -> void:
	# connecte le signal d'InputManager
	InputManager.phoneme_played.connect(_on_phoneme_played)

func _on_phoneme_played(label: String) -> void:
	if not in_conversation:
		return
	_spoken_buffer += label 
	check_answer(_spoken_buffer)
	print("buffer: ", _spoken_buffer)

func advance() -> void:
	_spoken_buffer = ""  # reset le buffer
	_line_index += 1
	if _line_index >= _current_npc.dialogue_lines.size():
		end_conversation()
	else:
		_show_line()

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


var _expected_answer: String = ""
var _current_reward: int = 0  # ← ajoute ça

func _show_line() -> void:
	var line = _current_npc.dialogue_lines[_line_index]
	_current_npc.show_dialogue_line(line)
	
	var npc_id = _current_npc.id
	if EXPECTED_ANSWERS.has(npc_id) and EXPECTED_ANSWERS[npc_id].has(line):
		_expected_answer = EXPECTED_ANSWERS[npc_id][line]["answer"]
		_current_reward  = EXPECTED_ANSWERS[npc_id][line]["reward"]
	else:
		_expected_answer = ""
		_current_reward  = 0

func check_answer(spoken_text: String) -> int:
	if _expected_answer == "":
		print("pas de réponse attendue pour cette ligne")
		_spoken_buffer = ""
		return 0
	
	print("attendu: ", _expected_answer, " | reçu: ", spoken_text.to_lower())
	
	if _expected_answer == spoken_text.to_lower():
		print("Bonne réponse ! +", _current_reward, " thunes")
		player.moneyIndicator += _current_reward
		_spoken_buffer = ""
		end_conversation()
		return 1
		
	if _expected_answer.contains(spoken_text.to_lower()):
		print("BONNE REPONSE EN COURS HIHI BIEN OUEJ")
		
		return 2
		
	else:
		print("Mauvaise réponse...")
		_spoken_buffer = ""
		end_conversation()
		return -1

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
