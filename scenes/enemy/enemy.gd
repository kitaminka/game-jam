class_name Enemy
extends CharacterBody2D


@export_group("Movement", "movement")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var movement_enabled: bool = false
@export var movement_speed: float = 30
@export var movement_stop_distance: float = 100.0


@export_group("Melee", "melee")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var melee_enabled: bool = false
@export var melee_damage: int = 10
@export var melee_interval: float = 0.5
@export var melee_distance: float = 7.0
@export var melee_hurtbox: Area2D
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
var _knockback_velocity: Vector2 #leftover velocity after


@onready var cnb := ChainAndBalls.get_instance()
@onready var health_component: HealthComponent = $HealthComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var highlight_rect: ColorRect = $Sprite2D/ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _initial_sprite_offset: Vector2
var _initial_marker_offset: Vector2


func _ready() -> void:
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(queue_free)
	_initial_sprite_offset = sprite.offset
	if is_instance_valid(shooting_marker):
		_initial_marker_offset = shooting_marker.position

	_randomize_animation()


func _physics_process(delta: float) -> void:
	var dist2 := cnb.player.global_position.distance_squared_to(global_position)

	velocity = Vector2.ZERO

	if movement_enabled:
		var direction: Vector2 = (cnb.player.global_position - global_position).normalized()
		if dist2 >= movement_stop_distance*movement_stop_distance:
			velocity += direction * movement_speed

	if knockback_enabled:
		velocity += _knockback_velocity
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_fading * delta)

	move_and_slide()

	sprite.flip_h = cnb.player.global_position.x < global_position.x
	if sprite.flip_h:
		sprite.offset = _initial_sprite_offset * Vector2(-1, 1)
	else:
		sprite.offset = _initial_sprite_offset

	if is_instance_valid(shooting_marker):
		if sprite.flip_h:
			shooting_marker.position = _initial_marker_offset * Vector2(-1, 1)
		else:
			shooting_marker.position = _initial_marker_offset

	if melee_enabled:
		if (
			dist2 < melee_distance*melee_distance
			and _melee_cooldown <= 0
			and _knockback_velocity.is_zero_approx()
			and (melee_hurtbox.has_overlapping_areas() or melee_hurtbox.has_overlapping_bodies())
		):
			_melee_cooldown = melee_interval
			cnb.health_component.damage(melee_damage)
			cnb.player.apply_central_impulse(global_position.direction_to(cnb.player.global_position) * melee_knockback)

		_melee_cooldown -= delta
		_melee_cooldown = maxf(_melee_cooldown, 0.0)

	if shooting_enabled:
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


## Public function, API expected by chain & balls
func apply_knockback(v: Vector2) -> void:
	_knockback_velocity += v


func _on_damaged(_amount: float) -> void:
	var t := highlight_rect.create_tween().chain()
	t.tween_property(highlight_rect, "color:a", 0, 0.125).from(0.75)


func _randomize_animation() -> void:
	animation_player.speed_scale = clampf(randfn(1, 0.2), 0.5, 1.5)
	animation_player.seek(randf_range(0, animation_player.current_animation_length))
