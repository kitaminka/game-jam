extends Node


var _levels: Array[String]
var _current_level: int


func _init() -> void:
	var f := FileAccess.open("res://scenes/files/levels.txt", FileAccess.READ)

	if not f:
		push_error("no levels.txt")
		return

	while not f.eof_reached():
		var l := f.get_line()
		_levels.push_back(l)
	f.close()


func load_level(id: int) -> void:
	assert(1 <= id and id <= _levels.size(), "level id out of bounds")
	_current_level = id - 1

	Transition.change_scene_path(_levels[_current_level])

	for e: Exit in get_tree().get_nodes_in_group(&"exit"):
		e.player_exited.connect(_next_level, CONNECT_ONE_SHOT)

	var cnb := ChainAndBalls.get_instance()
	if not cnb.got_lobotomized.is_connected(_player_dead):
		cnb.got_lobotomized.connect(_player_dead, CONNECT_ONE_SHOT)


func last_level() -> int:
	return _levels.size()


func _next_level() -> void:
	load_level(_current_level + 1)


func _player_dead() -> void:
	get_tree().create_timer(2.0).timeout.connect(load_level.bind(_current_level))
