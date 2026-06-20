## invariant: parent must be initialized and ready or null
class_name FlailBall
extends Node2D


signal position_updated


@export var rotation_speed: float = PI
@export var starting_rotation_angle: float = 0.0
@export var radius: float
@export var parent: FlailBall

var _rotation_angle: float = 0.0

@onready var _line: Line2D = $Line2D


func _ready() -> void:
	_rotation_angle = starting_rotation_angle
	if parent != null:
		(func () -> void:
			if not parent.is_node_ready():
				await parent.ready
			parent.position_updated.connect(_update_position)
		).call_deferred()
	else:
		hide() # we are root
		# TODO: remove collision


func _physics_process(_delta: float) -> void:
	if parent == null:
		position_updated.emit()


func _update_position() -> void:
	if not is_instance_valid(parent):
		position_updated.emit()
		return

	var delta: float = get_physics_process_delta_time()
	_rotation_angle += delta * rotation_speed
	_rotation_angle = fposmod(_rotation_angle, TAU)

	global_position = parent.global_position + Vector2.from_angle(_rotation_angle) * radius
	_line.points = PackedVector2Array([Vector2.ZERO, to_local(parent.global_position)])

	position_updated.emit()


func force_update_position() -> void:
	_update_position()
