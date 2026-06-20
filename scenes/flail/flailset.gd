class_name FlailSet
extends Node2D


const FLAIL_SCENE := preload("res://scenes/flail/flail_ball.tscn")



func _physics_process(delta: float) -> void:
	for child: Node in get_children():
		var fb := child as FlailBall
		if fb == null or fb.parent != null:
			continue

		fb.force_update_position()
