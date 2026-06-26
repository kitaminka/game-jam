extends Area2D


@export var speed: float = 120
@export var damage: int = 10
@export var knockback: float = 100.0

@onready var cnb := ChainAndBalls.get_instance()
@onready var life_timer: Timer = $LifeTimer

var _direction: Vector2
var _initial_player_pos: Vector2

var _was_deflected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	life_timer.timeout.connect(queue_free)

	_initial_player_pos = cnb.player.global_position

	_direction = global_position.direction_to(_initial_player_pos)
	look_at(_initial_player_pos)


	(func () -> void:
			_direction = global_position.direction_to(_initial_player_pos)
			look_at(_initial_player_pos)).call_deferred()


func _process(delta: float) -> void:
	position += _direction * speed * delta


func _handle_obstacle_collision() -> void:
	# ignore collisions with obstacles that happen before reaching the initial player position
	# this is needed to avoid the bullet disappearing immediately if it is instantiated inside a collider
	if _was_deflected or _direction.dot(_initial_player_pos - global_position) <= 0:
		queue_free()


func _on_body_entered(node: Node2D) -> void:
	if node == cnb.player:
		if _was_deflected:
			return

		cnb.health_component.damage(damage)
		cnb.player.apply_central_impulse(global_position.direction_to(cnb.player.global_position) * knockback)
		queue_free()
		return

	if _was_deflected:
		var hc := node.get("health_component") as HealthComponent
		if is_instance_valid(hc):
			hc.damage(damage)
			queue_free()
			return

	_handle_obstacle_collision()


func apply_knockback(v: Vector2) -> void:
	if v.length_squared() < 100**2:
		return

	_was_deflected = true
	damage = cnb.damage_fast
	_direction = v.normalized()
	rotation = _direction.angle()
