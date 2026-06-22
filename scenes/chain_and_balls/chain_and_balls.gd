class_name ChainAndBalls
extends Node2D


signal got_lobotomized


const _GROUNDED_FLAIL := preload("res://scenes/chain_and_balls/grounded_flail_ball.tscn")
const GroundedFlail := preload("res://scenes/chain_and_balls/grounded_flail_ball.gd")

@export var force_p: float = 100.0
@export var force_f: float = 100.0
@export var damage: int = 50

## Whether to consume stamina when both are flying
@export var stamina_on_flight: bool = false

@export_flags_2d_physics var hole_mask: int = 16
@export var hole_check_shape: Shape2D
@export var min_hole_speed: float = 20.0

var _last_grounded_flail: GroundedFlail
var _player_frozen_state: bool = false

var _prev_clothing_idx: int = 0

var _was_lobotomized: bool = false

@onready var flail: RigidBody2D = $Flail
@onready var player: RigidBody2D = $Player
@onready var chain: Line2D = $Chain
@onready var health_component: HealthComponent = $HealthComponent
@onready var flail_hurt_box: Area2D = %HurtBox

@onready var player_sprite: Sprite2D = $Player/Sprite2D
@onready var player_animation: AnimatedSprite2D = $Player/Sprite2D/AnimatedSprite2D

@onready var sfx_player: SfxPlayer = $Player/SfxPlayer

static func get_instance() -> ChainAndBalls:
	var cnb: ChainAndBalls = (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"chain_and_balls")

	if cnb == null:
		push_error("no cnb :(")

	return cnb


func _ready() -> void:
	health_component.died.connect(_on_died)
	health_component.damaged.connect(_on_damaged)
	health_component.damaged.connect(_udpate_nudity_state)
	health_component.healed.connect(_udpate_nudity_state)
	flail_hurt_box.body_entered.connect(_on_flail_enemy_entered)
	flail_hurt_box.area_entered.connect(_on_flail_enemy_entered)


func _physics_process(_delta: float) -> void:
	player_sprite.global_rotation = 0

	if player.global_position.x > flail.global_position.x:
		player_sprite.flip_h = true
	else:
		player_sprite.flip_h = false

	var p_over_hole := _is_over_hole(player.global_position)
	var f_over_hole := _is_over_hole(flail.global_position)

	flail.freeze = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not f_over_hole
	var flail_frozen_delta := int(flail.freeze) - int(_last_grounded_flail != null)
	player.freeze = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not p_over_hole

	if player.freeze and not flail.freeze:
		player.linear_velocity = Vector2.ZERO
		flail.apply_central_force((get_global_mouse_position() - flail.global_position).normalized() * force_f)
	elif not player.freeze and flail.freeze:
		flail.linear_velocity = Vector2.ZERO
		player.apply_central_force((get_global_mouse_position() - player.global_position).normalized() * force_p)

	if player.freeze:
		player_sprite.frame_coords.y = 1
		if not _player_frozen_state:
			_player_frozen_state = true
			player_animation.play()
			sfx_player.play_sound("land")
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
			sfx_player.play_sound("land")
		-1: # just released
			if is_instance_valid(_last_grounded_flail):
				_last_grounded_flail.make_hollow()
				var t := _last_grounded_flail.create_tween().chain()
				t.tween_interval(2.0)
				t.tween_property(_last_grounded_flail, "modulate:a", 0.0, 0.5)
				t.tween_callback(_last_grounded_flail.queue_free)
				_last_grounded_flail = null
			flail.show()


	if (
		p_over_hole and f_over_hole
		and flail.linear_velocity.length_squared() + player.linear_velocity.length_squared() < min_hole_speed*min_hole_speed
	):
		_fall_into_a_hole()


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


func _labotomize() -> void:
	if _was_lobotomized:
		return

	got_lobotomized.emit()

	_was_lobotomized = true
	sfx_player.prepare_to_die()

	print("game over")


func _on_damaged(amount: int) -> void:
	if _was_lobotomized:
		return

	print("player took ", amount, " damage")
	print("current health: ", health_component.health)
	var t := player_sprite.create_tween().chain()
	t.tween_property(player_sprite, "self_modulate", Color.WHITE, 0.125).from(Color.RED)
	sfx_player.play_sound("damaged")
	sfx_player.play_sound("damaged_scream")


func _on_died() -> void:
	if _was_lobotomized:
		return
	_labotomize()


func _on_flail_enemy_entered(enemy: Node2D) -> void:
	if flail.freeze:
		return

	var knockback := flail.linear_velocity.normalized() * _calc_knockback(flail.linear_velocity.length())
	if enemy.has_method("apply_knockback"):
		enemy.apply_knockback(knockback)

	if enemy.has_method("apply_armour"):
		enemy.apply_armour(flail, knockback)

	var hc := enemy.get("health_component") as HealthComponent
	if is_instance_valid(hc):
		hc.damage(damage)


func _calc_knockback(velocity: float) -> float:
	var extra := maxf(0, velocity - 300)
	var rest := velocity - extra

	return rest + extra ** 1.1


func _hide_animation() -> void:
	print("viu")
	player_animation.hide()


func _udpate_nudity_state(_amount: int) -> void:
	const CLOTHING_ELEM := preload("res://scenes/chain_and_balls/discarded_clothing.tscn")

	var idx := clampi(int(remap(health_component.health, health_component.initial_health, 0, 0, 3)), 0, 2)
	player_sprite.frame_coords.x = idx

	if idx != _prev_clothing_idx and _prev_clothing_idx in [0, 1]:
		var inst := CLOTHING_ELEM.instantiate() as RigidBody2D
		inst.global_position = player.global_position
		inst.global_rotation = randf_range(0, TAU)
		inst.linear_velocity = Vector2.UP * 100.0
		inst.angular_velocity = randf_range(-TAU, TAU)
		(inst.get_node("Sprite2D") as Sprite2D).frame = _prev_clothing_idx
		add_child.call_deferred(inst)

	_prev_clothing_idx = idx


func _is_over_hole(pos: Vector2) -> bool:
	var params := PhysicsShapeQueryParameters2D.new()
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.collision_mask = hole_mask
	params.transform.origin = pos
	params.shape = hole_check_shape
	return not get_world_2d().direct_space_state.intersect_shape(params, 1).is_empty()


func _fall_into_a_hole() -> void:
	if _was_lobotomized:
		return

	sfx_player.play_sound("fall_into_a_hole")
	_labotomize()

	health_component.damage.call_deferred(999999999)
	modulate.a = 0.5
