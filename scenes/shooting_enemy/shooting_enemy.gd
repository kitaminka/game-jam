class_name ShootingEnemy
extends CharacterBody2D


@export var bullet_scene: PackedScene

@export var speed: float = 120.0
@export var damage: int = 10
@export var damage_tick_interval: float = 0.5
@export var knockback_fading: float = 300.0

@export var stop_distance: float = 100

@onready var player := Player.get_instance()

var _is_touching_player: bool = false
var _time_left_to_dmg_tick: float = 0
var _knockback_velocity: Vector2

@onready var health_component: HealthComponent = $HealthComponent
@onready var shooting_timer: Timer = $ShootingTimer


func _ready() -> void:
	health_component.died.connect(queue_free)
	shooting_timer.timeout.connect(_shoot)


func _physics_process(delta: float) -> void:
	if not player:
		return

	var direction: Vector2 = (player.global_position - global_position).normalized()

	if (player.global_position - global_position).length_squared() >= stop_distance * stop_distance:
		velocity = direction * speed
		if not shooting_timer.is_stopped():
			shooting_timer.stop()
	else:
		if shooting_timer.is_stopped():
			shooting_timer.start()
		velocity = Vector2.ZERO

	velocity += _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_fading * delta)

	move_and_slide()

	if velocity.length() > 0:
		rotation = velocity.angle()


func _shoot() -> void:
	var bullet: Node2D = bullet_scene.instantiate()

	bullet.global_position = global_position

	get_parent().add_child(bullet)


func apply_knockback(v: Vector2) -> void:
	if not shooting_timer.is_stopped():
			shooting_timer.stop()
	_knockback_velocity += v
