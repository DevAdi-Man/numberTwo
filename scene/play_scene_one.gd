extends Node2D

@onready var tab_button_1: TextureButton = $UI/GridContainer/TabButton1
@onready var shocks: TextureRect = $UI/GridContainer/TabButton1/Shocks
@onready var tab_button_2: TextureButton = $UI/GridContainer/TabButton2
@onready var shoes: TextureRect = $UI/GridContainer/TabButton2/Shoes
@onready var tab_button_3: TextureButton = $UI/GridContainer/TabButton3
@onready var apple: TextureRect = $UI/GridContainer/TabButton3/Apple
@onready var tab_button_4: TextureButton = $UI/GridContainer/TabButton4
@onready var shoes_2: TextureRect = $UI/GridContainer/TabButton4/Shoes
@onready var tab_button_5: TextureButton = $UI/GridContainer/TabButton5
@onready var apple_2: TextureRect = $UI/GridContainer/TabButton5/Apple
@onready var tab_button_6: TextureButton = $UI/GridContainer/TabButton6
@onready var shocks_2: TextureRect = $UI/GridContainer/TabButton6/Shocks
@onready var pressed_sound: AudioStreamPlayer = $PressedSound

@onready var question: Label = $UI/QuestionBanner/Question
@onready var question_gesture: Label = $UI/QuestionBanner/QuestionGesture

@onready var wrong_answer: AudioStreamPlayer = $WrongAnswer
@onready var correct_answer: AudioStreamPlayer = $CorrectAnswer
@onready var level_completed: AudioStreamPlayer = $LevelCompleted


@onready var question_one_sound: AudioStreamPlayer = $QuestionOneSound
@onready var question_two_sound: AudioStreamPlayer = $QuestionTwoSound

@export var flip_duration: float = 0.18
@export var mismatch_wait: float = 0.6
@export var match_pop_scale: float = 1.15

@export var drop_in_distance: float = 60.0
@export var drop_in_duration: float = 0.5
@export var drop_in_stagger: float = 0.15
@onready var sound_button: TextureButton = $UI/SoundButton
@onready var next_button: TextureButton = $UI/NextButton
@onready var back_button: TextureButton = $UI/BackButton

@export var preview_duration: float = 2.0   # kitni der tak saare cards khule dikhenge

var cards: Array[Dictionary] = []
var first_card: Dictionary = {}
var second_card: Dictionary = {}
var is_checking: bool = false
var matched_count: int = 0


func _ready() -> void:
	next_button.visible = false
	cards = [
		{"button": tab_button_1, "object": shocks,   "id": "socks",  "matched": false, "flipped": false},
		{"button": tab_button_2, "object": shoes,    "id": "shoes",  "matched": false, "flipped": false},
		{"button": tab_button_3, "object": apple,    "id": "apple",  "matched": false, "flipped": false},
		{"button": tab_button_4, "object": shoes_2,  "id": "shoes",  "matched": false, "flipped": false},
		{"button": tab_button_5, "object": apple_2,  "id": "apple",  "matched": false, "flipped": false},
		{"button": tab_button_6, "object": shocks_2, "id": "socks",  "matched": false, "flipped": false},
	]

	for card in cards:
		var obj: TextureRect = card["object"]
		var btn: TextureButton = card["button"]

		obj.visible = false
		obj.modulate.a = 0.0
		obj.mouse_filter = Control.MOUSE_FILTER_IGNORE

		obj.pivot_offset = obj.size / 2
		btn.pivot_offset = btn.size / 2

		btn.pressed.connect(_on_card_pressed.bind(card))

		# Preview khatam hone tak koi bhi card click nahi ho sakta
		btn.disabled = true

	# -------------------------------------------------
	# QUESTION SEQUENCE
	# -------------------------------------------------
	await get_tree().process_frame

	await play_question_sequence()

	# -------------------------------------------------
	# PREVIEW: sab cards ek baar dikhado taki bachon ko
	# pata chale kaunsa card kahan hai, phir wapas hide
	# -------------------------------------------------
	await preview_cards()

	# Ab hi gameplay shuru — buttons enable karo
	for card in cards:
		card["button"].disabled = false


# ---------------------------------------------------------
# Question sequence
# ---------------------------------------------------------
func play_question_sequence() -> void:
	# ---------------------------------------------
	# Initially hide question visuals
	# ---------------------------------------------
	question.visible = false
	question_gesture.visible = false

	question.modulate.a = 0.0
	question_gesture.modulate.a = 0.0

	# ---------------------------------------------
	# QUESTION 1 SOUND
	# ---------------------------------------------
	if question_one_sound.stream:
		question_one_sound.play()

		# Wait until Question 1 sound is completely finished
		await question_one_sound.finished

	# ---------------------------------------------
	# QUESTION 1 REVEAL / ANIMATION
	# ---------------------------------------------
	question.visible = true
	question_gesture.visible = true

	drop_in_label(question, 0.0)
	drop_in_label(question_gesture, drop_in_stagger)

	# Wait for the animation to finish
	await get_tree().create_timer(
		drop_in_duration + drop_in_stagger
	).timeout

	# ---------------------------------------------
	# QUESTION 2 SOUND
	# ---------------------------------------------
	#
	# Q2 should NOT appear while Q1 is being played.
	# Q2 sound starts only after Q1 visual animation.
	#
	if question_two_sound.stream:
		question_two_sound.play()

		# Wait until Question 2 sound is completely finished
		await question_two_sound.finished

	# ---------------------------------------------
	# QUESTION 2 CAN NOW BE SHOWN
	# ---------------------------------------------
	#
	# If your Question 2 has different UI/animation,
	# trigger it here.
	#
	# Example:
	# show_question_two()
	#
	# For now nothing else is changed.


# ---------------------------------------------------------
# PREVIEW PHASE
# Sab cards ek saath flip open karo, thodi der dikhao,
# phir sab ek saath flip close kardo
# ---------------------------------------------------------
func preview_cards() -> void:
	# Phase 1: sab buttons ek saath "close" ho jaate hain (scale:x -> 0)
	var tween_in := create_tween()
	tween_in.set_parallel(true)
	for card in cards:
		var btn: TextureButton = card["button"]
		tween_in.tween_property(btn, "scale:x", 0.0, flip_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween_in.finished

	# Ab saare objects (shocks/shoes/apple) ek saath dikha do
	for card in cards:
		var obj: TextureRect = card["object"]
		obj.visible = true
		obj.modulate.a = 1.0
		card["flipped"] = true

	# Phase 2: sab buttons wapas khulte hain (scale:x -> 1) taaki object dikhe
	var tween_open := create_tween()
	tween_open.set_parallel(true)
	for card in cards:
		var btn: TextureButton = card["button"]
		tween_open.tween_property(btn, "scale:x", 1.0, flip_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween_open.finished

	# Sabko itni der tak dikhte rehne do
	await get_tree().create_timer(preview_duration).timeout

	# Phase 3: sab buttons ek saath close ho jaate hain
	var tween_close := create_tween()
	tween_close.set_parallel(true)
	for card in cards:
		var btn: TextureButton = card["button"]
		tween_close.tween_property(btn, "scale:x", 0.0, flip_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween_close.finished

	# Objects wapas hide kardo
	for card in cards:
		var obj: TextureRect = card["object"]
		obj.visible = false
		obj.modulate.a = 0.0

	# Phase 4: sab buttons wapas open ho jaate hain (khaali/blank state)
	var tween_out := create_tween()
	tween_out.set_parallel(true)
	for card in cards:
		var btn: TextureButton = card["button"]
		tween_out.tween_property(btn, "scale:x", 1.0, flip_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween_out.finished

	for card in cards:
		card["flipped"] = false


# ---------------------------------------------------------
# Label ko upar se slide + fade karke original position par
# le aata hai
# ---------------------------------------------------------
func drop_in_label(label: Label, delay: float = 0.0) -> void:
	var original_position: Vector2 = label.position

	# Start state
	label.position = original_position - Vector2(0, drop_in_distance)
	label.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

	if delay > 0.0:
		tween.tween_interval(delay)

	tween.tween_property(
		label,
		"modulate:a",
		1.0,
		drop_in_duration * 0.6
	).set_delay(delay) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		label,
		"position",
		original_position,
		drop_in_duration
	).set_delay(delay) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)


func _on_card_pressed(card: Dictionary) -> void:
	if is_checking or card["matched"] or card["flipped"]:
		return

	card["flipped"] = true

	await flip_card_open(card)

	if first_card.is_empty():
		first_card = card
	else:
		second_card = card
		is_checking = true

		await check_match()


func flip_card_open(card: Dictionary) -> void:
	var btn: TextureButton = card["button"]
	var obj: TextureRect = card["object"]

	var tween := create_tween()

	tween.tween_property(
		btn,
		"scale:x",
		0.0,
		flip_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished

	obj.visible = true
	obj.modulate.a = 1.0

	var tween2 := create_tween()

	tween2.tween_property(
		btn,
		"scale:x",
		1.0,
		flip_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tween2.finished


func flip_card_close(card: Dictionary) -> void:
	var btn: TextureButton = card["button"]
	var obj: TextureRect = card["object"]

	var tween := create_tween()

	tween.tween_property(
		btn,
		"scale:x",
		0.0,
		flip_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished

	obj.visible = false
	obj.modulate.a = 0.0

	var tween2 := create_tween()

	tween2.tween_property(
		btn,
		"scale:x",
		1.0,
		flip_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tween2.finished

	card["flipped"] = false


func check_match() -> void:
	if first_card["id"] == second_card["id"]:
		first_card["matched"] = true
		second_card["matched"] = true

		matched_count += 2

		# Correct match sound
		if correct_answer.stream:
			correct_answer.play()

		play_match_feedback(first_card["object"])
		play_match_feedback(second_card["object"])

		first_card["button"].disabled = true
		second_card["button"].disabled = true

	else:
		# Wrong match sound
		if wrong_answer.stream:
			wrong_answer.play()

		await get_tree().create_timer(mismatch_wait).timeout

		await flip_card_close(first_card)
		await flip_card_close(second_card)

	first_card = {}
	second_card = {}

	is_checking = false

	if matched_count == cards.size():
		await on_game_won()


func play_match_feedback(obj: TextureRect) -> void:
	var tween := create_tween()

	tween.tween_property(
		obj,
		"scale",
		Vector2(match_pop_scale, match_pop_scale),
		0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		obj,
		"scale",
		Vector2(1.0, 1.0),
		0.2
	).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func on_game_won() -> void:
	# Let the "correct answer" sound finish first, so it doesn't
	# overlap/mix with the level complete sound
	if correct_answer.playing:
		await correct_answer.finished

	# Level complete sound — wait for it to fully finish before moving on
	if level_completed.stream:
		level_completed.play()
		await level_completed.finished

	next_button.visible = true

func _on_home_button_pressed() -> void:
	pressed_sound.play()
	MusicManager.splash_icon(back_button)
	get_tree().change_scene_to_file("res://scene/start_scene.tscn")


func _on_sound_button_pressed() -> void:
	pressed_sound.play()
	MusicManager.toggle_music()
	MusicManager.sync_sound_button(sound_button)
	MusicManager.splash_icon(sound_button)


func _on_next_button_pressed() -> void:
	pressed_sound.play()
	MusicManager.splash_icon(next_button)
	get_tree().change_scene_to_file("res://scene/play_scene_two.tscn")
