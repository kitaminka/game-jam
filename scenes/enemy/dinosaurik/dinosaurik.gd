class_name Dinosaurik
extends CharacterBody2D


# signal expected by Exit
signal got_lobotomized
signal boss_started

enum State {
	STARTING,

	WALKING,
	CHARGING,

	METEOR_SHOWER,
	METEOR_TAIL,
}

enum ChargePhase {
	TELEGRAPH,
	CHARGE,
	RECOVERY,
}

@export var contact_damage: int = 20
@export var contact_knockback: float = 300.0

@export var walk_speed: float = 300.0
@export var walk_min_time: float = 1.5
@export var walk_max_time: float = 5.0

@export var charge_speed: float = 1000.0
@export var charge_decel: float = 200.0

@export var run_to_center_speed: float = 450.0
@export var center: Node2D
@export var meteor_manager: MeteorManager
@export var meteor_rect: Control

@export var shower_meteor_interval: float = 0.1
@export var shower_meteors_min: int = 40
@export var shower_meteors_max: int = 120

@export var tail_meteor_interval: float = 0.5
@export var tail_meteors_min: int = 10
@export var tail_meteors_max: int = 20

var _states: Array[State]
var _prev_state := State.STARTING
var _state_just_changed: bool

var _walk_time: float = 0.0

var _charge_phase: ChargePhase

var _meteors_left: int = 0
var _meteor_cooldown: float = 0

var _was_on_screen: bool = false

@onready var cnb := ChainAndBalls.get_instance()
@onready var health_component: HealthComponent = $HealthComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = %Sprite2D
@onready var flip_group: Node2D = $FlipGroup
@onready var hurtbox: Area2D = $HurtBox
@onready var damage_flash: ColorRect = %DamageFlash


func _ready() -> void:
	hurtbox.body_entered.connect(_hurtbox_body_entered)
	health_component.damaged.connect(_on_damaged)

	($VisibleOnScreenNotifier2D as VisibleOnScreenNotifier2D).screen_entered.connect(func () -> void:
		if not _was_on_screen:
			_was_on_screen = true
			boss_started.emit()
	)

	health_component.died.connect(got_lobotomized.emit)


func _fill_states() -> void:
	if not _states.is_empty():
		return

	_states = [
		State.WALKING,
		State.WALKING,

		State.CHARGING,
		State.CHARGING,

		State.METEOR_SHOWER,
		State.METEOR_TAIL,
	]

	_states.shuffle()


func _state_finished() -> void:
	_states.pop_back()


func _physics_process(_delta: float) -> void:
	if not _was_on_screen:
		return

	if health_component.is_dead():
		# TODO: animation
		return

	_fill_states()

	_state_just_changed = _prev_state != _states.back()
	_prev_state = _states.back()

	match _states.back():
		State.WALKING:
			_do_walk()
		State.CHARGING:
			_do_charge()
		State.METEOR_SHOWER:
			_do_meteor_shower()
		State.METEOR_TAIL:
			_do_meteor_tail()



func _do_walk() -> void:
	if _state_just_changed:
		_walk_time += randf_range(walk_min_time, walk_max_time)

	animation_player.play(&"walk", 0.5)

	var dir := global_position.direction_to(cnb.player.global_position)

	velocity = dir * walk_speed

	move_and_slide()
	_look_at_player()

	var delta := get_physics_process_delta_time()
	_walk_time -= delta
	if _walk_time <= 0:
		_state_finished()



func _do_charge() -> void:
	if _state_just_changed:
		_charge_phase = ChargePhase.TELEGRAPH
		_force_play(&"start_charge")
		animation_player.animation_finished.connect(func (_anim: Variant) -> void: _start_charge())


	match _charge_phase:
		ChargePhase.TELEGRAPH:
			_look_at_player()
		ChargePhase.CHARGE:
			var delta := get_physics_process_delta_time()
			velocity = velocity.move_toward(Vector2.ZERO, charge_decel * delta)

			move_and_slide()

			_look_in(velocity.x)

			var real_vel := get_position_delta() / delta

			if real_vel.length_squared() < 1:
				_charge_phase = ChargePhase.RECOVERY
				_force_play(&"charge_recovery")
				animation_player.animation_finished.connect(func (_anim: Variant) -> void: _state_finished(), CONNECT_ONE_SHOT)
		ChargePhase.RECOVERY:
			pass # do nothing


func _start_charge() -> void:
	_charge_phase = ChargePhase.CHARGE
	var dir := global_position.direction_to(cnb.player.global_position)
	velocity = dir * charge_speed

	_force_play(&"charge")


func _do_meteor_shower() -> void:
	if _state_just_changed:
		_meteors_left = randi_range(shower_meteors_min, shower_meteors_max)

	_do_meteors(shower_meteor_interval, _get_random_arena_pos)


func _do_meteor_tail() -> void:
	if _state_just_changed:
		_meteors_left = randi_range(tail_meteors_min, tail_meteors_max)

	_do_meteors(tail_meteor_interval, _get_player_pos)


func _do_meteors(interval: float, get_spawn_pos: Callable) -> void:
	if _state_just_changed:
		_meteor_cooldown = 2.0

	if not _is_in_center():
		_run_to_center()
		return

	_look_at_player()
	animation_player.play(&"charge", 0.5)

	var delta := get_physics_process_delta_time()
	_meteor_cooldown -= delta

	if _meteor_cooldown <= 0:
		var pos: Vector2 = get_spawn_pos.call()
		meteor_manager.do_meteor(pos)

		_meteor_cooldown = interval
		_meteors_left -= 1

	if _meteors_left <= 0:
		_state_finished()


func _is_in_center() -> bool:
	const D: float = 40

	return global_position.distance_squared_to(center.global_position) <= D*D


func _run_to_center() -> void:
	animation_player.play(&"walk", 0.5)

	var dir := global_position.direction_to(center.global_position)
	velocity = dir * run_to_center_speed
	_look_in(dir.x)

	move_and_slide()


func _look_at_player() -> void:
	_look_in(cnb.player.global_position.x - global_position.x)


func _look_in(dir: float) -> void:
	if is_zero_approx(dir):
		return
	flip_group.scale.x = signf(dir)


func _force_play(anim: StringName) -> void:
	if animation_player.current_animation == anim:
		animation_player.stop()
	animation_player.play(anim, 0.5)



func _get_player_pos() -> Vector2:
	return cnb.player.global_position



func _get_random_arena_pos() -> Vector2:
	var r: Rect2 = meteor_rect.get_global_rect()

	return r.position + Vector2(
		randf_range(0, r.size.x),
		randf_range(0, r.size.y),
	)


func _hurtbox_body_entered(node: Node2D) -> void:
	if health_component.is_dead():
		return

	if node != cnb.player:
		return

	var dir := global_position.direction_to(node.global_position)
	if not velocity.is_zero_approx():
		dir = (dir + velocity.normalized()) * 0.5

	cnb.health_component.damage(contact_damage)
	cnb.player.apply_central_impulse(dir * contact_knockback)



func _on_damaged(_amount: int) -> void:
	damage_flash.create_tween().chain().tween_property(damage_flash, "color:a", 0, 0.3).from(0.75)
	# TODO: SOUND!


func apply_armour(flail: RigidBody2D, _knockback: Vector2) -> void:
	flail.apply_central_impulse(-2 * flail.linear_velocity)
