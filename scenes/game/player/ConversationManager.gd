# ConversationManager.gd — Autoload
extends Node

signal conversation_started(pnj)
signal conversation_ended

var in_conversation = false
var current_pnj = null
var player = null
var camera = null

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
	
	emit_signal("conversation_started", pnj)

func end_conversation() -> void:
	if not in_conversation:
		return
	in_conversation = false
	
	var ct = camera.create_tween().set_parallel(true)
	ct.tween_property(camera, "zoom", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_IN_OUT)
	ct.tween_property(camera, "global_position", player.global_position, 0.3)
	
	current_pnj = null
	emit_signal("conversation_ended")
