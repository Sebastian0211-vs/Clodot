extends CanvasLayer

# ─────────────────────────────────────────────────────────────────────────────
#  Notebook.gd  —  Pronunciation dictionary overlay
#  Add as AutoLoad in Project Settings → AutoLoad
#  Toggle with TAB. LineEdit focus blocks InputManager when open.
# ─────────────────────────────────────────────────────────────────────────────

const SAVE_PATH := "user://notebook.json"

var _entries: Array = []   # Array of { "word": String, "phonemes": Array }

# ── UI nodes built in _ready ──────────────────────────────────────────────────
var _panel:      PanelContainer
var _word_input: LineEdit
var _entry_list: VBoxContainer
var _scroll:     ScrollContainer


func _ready() -> void:
	layer = 10
	# Counteract window/stretch/scale=8 so we can use normal pixel values
	var stretch: float = ProjectSettings.get_setting("display/window/size/scale", 1.0)
	if stretch == 0.0: stretch = 1.0
	scale = Vector2.ONE / stretch
	_build_ui()
	_panel.visible = false
	_load()
	_refresh_list()


# ─── UI construction ──────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Normal screen pixels — the CanvasLayer scale compensates for stretch
	var panel_w: float = 380.0   # ← tweak this (screen pixels)
	var panel_h: float = 460.0   # ← tweak this (screen pixels)

	var screen := Vector2(DisplayServer.window_get_size())
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.size = Vector2(panel_w, panel_h)
	_panel.position = Vector2((screen.x - panel_w) / 2.0, (screen.y - panel_h) / 2.0)
	add_child(_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(root_vbox)

	# ── Header ────────────────────────────────────────────────────────────────
	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	var title := Label.new()
	title.text = "📓 Mon carnet de prononciation"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 14)
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.pressed.connect(_close)
	header.add_child(close_btn)

	# ── Input row ─────────────────────────────────────────────────────────────
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 6)
	root_vbox.add_child(input_row)

	_word_input = LineEdit.new()
	_word_input.placeholder_text = "Écrire un mot à noter..."
	_word_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_word_input.text_submitted.connect(_on_word_submitted)
	input_row.add_child(_word_input)

	var add_btn := Button.new()
	add_btn.text = "＋ Ajouter"
	add_btn.pressed.connect(func(): _on_word_submitted(_word_input.text))
	input_row.add_child(add_btn)

	# ── Hint ──────────────────────────────────────────────────────────────────
	var hint := Label.new()
	hint.text = "Entrée pour ajouter  •  ▶ pour écouter  •  TAB pour fermer"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	root_vbox.add_child(hint)

	root_vbox.add_child(HSeparator.new())

	# ── Scrollable entry list ─────────────────────────────────────────────────
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size = Vector2(0, 300)
	root_vbox.add_child(_scroll)

	_entry_list = VBoxContainer.new()
	_entry_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_list.add_theme_constant_override("separation", 4)
	_scroll.add_child(_entry_list)


# ─── Toggle ───────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_toggle()
			get_viewport().set_input_as_handled()


func _toggle() -> void:
	_panel.visible = not _panel.visible
	if _panel.visible:
		_word_input.grab_focus()
		_word_input.clear()


func _close() -> void:
	_panel.visible = false


# ─── Add entry ────────────────────────────────────────────────────────────────
func _on_word_submitted(raw: String) -> void:
	var word := raw.strip_edges().to_lower()
	if word.is_empty():
		return

	# Duplicate check
	for entry in _entries:
		if entry["word"] == word:
			_word_input.clear()
			_flash_entry(word)
			return

	var phonemes: Array = InputManager.decompose_to_phonemes(word)
	_entries.append({ "word": word, "phonemes": phonemes })
	_save()
	_refresh_list()
	_word_input.clear()
	_word_input.grab_focus()

	# Scroll to bottom so the new entry is visible
	await get_tree().process_frame
	_scroll.scroll_vertical = _scroll.get_v_scroll_bar().max_value

	print("[Notebook] Ajouté : %s → %s" % [word, phonemes])


# ─── Entry list UI ────────────────────────────────────────────────────────────
func _refresh_list() -> void:
	for child in _entry_list.get_children():
		child.queue_free()

	if _entries.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Aucun mot enregistré pour l'instant."
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_entry_list.add_child(empty_lbl)
		return

	for entry in _entries:
		_entry_list.add_child(_make_row(entry))


func _make_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# ▶ Play button
	var play_btn := Button.new()
	play_btn.text = "▶"
	play_btn.tooltip_text = "Écouter"
	play_btn.custom_minimum_size = Vector2(32, 0)
	play_btn.pressed.connect(func():
		InputManager.speak(entry["word"])
	)
	row.add_child(play_btn)

	# Word
	var word_lbl := Label.new()
	word_lbl.text = entry["word"]
	word_lbl.add_theme_font_size_override("font_size", 15)
	word_lbl.custom_minimum_size = Vector2(130, 0)
	row.add_child(word_lbl)

	# Phonemes
	var phoneme_lbl := Label.new()
	phoneme_lbl.text = "/ %s /" % "  ".join(entry["phonemes"])
	phoneme_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 0.95))
	phoneme_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phoneme_lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(phoneme_lbl)

	# ✕ Delete button
	var del_btn := Button.new()
	del_btn.text = "✕"
	del_btn.tooltip_text = "Supprimer"
	del_btn.flat = true
	del_btn.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	del_btn.pressed.connect(func(): _remove_entry(entry["word"]))
	row.add_child(del_btn)

	return row


func _flash_entry(word: String) -> void:
	for row in _entry_list.get_children():
		if row is HBoxContainer:
			var lbl := row.get_child(1) as Label
			if lbl and lbl.text == word:
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
