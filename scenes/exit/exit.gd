class_name Exit
extends Area2D


signal player_exited

@export var win_condition_enemies: bool = false
var _enemies_left: int = 0
@onready var label: Label = $Label


func _ready() -> void:
	remove_child(label)

	if win_condition_enemies:
		for enemy in get_tree().get_nodes_in_group(&"enemy"):
			enemy.got_lobotomized.connect(_on_enemy_death, CONNECT_ONE_SHOT)
			_enemies_left += 1

	body_entered.connect(func (_v: Variant) -> void: _check_player())
	area_entered.connect(func (_v: Variant) -> void: _check_player())

	_update_visual.call_deferred()
	_check_player.call_deferred(true)


func _on_enemy_death() -> void:
	_enemies_left -= 1
	_enemies_left = maxi(_enemies_left, 0)

	_update_visual()
	_check_player(true)


func _update_visual() -> void:
	if _enemies_left <= 0:
		($Sprite2D as Node2D).modulate = Color.LIME


func _check_player(silent: bool = false) -> void:
	if _enemies_left > 0 and not silent:
		var inst: Label = label.duplicate()
		add_child(inst)

		inst.text = "%d left" % _enemies_left

		var t := inst.create_tween().set_parallel()
		t.tween_property(inst, "position:y", -20, 2.0).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		t.tween_property(inst, "modulate:a", 0.0, 1).set_delay(1)
		t.chain().tween_callback(inst.queue_free)


	if _enemies_left <= 0 and (has_overlapping_bodies() or has_overlapping_areas()):
		print("Plater exited!")
		player_exited.emit()
