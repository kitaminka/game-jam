extends Area2D


@export var damage_zone_scene: PackedScene

@export var speed: float = 120
@export var rotation_speed: float = 1
@export var zone_spawn_range: float = 10

@onready var life_timer: Timer = $LifeTimer
@onready var bullet_sprite: Sprite2D = $Sprite2D
@onready var cnb := ChainAndBalls.get_instance()

var direction: Vector2


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	life_timer.timeout.connect(_spawn_damage_zone)

	direction = (cnb.player.global_position - global_position).normalized()

	(func () -> void:
		direction = (cnb.player.global_position - global_position).normalized()
	).call_deferred()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	rotation += rotation_speed * delta


func _on_body_entered(_area: Node2D) -> void:
	_spawn_damage_zone()


func _spawn_damage_zone() -> void:
	var damage_zone: Node2D = damage_zone_scene.instantiate()
	damage_zone.global_position = global_position
	damage_zone.position.x += randf_range(-zone_spawn_range, zone_spawn_range)
	damage_zone.position.y += randf_range(-zone_spawn_range, zone_spawn_range)
	get_parent().add_child.call_deferred(damage_zone)

	queue_free()
