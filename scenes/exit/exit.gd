class_name Exit
extends Area2D


signal player_exited

@export var win_condition_enemies: bool = false
var _enemies_left: int = 0


func _ready() -> void:
	if win_condition_enemies:
		for enemy in get_tree().get_nodes_in_group(&"enemy"):
			enemy.got_lobotomized.connect(_on_enemy_death, CONNECT_ONE_SHOT)
			_enemies_left += 1

	body_entered.connect(func (_v: Variant) -> void: _check_player())
	area_entered.connect(func (_v: Variant) -> void: _check_player())

	_update_visual.call_deferred()
	_check_player.call_deferred()


func _on_enemy_death() -> void:
	_enemies_left -= 1
	_enemies_left = maxi(_enemies_left, 0)

	if _enemies_left <= 0:
		_update_visual()

	_check_player()


func _update_visual() -> void:
	if _enemies_left <= 0:
		($Sprite2D as Node2D).modulate = Color.LIME


func _check_player() -> void:
	if _enemies_left <= 0 and (has_overlapping_bodies() or has_overlapping_areas()):
		print("Plater exited!")
		player_exited.emit()
