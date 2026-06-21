extends AudioStreamPlayer


@export var loop_stream: AudioStream


func _ready() -> void:
	finished.connect(func() -> void:
		stream = loop_stream
		play()
	)


func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		volume_db = -7
	else:
		volume_db = 0
