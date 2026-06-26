extends AnimatedSprite2D


const RADIUS: float = 64.0

@export var knockback: float = 200.0
@export var damage: int = 30

@export_flags_2d_physics var mask: int = 1


func _ready() -> void:
	execute.call_deferred()


func execute() -> void:
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
			cnb.health_component.damage(damage)
			cnb.player.apply_central_impulse(global_position.direction_to(cnb.player.global_position) * knockback)
		elif col.collider == cnb.flail:
			cnb.flail.apply_central_impulse(global_position.direction_to(cnb.flail.global_position) * knockback)

	await get_tree().create_timer(0.1).timeout

	get_child(0).show()

	var t := create_tween()
	t.tween_interval(3.0)
	t.chain().tween_property(self, "modulate:a", 0.0, 1.0)
	t.chain().tween_callback(queue_free)
