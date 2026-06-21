extends Node2D

@export var force_p: float = 100.0
@export var force_f: float = 100.0

@onready var flail: RigidBody2D = $Flail
@onready var player: RigidBody2D = $Player
# @onready var joint: DampedSpringJoint2D = $Joint


func _ready() -> void:
	player.add_collision_exception_with(flail)


func _physics_process(delta: float) -> void:
	flail.freeze = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	player.freeze = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	if player.freeze and not flail.freeze:
		player.linear_velocity = Vector2.ZERO
		flail.apply_central_force((get_global_mouse_position() - flail.global_position).normalized() * force_f)
	elif not player.freeze and flail.freeze:
		flail.linear_velocity = Vector2.ZERO
		var want_player := 2 * flail.global_position - get_global_mouse_position()
		want_player = get_global_mouse_position()
		# want_player = get_global_mouse_position()
		player.apply_central_force((want_player - player.global_position).normalized() * force_p)
	elif not player.freeze and not flail.freeze:
		pass
		# flail.apply_central_force((get_global_mouse_position() - flail.global_position).normalized() * force_f)
		#
		# var center := (flail.global_position + player.global_position) * 0.5
		# var want_player := 2 * center - get_global_mouse_position()
		# player.apply_central_force((want_player - player.global_position).normalized() * force_p)

	_apply_constaint()


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_dashed_line(to_local(player.global_position), to_local(flail.global_position), Color.ORANGE)

	if player.freeze and not flail.freeze:
		draw_dashed_line(to_local(get_global_mouse_position()), to_local(flail.global_position), Color.RED)
	elif not player.freeze and flail.freeze:
		var want_player := 2 * flail.global_position - get_global_mouse_position()
		want_player = get_global_mouse_position()
		player.apply_central_force((want_player - player.global_position).normalized() * force_p)
		# want_player = get_global_mouse_position()
		draw_dashed_line(to_local(want_player), to_local(player.global_position), Color.RED)
	elif not player.freeze and not flail.freeze:
		pass
		# var center := (flail.global_position + player.global_position) * 0.5
		# var want_player := 2 * center - get_global_mouse_position()
		# draw_dashed_line(to_local(get_global_mouse_position()), to_local(flail.global_position), Color.RED)
		# draw_dashed_line(to_local(want_player), to_local(player.global_position), Color.RED)


	# draw_line(to_local(player.global_position), to_local(player.global_position + player.linear_velocity), Color.LIME)
	# draw_line(to_local(flail.global_position), to_local(flail.global_position + flail.linear_velocity), Color.LIME)


func _apply_constaint() -> void:
	const MAX_DIST := 50.0

	var delta := flail.global_position - player.global_position
	var delta_len := delta.length()

	if delta_len <= MAX_DIST:
		return

	var dir := delta / delta_len
	var error := delta_len - MAX_DIST

	var p_bias: float = 0.5

	if player.freeze and not flail.freeze:
		p_bias = 0
	elif not player.freeze and flail.freeze:
		p_bias = 1

	player.global_position += dir * error * p_bias
	flail.global_position -= dir * error * (1 - p_bias)

	var rel_vel := (flail.linear_velocity - player.linear_velocity).dot(dir)
	if rel_vel <= 0:
		return

	var inv_mass_sum := 1.0 / player.mass + 1.0 / flail.mass

	var impulse_mag := -rel_vel / inv_mass_sum
	var impulse := dir * impulse_mag

	player.apply_impulse(-impulse * p_bias)
	flail.apply_impulse(impulse * (1 - p_bias))


func _projection(of: Vector2, onto: Vector2) -> float:
	return of.dot(onto) / onto.length()
