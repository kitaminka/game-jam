extends Node2D


func _ready() -> void:
	for child: RigidBody2D in get_children():
		child.linear_velocity = child.position.normalized() * randf_range(10, 20)
		child.angular_velocity = randf_range(-TAU, TAU) * 2
