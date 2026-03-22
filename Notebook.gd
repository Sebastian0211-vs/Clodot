extends CanvasLayer

# ─────────────────────────────────────────────────────────────────────────────
#  Notebook.gd  —  Pronunciation dictionary overlay
#  Toggle with TAB — slides in from the right.
# ─────────────────────────────────────────────────────────────────────────────

const SAVE_PATH := "user://notebook.json"

var _entries: Array = []

var _panel:      Control
var _word_input: LineEdit
var _entry_list: VBoxContainer
var _scroll:     ScrollContainer

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

	# ── Background image ─────────────────────────────────────────────────────
	var bg := TextureRect.new()
	bg.texture      = load("res://assets/carnet.png")
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(bg)

	# ── Content margin ────────────────────────────────────────────────────────
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

	# ── Title ─────────────────────────────────────────────────────────────────
	var title := Label.new()
	title.text = " "
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color.BLACK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(title)

	# ── Input row ─────────────────────────────────────────────────────────────
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 4)
	root_vbox.add_child(input_row)

	_word_input = LineEdit.new()
	_word_input.placeholder_text = "Écrire un mot..."
	_word_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_word_input.add_theme_font_size_override("font_size", 9)
	_word_input.add_theme_color_override("font_color", Color.BLACK)
	_word_input.add_theme_color_override("font_placeholder_color", Color(0.0, 0.0, 0.0, 0.4))
	var transparent_style := StyleBoxEmpty.new()
	_word_input.add_theme_stylebox_override("normal",    transparent_style)
	_word_input.add_theme_stylebox_override("focus",     transparent_style)
	_word_input.add_theme_stylebox_override("read_only", transparent_style)
	_word_input.text_submitted.connect(_on_word_submitted)
	input_row.add_child(_word_input)

	var add_btn := Button.new()
	add_btn.text = "＋"
	add_btn.flat = true
	add_btn.add_theme_font_size_override("font_size", 10)
	add_btn.add_theme_color_override("font_color", Color.BLACK)
	add_btn.pressed.connect(func(): _on_word_submitted(_word_input.text))
	input_row.add_child(add_btn)

	# ── Scrollable entry list ─────────────────────────────────────────────────
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
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			get_viewport().set_input_as_handled()
			_toggle()


func _toggle() -> void:
	if _is_open:
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


func _close() -> void:
	_slide_out()


# ─── Add entry ────────────────────────────────────────────────────────────────
func _on_word_submitted(raw: String) -> void:
	var word := raw.strip_edges().to_lower()
	if word.is_empty():
		return

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

	await get_tree().process_frame
	_scroll.scroll_vertical = _scroll.get_v_scroll_bar().max_value

	print("[Notebook] Ajouté : %s → %s" % [word, phonemes])


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

	# ✕ delete button on the LEFT
	var del_btn := Button.new()
	del_btn.text = "✕"
	del_btn.flat = true
	del_btn.add_theme_font_size_override("font_size", 7)
	del_btn.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.5))
	del_btn.pressed.connect(func(): _remove_entry(entry["word"]))
	row.add_child(del_btn)

	# Word + phonemes label — click to play
	var lbl := Label.new()
	lbl.text = "%s  —  / %s /" % [entry["word"], "  ".join(entry["phonemes"])]
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	lbl.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			InputManager.speak(entry["word"])
	)
	row.add_child(lbl)

	return row


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
