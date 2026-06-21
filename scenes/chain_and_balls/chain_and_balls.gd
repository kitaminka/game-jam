class_name ChainAndBalls
extends Node2D

const _GROUNDED_FLAIL := preload("res://scenes/chain_and_balls/grounded_flail_ball.tscn")
const GroundedFlail := preload("res://scenes/chain_and_balls/grounded_flail_ball.gd")

@export var force_p: float = 100.0
@export var force_f: float = 100.0
@export var damage: int = 50

@export_group("Stamina", "stamina")
@export var stamina_enabled: bool = false
@export var stamina_consumption: float = 0.3
@export var stamina_regeneration: float = 0.7

## Whether to consume stamina when both are flying
@export var stamina_on_flight: bool = false

var _last_grounded_flail: GroundedFlail
var _player_frozen_state: bool = false

var _stamina: float = 1.0
var _stamina_ran_out: bool = false

@onready var flail: RigidBody2D = $Flail
@onready var player: RigidBody2D = $Player
@onready var chain: Line2D = $Chain
@onready var health_component: HealthComponent = $HealthComponent
@onready var flail_hurt_box: Area2D = %HurtBox

@onready var player_sprite: Sprite2D = $Player/Sprite2D
@onready var player_animation: AnimatedSprite2D = $Player/Sprite2D/AnimatedSprite2D

static func get_instance() -> ChainAndBalls:
	var cnb: ChainAndBalls = (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"chain_and_balls")

	if cnb == null:
		push_error("no cnb :(")

	return cnb


func _ready() -> void:
	health_component.died.connect(_on_died)
	health_component.damaged.connect(_on_damaged)
	flail_hurt_box.body_entered.connect(_on_flail_enemy_entered)
	flail_hurt_box.area_entered.connect(_on_flail_enemy_entered)


func _physics_process(delta: float) -> void:
	player_sprite.global_rotation = 0

	if player.position.x > flail.position.x:
		player_sprite.flip_h = true
	else:
		player_sprite.flip_h = false

	var inp_flail := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	flail.freeze = inp_flail or (stamina_enabled and (_stamina <= 0.0 or _stamina_ran_out))
	var flail_frozen_delta := int(flail.freeze) - int(_last_grounded_flail != null)
	player.freeze = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	if inp_flail:
		_stamina_ran_out = false

	if player.freeze and not flail.freeze:
		player.linear_velocity = Vector2.ZERO
		flail.apply_central_force((get_global_mouse_position() - flail.global_position).normalized() * force_f)
	elif not player.freeze and flail.freeze:
		flail.linear_velocity = Vector2.ZERO
		player.apply_central_force((get_global_mouse_position() - player.global_position).normalized() * force_p)

	if stamina_enabled:
		if not flail.freeze and (not stamina_on_flight or player.freeze):
			_stamina -= stamina_consumption * delta
		else:
			_stamina += stamina_regeneration * delta

		_stamina = clampf(_stamina, 0, 1)
		if _stamina <= 0:
			_stamina_ran_out = true


	if player.freeze:
		player_sprite.frame_coords.y = 1
		if not _player_frozen_state:
			_player_frozen_state = true
			player_animation.play()
	else:
		player_sprite.frame_coords.y = 0
		_player_frozen_state = false

	_apply_constaint()

	chain.points = PackedVector2Array([
		chain.to_local(flail.global_position),
		chain.to_local(player.global_position),
	])

	match flail_frozen_delta:
		1: # just landed
			if is_instance_valid(_last_grounded_flail):
				_last_grounded_flail.queue_free()
			_last_grounded_flail = _GROUNDED_FLAIL.instantiate()
			_last_grounded_flail.global_position = flail.global_position
			flail.hide()
			add_child(_last_grounded_flail)
		-1: # just released
			if is_instance_valid(_last_grounded_flail):
				_last_grounded_flail.make_hollow()
				var t := _last_grounded_flail.create_tween().chain()
				t.tween_interval(2.0)
				t.tween_property(_last_grounded_flail, "modulate:a", 0.0, 0.5)
				t.tween_callback(_last_grounded_flail.queue_free)
				_last_grounded_flail = null
			flail.show()


	var stamina_label := %StaminaLabel as Label
	stamina_label.visible = stamina_enabled
	stamina_label.text = "%.2f" % _stamina


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


func _on_damaged(amount: int) -> void:
	player_sprite.frame_coords.x = int(3 - health_component.health / (health_component.initial_health * (1.0/3.0)))
	print("player took ", amount, " damage")


func _on_died() -> void:
	print("game over")

func _on_flail_enemy_entered(enemy: Node2D) -> void:
	if not enemy or not enemy.has_method("apply_knockback") or not enemy.get("health_component"):
		return

	enemy.health_component.damage(damage)
	var k := flail.linear_velocity
	enemy.apply_knockback(k.normalized() * _calc_knockback(k.length()))


func _calc_knockback(velocity: float) -> float:
	var extra := maxf(0, velocity - 300)
	var rest := velocity - extra

	return rest + extra ** 1.1

func _hide_animation() -> void:
	print("viu")
	player_animation.hide()
