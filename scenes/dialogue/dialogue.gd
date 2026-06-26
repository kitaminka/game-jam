class_name DialogueManager
extends PanelContainer


signal finished

var scenario: String
var _soft_finished: bool = false

var _is_waiting: bool = false
signal _wait_interrupted

@onready var container: VBoxContainer = %MessageContainer
@onready var scroll: ScrollContainer = %ScrollContainer


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await _wait_or_input(2)

	const LINE_JAMES: PackedScene = preload("res://scenes/dialogue/line_james.tscn")
	const LINE_PHONE: PackedScene = preload("res://scenes/dialogue/line_phone.tscn")
	const LINE_NARRATOR: PackedScene = preload("res://scenes/dialogue/line_narrator.tscn")

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
			'N': scn = LINE_NARRATOR
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

		if not inst.is_done():
			await inst.done

		await _wait_or_input(0.5)

	var l := Label.new()
	l.text = "-- PRESS SPACE --"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(HSeparator.new())
	container.add_child(l)

	await get_tree().process_frame
	scroll.ensure_control_visible(l)

	await _wait_or_input(9999999999999)
	finished.emit()


func _input(event: InputEvent) -> void:
	if _is_waiting and event.is_action_pressed("dialog_skip"):
		get_viewport().set_input_as_handled()
		_wait_interrupted.emit()



func _wait_or_input(t: float) -> void:
	_is_waiting = true
	var timer := get_tree().create_timer(t)
	timer.timeout.connect(_wait_interrupted.emit)
	await _wait_interrupted
	_is_waiting = false
	timer.timeout.disconnect(_wait_interrupted.emit)
