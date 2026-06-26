extends Node2D

# less then visual, makes it more forgiving
const RADIUS: float = 30

@export var damage: int = 5
@export var damage_interval: float = 0.75
@export var lifetime: float = 5

@export_flags_2d_physics var mask: int = 1

var _does_damage: bool = true
@onready var _time_to_tick: float = damage_interval


func _ready() -> void:
	var t := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.tween_interval(lifetime)
	t.chain().tween_callback(func () -> void:
		_does_damage = false)
	t.chain().tween_property(self, "modulate:a", 0, 1)
	t.chain().tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	if not _does_damage:
		return

	_time_to_tick -= delta

	if _time_to_tick <= 0:
		_do_damage()
		_time_to_tick += damage_interval


func _do_damage() -> void:
	var params := PhysicsShapeQueryParameters2D.new()

	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.collision_mask = mask

	var cirlce := CircleShape2D.new()
	cirlce.radius = RADIUS
	params.shape = cirlce

	params.transform.origin = global_position

	var cnb := ChainAndBalls.get_instance()

	for col: Dictionary in get_world_2d().direct_space_state.intersect_shape(params, 2):
		if col.collider == cnb.player:
			cnb.zone_damage(damage)
