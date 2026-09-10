extends Node2D

@onready var text_one: Label = $UI/Board/textOne
@onready var text_two: Label = $UI/Board/textTwo
@onready var hurrey_sound: AudioStreamPlayer = $HurreySound
@onready var now_you_know_the_number_two_sound: AudioStreamPlayer = $NowYouKnowTheNumberTwoSound

@export var stagger_delay: float = 0.08
@export var word_gap: float = 0.2   # text_one aur text_two ke beech gap

func _ready() -> void:
	await get_tree().process_frame

	# HurreySound khatam hone ke baad text_one burst hoga
	if hurrey_sound.stream:
		hurrey_sound.play()
		await hurrey_sound.finished

	await burst_text_chars(text_one, stagger_delay)

	await get_tree().create_timer(word_gap).timeout

	# NowYouKnowTheNumberTwoSound khatam hone ke baad text_two burst hoga
	if now_you_know_the_number_two_sound.stream:
		now_you_know_the_number_two_sound.play()
		await now_you_know_the_number_two_sound.finished

	await burst_text_chars(text_two, stagger_delay)


func _on_home_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/start_scene.tscn")


func _on_reset_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/play_scene_one.tscn")


# ---------------------------------------------------------
# Single character burst animation
# ---------------------------------------------------------
func burst_text(label: Label) -> void:
	label.pivot_offset = label.size / 2
	label.scale = Vector2(0.0, 0.0)
	label.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(label, "modulate:a", 1.0, 0.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_property(label, "scale", Vector2(2.0, 2.0), 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.3) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------
# Character-by-character burst — poore Label ke text ko
# individual letters mein tod ke ek-ek karke burst karta hai
# ---------------------------------------------------------
func burst_text_chars(label: Label, delay: float = 0.08) -> void:
	var text := label.text
	if text.is_empty():
		return

	var original_size := label.size

	var font: Font
	var font_size: int
	if label.label_settings:
		font = label.label_settings.font
		font_size = label.label_settings.font_size
	else:
		font = label.get_theme_font("font")
		font_size = label.get_theme_font_size("font_size")

	if font == null:
		font = ThemeDB.fallback_font
	if font_size <= 0:
		font_size = ThemeDB.fallback_font_size

	var template: Label = label.duplicate()
	template.visible = true

	label.custom_minimum_size = original_size
	label.size = original_size
	label.text = ""

	var char_sizes: Array = []
	var total_width := 0.0
	for i in text.length():
		var c := text[i]
		var sz: Vector2 = font.get_string_size(c, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		char_sizes.append(sz)
		total_width += sz.x

	var align_offset := 0.0
	match label.horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			align_offset = (original_size.x - total_width) / 2.0
		HORIZONTAL_ALIGNMENT_RIGHT:
			align_offset = original_size.x - total_width
		_:
			align_offset = 0.0

	var vertical_offset := 0.0
	match label.vertical_alignment:
		VERTICAL_ALIGNMENT_CENTER:
			vertical_offset = (original_size.y - font_size) / 2.0
		VERTICAL_ALIGNMENT_BOTTOM:
			vertical_offset = original_size.y - font_size
		_:
			vertical_offset = 0.0

	var x_cursor := align_offset
	var char_labels: Array[Label] = []

	for i in text.length():
		var c := text[i]
		var char_label: Label = template.duplicate()

		char_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		char_label.anchor_left = 0
		char_label.anchor_top = 0
		char_label.anchor_right = 0
		char_label.anchor_bottom = 0
		char_label.grow_horizontal = Control.GROW_DIRECTION_END
		char_label.grow_vertical = Control.GROW_DIRECTION_END

		char_label.text = c
		char_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		char_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		char_label.custom_minimum_size = char_sizes[i]
		char_label.size = char_sizes[i]
		char_label.position = Vector2(x_cursor, vertical_offset)
		char_label.pivot_offset = char_sizes[i] / 2
		char_label.z_index = 1

		label.add_child(char_label)
		char_labels.append(char_label)

		x_cursor += char_sizes[i].x

	template.queue_free()

	for i in char_labels.size():
		var cl := char_labels[i]
		var t := get_tree().create_timer(i * delay)
		t.timeout.connect(func(): burst_text(cl))

	var single_burst_duration := 0.55
	var last_char_start_delay := (char_labels.size() - 1) * delay
	var total_wait := last_char_start_delay + single_burst_duration

	await get_tree().create_timer(total_wait).timeout
