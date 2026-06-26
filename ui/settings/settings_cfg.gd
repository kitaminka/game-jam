extends Node


const CFG_PATH: String = "user://settings.cfg"

var config: ConfigFile


func _init() -> void:
	config = ConfigFile.new()
	var err: Error = config.load(CFG_PATH)
	if err != Error.OK and err != Error.ERR_FILE_NOT_FOUND:
		printerr("[Settings]: reading error: ", error_string(err))


func hard_mode() -> bool:
	return config.get_value("gameplay", "hard_mode", false)


func set_hard_mode(v: bool) -> void:
	config.set_value("gameplay", "hard_mode", v)
	config.save(CFG_PATH)
