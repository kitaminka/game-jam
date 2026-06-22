extends CharacterBody2D


@export var walk_speed: float = 300.0
@export var walk_min_time: float = 1.5
@export var walk_max_time: float = 5.0

@export var charge_speed: float = 1000.0
@export var charge_decel: float = 200.0

# signal expected by Exit
signal got_lobotomized

enum State {
	STARTING,

	WALKING,
	CHARGING,

	METEOR_SHOWER,
	METEOR_TAIL,
}

@onready var cnb := ChainAndBalls.get_instance()
@onready var health_component: HealthComponent = $HealthComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = %Sprite2D
@onready var flip_group: Node2D = $FlipGroup

var _states: Array[State]
var _prev_state := State.STARTING
var _state_just_changed: bool


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



var _walk_time: float = 0.0

func _do_walk() -> void:
	if _state_just_changed:
		_walk_time += randf_range(walk_min_time, walk_max_time)

	animation_player.play(&"walk")

	var dir := global_position.direction_to(cnb.player.global_position)

	velocity = dir * walk_speed

	move_and_slide()
	_look_at_player()

	var delta := get_physics_process_delta_time()
	_walk_time -= delta
	if _walk_time <= 0:
		_state_finished()


enum ChargePhase {
	TELEGRAPH,
	CHARGE,
	RECOVERY,
}

var _charge_phase: ChargePhase

func _do_charge() -> void:
	if _state_just_changed:
		_charge_phase = ChargePhase.TELEGRAPH
		animation_player.play(&"start_charge")
		animation_player.animation_finished.connect(func (_anim: Variant) -> void: _start_charge())


	match _charge_phase:
		ChargePhase.TELEGRAPH:
			_look_at_player()
		ChargePhase.CHARGE:
			var delta := get_physics_process_delta_time()
			velocity = velocity.move_toward(Vector2.ZERO, charge_decel * delta)
			move_and_slide()
			_look_in(velocity.x)

			if velocity.is_zero_approx():
				_charge_phase = ChargePhase.RECOVERY
				animation_player.play("charge_recovery")

				animation_player.animation_finished.connect(func (_anim: Variant) -> void: _state_finished())
		ChargePhase.RECOVERY:
			pass # do nothing


func _start_charge() -> void:
	_charge_phase = ChargePhase.CHARGE
	var dir := global_position.direction_to(cnb.player.global_position)
	velocity = dir * charge_speed

	animation_player.play(&"charge")


func _do_meteor_shower() -> void: _state_finished()
func _do_meteor_tail() -> void: _state_finished()


func _look_at_player() -> void:
	_look_in(cnb.player.global_position.x - global_position.x)


func _look_in(dir: float) -> void:
	if is_zero_approx(dir):
		return
	flip_group.scale.x = signf(dir)
