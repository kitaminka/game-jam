class_name DialogueManager
extends PanelContainer


signal finished

var scenario: String
var _soft_finished: bool = false

@onready var container: VBoxContainer = %MessageContainer
@onready var scroll: ScrollContainer = %ScrollContainer


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await get_tree().create_timer(2.0).timeout

	const LINE_JAMES: PackedScene = preload("res://scenes/dialogue/line_james.tscn")
	const LINE_PHONE: PackedScene = preload("res://scenes/dialogue/line_phone.tscn")

	var lines := scenario.split("\n", false)
	var first := true

	for line: String in lines:
		line = line.strip_edges()

		if line.is_empty():
			continue

		var speaker := line[0]
		var data := line.substr(1).strip_edges()

		var scn: PackedScene
		match speaker:
			'#': continue
			'J': scn = LINE_JAMES
			'P': scn = LINE_PHONE
			_:
				push_error("unknown speaker: %s" % speaker)
				continue

		if not first:
			container.add_child(HSeparator.new())
		first = false

		var inst: DialogLine = scn.instantiate()
		inst.data = data

		container.add_child(inst)

		await get_tree().process_frame
		scroll.ensure_control_visible(inst)

		await inst.done
		await get_tree().create_timer(0.5).timeout

	var l := Label.new()
	l.text = "-- PRESS SPACE --"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(HSeparator.new())
	container.add_child(l)

	await get_tree().process_frame
	scroll.ensure_control_visible(l)

	_soft_finished = true


func _input(event: InputEvent) -> void:
	if _soft_finished and event.is_action_pressed("dialog_skip"):
		get_viewport().set_input_as_handled()
		finished.emit()
		_soft_finished = false
