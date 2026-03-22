extends Node

const OVERLAP_SEC    := 0.14
const WORD_PAUSE_SEC := 0.14
const PITCH_VARIANCE := 0.04
const PAUSE_TOKEN    := ""

signal phoneme_played(phoneme: String)

const BASE_MAP: Dictionary = {
	# ── VOYELLES — touches qui y ressemblent graphiquement ───────────────────
	KEY_A:  { "label": "a",  "phoneme": "a",  "file": "2193_vignette_-a-.mp3"        },
	KEY_E:  { "label": "e",  "phoneme": "e",  "file": "2207_vignette_-e-.mp3"        },
	KEY_R:  { "label": "e",  "phoneme": "ɛ",  "file": "2209_vignette_-e-.mp3"        }, # e ouvert proche de e
	KEY_I:  { "label": "i",  "phoneme": "i",  "file": "2191_vignette_-i-.mp3"        },
	KEY_O:  { "label": "o",  "phoneme": "o",  "file": "2211_vignette_-o-ferme.mp3"   },
	KEY_P:  { "label": "o",  "phoneme": "ɔ",  "file": "2213_vignette_-o-ouvert.mp3"  }, # o ouvert proche de o
	KEY_U:  { "label": "ou", "phoneme": "u",  "file": "2195_vignette_-ou-.mp3"       },
	KEY_Y:  { "label": "u",  "phoneme": "y",  "file": "2197_vignette_-u-.mp3"        }, # u français proche de u
	KEY_W:  { "label": "wa", "phoneme": "wa", "file": "2571_vignette_-wa-.mp3"       }, # w → wa naturel
	KEY_H:  { "label": "eu", "phoneme": "ø",  "file": "2215_vignette_-eu-ferme.mp3"  }, # central
	KEY_J:  { "label": "eu", "phoneme": "œ",  "file": "2217_vignette_-eu-ouvert.mp3" }, # à côté de H

	# ── NASALES — regroupées côté droit ──────────────────────────────────────
	KEY_SEMICOLON: { "label": "an", "phoneme": "ɑ̃", "file": "2205_vignette_-an-_0.mp3" },
	KEY_K:         { "label": "in", "phoneme": "ɛ̃", "file": "2201_vignette_-in-.mp3"   },
	KEY_L:         { "label": "on", "phoneme": "ɔ̃", "file": "2203_vignette_-on-.mp3"   },

	# ── CONSONNES — lettre = son ──────────────────────────────────────────────
	KEY_B:  { "label": "b",  "phoneme": "b",  "file": "2542_vignette_-b-_0.mp3"      },
	KEY_D:  { "label": "d",  "phoneme": "d",  "file": "2546_vignette_-d-.mp3"        },
	KEY_F:  { "label": "f",  "phoneme": "f",  "file": "2556_vignette_-f-.mp3"        },
	KEY_G:  { "label": "g",  "phoneme": "g",  "file": "2550_vignette_-g-.mp3"        },
	KEY_M:  { "label": "m",  "phoneme": "m",  "file": "2552_vignette_-m-.mp3"        },
	KEY_N:  { "label": "n",  "phoneme": "n",  "file": "2554_vignette_-n-.mp3"        },
	KEY_V:  { "label": "v",  "phoneme": "v",  "file": "2558_vignette_-v-_0.mp3"      },
	KEY_Z:  { "label": "z",  "phoneme": "z",  "file": "2562_vignette_-z-.mp3"        },
	KEY_S:  { "label": "s",  "phoneme": "s",  "file": "2560_vignette_-s-.mp3"        },
	KEY_T:  { "label": "t",  "phoneme": "t",  "file": "2544_vignette_-t-.mp3"        },
	KEY_C:  { "label": "ch", "phoneme": "ʃ",  "file": "2564_vignette_-ch-.mp3"       }, # c → ch intuitif
	KEY_X:  { "label": "ge", "phoneme": "ʒ",  "file": "2566_vignette_-ge-.mp3"       }, # x → son proche
	KEY_Q:  { "label": "k",  "phoneme": "k",  "file": "2548_vignette_-k-.mp3"        }, # q → k naturel
	KEY_1:  { "label": "l",  "phoneme": "l",  "file": "2573_vignette_-l-.mp3"      }, # ✅ L → l
	KEY_2: { "label": "p", "phoneme": "p", "file": "2540_vignette_-p-_0.mp3"     },
	KEY_3: { "label": "r", "phoneme": "ʁ", "file": "2575_vignette_-r-.mp3"       },
}

# Isolated consonant/vowel sounds
const PHONEME_TO_FILE: Dictionary = {
	"i":  "2191_vignette_-i-.mp3",
	"a":  "2193_vignette_-a-.mp3",
	"u":  "2195_vignette_-ou-.mp3",
	"y":  "2197_vignette_-u-.mp3",
	"ɛ̃": "2201_vignette_-in-.mp3",
	"ɔ̃": "2203_vignette_-on-.mp3",
	"ɑ̃": "2205_vignette_-an-_0.mp3",
	"e":  "2207_vignette_-e-.mp3",
	"ɛ":  "2209_vignette_-e-.mp3",
	"o":  "2211_vignette_-o-ferme.mp3",
	"ɔ":  "2213_vignette_-o-ouvert.mp3",
	"ø":  "2215_vignette_-eu-ferme.mp3",
	"œ":  "2217_vignette_-eu-ouvert.mp3",
	"wa": "2571_vignette_-wa-.mp3",
	"p":  "2540_vignette_-p-_0.mp3",
	"b":  "2542_vignette_-b-_0.mp3",
	"t":  "2544_vignette_-t-.mp3",
	"d":  "2546_vignette_-d-.mp3",
	"k":  "2548_vignette_-k-.mp3",
	"g":  "2550_vignette_-g-.mp3",
	"m":  "2552_vignette_-m-.mp3",
	"n":  "2554_vignette_-n-.mp3",
	"f":  "2556_vignette_-f-.mp3",
	"v":  "2558_vignette_-v-_0.mp3",
	"s":  "2560_vignette_-s-.mp3",
	"z":  "2562_vignette_-z-.mp3",
	"ʃ":  "2564_vignette_-ch-.mp3",
	"ʒ":  "2566_vignette_-ge-.mp3",
	"l":  "2573_vignette_-l-.mp3",
	"ʁ":  "2575_vignette_-r-.mp3",
}

# Syllable file for each consonant (always the -xa- version)
const CONSONANT_SYLLABLE_FILE: Dictionary = {
	"p":  "2539_vignette_-pa-.mp3",
	"b":  "2541_vignette_-ba-.mp3",
	"t":  "2543_vignette_-ta-.mp3",
	"d":  "2545_vignette_-da-.mp3",
	"k":  "2547_vignette_-ka-.mp3",
	"g":  "2549_vignette_-ga-.mp3",
	"m":  "2551_vignette_-ma-.mp3",
	"n":  "2553_vignette_-na-.mp3",
	"f":  "2555_vignette_-fa-.mp3",
	"v":  "2557_vignette_-va-.mp3",
	"s":  "2559_vignette_-sa-.mp3",
	"z":  "2561_vignette_-za-.mp3",
	"ʃ":  "2563_vignette_-cha-.mp3",
	"ʒ":  "2565_vignette_-gea-.mp3",
	"l":  "2572_vignette_-la-.mp3",
	"ʁ":  "2574_vignette_-ra-.mp3",
}

const VOWELS: Array = [
	"i", "a", "u", "y", "e", "ɛ", "o", "ɔ", "ø", "œ",
	"ɑ̃", "ɛ̃", "ɔ̃", "wa", "ə",
]

const PHONEME_RULES: Array = [
	# ── De-nasalization: doubled consonant breaks the nasal vowel ─────────────
	# Must come BEFORE the nasal vowel rules below
	["onn", ["ɔ", "n"]],   # donne, bonne, sonne
	["omm", ["ɔ", "m"]],   # comme, somme, homme
	["ann", ["a", "n"]],   # anne, canne
	["amm", ["a", "m"]],   # flamme, gramme
	["emm", ["a", "m"]],   # femme (emm → am in French)
	["enn", ["ɛ", "n"]],   # antenne, penne
	["inn", ["i", "n"]],   # innocente
	["imm", ["i", "m"]],   # immense
	# ── Multi-char vowel clusters ─────────────────────────────────────────────
	["eau", "o"], ["ou", "u"], ["au", "o"],
	["ai", "ɛ"], ["ei", "ɛ"], ["oi", "wa"],
	["eu", "ø"],
	# ── Nasals (only reached when NOT preceded by a doubled consonant) ────────
	["an", "ɑ̃"], ["am", "ɑ̃"],
	["en", "ɑ̃"], ["em", "ɑ̃"],
	["in", "ɛ̃"], ["im", "ɛ̃"],
	["on", "ɔ̃"], ["om", "ɔ̃"],
	# ── Consonant clusters ────────────────────────────────────────────────────
	["ph", "f"], ["ch", "ʃ"],
	["qu", "k"], ["ce", "s"],
	# ── Accented vowels ───────────────────────────────────────────────────────
	["é", "e"], ["è", "ɛ"], ["ê", "ɛ"],
	["à", "a"], ["â", "a"], ["ç", "s"],
	# ── Single letters ────────────────────────────────────────────────────────
	["a", "a"], ["i", "i"],
	["o", "o"], ["u", "y"], ["y", "i"],
	["b", "b"], ["c", "k"], ["d", "d"],
	["f", "f"], ["g", "g"], ["h", ""],
	["j", "ʒ"], ["k", "k"], ["l", "l"],
	["m", "m"], ["n", "n"], ["p", "p"],
	["r", "ʁ"], ["s", "s"], ["t", "t"],
	["v", "v"], ["w", "v"], ["z", "z"],
]

var key_map: Dictionary = {}
var _players:       Array = []
var _current:       int   = 0
var _queue:         Array = []
var _overlap_timer: Timer = null
var _pause_timer:   Timer = null


func _ready() -> void:
	for i in 2:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

	_overlap_timer = Timer.new()
	_overlap_timer.one_shot = true
	_overlap_timer.timeout.connect(_on_overlap_timer)
	add_child(_overlap_timer)

	_pause_timer = Timer.new()
	_pause_timer.one_shot = true
	_pause_timer.timeout.connect(_on_pause_timer)
	add_child(_pause_timer)

	_build_default_mapping()
	_print_mapping()


func _build_default_mapping() -> void:
	key_map = BASE_MAP.duplicate(true)


func randomize_mappings() -> void:
	var keys:    Array = BASE_MAP.keys()
	var entries: Array = BASE_MAP.values().duplicate()
	entries.shuffle()
	key_map.clear()
	for i in keys.size():
		key_map[keys[i]] = entries[i]
	_print_mapping()


func _print_mapping() -> void:
	print("── Current mapping ──────────────────────────────────")
	for keycode in key_map:
		print("  ", OS.get_keycode_string(keycode),
			  "  →  ", key_map[keycode]["label"],
			  "  (", key_map[keycode]["file"], ")")
	print("─────────────────────────────────────────────────────")


# ─── Public speak API ─────────────────────────────────────────────────────────
func speak(text: String) -> void:
	var words := text.strip_edges().split(" ", false)
	for w_idx in words.size():
		var phonemes := decompose_to_phonemes(words[w_idx])
		print("[speak] %s → %s" % [words[w_idx], phonemes])

		var i := 0
		while i < phonemes.size():
			var ph:      String = phonemes[i]
			var next_ph: String = phonemes[i + 1] if i + 1 < phonemes.size() else ""

			if CONSONANT_SYLLABLE_FILE.has(ph) and next_ph in VOWELS:
				if next_ph == "a":
					# ── Best case: consonant + a → single -xa- clip, skip the a ──
					_queue.append(CONSONANT_SYLLABLE_FILE[ph])
					print("[speak]   %s+a → %s (skip a)" % [ph, CONSONANT_SYLLABLE_FILE[ph]])
					i += 2   # consume both the consonant and the "a"
				else:
					# ── Other vowel: -xa- for natural release, then vowel clip ──
					_queue.append(CONSONANT_SYLLABLE_FILE[ph])
					print("[speak]   %s+%s → syllable + vowel" % [ph, next_ph])
					i += 1   # only consume the consonant; vowel plays on next loop
			elif PHONEME_TO_FILE.has(ph):
				_queue.append(PHONEME_TO_FILE[ph])
				i += 1
			else:
				print("[speak] No audio for phoneme: '%s'" % ph)
				i += 1

		if w_idx < words.size() - 1:
			_queue.append(PAUSE_TOKEN)

	_try_play_next()


func decompose_to_phonemes(text: String) -> Array:
	var result: Array = []
	var input := text.to_lower()
	var i := 0
	while i < input.length():
		var matched := false
		for rule in PHONEME_RULES:
			var grapheme: String = rule[0]
			if input.substr(i, grapheme.length()) == grapheme:
				var output = rule[1]
				if output is String:
					if output != "":
						result.append(output)
				elif output is Array:
					for ph: String in output:
						if ph != "":
							result.append(ph)
				i += grapheme.length()
				matched = true
				break
		if not matched:
			i += 1
	return result


# ─── Queue / playback ─────────────────────────────────────────────────────────
func _try_play_next() -> void:
	if _overlap_timer.time_left > 0 or _pause_timer.time_left > 0:
		return
	if _queue.is_empty():
		return

	var filename: String = _queue.pop_front()
	if filename == PAUSE_TOKEN:
		_pause_timer.start(WORD_PAUSE_SEC)
		return

	_play_file(filename)


func _on_overlap_timer() -> void:
	_try_play_next()


func _on_pause_timer() -> void:
	_try_play_next()


func _play_file(filename: String) -> void:
	var path := "res://audio/" + filename
	var stream: AudioStream = load(path)
	if stream == null:
		push_warning("[InputManager] Audio not found: " + path)
		_try_play_next()
		return

	_current = (_current + 1) % 2
	var player: AudioStreamPlayer = _players[_current]
	player.pitch_scale = 1.0 + randf_range(-PITCH_VARIANCE, PITCH_VARIANCE)
	player.stream = stream
	player.play()

	var delay: float = max(stream.get_length() - OVERLAP_SEC, stream.get_length() * 0.5)
	_overlap_timer.start(delay)


# ─── Input handling ───────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var keycode: int = event.keycode

	if key_map.has(keycode):
		var entry: Dictionary = key_map[keycode]
		print("[InputManager] Key pressed: ", OS.get_keycode_string(keycode),
			  "  →  ", entry["label"])
		_play_file(entry["file"])
		phoneme_played.emit(entry["phoneme"])
	else:
		print("[InputManager] Untracked key (keycode: ", keycode, ")")
