extends Control


const _FLAIL_GROUP := &"flailball"
const _FLAIL := preload("res://scenes/flail/flail_ball.tscn")

@export var speedup_delta: float = PI
@export var default_flail_speed: float = TAU / 4
@export var max_flail_levels: int = 4
@export var flail_nested_length_ratio: float = 0.75
@export var flail_nested_speed_ratio: float = 2
@export var flail_initial_length: float = 100.0

signal upgrade_done

var _is_upgrading: bool

var _budget_new_flails: int
var _budget_speedups: int
var _hovered_flails: Array[FlailBall] = []

@onready var _button_speedup: Button = %ButtonSpeedup
@onready var _button_new_flail: Button = %ButtonNewFlail
@onready var _button_change_dir: Button = %ButtonChangeDir
@onready var _button_exit: Button = %ButtonExit


func _input(event: InputEvent) -> void:
	if not _is_upgrading:
		if OS.is_debug_build() and event.is_action_pressed(&"debug_start_upgrade"):
			get_viewport().set_input_as_handled()
			start_upgrade_sequence(999, 999)
		return

	var ev := event as InputEventMouseButton
	if ev == null:
		return

	if ev.button_index == MOUSE_BUTTON_LEFT and ev.is_pressed() and not _hovered_flails.is_empty():
		get_viewport().set_input_as_handled()
		_do_upgrade()


func start_upgrade_sequence(new_flails: int, speedups: int) -> void:
	var t := create_tween().set_ignore_time_scale(true)
	t.tween_property(Engine, "time_scale", 0.01, 1)
	await t.finished

	show()

	_is_upgrading = true

	_budget_new_flails += new_flails
	_budget_speedups += speedups

	_button_speedup.disabled = _budget_speedups == 0
	_button_new_flail.disabled = _budget_new_flails == 0

	_reset_buttons()
	_button_change_dir.button_pressed = true

	# player is upgrading...

	_start_flail_monitor()

	await _button_exit.pressed

	_stop_flail_monitor()

	# teardown

	hide()

	_is_upgrading = false

	t = create_tween().set_ignore_time_scale(true)
	t.tween_property(Engine, "time_scale", 1, 1)
	await t.finished

	upgrade_done.emit()


func _start_flail_monitor() -> void:
	_hovered_flails.clear()
	for flail: FlailBall in get_tree().get_nodes_in_group(_FLAIL_GROUP):
		if not flail.hurt_box.mouse_entered.is_connected(_flail_hovered):
			flail.hurt_box.mouse_entered.connect(_flail_hovered, CONNECT_APPEND_SOURCE_OBJECT)
		if not flail.hurt_box.mouse_exited.is_connected(_flail_not_hovered):
			flail.hurt_box.mouse_exited.connect(_flail_not_hovered, CONNECT_APPEND_SOURCE_OBJECT)


func _stop_flail_monitor() -> void:
	for flail: FlailBall in _hovered_flails:
		flail.set_selected(false)
	_hovered_flails.clear()
	queue_redraw()


func _flail_hovered(node: Node) -> void:
	if not _is_upgrading:
		return

	var f := node.get_parent() as FlailBall
	if is_instance_valid(f):
		_hovered_flails.push_back(f)
		_update_selected()


func _flail_not_hovered(node: Node) -> void:
	if not _is_upgrading:
		return

	var f := node.get_parent() as FlailBall
	_hovered_flails.erase(f)
	f.set_selected(false)
	_update_selected()


func _update_selected() -> void:
	for node: FlailBall in _hovered_flails:
		node.set_selected(false)
	if not _hovered_flails.is_empty():
		_hovered_flails[0].set_selected(true)


func _do_upgrade() -> void:
	var flail := _hovered_flails[0]

	if _button_change_dir.button_pressed:
		_do_change_dir(flail)
	elif _button_new_flail.button_pressed:
		_do_add_flail(flail)
	elif _button_speedup.button_pressed:
		_do_speedup(flail)
	else:
		# nothing is selected somehow??
		push_error("trying to upgrade by no mode is selected")


func _do_change_dir(flail: FlailBall) -> void:
	print("do change dir")
	if flail.parent == null:
		print("cannot change dir in root!")
		return

	flail.rotation_speed = -flail.rotation_speed
	# TODO: draw visual maybe

func _do_speedup(flail: FlailBall) -> void:
	print("do speedup")

	if flail.parent == null:
		print("cannot speedup root!")
		return

	flail.rotation_speed = signf(flail.rotation_speed) * absf(flail.rotation_speed) + speedup_delta

	# TODO: draw visual maybe

	_budget_speedups -= 1
	if _budget_speedups <= 0:
		_button_speedup.disabled = true
		_reset_buttons()
		_button_change_dir.button_pressed = true


func _do_add_flail(flail: FlailBall) -> void:
	print("do add flail")
	var inst := _FLAIL.instantiate() as FlailBall

	var depth: int = 0
	var ff := flail
	while ff != null:
		ff = ff.parent
		depth += 1

	if depth >= max_flail_levels:
		print("nesting too deep!")
		return

	print(depth)
	inst.parent = flail
	inst.radius = flail_initial_length * (flail_nested_length_ratio ** (depth-1))
	inst.rotation_speed = default_flail_speed * (flail_nested_speed_ratio ** (depth-1)) * (randi_range(0, 1) * 2 - 1) * clampf(randfn(1, 0.9), 0.5, 1.5)
	inst.starting_rotation_angle = randf_range(0, TAU)

	inst.ready.connect((
		func () -> void:
			inst.hurt_box.mouse_entered.connect(_flail_hovered, CONNECT_APPEND_SOURCE_OBJECT)
			inst.hurt_box.mouse_exited.connect(_flail_not_hovered, CONNECT_APPEND_SOURCE_OBJECT)
	), CONNECT_ONE_SHOT)

	flail.get_parent().add_child(inst)
	flail.force_update_position()

	_budget_new_flails -= 1
	if _budget_new_flails <= 0:
		_button_new_flail.disabled = true
		_reset_buttons()
		_button_change_dir.button_pressed = true


func _reset_buttons() -> void:
	_button_change_dir.set_pressed_no_signal(false)
	_button_new_flail.set_pressed_no_signal(false)
	_button_speedup.set_pressed_no_signal(false)
