extends Node


var _levels: Array[String]
var _current_level: int


func _init() -> void:
	RenderingServer.set_default_clear_color("#3e3b38")

	var f := FileAccess.open("res://scenes/levels/levels.txt", FileAccess.READ)

	if not f:
		push_error("no levels.txt")
		return

	while not f.eof_reached():
		var l := f.get_line().strip_edges()

		if l.begins_with("#") or l == "":
			continue

		_levels.push_back(l)

	f.close()

	print("[GamaManager] discovered %d levels" % _levels.size())


func _ready() -> void:
	_ensure_music.call_deferred()


func load_level(id: int) -> void:
	assert(1 <= id and id <= _levels.size(), "level id out of bounds")
	_current_level = id

	print("[GamaManager] loading level %d (%s)" % [id, _levels[id-1]])

	await Transition.change_scene_path(_levels[id-1])

	if not get_tree().current_scene.is_node_ready():
		await get_tree().current_scene.ready

	for e: Exit in get_tree().get_nodes_in_group(&"exit"):
		e.player_exited.connect(_next_level, CONNECT_ONE_SHOT)

	var cnb := ChainAndBalls.get_instance()
	if not cnb.got_lobotomized.is_connected(_player_dead):
		cnb.got_lobotomized.connect(_player_dead, CONNECT_ONE_SHOT)

	_ensure_music.call_deferred()


func _ensure_music() -> void:
	MusicManager.ensure_playing("main")


func last_level() -> int:
	return _levels.size()


func current_level() -> int:
	return _current_level


func _next_level() -> void:
	Persistence.current_score = _current_level
	Persistence.submit()

	if _current_level >= last_level():
		await load_level(last_level())
		return

	await load_level(_current_level + 1)


func _player_dead() -> void:
	get_tree().create_timer(2.0).timeout.connect(load_level.bind(_current_level))
