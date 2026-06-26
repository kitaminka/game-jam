extends Node2D


var _player_camera: Camera2D

@onready var boss_camera: Camera2D = %Camera
@onready var health_bar: ProgressBar = %HealthBar
@onready var dinosaurik: Dinosaurik = %Dinosaurik
@onready var boss_ui: Control = %BossUI


func _ready() -> void:
	dinosaurik.health_component.damaged.connect(_on_dino_damaged)
	dinosaurik.health_component.died.connect(_on_boss_died)
	dinosaurik.boss_started.connect(_on_boss_started)

	boss_ui.hide()


func _on_dino_damaged(_amount: int) -> void:
	var p := float(dinosaurik.health_component.health) / float(dinosaurik.health_component.initial_health)
	health_bar.create_tween().tween_property(health_bar, "value", p, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)


func _on_boss_started() -> void:
	boss_ui.show()

	MusicManager.ensure_playing("dino_boss")

	_initial_zoom = boss_camera.zoom
	_initial_pos = boss_camera.global_position

	_player_camera = get_viewport().get_camera_2d()
	boss_camera.zoom = _player_camera.zoom
	boss_camera.global_position = _player_camera.get_screen_center_position()
	boss_camera.reset_smoothing()

	boss_camera.enabled = true
	boss_camera.make_current()

	var t := boss_camera.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_parallel()
	t.tween_property(boss_camera, "zoom", _initial_zoom, 0.7)
	t.tween_property(boss_camera, "global_position", _initial_pos, 0.5)
	t.tween_method(func (_v: int) -> void: boss_camera.reset_smoothing(), 0, 0, 0.5)


func _on_boss_died() -> void:
	var t := boss_camera.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_method(_interpolate_camera, 0.0, 1.0, 2.0)
	t.chain().tween_callback(func() -> void:
		boss_camera.enabled = false
	)

	MusicManager.fade_to_stop(2)


var _initial_pos: Vector2
var _initial_zoom: Vector2

func _interpolate_camera(w: float) -> void:
	boss_camera.zoom = lerp(_initial_zoom, _player_camera.zoom, w)
	boss_camera.global_position = lerp(_initial_pos, _player_camera.get_screen_center_position(), w)
	boss_camera.reset_smoothing()
