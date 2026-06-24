class_name MeteorManager
extends CanvasGroup


const _METEOR := preload("res://scenes/levels/dino_boss/meteor.tscn")
const _BOOM := preload("res://scenes/levels/dino_boss/boom.tscn")
const _WARN := preload("res://scenes/levels/dino_boss/warn.tscn")

@export var warn_time: float = 1.0

@export var anim_time: float = 0.6
@export var anim_fade_time: float = 0.4
@export var anim_angle: float = TAU/12
@export var anim_distance: float = 200.0

var _id_counter: int = 0
var _meteor_pos: Dictionary[int, Vector2] = {}


func do_meteor(at: Vector2) -> void:
	_id_counter += 1
	var id := _id_counter
	_meteor_pos[id] = at

	var _initial_pos := at + Vector2.UP.rotated(randf_range(-anim_angle, anim_angle)) * anim_distance

	var meteor: Node2D = _METEOR.instantiate()
	var boom: Node2D = _BOOM.instantiate()
	var warn: Node2D = _WARN.instantiate()

	add_child(warn)
	warn.global_position = at

	get_parent().add_child(meteor)
	meteor.global_position = _initial_pos
	meteor.look_at(at)
	meteor.modulate.a = 0

	var t := meteor.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.chain().tween_interval(warn_time - anim_time)
	t.chain().tween_property(meteor, "modulate:a", 1.0, anim_fade_time)
	t.parallel().tween_property(meteor, "global_position", at, anim_time)
	t.chain().tween_callback(func () -> void:
		meteor.queue_free()
		warn.queue_free()

		_meteor_pos.erase(id)
		get_parent().add_child(boom)
		boom.global_position = at
	)
