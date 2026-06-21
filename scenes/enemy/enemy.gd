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


func _ready() -> void:
	health_component.died.connect(queue_free)


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

	if melee_enabled:
		if dist2 < melee_distance*melee_distance and _melee_cooldown <= 0 and _knockback_velocity.is_zero_approx():
			_melee_cooldown = melee_interval

			for node: Node2D in melee_hurtbox.get_overlapping_areas() + melee_hurtbox.get_overlapping_bodies() :
				var health := node.get("health_component") as HealthComponent
				if health == null:
					continue

				health.damage(melee_damage)

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
