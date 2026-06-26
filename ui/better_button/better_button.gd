class_name BetterButton
extends Button


# use load("sfx") to set some sfx as default
@export var _press_sfx: AudioStream
@export var sfx_volume_db: float = 0


func _ready() -> void:
	_set_sfx()
	pressed.connect(_on_press)


## Overridable method that is called on each button press
func _on_press() -> void:
	pass


func _set_sfx() -> void:
	var press_sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
	press_sfx_player.volume_db = sfx_volume_db
	press_sfx_player.bus = "SFX"
	press_sfx_player.stream = _press_sfx
	button_down.connect(press_sfx_player.play)
	add_child(press_sfx_player)
