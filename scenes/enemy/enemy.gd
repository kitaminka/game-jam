class_name Enemy
extends CharacterBody2D


signal got_lobotomized


@export_group("Movement", "movement")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var movement_enabled: bool = false
@export var movement_speed: float = 30
@export var movement_stop_distance: float = 100.0


@export_group("Melee", "melee")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var melee_enabled: bool = false
@export var melee_damage: int = 10
@export var melee_interval: float = 0.5
@export var melee_distance: float = 7.0
@export var melee_knockback: float = 100.0
var _melee_cooldown: float = 0.0


@export_group("Shooting", "shooting")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var shooting_enabled: bool = false
@export var shooting_scene: PackedScene
@export var shooting_interval: float = 5.0
@export var shooting_distance: float = 100.0
@export var shooting_marker: Node2D
var _shooting_cooldown: float = 0.0


@export_group("Knockback", "knockback")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var knockback_enabled: bool = false
@export var knockback_fading: float = 300.0
@export var knockback_multiplier: float = 1.0
var _knockback_velocity: Vector2 #leftover velocity after


@export_group("Armour", "armour")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var armour_enabled: bool = false
@export var armour_efficiency: float = 0.9


@onready var cnb := ChainAndBalls.get_instance()
@onready var health_component: HealthComponent = $HealthComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var highlight_rect: ColorRect = $Sprite2D/ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hole_detector: Area2D = $HoleDetector
@onready var navigation: NavigationAgent2D = $NavigationAgent2D
@onready var sfx_player: SfxPlayer = $SfxPlayer

var _initial_sprite_offset: Vector2
var _initial_marker_offset: Vector2
var _was_lobotomized: bool = false


func _ready() -> void:
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_death)
	_initial_sprite_offset = sprite.offset
	if is_instance_valid(shooting_marker):
		_initial_marker_offset = shooting_marker.position

	_randomize_animation()

	var do_fall := func (_body: Variant) -> void: _fall_into_a_hole()

	hole_detector.body_entered.connect(do_fall, CONNECT_ONE_SHOT)
	hole_detector.area_entered.connect(do_fall, CONNECT_ONE_SHOT)

	navigation.max_speed = movement_speed
	navigation.velocity_computed.connect(_on_velocity_computed)

	set_physics_process(false)
	($VisibleOnScreenNotifier2D as VisibleOnScreenNotifier2D).screen_entered.connect(set_physics_process.bind(true))


func _physics_process(delta: float) -> void:
	var dist2 := cnb.player.global_position.distance_squared_to(global_position)

	velocity = Vector2.ZERO

	if movement_enabled and not _was_lobotomized:
		if navigation.target_position.distance_squared_to(cnb.player.global_position) > navigation.target_desired_distance**2:
			navigation.target_position = cnb.player.global_position
		var want := navigation.get_next_path_position()
		if global_position.distance_squared_to(want) >= movement_stop_distance*movement_stop_distance:
			velocity += global_position.direction_to(want) * movement_speed

	if knockback_enabled:
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_fading * delta)

	# this calls move and slide implicitly through _on_velocity_computed
	navigation.velocity = velocity

	if not _was_lobotomized:
		var s := signf(navigation.get_next_path_position().x - global_position.x)

		sprite.flip_h = s < 0
		if sprite.flip_h:
			sprite.offset = _initial_sprite_offset * Vector2(-1, 1)
		else:
			sprite.offset = _initial_sprite_offset

		if is_instance_valid(shooting_marker):
			if sprite.flip_h:
				shooting_marker.position = _initial_marker_offset * Vector2(-1, 1)
			else:
				shooting_marker.position = _initial_marker_offset

	if melee_enabled and not _was_lobotomized:
		if (
			dist2 < melee_distance*melee_distance
			and _melee_cooldown <= 0
			and _knockback_velocity.is_zero_approx()
		):
			_melee_cooldown = melee_interval
			cnb.health_component.damage(melee_damage)
			cnb.player.apply_central_impulse(global_position.direction_to(cnb.player.global_position) * melee_knockback)

		_melee_cooldown -= delta
		_melee_cooldown = maxf(_melee_cooldown, 0.0)

	if shooting_enabled and not _was_lobotomized:
		if dist2 < shooting_distance*shooting_distance and _shooting_cooldown <= 0 and _knockback_velocity.is_zero_approx():
			_shooting_cooldown = shooting_interval

			var inst := shooting_scene.instantiate() as Node2D
			if shooting_marker == null:
				inst.global_position = global_position
			else:
				inst.global_position = shooting_marker.global_position

			get_parent().add_child(inst)

		_shooting_cooldown -= delta
		_shooting_cooldown = maxf(_shooting_cooldown, 0.0)


func _on_velocity_computed(vel: Vector2) -> void:
	velocity = vel + _knockback_velocity
	move_and_slide()


func _on_damaged(_amount: float) -> void:
	var t := highlight_rect.create_tween().chain()
	t.tween_property(highlight_rect, "color:a", 0, 0.125).from(0.75)
	sfx_player.play_sound("damaged")


func _randomize_animation() -> void:
	animation_player.speed_scale = clampf(randfn(1, 0.2), 0.5, 1.5)
	animation_player.seek(randf_range(0, animation_player.current_animation_length))


func _labotomize() -> void:
	if _was_lobotomized:
		return

	got_lobotomized.emit()

	_was_lobotomized = true
	animation_player.stop()
	sfx_player.prepare_to_die()


func _on_death() -> void:
	if _was_lobotomized:
		return
	_labotomize()

	var t := create_tween()
	t.tween_property(sprite, "global_rotation", _rand_sign() * TAU / 4, 1).as_relative().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.chain().tween_interval(2.0)
	t.chain().tween_property(self, "modulate:a", 0.0, 1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.chain().tween_callback(queue_free)


func _fall_into_a_hole() -> void:
	if _was_lobotomized:
		return

	sfx_player.play_sound("fall_into_a_hole")

	_labotomize()

	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	t.tween_property(self, "modulate:a", 0.0, 1)
	t.parallel().tween_property(self, "global_position", Vector2.DOWN*5.0, 1).as_relative()
	t.parallel().tween_property(sprite, "global_rotation", _rand_sign() * TAU / 7, 1).as_relative()
	t.chain().tween_callback(queue_free)


func _rand_sign() -> float:
	return float(randi_range(0, 1) * 2 - 1)


## Public function, API expected by chain & balls
func apply_knockback(v: Vector2) -> void:
	_knockback_velocity += v * knockback_multiplier


func apply_armour(r: RigidBody2D, _knockback: Vector2) -> void:
	if not armour_enabled:
		return

	print("armour!")
	var dir := global_position.direction_to(r.global_position)
	var c := r.linear_velocity.project(dir)
	r.apply_central_impulse(-(1 + armour_efficiency) * c)
	r.apply_torque_impulse(randf_range(-PI, PI))
