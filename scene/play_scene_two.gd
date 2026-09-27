extends Node2D

@onready var laddoo_one: TextureButton = $UI/DragBoardLaddoo/LaddooOne
@onready var laddoo_two: TextureButton = $UI/DragBoardLaddoo/LaddooTwo
@onready var laddoo_one_appear: TextureRect = $UI/Plate/LaddooOneAppear
@onready var laddoo_two_appear: TextureRect = $UI/Plate/LaddooTwoAppear
@onready var question: Label = $UI/QuestionBanner/Question
@onready var question_2: Label = $UI/QuestionBanner/Question2
@onready var question_one_sound: AudioStreamPlayer = $QuestionOneSound
@onready var question_two_sound: AudioStreamPlayer = $QuestionTwoSound
@onready var wrong_answer: AudioStreamPlayer = $WrongAnswer
@onready var correct_answer: AudioStreamPlayer = $CorrectAnswer
@onready var level_completed: AudioStreamPlayer = $LevelCompleted
@onready var pressed_sound: AudioStreamPlayer = $PressedSound
@onready var sound_button: TextureButton = $UI/SoundButton

@onready var next_button: TextureButton = $UI/NextButton
@onready var back_button: TextureButton = $UI/BackButton

@export var appear_duration_pop: float = 0.25
@export var appear_duration_settle: float = 0.3
@export var appear_overshoot: float = 1.2
@export var disappear_duration: float = 0.2

@export var drop_in_distance: float = 60.0
@export var drop_in_duration: float = 0.5
@export var drop_in_stagger: float = 0.15

var laddoo_one_picked: bool = false
var laddoo_two_picked: bool = false


func _ready() -> void:
	next_button.visible = false
	
	laddoo_one_appear.visible = false
	laddoo_one_appear.modulate.a = 0.0
	laddoo_one_appear.scale = Vector2.ZERO
	laddoo_one_appear.pivot_offset = laddoo_one_appear.size / 2

	laddoo_two_appear.visible = false
	laddoo_two_appear.modulate.a = 0.0
	laddoo_two_appear.scale = Vector2.ZERO
	laddoo_two_appear.pivot_offset = laddoo_two_appear.size / 2

	laddoo_one.pivot_offset = laddoo_one.size / 2
	laddoo_two.pivot_offset = laddoo_two.size / 2

	# Question sound khatam hone tak koi bhi laddoo tap nahi ho sakta
	laddoo_one.disabled = true
	laddoo_two.disabled = true

	await get_tree().process_frame

	await play_question_sequence()

	# Ab hi laddoo buttons enable honge
	laddoo_one.disabled = false
	laddoo_two.disabled = false


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


func _on_laddoo_one_pressed() -> void:
	if laddoo_one.disabled:
		return

	laddoo_one.disabled = true
	laddoo_one_picked = true

	# Both laddoos are valid answers, so this always plays the correct sound
	if correct_answer.stream:
		correct_answer.play()

	await move_and_appear(laddoo_one, laddoo_one_appear)

	await check_level_complete()


func _on_laddoo_two_pressed() -> void:
	if laddoo_two.disabled:
		return

	laddoo_two.disabled = true
	laddoo_two_picked = true

	# Both laddoos are valid answers, so this always plays the correct sound
	if correct_answer.stream:
		correct_answer.play()

	await move_and_appear(laddoo_two, laddoo_two_appear)

	await check_level_complete()


var level_won: bool = false

func check_level_complete() -> void:
	if laddoo_one_picked and laddoo_two_picked:
		if not level_won:
			level_won = true
			await on_game_won()


func move_and_appear(item: Control, target: TextureRect) -> void:
	var tween := create_tween()
	var target_pos = target.global_position
	
	# Move slowly to target
	tween.tween_property(item, "global_position", target_pos, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	item.visible = false
	
	# Small pop when it lands
	target.visible = true
	target.modulate.a = 1.0
	target.scale = Vector2(1.2, 1.2)
	
	var pop_tween := create_tween()
	pop_tween.tween_property(target, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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


func disappear_item(item: Control) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(item, "modulate:a", 0.0, disappear_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(item, "scale", Vector2(0.6, 0.6), disappear_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	item.visible = false


func appear_item(item: TextureRect) -> void:
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
	get_tree().change_scene_to_file("res://scene/start_scene.tscn")
	


func _on_sound_button_pressed() -> void:
	pressed_sound.play()
	MusicManager.toggle_music()
	MusicManager.splash_icon(sound_button)
	MusicManager.sync_sound_button(sound_button)


func _on_next_button_pressed() -> void:
	pressed_sound.play()
	MusicManager.splash_icon(next_button)
	get_tree().change_scene_to_file("res://scene/play_scene_three.tscn")
