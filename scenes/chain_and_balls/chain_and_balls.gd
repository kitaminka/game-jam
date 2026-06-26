class_name ChainAndBalls
extends Node2D


signal got_lobotomized

const _GROUNDED_FLAIL := preload("res://scenes/chain_and_balls/grounded_flail_ball.tscn")
const GroundedFlail := preload("res://scenes/chain_and_balls/grounded_flail_ball.gd")

const _FAST_HIT_EFFECT := preload("res://scenes/chain_and_balls/fast_hit_effect.tscn")
const _LAND_EFFECT := preload("res://scenes/chain_and_balls/land_effect.tscn")

const _DEAD_PLAYER_SPRITE := preload("res://assets/art/dead_ass.png")

enum FlailVelocityBucket {SLOW, NORMAL, FAST}

@export_category("Forces")
@export var force_p: float = 100.0
@export var force_f: float = 100.0

@export_category("Attack")
@export var damage_slow: int = 0
@export var damage_normal: int = 50
@export var damage_fast: int = 100
@export var flail_velocity_threshold_normal: float = 100.0
@export var flail_velocity_threshold_fast: float = 250.0

@export_category("Hole")
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
@onready var shadow: Sprite2D = %Shadow

@onready var player_sprite: Sprite2D = $Player/Sprite2D

@onready var camera: Camera2D = %Camera2D

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

	if not SettingsCfg.hard_mode():
		health_component.initial_health *= 2
		health_component.health *= 2
		damage_normal *= 2
		damage_fast *= 2


func _physics_process(_delta: float) -> void:
	player_sprite.global_rotation = 0


	if not _was_lobotomized:
		if player.global_position.x > flail.global_position.x:
			player_sprite.flip_h = true
		else:
			player_sprite.flip_h = false

	var p_over_hole := _is_over_hole(player.global_position)
	var f_over_hole := _is_over_hole(flail.global_position)

	var flail_frozen_delta: int
	if not _was_lobotomized:
		flail.freeze = Input.is_action_pressed("drop_ball") and not f_over_hole
		flail_frozen_delta = int(flail.freeze) - int(_last_grounded_flail != null)
		player.freeze = Input.is_action_pressed("drop_player") and not p_over_hole

		if player.freeze and not flail.freeze:
			player.linear_velocity = Vector2.ZERO
			flail.apply_central_force((get_global_mouse_position() - flail.global_position).normalized() * force_f)
		elif not player.freeze and flail.freeze:
			flail.linear_velocity = Vector2.ZERO
			player.apply_central_force((get_global_mouse_position() - player.global_position).normalized() * force_p)

	if player.freeze and not _was_lobotomized:
		player_sprite.frame_coords.y = 1
		if not _player_frozen_state:
			_player_frozen_state = true
			var inst: Node2D = _LAND_EFFECT.instantiate()
			add_child(inst)
			inst.global_position = player.global_position
			if not _was_lobotomized:
				sfx_player.play_sound("land")
	else:
		player_sprite.frame_coords.y = 0
		_player_frozen_state = false

	if not _was_lobotomized:
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
			flail.hide()
			add_child(_last_grounded_flail)
			_last_grounded_flail.global_position = flail.global_position
			if not _was_lobotomized:
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

	chain.hide()
	flail.linear_damp += 0.1

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
	player_sprite.texture = _DEAD_PLAYER_SPRITE
	player_sprite.vframes = 1
	player_sprite.hframes = 1
	player_sprite.offset.y += 11


func _get_flail_velocity_bucket() -> FlailVelocityBucket:
	var flail_velocity_sqr := flail.linear_velocity.length_squared()

	if flail_velocity_sqr < flail_velocity_threshold_normal * flail_velocity_threshold_normal:
		return FlailVelocityBucket.SLOW
	elif flail_velocity_sqr < flail_velocity_threshold_fast * flail_velocity_threshold_fast:
		return FlailVelocityBucket.NORMAL
	else:
		return FlailVelocityBucket.FAST


func _on_flail_enemy_entered(enemy: Node2D) -> void:
	if flail.freeze:
		return

	var bucket := _get_flail_velocity_bucket()

	var knockback := flail.linear_velocity.normalized() * _calc_knockback(flail.linear_velocity.length())
	if enemy.has_method("apply_knockback"):
		enemy.apply_knockback(knockback)

	if enemy.has_method("apply_armour"):
		enemy.apply_armour(flail, knockback)

	var hc := enemy.get("health_component") as HealthComponent
	if is_instance_valid(hc):
		var damage: int

		match bucket:
			FlailVelocityBucket.SLOW:
				damage = damage_slow
			FlailVelocityBucket.NORMAL:
				damage = damage_normal
			FlailVelocityBucket.FAST:
				damage = damage_fast

		hc.damage(damage)

	if bucket == FlailVelocityBucket.FAST:
		var effect: AnimatedSprite2D = _FAST_HIT_EFFECT.instantiate()
		add_child(effect)
		effect.global_position = flail.global_position
		effect.rotation = flail.linear_velocity.angle() - PI/2
		effect.animation_finished.connect(effect.queue_free)


func _calc_knockback(velocity: float) -> float:
	var extra := maxf(0, velocity - 300)
	var rest := velocity - extra

	return rest + extra ** 1.1


func _udpate_nudity_state(_amount: int) -> void:
	const CLOTHING_ELEM := preload("res://scenes/chain_and_balls/discarded_clothing.tscn")

	var idx := clampi(int(remap(health_component.health, health_component.initial_health, 0, 0, 3)), 0, 2)
	player_sprite.frame_coords.x = idx

	if idx != _prev_clothing_idx and _prev_clothing_idx in [0, 1]:
		var inst := CLOTHING_ELEM.instantiate() as RigidBody2D

		inst.global_rotation = randf_range(0, TAU)
		inst.linear_velocity = Vector2.UP * 100.0
		inst.angular_velocity = randf_range(-TAU, TAU)
		(inst.get_node("Sprite2D") as Sprite2D).frame = _prev_clothing_idx

		(func () -> void:
			add_child(inst)
			inst.global_position = player.global_position
		).call_deferred()

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

	var t := create_tween().set_parallel()
	t.tween_property(player_sprite, "rotation", TAU * 3, 2).as_relative()
	t.tween_property(player_sprite, "modulate:a", 0, 2)
	shadow.hide()

	player.freeze = true


func zone_damage(dmg: int) -> void:
	if not _is_over_hole(player.global_position):
		health_component.damage(dmg)
