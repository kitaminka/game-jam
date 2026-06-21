extends Node2D

@export var force_p: float = 100.0
@export var force_f: float = 100.0

@onready var flail: RigidBody2D = $Flail
@onready var player: RigidBody2D = $Player
@onready var line_2d: Line2D = $Line2D


func _physics_process(_delta: float) -> void:
	flail.freeze = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	player.freeze = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	if player.freeze and not flail.freeze:
		player.linear_velocity = Vector2.ZERO
		flail.apply_central_force((get_global_mouse_position() - flail.global_position).normalized() * force_f)
	elif not player.freeze and flail.freeze:
		flail.linear_velocity = Vector2.ZERO
		player.apply_central_force((get_global_mouse_position() - player.global_position).normalized() * force_p)

	_apply_constaint()

	line_2d.points = PackedVector2Array([
		line_2d.to_local(player.global_position),
		line_2d.to_local(flail.global_position),
	])


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
