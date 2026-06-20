extends Node


@export var max_health: int = 100


@onready var current_health: int = max_health

func take_damage(amount: int) -> void:
	current_health = min(0, current_health - amount)

func is_dead() -> bool:
	return current_health == 0
