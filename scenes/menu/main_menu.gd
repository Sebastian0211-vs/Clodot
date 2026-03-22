extends Control

const GAME_SCENE := "res://scenes/game/world.tscn"

# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var title_sprite : AnimatedSprite2D = $Title
@onready var play_btn     : Button   = $PlayBtn
@onready var scanlines    : TextureRect = $Scanlines

# ── State ─────────────────────────────────────────────────────────────────────
var _stars        : Array   = []
var _time         : float   = 0.0
var _transitioning: bool    = false
var _btn_ready    : bool    = false

# ── Colours (match game palette) ─────────────────────────────────────────────
const C_BG     := Color(0.04, 0.05, 0.12)          # deep midnight blue
const C_YELLOW := Color(0.96, 0.94, 0.62)          # stamina-bar gold
const C_BLUE   := Color(0.55, 0.78, 0.90)          # thirsty-bar blue
const C_DIM    := Color(0.25, 0.30, 0.55, 0.35)    # dim star tint


func _ready() -> void:
	_seed_stars()
	_style_button()
	_build_scanlines()
	_run_intro()
	play_btn.pressed.connect(_on_play_pressed)


# ── Stars ─────────────────────────────────────────────────────────────────────
func _seed_stars() -> void:
	var vp := get_viewport_rect().size
	for i in 90:
		_stars.append({
			"x"   : randf() * vp.x,
			"y"   : randf() * vp.y,
			"r"   : randf_range(0.25, 1.1),
			"spd" : randf_range(0.4, 2.5),
			"phi" : randf() * TAU,
			"col" : C_BLUE if randf() > 0.7 else Color(1, 1, 1),
		})


# ── Scanline overlay ──────────────────────────────────────────────────────────
func _build_scanlines() -> void:
	var img  := Image.create(2, 6, false, Image.FORMAT_RGBA8)
	for y in 6:
		var a := 0.0 if y < 2 else 0.0 if y < 4 else 0.13
		img.set_pixel(0, y, Color(0, 0, 0, a))
		img.set_pixel(1, y, Color(0, 0, 0, a))
	var tex := ImageTexture.create_from_image(img)

	scanlines.texture             = tex
	scanlines.texture_repeat      = CanvasItem.TEXTURE_REPEAT_ENABLED
	scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	scanlines.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	scanlines.modulate            = Color(1, 1, 1, 0.55)


# ── Button style (pixel-bordered, gold) ───────────────────────────────────────
func _style_button() -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb     := StyleBoxFlat.new()
		var is_hov: bool = state in ["hover", "pressed"]
		sb.bg_color        = Color(C_YELLOW.r, C_YELLOW.g, C_YELLOW.b, 0.14) if is_hov \
		                     else Color(C_BG.r, C_BG.g, C_BG.b, 0.85)
		sb.border_color    = C_YELLOW if state != "focus" else Color(C_YELLOW.r, C_YELLOW.g, C_YELLOW.b, 0.4)
		sb.set_border_width_all(1)
		sb.content_margin_left   = 10
		sb.content_margin_right  = 10
		sb.content_margin_top    = 4
		sb.content_margin_bottom = 4
		play_btn.add_theme_stylebox_override(state, sb)

	play_btn.add_theme_color_override("font_color",         C_YELLOW)
	play_btn.add_theme_color_override("font_hover_color",   Color(1.0, 1.0, 0.80))
	play_btn.add_theme_color_override("font_pressed_color", C_YELLOW)
	play_btn.add_theme_font_size_override("font_size", 7)


# ── Intro tween ───────────────────────────────────────────────────────────────
func _run_intro() -> void:
	title_sprite.modulate.a     = 0.0
	title_sprite.position.y    += 8.0
	play_btn.modulate.a         = 0.0
	play_btn.scale              = Vector2(0.85, 0.85)

	var tw := create_tween()
	tw.tween_interval(0.25)

	# Title slides up and fades in
	tw.set_parallel(true)
	tw.tween_property(title_sprite, "modulate:a", 1.0, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(title_sprite, "position:y", title_sprite.position.y - 8.0, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(false)

	tw.tween_interval(0.35)

	# Button pops in
	tw.set_parallel(true)
	tw.tween_property(play_btn, "modulate:a", 1.0, 0.45)
	tw.tween_property(play_btn, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(false)

	tw.tween_callback(func(): _btn_ready = true)


# ── Per-frame ─────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

	# Gentle title bob (clamped so it never clips top)
	if title_sprite.modulate.a >= 0.99:
		title_sprite.position.y = 44.0 + sin(_time * 1.8) * 1.5

	# Play-button gold pulse
	if _btn_ready and not _transitioning:
		var p := sin(_time * 3.2) * 0.07 + 0.93
		play_btn.modulate = Color(1.0, 1.0, p, 1.0)


# ── Custom draw (background + stars) ─────────────────────────────────────────
func _draw() -> void:
	var vp := get_viewport_rect().size

	# Background gradient (top darker, bottom slightly lighter)
	draw_rect(Rect2(Vector2.ZERO, vp), C_BG)
	draw_rect(Rect2(0, vp.y * 0.55, vp.x, vp.y * 0.45), Color(0.05, 0.07, 0.15, 0.35))

	# Stars
	for s in _stars:
		var twinkle := sin(_time * s["spd"] + s["phi"]) * 0.38 + 0.62
		var col     := Color(s["col"].r, s["col"].g, s["col"].b, twinkle * 0.75)
		draw_circle(Vector2(s["x"], s["y"]), s["r"], col)

	# Subtle horizon glow
	var glow_y := vp.y * 0.62
	for i in 12:
		var t     := float(i) / 12.0
		var alpha := (1.0 - t) * 0.06
		draw_line(Vector2(0, glow_y + i * 0.7), Vector2(vp.x, glow_y + i * 0.7),
		          Color(C_BLUE.r, C_BLUE.g, C_BLUE.b, alpha))


# ── Play button ───────────────────────────────────────────────────────────────
func _on_play_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	play_btn.disabled = true

	var tw := create_tween()
	# Brief white flash on button
	tw.tween_property(play_btn, "modulate", Color(2, 2, 2, 1.0), 0.06)
	tw.tween_property(play_btn, "modulate", Color(1, 1, 1, 1.0), 0.08)
	tw.tween_interval(0.1)
	# Fade whole screen to black
	tw.tween_property(self, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): get_tree().change_scene_to_file(GAME_SCENE))
