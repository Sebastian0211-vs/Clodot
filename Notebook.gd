extends CanvasLayer

# ─────────────────────────────────────────────────────────────────────────────
#  Notebook.gd  —  Pronunciation dictionary overlay
#
#  Each entry stores the phoneme labels captured at registration time.
#  The display always shows WHICH KEY currently produces each phoneme,
#  so after a randomisation the player knows exactly what to press.
# ─────────────────────────────────────────────────────────────────────────────

const SAVE_PATH := "user://notebook.json"

enum State { IDLE, RECORDING }

var _state:          State  = State.IDLE
var _recording_word: String = ""
var _recording_buf:  Array  = []

var _entries: Array = []

var _panel:        Control
var _word_input:   LineEdit
var _entry_list:   VBoxContainer
var _scroll:       ScrollContainer
var _rec_label:    Label
var _rec_preview:  Label
var _input_row:    HBoxContainer

var _is_open:    bool  = false
var _tween:      Tween = null

var _center_x:    float = 0.0
var _offscreen_x: float = 0.0
var _panel_y:     float = 0.0


func _ready() -> void:
	layer = 10
	_build_ui()
	_panel.modulate.a = 0.0
	_load()
	_refresh_list()


# ─── UI construction ──────────────────────────────────────────────────────────
func _build_ui() -> void:
	var vp      := get_viewport().get_visible_rect().size
	var panel_w := vp.x * 0.55
	var panel_h := vp.y * 0.85

	_center_x    = (vp.x - panel_w) * 0.5
	_offscreen_x = vp.x + 20.0
	_panel_y     = (vp.y - panel_h) * 0.5

	var anchor := Control.new()
	anchor.set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)

	_panel          = Control.new()
	_panel.size     = Vector2(panel_w, panel_h)
	_panel.position = Vector2(_offscreen_x, _panel_y)
	anchor.add_child(_panel)

	var bg := TextureRect.new()
	bg.texture      = load("res://assets/carnet.png")
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   int(panel_w * 0.20))
	margin.add_theme_constant_override("margin_right",  int(panel_w * 0.15))
	margin.add_theme_constant_override("margin_top",    int(panel_h * 0.18))
	margin.add_theme_constant_override("margin_bottom", int(panel_h * 0.18))
	_panel.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(root_vbox)

	var title := Label.new()
	title.text = "de prononciation"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color.BLACK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(title)

	_input_row = HBoxContainer.new()
	_input_row.add_theme_constant_override("separation", 4)
	root_vbox.add_child(_input_row)

	_word_input = LineEdit.new()
	_word_input.placeholder_text = "Nom du mot à noter..."
	_word_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_word_input.add_theme_font_size_override("font_size", 9)
	_word_input.add_theme_color_override("font_color", Color.BLACK)
	_word_input.add_theme_color_override("font_placeholder_color", Color(0.0, 0.0, 0.0, 0.4))
	var ts := StyleBoxEmpty.new()
	_word_input.add_theme_stylebox_override("normal",    ts)
	_word_input.add_theme_stylebox_override("focus",     ts)
	_word_input.add_theme_stylebox_override("read_only", ts)
	_word_input.text_submitted.connect(_on_word_submitted)
	_input_row.add_child(_word_input)

	var add_btn := Button.new()
	add_btn.text = "＋"
	add_btn.flat = true
	add_btn.add_theme_font_size_override("font_size", 10)
	add_btn.add_theme_color_override("font_color", Color.BLACK)
	add_btn.pressed.connect(func(): _on_word_submitted(_word_input.text))
	_input_row.add_child(add_btn)

	_rec_label = Label.new()
	_rec_label.add_theme_font_size_override("font_size", 8)
	_rec_label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.7))
	_rec_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rec_label.visible = false
	root_vbox.add_child(_rec_label)

	_rec_preview = Label.new()
	_rec_preview.add_theme_font_size_override("font_size", 10)
	_rec_preview.add_theme_color_override("font_color", Color.BLACK)
	_rec_preview.visible = false
	root_vbox.add_child(_rec_preview)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(_scroll)

	_entry_list = VBoxContainer.new()
	_entry_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_list.add_theme_constant_override("separation", 4)
	_scroll.add_child(_entry_list)


# ─── Input ────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var kc: int = event.keycode

	if kc == KEY_CAPSLOCK:
		get_viewport().set_input_as_handled()
		_toggle()
		return

	if not _is_open:
		return

	if _state == State.RECORDING:
		get_viewport().set_input_as_handled()
		match kc:
			KEY_ENTER, KEY_KP_ENTER:
				_confirm_recording()
			KEY_BACKSPACE:
				if _recording_buf.size() > 0:
					_recording_buf.pop_back()
					_update_rec_preview()
			KEY_ESCAPE:
				_cancel_recording()
			_:
				if InputManager.key_map.has(kc):
					var label: String = InputManager.key_map[kc]["label"]
					_recording_buf.append(label)
					_update_rec_preview()
					InputManager._play_file(InputManager.key_map[kc]["file"])


# ─── Toggle ───────────────────────────────────────────────────────────────────
func _toggle() -> void:
	if _is_open:
		if _state == State.RECORDING:
			_cancel_recording()
		_slide_out()
	else:
		_slide_in()


func _slide_in() -> void:
	_is_open = true

	if _tween:
		_tween.kill()
		_tween = null

	_panel.position   = Vector2(_offscreen_x, _panel_y)
	_panel.modulate.a = 1.0

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.tween_property(_panel, "position:x", _center_x, 0.45)

	# Refresh so key labels are up to date with current mapping
	_refresh_list()
	_word_input.grab_focus()
	_word_input.clear()


func _slide_out() -> void:
	_is_open = false

	if _tween:
		_tween.kill()
		_tween = null

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.tween_property(_panel, "position:x", _offscreen_x, 0.35)


# ─── Recording ────────────────────────────────────────────────────────────────
func _on_word_submitted(raw: String) -> void:
	var word := raw.strip_edges().to_lower()
	if word.is_empty():
		return

	for entry in _entries:
		if entry["word"] == word:
			_word_input.clear()
			_flash_entry(word)
			return

	_recording_word = word
	_recording_buf  = []
	_state          = State.RECORDING

	_input_row.visible   = false
	_rec_label.visible   = true
	_rec_preview.visible = true
	_rec_label.text = "« %s »  —  appuie sur tes touches\n⌫ effacer  •  Entrée valider  •  Échap annuler" % word
	_update_rec_preview()
	_word_input.release_focus()


func _update_rec_preview() -> void:
	if _recording_buf.is_empty():
		_rec_preview.text = "( ... )"
	else:
		_rec_preview.text = "  ".join(_recording_buf)


func _confirm_recording() -> void:
	if _recording_buf.is_empty():
		_cancel_recording()
		return

	_entries.append({ "word": _recording_word, "phonemes": _recording_buf.duplicate() })
	_save()
	_refresh_list()

	await get_tree().process_frame
	_scroll.scroll_vertical = _scroll.get_v_scroll_bar().max_value

	print("[Notebook] Ajouté : %s → %s" % [_recording_word, _recording_buf])
	_exit_recording()


func _cancel_recording() -> void:
	print("[Notebook] Annulé.")
	_exit_recording()


func _exit_recording() -> void:
	_state          = State.IDLE
	_recording_word = ""
	_recording_buf  = []

	_input_row.visible   = true
	_rec_label.visible   = false
	_rec_preview.visible = false

	_word_input.clear()
	_word_input.grab_focus()


# ─── Key lookup ───────────────────────────────────────────────────────────────
# Returns the key name (e.g. "A", "F1") currently mapped to a given phoneme
# label, or "?" if none found.
func _key_for_phoneme(phoneme_label: String) -> String:
	for keycode in InputManager.key_map:
		if InputManager.key_map[keycode]["label"] == phoneme_label:
			return OS.get_keycode_string(keycode)
	return "?"


# ─── Entry list UI ────────────────────────────────────────────────────────────
func _refresh_list() -> void:
	for child in _entry_list.get_children():
		child.queue_free()

	if _entries.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Aucun mot enregistré."
		empty_lbl.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.4))
		empty_lbl.add_theme_font_size_override("font_size", 8)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_entry_list.add_child(empty_lbl)
		return

	for entry in _entries:
		_entry_list.add_child(_make_row(entry))


func _make_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	# ✕ delete on the left
	var del_btn := Button.new()
	del_btn.text = "✕"
	del_btn.flat = true
	del_btn.add_theme_font_size_override("font_size", 7)
	del_btn.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.5))
	del_btn.pressed.connect(func(): _remove_entry(entry["word"]))
	row.add_child(del_btn)

	# Build key sequence: each stored phoneme → current key name in [brackets]
	var key_parts: Array = []
	for ph in entry["phonemes"]:
		key_parts.append("[%s]" % _key_for_phoneme(ph))

	# "word  —  [A] [F2] [K] ..."  — click to play
	var lbl := Label.new()
	lbl.text = "%s  —  %s" % [entry["word"], " ".join(key_parts)]
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	lbl.tooltip_text = "Clic pour écouter"
	lbl.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_play_phoneme_sequence(entry["phonemes"])
	)
	row.add_child(lbl)

	return row


# ─── Playback ─────────────────────────────────────────────────────────────────
func _play_phoneme_sequence(phonemes: Array) -> void:
	for ph in phonemes:
		for keycode in InputManager.key_map:
			if InputManager.key_map[keycode]["label"] == ph:
				InputManager._queue.append(InputManager.key_map[keycode]["file"])
				break
	InputManager._try_play_next()


func _flash_entry(word: String) -> void:
	for row in _entry_list.get_children():
		if row is HBoxContainer:
			var lbl := row.get_child(1) as Label
			if lbl and lbl.text.begins_with(word):
				var tween := create_tween()
				tween.tween_property(lbl, "modulate", Color(1.0, 0.4, 0.4), 0.1)
				tween.tween_property(lbl, "modulate", Color(1.0, 1.0, 1.0), 0.5)
				return


func _remove_entry(word: String) -> void:
	_entries = _entries.filter(func(e): return e["word"] != word)
	_save()
	_refresh_list()
	print("[Notebook] Supprimé : %s" % word)


# ─── Persistence ──────────────────────────────────────────────────────────────
func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[Notebook] Impossible d'enregistrer : " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(_entries, "\t"))
	file.close()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Array:
		_entries = parsed
		print("[Notebook] %d mot(s) chargé(s)." % _entries.size())
