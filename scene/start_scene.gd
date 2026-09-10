extends Node2D

@onready var logo_board: TextureRect = $UI/LogoBoard
@onready var logo_board_two: TextureRect = $UI/LogoBoardTwo
@onready var chhota: Label = $UI/LogoBoardTwo/Chhota
@onready var bheem: Label = $UI/LogoBoardTwo/Bheem
@onready var title: Label = $UI/LogoBoard/title
@onready var title_4: Label = $UI/LogoBoard/title4
@onready var title_2: Label = $UI/LogoBoard/title2
@onready var title_3: Label = $UI/LogoBoard/title3
@onready var sound_button: TextureButton = $UI/SoundButton
@onready var pressed_sound: AudioStreamPlayer = $PressedSound
@onready var play_icon: TextureButton = $UI/PlayButtonBackground/PlayIcon

@export var swing_speed: float = 1.2
@export var scale_amount: float = 0.08
@export var rotate_amount: float = 2.0
@export var phase_offset: float = 0.5

var time_elapsed: float = 0.0

func _ready() -> void:
	logo_board.pivot_offset = Vector2(logo_board.size.x / 2, 0)
	logo_board_two.pivot_offset = Vector2(logo_board_two.size.x / 2, 0)

	await get_tree().process_frame

	# Ab ek word poora burst hone ke BAAD hi agla shuru hoga
	await burst_text_chars(title)
	await burst_text_chars(title_2)
	await burst_text_chars(title_3)
	await burst_text_chars(title_4)
	await burst_text_chars(chhota)
	await burst_text_chars(bheem)

func _process(delta: float) -> void:
	time_elapsed += delta
	var t1 := sin(time_elapsed * swing_speed)
	var t2 := sin(time_elapsed * swing_speed + phase_offset)

	logo_board.rotation_degrees = t1 * rotate_amount
	logo_board.scale.y = 1.0 + (t1 * scale_amount)

	logo_board_two.rotation_degrees = t2 * rotate_amount
	logo_board_two.scale.y = 1.0 + (t2 * scale_amount)


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


# Ab yeh function "await-able" hai — jab tak sab characters burst
# complete nahi ho jaate, yeh return nahi karega.
func burst_text_chars(label: Label, stagger_delay: float = 0.08) -> void:
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

		# --- IMPORTANT FIX: anchors/grow ko top-left pe reset karo ---
		# taaki position/size plain absolute coords ki tarah kaam karein,
		# original label ke anchor preset se affect na ho
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
		var t := get_tree().create_timer(i * stagger_delay)
		t.timeout.connect(func(): burst_text(cl))

	var single_burst_duration := 0.55
	var last_char_start_delay := (char_labels.size() - 1) * stagger_delay
	var total_wait := last_char_start_delay + single_burst_duration

	await get_tree().create_timer(total_wait).timeout


func _on_play_icon_pressed() -> void:
	pressed_sound.play()
	MusicManager.splash_icon(play_icon)
	get_tree().change_scene_to_file("res://scene/play_scene_one.tscn")


func _on_sound_button_pressed() -> void:
	pressed_sound.play()
	MusicManager.toggle_music()
	MusicManager.sync_sound_button(sound_button)

	# Small flash/pulse on the cart icon as feedback, no size change
	var sound_tween := create_tween()
	sound_tween.tween_property(sound_button, "modulate", Color(1.3, 1.3, 1.3), 0.1)
	sound_tween.tween_property(sound_button, "modulate", Color(1, 1, 1), 0.2)
