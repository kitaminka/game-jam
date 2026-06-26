extends Node2D


@onready var start_trigger: Area2D = %StartTrigger


func _ready() -> void:
	start_trigger.body_entered.connect(func (_v: Variant) -> void:
		get_tree().call_group(&"tanks!!", "start")
		MusicManager.ensure_playing("dino_boss"),
		 CONNECT_ONE_SHOT)
