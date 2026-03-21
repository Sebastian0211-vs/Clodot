extends Node


var _player: AudioStreamPlayer


const BASE_MAP: Dictionary = {
	# ── Vowels ────────────────────────────────────────────────────
	KEY_I:  { "label": "-i-",        "file": "2191_vignette_-i-.mp3"           },
	KEY_A:  { "label": "-a-",        "file": "2193_vignette_-a-.mp3"           },
	KEY_O:  { "label": "-ou-",       "file": "2195_vignette_-ou-.mp3"          },
	KEY_U:  { "label": "-u-",        "file": "2197_vignette_-u-.mp3"           },
	KEY_N:  { "label": "-in-",       "file": "2201_vignette_-in-.mp3"          },
	KEY_M:  { "label": "-on-",       "file": "2203_vignette_-on-.mp3"          },
	KEY_W:  { "label": "-an-",       "file": "2205_vignette_-an-_0.mp3"        },
	KEY_E:  { "label": "-e- (fermé)","file": "2207_vignette_-e-.mp3"           },
	KEY_R:  { "label": "-e- (ouvert)","file": "2209_vignette_-e-.mp3"          },
	KEY_0:  { "label": "-o- fermé",  "file": "2211_vignette_-o-ferme.mp3"      },
	KEY_9:  { "label": "-o- ouvert", "file": "2213_vignette_-o-ouvert.mp3"     },
	KEY_8:  { "label": "-eu- fermé", "file": "2215_vignette_-eu-ferme.mp3"     },
	KEY_7:  { "label": "-eu- ouvert","file": "2217_vignette_-eu-ouvert.mp3"    },
	# ── Consonants (with vowel + alone) ───────────────────────────
	KEY_P:  { "label": "-pa-",       "file": "2539_vignette_-pa-.mp3"          },
	KEY_F1: { "label": "-p-",        "file": "2540_vignette_-p-_0.mp3"         },
	KEY_B:  { "label": "-ba-",       "file": "2541_vignette_-ba-.mp3"          },
	KEY_F2: { "label": "-b-",        "file": "2542_vignette_-b-_0.mp3"         },
	KEY_T:  { "label": "-ta-",       "file": "2543_vignette_-ta-.mp3"          },
	KEY_F3: { "label": "-t-",        "file": "2544_vignette_-t-.mp3"           },
	KEY_D:  { "label": "-da-",       "file": "2545_vignette_-da-.mp3"          },
	KEY_F4: { "label": "-d-",        "file": "2546_vignette_-d-.mp3"           },
	KEY_K:  { "label": "-ka-",       "file": "2547_vignette_-ka-.mp3"          },
	KEY_C:  { "label": "-k-",        "file": "2548_vignette_-k-.mp3"           },
	KEY_G:  { "label": "-ga-",       "file": "2549_vignette_-ga-.mp3"          },
	KEY_H:  { "label": "-g-",        "file": "2550_vignette_-g-.mp3"           },
	KEY_COMMA:     { "label": "-ma-","file": "2551_vignette_-ma-.mp3"          },
	KEY_SEMICOLON: { "label": "-m-", "file": "2552_vignette_-m-.mp3"           },
	KEY_J:  { "label": "-na-",       "file": "2553_vignette_-na-.mp3"          },
	KEY_L:  { "label": "-n-",        "file": "2554_vignette_-n-.mp3"           },
	KEY_1:  { "label": "-fa-",       "file": "2555_vignette_-fa-.mp3"          },
	KEY_2:  { "label": "-va-",       "file": "2557_vignette_-va-.mp3"          },
	KEY_V:  { "label": "-v-",        "file": "2558_vignette_-v-_0.mp3"         },
	KEY_3:  { "label": "-sa-",       "file": "2559_vignette_-sa-.mp3"          },
	KEY_4:  { "label": "-za-",       "file": "2561_vignette_-za-.mp3"          },
	KEY_Z:  { "label": "-z-",        "file": "2562_vignette_-z-.mp3"           },
	KEY_5:  { "label": "-cha-",      "file": "2563_vignette_-cha-.mp3"         },
	KEY_Q:  { "label": "-ch-",       "file": "2564_vignette_-ch-.mp3"          },
	KEY_6:  { "label": "-gea-",      "file": "2565_vignette_-gea-.mp3"         },
	KEY_X:  { "label": "-ge-",       "file": "2566_vignette_-ge-.mp3"          },
	KEY_Y:  { "label": "-ja-",       "file": "2567_vignette_-ja-.mp3"          },
}

var key_map: Dictionary = {}


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_build_default_mapping()
	_print_mapping()


func _build_default_mapping() -> void:
	key_map = BASE_MAP.duplicate(true)
	print("[InputManager] Default mapping restored.")


func randomize_mappings() -> void:
	var keys:    Array = BASE_MAP.keys()
	var entries: Array = BASE_MAP.values().duplicate()
	entries.shuffle()
	key_map.clear()
	for i in keys.size():
		key_map[keys[i]] = entries[i]
	print("[InputManager] Mappings randomized!")
	_print_mapping()


func _print_mapping() -> void:
	print("── Current mapping ──────────────────────────────────")
	for keycode in key_map:
		print("  ", OS.get_keycode_string(keycode),
			  "  →  ", key_map[keycode]["label"],
			  "  (", key_map[keycode]["file"], ")")
	print("─────────────────────────────────────────────────────")


func _play(filename: String) -> void:
	var path := "res://audio/" + filename
	var stream = load(path)
	if stream == null:
		push_warning("[InputManager] Audio not found: " + path)
		return
	_player.stream = stream
	_player.play()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var keycode: int = event.keycode

	if key_map.has(keycode):
		var entry: Dictionary = key_map[keycode]
		print("[InputManager] Key pressed: ", OS.get_keycode_string(keycode),
			  "  →  ", entry["label"])
		_play(entry["file"])
	else:
		print("[InputManager] Untracked key (keycode: ", keycode, ")")
