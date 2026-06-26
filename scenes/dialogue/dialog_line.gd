class_name DialogLine
extends Control


signal done

@export var cps: float = 10

var data: String
var tween: Tween

@onready var rich_text_label: RichTextLabel = %RichTextLabel


func _ready() -> void:
	rich_text_label.text = data
	tween = create_tween()
	rich_text_label.visible_ratio = 0

	tween.set_loops(data.length())
	tween.tween_callback(func () -> void:
		rich_text_label.visible_characters += 1
	).set_delay(1.0 / cps)

	tween.finished.connect(func () -> void:
		tween = null
		done.emit()
	)


func _input(event: InputEvent) -> void:
	if is_instance_valid(tween) and tween.is_running() and event.is_action_pressed("dialog_skip"):
		get_viewport().set_input_as_handled()
		tween.custom_step(1e100)
		tween = null
