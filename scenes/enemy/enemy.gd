extends CharacterBody2D

@export var speed: float = 120.0
@export var target: NodePath

var player: Node

func _ready() -> void:
	if not target.is_empty():
		player = get_node(target)

func _physics_process(delta: float) -> void:
	if not player:
		return
	
	var direction: Vector2 = (player.global_position - global_position).normalized()
	
	velocity = direction * speed
	
	move_and_slide()
	
	if velocity.length() > 0:
		rotation = velocity.angle()
