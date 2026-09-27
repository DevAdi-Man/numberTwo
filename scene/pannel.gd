extends Node2D

@onready var panel: Panel = $CanvasLayer/PannelBackground/Panel
@onready var laddoo: TextureRect = $CanvasLayer/PannelBackground/Panel/Laddoo
@onready var laddoo_2: TextureRect = $CanvasLayer/PannelBackground/Panel/Laddoo2
@onready var laddoo_3: TextureRect = $CanvasLayer/PannelBackground/Panel/Laddoo3
@onready var button_box: HBoxContainer = $CanvasLayer/PannelBackground/Panel/HBoxContainer
@onready var home: TextureButton = $CanvasLayer/PannelBackground/Panel/HBoxContainer/HomeButton
@onready var replay: TextureButton = $CanvasLayer/PannelBackground/Panel/HBoxContainer/ReplayButton

# HBoxContainer ki original position store karne ke liye
var button_box_original_pos: Vector2


func _ready() -> void:
	_setup_initial_states()
	_play_entrance_animation()
	# Fallback to direct HTTP request using token from cmdline
	var token = ""
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--token="):
			token = arg.trim_prefix("--token=")
		elif arg == "--token" and OS.get_cmdline_args().find("--token") != -1:
			var idx = OS.get_cmdline_args().find("--token")
			if idx + 1 < OS.get_cmdline_args().size():
				token = OS.get_cmdline_args()[idx + 1]

	if token != "":
		push_error("DEBUG_FORCE: Found token, doing HTTP Request")
		var http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.request_completed.connect(self._on_request_completed)
		var url = "https://bheem.ilifelearn.com/api/player/progress/ladoos"
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + token]
		var body = JSON.stringify({"gameId": "number-two", "gameName": "Number Two", "ladoos": 3})
		http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	else:
		print("DEBUG_FORCE: Token not found in cmdline")


func _setup_initial_states() -> void:
	# container ki original position save kar lo (buttons is se hi controlled hain)
	button_box_original_pos = button_box.position

	# panel ko chhota rakho shuru me (center se scale hoga)
	panel.pivot_offset = panel.size / 2
	panel.scale = Vector2.ZERO

	# laddoos bhi chhote rakho shuru me
	laddoo.pivot_offset = laddoo.size / 2
	laddoo_2.pivot_offset = laddoo_2.size / 2
	laddoo_3.pivot_offset = laddoo_3.size / 2
	laddoo.scale = Vector2.ZERO
	laddoo_2.scale = Vector2.ZERO
	laddoo_3.scale = Vector2.ZERO

	# poore button_box ko neeche aur invisible rakho, individual buttons ko touch mat karo
	button_box.modulate.a = 0.0
	button_box.position.y = button_box_original_pos.y + 40


func _play_entrance_animation() -> void:
	# 1. Sabse pehle panel pop-in hoga
	var panel_tween := create_tween()
	panel_tween.set_trans(Tween.TRANS_BACK)
	panel_tween.set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(panel, "scale", Vector2.ONE, 0.5)

	await panel_tween.finished

	# 2. Uske baad laddoos ek ek karke apni jagah aayenge
	_animate_laddoo(laddoo)
	await get_tree().create_timer(0.15).timeout

	_animate_laddoo(laddoo_2)
	await get_tree().create_timer(0.15).timeout

	_animate_laddoo(laddoo_3)
	await get_tree().create_timer(0.4).timeout

	# 3. Sabse aakhir me poora button_box (Home + Replay dono) apni original jagah settle hoga
	_animate_button_box()


func _animate_laddoo(target: TextureRect) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", Vector2.ONE, 0.6)


func _animate_button_box() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button_box, "modulate:a", 1.0, 0.35)
	tween.tween_property(button_box, "position", button_box_original_pos, 0.35)


func _on_home_pressed() -> void:
	get_tree().quit()


func _on_replay_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/play_scene_one.tscn")
