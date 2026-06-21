class_name GameManager
extends Node


@export var spawn_radius: float = 500.0
@export var waves: Array[Wave]
@export var eternal_wave: Wave
@export var eternal_wave_budget_multiplier: float = 1.25

var _cur_wave_idx: int = 0

var _cur_wave: Wave
var _cur_wave_start_ticks: int
var _spawn_entries: Array[SpawnEntry]
var _cur_spawn_entry_idx: int = 0


func _ready() -> void:
	_load_cur_wave()


func _physics_process(_delta: float) -> void:
	var cur_ticks := Time.get_ticks_usec()

	if _cur_spawn_entry_idx >= _spawn_entries.size():
		if cur_ticks < _cur_wave_start_ticks + int(_cur_wave.duration * 1000000):
			return

		_cur_wave_idx += 1
		_load_cur_wave()

	if cur_ticks < _cur_wave_start_ticks + _spawn_entries[_cur_spawn_entry_idx].ticks_offset:
		return

	_spawn_enemy(_spawn_entries[_cur_spawn_entry_idx].enemy_scene)

	_cur_spawn_entry_idx += 1


func _generate_spawn_position() -> Vector2:
	return Player.get_instance().global_position + Vector2.from_angle(randf_range(0, 2 * PI)) * spawn_radius


func _spawn_enemy(enemy_scene: PackedScene) -> void:
	var node := enemy_scene.instantiate() as Node2D
	node.global_position = _generate_spawn_position()
	add_child(node)


func _load_cur_wave() -> void:
	if _cur_wave_idx >= waves.size():
		if _cur_wave_idx != waves.size(): # not modify the first instance of the eternal wave
			eternal_wave.budget = int(eternal_wave.budget * eternal_wave_budget_multiplier)

		_load_wave(eternal_wave);
	else:
		_load_wave(waves[_cur_wave_idx])

	print("[wave #%s started %s] duration: %s, budget: %s, enemies spawned: %s" %
		[_cur_wave_idx, ("(eternal wave)" if _cur_wave_idx >= waves.size() else ""), _cur_wave.duration, _cur_wave.budget, _spawn_entries.size()])


func _load_wave(wave: Wave) -> void:
	_cur_wave = wave
	_cur_wave_start_ticks = Time.get_ticks_usec()
	_spawn_entries = _generate_spawn_entries(wave)
	_cur_spawn_entry_idx = 0


func _generate_spawn_entries(wave: Wave) -> Array[SpawnEntry]:
	var budget_left := wave.budget
	var ret: Array[SpawnEntry] = []
	var price_list_sorted := wave.price_list.duplicate()

	price_list_sorted.sort_custom(
		func(a: WaveEnemyEntry, b: WaveEnemyEntry) -> bool:
			return a.price <= b.price
	)

	while budget_left > 0:
		var affordable_weight_sum: float = 0
		for e: WaveEnemyEntry in price_list_sorted:
			if e.price > budget_left:
				break
			assert(e.price > 0)
			affordable_weight_sum += e.probability_weight

		if affordable_weight_sum == 0:
			break

		var rand_num: float = randf_range(0, 1)
		var accum: float = 0
		var selected: WaveEnemyEntry = null

		for e: WaveEnemyEntry in price_list_sorted:
			accum += e.probability_weight / affordable_weight_sum
			if accum >= rand_num:
				selected = e
				break

		budget_left -= selected.price

		var spawn_entry: SpawnEntry = SpawnEntry.new()
		spawn_entry.enemy_scene = selected.enemy_scene
		spawn_entry.ticks_offset = int(randf_range(0, wave.duration) * 1000000)

		ret.append(spawn_entry)

	ret.sort_custom(
		func(a: SpawnEntry, b: SpawnEntry) -> bool:
			return a.ticks_offset <= b.ticks_offset
	)

	return ret


class SpawnEntry:
	var ticks_offset: int
	var enemy_scene: PackedScene
