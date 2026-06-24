extends Node


class MusicEntry:
	var preloop_path: String
	var loop_path: String

	func _init(new_preloop_path: String, new_loop_path: String):
		preloop_path = new_preloop_path
		loop_path = new_loop_path


var entries: Dictionary[String, MusicEntry] = {
	"main_menu":
		MusicEntry.new
		(
			"res://assets/audio/music/main_menu_preloop_w_pause.wav",
			"res://assets/audio/music/main_menu_loop.wav"
		),
	"main":
		MusicEntry.new
		(
			"res://assets/audio/music/main_preloop_w_pause.wav",
			"res://assets/audio/music/main_loop.wav"
		)
}

var _player: AudioStreamPlayer
var _have_selected_entry: bool = false
var _selected_entry_key: String
var _selected_preloop: AudioStream
var _selected_loop: AudioStream


func _ready() -> void:
	_player = AudioStreamPlayer.new()

	add_child(_player)

	_player.bus = "Music"
	_player.finished.connect(_do_loop)
	_player.process_mode = Node.PROCESS_MODE_ALWAYS


func ensure_playing(key: String) -> void:
	if key not in entries:
		push_error("unknown key: '%s'" % key)
		return

	if _have_selected_entry and _selected_entry_key == key:
		return

	var entry := entries[key]

	_have_selected_entry = true
	_selected_entry_key = key
	_selected_preloop = load(entry.preloop_path)
	_selected_loop = load(entry.loop_path)

	_player.stream = _selected_preloop
	_player.play()


func _do_loop() -> void:
	_player.stream = _selected_loop
	_player.play()
