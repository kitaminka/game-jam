extends PathFollow2D

@export var speed: float = 75

var _started: bool = false
@onready var cnb: ChainAndBalls = ChainAndBalls.get_instance()
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	($Death as Area2D).body_entered.connect(_kill_object)
	($Death as Area2D).area_entered.connect(_kill_object)

	($TankDeath as Area2D).area_entered.connect(_kill_tank)
	($TankDeath as Area2D).body_entered.connect(_kill_tank)

	animation_player.speed_scale = randf_range(0.9, 1.1)


func _physics_process(delta: float) -> void:
	if not _started:
		return

	for child: Node in get_children():
		if child.is_in_group(&"upright"):
			var s := child as Node2D
			s.global_rotation = 0
			var x := Vector2.RIGHT.rotated(rotation).x
			if not is_zero_approx(x):
				s.scale.x = signf(x)

	progress += delta * speed


func _kill_object(node: Node) -> void:
	if node == cnb.flail:
		cnb.flail.apply_impulse(Vector2.ONE.rotated(rotation) * 300.0)
		return

	if node == cnb.player:
		cnb.health_component.damage(9999999999)
		return

	var hc := node.get("health_component") as HealthComponent
	if is_instance_valid(hc):
		hc.damage(999999999)


func start() -> void:
	_started = true



func _kill_tank(_v: Variant) -> void:
	speed = 0
	animation_player.play("death")
	$Death.queue_free()
