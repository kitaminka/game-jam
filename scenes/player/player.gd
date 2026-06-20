extends CharacterBody2D


@export var speed: float = 150.0
@export var acceleration: float = 1800.0


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	velocity = velocity.move_toward(input_dir * speed, acceleration * delta)

	move_and_slide()
