extends CenterContainer


@onready var main: VBoxContainer = %Main
@onready var settings: VBoxContainer = %Settings
@onready var level_select: VBoxContainer = %LevelSelect
@onready var level_grid: GridContainer = %LevelGrid
@onready var button_continue: Button = %ButtonContinue
@onready var button_level_select: Button = %ButtonLevelSelect
@onready var button_settings: Button = %ButtonSettings
@onready var button_reset_progress: Button = %ButtonResetProgress
@onready var confirm_reset: ConfirmationDialog = %ConfirmReset


func _ready() -> void:
	_fill_level_select()

	_hide_all()
	main.show()

	button_level_select.pressed.connect(func () -> void:
		_hide_all()
		level_select.show())
	button_settings.pressed.connect(func () -> void:
		_hide_all()
		settings.show())


	for b: Button in get_tree().get_nodes_in_group("back_button"):
		b.pressed.connect(func () -> void:
			_hide_all()
			main.show())

	button_continue.pressed.connect(func () -> void:
		GameManager.load_level(Persistence.best_score+1))
	button_continue.disabled = Persistence.best_score >= GameManager.last_level()

	button_reset_progress.pressed.connect(confirm_reset.popup_centered)
	confirm_reset.confirmed.connect(Persistence.reset)

	MusicManager.ensure_playing.call_deferred("main_menu")


func _hide_all() -> void:
	main.hide()
	settings.hide()
	level_select.hide()


func _fill_level_select() -> void:
	var last_unlocked: int = Persistence.best_score

	for i: int in GameManager.last_level():
		var inst := Button.new()
		inst.text = str(i+1)
		inst.disabled = (i > last_unlocked) and i != 0

		inst.pressed.connect(GameManager.load_level.bind(i+1))

		level_grid.add_child(inst)
