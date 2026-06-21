class_name Enemy
extends CharacterBody2D


@export var speed: float = 30
@export var damage: int = 10
@export var damage_tick_interval: float = 0.5
@export var knockback_fading: float = 300.0

@onready var player := Player.get_instance()

var _is_touching_player: bool = false
var _time_left_to_dmg_tick: float = 0
var _knockback_velocity: Vector2

@onready var dmg_area: Area2D = $Area2D
@onready var health_component: HealthComponent = $HealthComponent


func _ready() -> void:
	dmg_area.body_entered.connect(_on_dmg_body_entered)
	dmg_area.body_exited.connect(_on_dmg_body_exited)

	health_component.died.connect(queue_free)


func _physics_process(delta: float) -> void:
	if not player:
		return

	var direction: Vector2 = (player.global_position - global_position).normalized()

	if (player.global_position - global_position).length_squared() >= 1:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	velocity += _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_fading * delta)

	move_and_slide()

	if velocity.length() > 0:
		rotation = velocity.angle()

	_time_left_to_dmg_tick -= delta

	if _is_touching_player and _time_left_to_dmg_tick <= 0:
		player.health_component.damage(damage)
		_time_left_to_dmg_tick += damage_tick_interval


func _on_dmg_body_entered(_area: Node2D) -> void:
	_is_touching_player = true
	_time_left_to_dmg_tick = 0


func _on_dmg_body_exited(_area: Node2D) -> void:
	_is_touching_player = false


func apply_knockback(v: Vector2) -> void:
	_knockback_velocity += v
