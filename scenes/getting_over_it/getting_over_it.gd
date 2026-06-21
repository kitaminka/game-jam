extends Node2D

@export var force_p: float = 100.0
@export var force_f: float = 100.0

@onready var flail: RigidBody2D = $Flail
@onready var player: RigidBody2D = $Player
# @onready var joint: DampedSpringJoint2D = $Joint


func _physics_process(delta: float) -> void:
	flail.freeze = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if flail.freeze:
		flail.set_axis_velocity(Vector2.ZERO)
	player.freeze = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if player.freeze:
		player.set_axis_velocity(Vector2.ZERO)

	if player.freeze and not flail.freeze:
		flail.apply_central_force((get_global_mouse_position() - flail.global_position).normalized() * force_f)
	elif not player.freeze and flail.freeze:
		var want_player := 2 * flail.global_position - get_global_mouse_position()
		player.apply_central_force((want_player - player.global_position).normalized() * force_p)
	elif not player.freeze and not flail.freeze:
		flail.apply_central_force((get_global_mouse_position() - flail.global_position).normalized() * force_f)

		var center := (flail.global_position + player.global_position) * 0.5
		var want_player := 2 * center - get_global_mouse_position()
		player.apply_central_force((want_player - player.global_position).normalized() * force_p)

	_apply_constaint()


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_dashed_line(to_local(player.global_position), to_local(flail.global_position), Color.ORANGE)

	if player.freeze and not flail.freeze:
		draw_dashed_line(to_local(get_global_mouse_position()), to_local(flail.global_position), Color.RED)
	elif not player.freeze and flail.freeze:
		var want_player := 2 * flail.global_position - get_global_mouse_position()
		player.apply_central_force((want_player - player.global_position).normalized() * force_p)
		draw_dashed_line(to_local(want_player), to_local(player.global_position), Color.RED)
	elif not player.freeze and not flail.freeze:
		var center := (flail.global_position + player.global_position) * 0.5
		var want_player := 2 * center - get_global_mouse_position()
		draw_dashed_line(to_local(get_global_mouse_position()), to_local(flail.global_position), Color.RED)
		draw_dashed_line(to_local(want_player), to_local(player.global_position), Color.RED)


func _apply_constaint() -> void:
	const MAX_DIST: float = 50

	var dist := player.global_position.distance_to(flail.global_position)
	dist -= MAX_DIST

	if dist < 0:
		return


	var p_to_f := player.global_position.direction_to(flail.global_position)

	player.global_position += p_to_f * dist * 0.5
	flail.global_position += -p_to_f * dist * 0.5

	flail.linear_velocity -= maxf(_projection(flail.linear_velocity, p_to_f), 0) * p_to_f
	player.linear_velocity -= maxf(_projection(player.linear_velocity, -p_to_f), 0) * -p_to_f


func _projection(of: Vector2, onto: Vector2) -> float:
	return of.dot(onto) / onto.length()
