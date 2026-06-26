extends CanvasLayer


@onready var bg: CanvasItem = $BG


func _process(_delta: float) -> void:
	visible = get_tree().paused
	bg.visible = visible


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&'pause_game'):
		return

	get_viewport().set_input_as_handled()
	for child: Node in %ContinueButton.get_children():
		if is_instance_of(child, AudioStreamPlayer):
			(child as AudioStreamPlayer).play()
	get_tree().paused = not get_tree().paused
