extends Control

const URL := "https://www.addictionsuisse.ch/faits-et-chiffres/alcool/alcool-prevention/"

@onready var img : TextureRect = $Image

# ── Call this from anywhere to safely go to the end screen ───────────────────
static func go(node: Node) -> void:
	node.get_tree().change_scene_to_file("res://scenes/end/end_screen.tscn")

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	img.modulate.a = 0.0
	modulate.a     = 1.0

	var tw := create_tween()
	tw.tween_property(img, "modulate:a", 1.0, 1.2).set_ease(Tween.EASE_OUT)
	tw.tween_interval(3.5)
	tw.tween_property(self, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tw.tween_callback(_finish)


func _finish() -> void:
	OS.shell_open(URL)
	get_tree().quit()
