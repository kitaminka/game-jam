extends Node


@export var start_music: bool = true


func _ready() -> void:
	if start_music:
		MusicManager.ensure_playing.call_deferred("main")
