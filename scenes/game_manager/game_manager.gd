extends Node


const DIALOG_SCENE := preload("res://scenes/dialogue/dialogue.tscn")

var _levels: Array[String]
var _pre_dialogs: Array[String]
var _final_dialog: String
var _current_level: int


func _init() -> void:
	RenderingServer.set_default_clear_color("#3e3b38")

	var f := FileAccess.open("res://scenes/levels/levels.txt", FileAccess.READ)

	if not f:
		push_error("no levels.txt")
		return

	var last_dialog: String = ""
	var found_dialogs: int = 0

	while not f.eof_reached():
		var l := f.get_line().strip_edges()

		if l.begins_with("#") or l == "":
			continue

		if l.begins_with("dialog:"):
			if last_dialog != "":
				push_error("multiple dialog: lines")
				continue

			found_dialogs += 1
			last_dialog = l.trim_prefix("dialog:").strip_edges()
			continue

		_pre_dialogs.push_back(last_dialog)
		last_dialog = ""

		_levels.push_back(l)

	if last_dialog != "":
		_final_dialog = last_dialog


	f.close()

	print("[GamaManager] discovered %d levels, %d dialogs" % [_levels.size(), found_dialogs])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_level"):
		get_viewport().set_input_as_handled()

		var current: Node = get_tree().current_scene

		if is_instance_valid(current) and current.get_meta("is_restartable", false) and not Transition.is_mid_transition():
			_restart_level()


func load_level(id: int) -> void:
	assert(1 <= id and id <= _levels.size(), "level id out of bounds")
	_current_level = id

	print("[GamaManager] loading level %d (%s)" % [id, _levels[id-1]])

	if _pre_dialogs[id-1] != "":
		print("[GamaManager] but first a little story (%s)..." % _pre_dialogs[id-1])
		await _play_dialog(_pre_dialogs[id-1])

	await Transition.change_scene_path(_levels[id-1])

	_initialize_level()



func last_level() -> int:
	return _levels.size()


func current_level() -> int:
	return _current_level

func _initialize_level() -> void:
	if not get_tree().current_scene.is_node_ready():
		await get_tree().current_scene.ready

	for e: Exit in get_tree().get_nodes_in_group(&"exit"):
		e.player_exited.connect(_next_level, CONNECT_ONE_SHOT)

	var cnb := ChainAndBalls.get_instance()
	if not cnb.got_lobotomized.is_connected(_restart_level):
		cnb.got_lobotomized.connect(_restart_level, CONNECT_ONE_SHOT)


func _next_level() -> void:
	Persistence.current_score = _current_level
	Persistence.submit()

	if _current_level >= last_level():
		print("[GameManager] last level completed")

		if _final_dialog != "":
			print("[GameManager] playing ending cutscene")
			await _play_dialog(_final_dialog)

		Transition.change_scene_path('res://ui/menus/main_menu/main_menu.tscn')
		return

	await load_level(_current_level + 1)


func _player_dead() -> void:
	get_tree().create_timer(2.0).timeout.connect(_restart_level)


func _restart_level() -> void:
	await Transition.reload_scene()
	_initialize_level()


func _play_dialog(s: String) -> void:
	var inst: DialogueManager = DIALOG_SCENE.instantiate()
	inst.scenario = FileAccess.get_file_as_string(s)
	Transition.change_scene_instance(inst)
	await inst.finished
