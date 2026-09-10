extends Node

var music_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.stream = preload("res://assets/sound/edugamery-music-17.mp3")
	music_player.volume_db = -15.0  # lower this to make it quieter (e.g. -20, -30)
	music_player.play()

func toggle_music() -> void:
	if music_player.playing:
		music_player.stop()
	else:
		music_player.play()

func sync_sound_button(btn: TextureButton) -> void:
	btn.button_pressed = !music_player.playing

func splash_icon(button:TextureButton) -> void:
	var icon  := create_tween()
	icon.tween_property(button, "modulate", Color(1.3, 1.3, 1.3), 0.1)
	icon.tween_property(button, "modulate", Color(1, 1, 1), 0.2)
