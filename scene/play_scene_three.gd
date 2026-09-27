extends Node2D

@onready var butter_fly_two: TextureButton = $UI/ButterFlyTwo
@onready var butter_fly_one: TextureButton = $UI/ButterFlyOne

@onready var question: Label = $UI/QuestionBanner/Question
@onready var question_2: Label = $UI/QuestionBanner/Question2

@onready var number_one_background: TextureRect = $UI/NumberOneBackground
@onready var one: Label = $UI/NumberOneBackground/One
@onready var number_two_background: TextureRect = $UI/NumberTwoBackground
@onready var two: Label = $UI/NumberTwoBackground/Two
@onready var question_one_sound: AudioStreamPlayer = $QuestionOneSound
@onready var question_two_sound: AudioStreamPlayer = $QuestionTwoSound
@onready var wrong_answer: AudioStreamPlayer = $WrongAnswer
@onready var correct_answer: AudioStreamPlayer = $CorrectAnswer
@onready var level_completed: AudioStreamPlayer = $LevelCompleted
@onready var oneSound: AudioStreamPlayer = $One
@onready var twoSound: AudioStreamPlayer = $Two

@onready var pressed_sound: AudioStreamPlayer = $PressedSound
@onready var next_button: TextureButton = $UI/NextButton

@onready var sound_button: TextureButton = $UI/SoundButton
@onready var back_button: TextureButton = $UI/BackButton

@export var appear_duration_pop: float = 0.25
@export var appear_duration_settle: float = 0.3
@export var appear_overshoot: float = 1.2

@export var label_pop_delay: float = 0.15
@export var label_pop_overshoot: float = 1.3

@export var drop_in_distance: float = 60.0
@export var drop_in_duration: float = 0.5
@export var drop_in_stagger: float = 0.15

var click_count: int = 0

func _ready() -> void:
	next_button.visible = false
	setup_hidden(number_one_background)
	setup_hidden(number_two_background)
	setup_hidden(one)
	setup_hidden(two)

	await get_tree().process_frame

	await play_question_sequence()


# ---------------------------------------------------------
# Question sequence
# ---------------------------------------------------------
func play_question_sequence() -> void:
	# ---------------------------------------------
	# Initially hide question visuals
	# ---------------------------------------------
	question.visible = false
	question_2.visible = false

	question.modulate.a = 0.0
	question_2.modulate.a = 0.0

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

	drop_in_label(question, 0.0)

	# Wait for the animation to finish
	await get_tree().create_timer(drop_in_duration).timeout

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
	# QUESTION 2 REVEAL / ANIMATION
	# ---------------------------------------------
	question_2.visible = true

	drop_in_label(question_2, 0.0)


func _on_butter_fly_one_pressed() -> void:
	# ButterflyOne hamesha apna hi background use karega (position-wise fixed)
	await handle_butterfly_click(butter_fly_one, number_one_background, one)


func _on_butter_fly_two_pressed() -> void:
	# ButterflyTwo hamesha apna hi background use karega (position-wise fixed)
	await handle_butterfly_click(butter_fly_two, number_two_background, two)


# ---------------------------------------------------------
# btn        -> jo butterfly dabaya gaya
# bg         -> USI butterfly ka apna fixed background (position match)
# label      -> USI background ka apna label
# Lekin label ka TEXT aur SOUND click-order (sequence) se decide hoga
# ---------------------------------------------------------
func handle_butterfly_click(btn: TextureButton, bg: TextureRect, label: Label) -> void:
	if btn.disabled:
		return

	btn.disabled = true
	click_count += 1

	if click_count == 1:
		label.text = "1"

		if oneSound.stream:
			oneSound.play()
	elif click_count == 2:
		label.text = "2"

		if twoSound.stream:
			twoSound.play()

	appear_item(bg)
	pop_label(label)

	if click_count == 2:
		await on_game_won()


func on_game_won() -> void:
	# Let the "Two" sequence sound finish first
	if twoSound.playing:
		await twoSound.finished

	# Both butterflies are now correctly placed — play the correct answer sound
	if correct_answer.stream:
		correct_answer.play()
		await correct_answer.finished

	# Level complete sound — wait for it to fully finish before moving on
	if level_completed.stream:
		level_completed.play()
		await level_completed.finished

	next_button.visible = true

func setup_hidden(item: Control) -> void:
	item.visible = false
	item.modulate.a = 0.0
	item.scale = Vector2.ZERO
	item.pivot_offset = item.size / 2


func appear_item(item: Control) -> void:
	if item.visible and item.modulate.a >= 1.0:
		return

	item.visible = true
	item.scale = Vector2.ZERO
	item.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(item, "modulate:a", 1.0, appear_duration_pop) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_property(item, "scale", Vector2(appear_overshoot, appear_overshoot), appear_duration_pop) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.chain().tween_property(item, "scale", Vector2(1.0, 1.0), appear_duration_settle) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func pop_label(label: Label) -> void:
	label.visible = true
	label.scale = Vector2.ZERO
	label.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(label, "modulate:a", 1.0, appear_duration_pop) \
		.set_delay(label_pop_delay) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_property(label, "scale", Vector2(label_pop_overshoot, label_pop_overshoot), appear_duration_pop) \
		.set_delay(label_pop_delay) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.chain().tween_property(label, "scale", Vector2(1.0, 1.0), appear_duration_settle) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func drop_in_label(label: Label, delay: float = 0.0) -> void:
	var original_position: Vector2 = label.position

	label.position = original_position - Vector2(0, drop_in_distance)
	label.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(label, "modulate:a", 1.0, drop_in_duration * 0.6) \
		.set_delay(delay) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_property(label, "position", original_position, drop_in_duration) \
		.set_delay(delay) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_home_button_pressed() -> void:
	pressed_sound.play()
	MusicManager.splash_icon(back_button)
	get_tree().change_scene_to_file("res://scene/start_scene.tscn");


func _on_sound_button_pressed() -> void:
	pressed_sound.play()
	MusicManager.toggle_music()
	MusicManager.splash_icon(sound_button)
	MusicManager.sync_sound_button(sound_button)


func _on_next_button_pressed() -> void:
	pressed_sound.play()
	MusicManager.splash_icon(next_button)
	get_tree().change_scene_to_file("res://scene/result_scene.tscn")
