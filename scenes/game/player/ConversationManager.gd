# ConversationManager.gd — Autoload
extends Node


signal conversation_started(pnj)
signal conversation_ended

var in_conversation = false
var current_pnj = null
var player = null
var camera = null

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

const EXPECTED_ANSWERS = {
	0: {
		"Bonjour !":                             { "answer": ["bonjour", "salut", "sou"],       "reward": 0.10 },
		"Belle journée !":                       { "answer": ["beau", "thune", "piece"],        "reward": 0.05 },
		"Tu as besoin d'argent ?":               { "answer": ["fric", "thune", "stp"],          "reward": 0.50 },
		"Ne m'approche pas !":                   { "answer": ["stop", "pardon", "desole"],      "reward": 0.20 },
		"C'était sympa, jusqu'à que t'arrives.": { "answer": ["desole", "clope", "biere"],      "reward": 0.15 },
	},
	1: {
		"...":               { "answer": ["silence", "sou", "hein"],       "reward": 0.05 },
		"Blah blah":         { "answer": ["blah", "fric", "quoi"],         "reward": 0.05 },
		"Requin en peluche": { "answer": ["requin", "doux", "peluche"],    "reward": 1.50 },
		"Doux et bleu":      { "answer": ["doux", "bleu", "biere"],        "reward": 0.30 },
		"Serre-moi fort":    { "answer": ["fort", "serre", "clope"],       "reward": 0.75 },
	},
	2: {
		"Tchao !":                   { "answer": ["tchao", "sous", "ciao"],      "reward": 0.10 },
		"Ça va ou quoi ?":           { "answer": ["bien", "biere", "oui"],       "reward": 0.10 },
		"T'as où le chalet ?":       { "answer": ["chalet", "thune", "ici"],     "reward": 0.50 },
		"Tu veux graille un truc ?": { "answer": ["manger", "faim", "clope"],    "reward": 0.40 },
		"Ca roule":                  { "answer": ["roule", "fric", "nickel"],    "reward": 0.15 },
	},
	3: {
		"Salut !":                       { "answer": ["salut", "sou", "coucou"],       "reward": 0.10 },
		"C'est moi, le jobelin !":       { "answer": ["jobelin", "piece", "toi"],      "reward": 2.00 },
		"Entrain de jobeliner et toi ?": { "answer": ["jobelin", "biere", "oui"],      "reward": 2.50 },
		"Oui ?":                         { "answer": ["oui", "thune", "clope"],        "reward": 0.20 },
		"Rejoins les jobelins !":        { "answer": ["jobelin", "fric", "rejoins"],   "reward": 3.00 },
	},
	4: {
		"Bienvenue !":               { "answer": ["merci", "sous", "salut"],     "reward": 0.05 },
		"On a tout ce qu'il faut":   { "answer": ["biere", "clope", "parfait"],  "reward": 0.20 },
		"Bonne affaire aujourd'hui": { "answer": ["fric", "thune", "piece"],     "reward": 0.75 },
		"Venez !":                   { "answer": ["oui", "venir", "sou"],        "reward": 0.10 },
		"Soldes !":                  { "answer": ["solde", "fric", "biere"],     "reward": 1.00 },
	},
	5: {
		"Shalom !":                     { "answer": ["shalom", "sou", "bonjour"],    "reward": 0.10 },
		"C'est compliqué...":           { "answer": ["clope", "biere", "dur"],       "reward": 0.25 },
		"Hamas, Hamas !":               { "answer": ["hamas", "non", "stop"],        "reward": 0.50 },
		"J'ai le droit de me défendre": { "answer": ["droit", "thune", "ok"],        "reward": 0.35 },
		"Bibi out":                     { "answer": ["bibi", "fric", "bye"],         "reward": 0.75 },
	},
	6: {
		"Ina ina ina !":            { "answer": ["ina", "sou", "hein"],           "reward": 0.10 },
		"Takoooo !":                { "answer": ["tako", "pieuvre", "biere"],     "reward": 0.40 },
		"*bloop*":                  { "answer": ["bloop", "bulle", "clope"],      "reward": 0.15 },
		"T'as vu mon tentacule ?":  { "answer": ["tentacule", "piece", "bizarre"],"reward": 1.00 },
		"Je dessine, donc je suis": { "answer": ["dessine", "fric", "stylo"],     "reward": 0.60 },
	},
	7: {
		"Sus...":              { "answer": ["sus", "thune", "qui"],         "reward": 0.20 },
		"*vent*":              { "answer": ["vent", "clope", "quoi"],       "reward": 0.10 },
		"C'était pas moi":     { "answer": ["moi", "biere", "si"],          "reward": 0.50 },
		"T'es l'imposteur":    { "answer": ["imposteur", "fric", "moi"],    "reward": 1.00 },
		"Emergency meeting !": { "answer": ["meeting", "sous", "vite"],     "reward": 2.00 },
	},
}

const FAILED = ["euh...", "ok ?", "ARRÊTE DE ME SUIVRE", "Et si on arrêtait de se parler ?", "Ahah... quoi ?", "ça va... ?"]
const SUCCESS = ["Tiens, j'espère que ça te servira !", "Enfaite t'es plutôt sympa !", "Prends-ça.", "Cadeau.", "Argent."]

var _current_npc = null
var _line_index: int = 0

# Dans ConversationManager
var _spoken_buffer: Array = []

func _ready() -> void:
	InputManager.phoneme_played.connect(_on_phoneme_played)

func _on_phoneme_played(phoneme: String) -> void:
	if not in_conversation:
		return
	_spoken_buffer.append(phoneme)
	check_answer(_spoken_buffer)
	print("buffer: ", _spoken_buffer)

func advance() -> void:
	_spoken_buffer =[]  # reset le buffer
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


var _expected_answers: Array = []
var _current_reward: float = 0.0

signal answers_updated(answers: Array, panel)

func _show_line() -> void:
	var line = _current_npc.dialogue_lines[_line_index]
	_current_npc.show_dialogue_line(line)
	
	var npc_id = _current_npc.id
	if EXPECTED_ANSWERS.has(npc_id) and EXPECTED_ANSWERS[npc_id].has(line):
		_expected_answers = EXPECTED_ANSWERS[npc_id][line]["answer"]
		_current_reward = EXPECTED_ANSWERS[npc_id][line]["reward"]
		var all_answers = []
		for entry in EXPECTED_ANSWERS[npc_id][line]["answer"]:
			print(entry)
			all_answers.append(entry)
		answers_updated.emit(all_answers, _current_npc.get_node("Dialog/PanelContainer"))

	else:
		_expected_answers = []
		_current_reward  = 0
		answers_updated.emit([])


func array_contains_all(main: Array, subset: Array) -> bool:
	return subset.all(func(e): return main.has(e))

func check_answer(spoken_text: Array) -> void:
	var foundtyping = false
	for answer in _expected_answers:
		if _expected_answers == []:
			_spoken_buffer = []
			return 
		var phonem_answer = InputManager.decompose_to_phonemes(answer)
		var phonem_spoken_text = spoken_text
		
		print("ANSWER", phonem_answer, "SPOKEN", phonem_spoken_text)
				
		if phonem_answer == phonem_spoken_text:
			player.increaseMoney(_current_reward)
			_spoken_buffer = []
			_expected_answers = []
			var npc = _current_npc
			await player.trigger_success()
			var success = int(randi()%SUCCESS.size())
			npc.dialogtext.text =SUCCESS[success]
			await get_tree().create_timer(2.0).timeout
			end_conversation()
			return 
			
		if array_contains_all(phonem_answer, phonem_spoken_text):
			foundtyping = true
			return 
			
	if !foundtyping:
		_spoken_buffer = []
		var npc = _current_npc
		await player.trigger_fail()
		var failure = int(randi() % FAILED.size())
		npc.dialogtext.text = FAILED[failure]
		await get_tree().create_timer(2.0).timeout
		npc._speed = npc._speed * (10 + randf() * 30)
		npc.get_node("StaticBody2D/CollisionShape2D").disabled = true
		npc.get_node("Area2D/CollisionShape2D").disabled = true
		end_conversation()

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
