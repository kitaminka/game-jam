class_name SfxPlayer
extends Node2D


@export var audio_streams: Dictionary[String, AudioStream]

var players: Dictionary[String, AudioStreamPlayer2D]


func _ready() -> void:
	var player_tmpl := $AudioStreamPlayer2D

	player_tmpl.get_parent().remove_child(player_tmpl)

	for key: String in audio_streams.keys():
		var player: AudioStreamPlayer2D = player_tmpl.duplicate()
		players[key] = player
		player.name = key
		player.stream = audio_streams[key]
		add_child(player)


# returns the played audio stream
func play_stream_from(key: String) -> AudioStream:
	if key not in audio_streams:
		push_error("unknown key: '%s'" % key)
		return null

	var player := players[key]

	player.play()

	return audio_streams[key]
