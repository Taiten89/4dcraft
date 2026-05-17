class_name Calculation_Modes
extends Node

var modes: Array[String] = ["default", "custom"]


func _init () -> void:
	traverse("res://Calculation/Modes/")


func traverse (dir: String) -> void:
	var da := DirAccess.open(dir)
	for subdir in da.get_directories():
		traverse(dir + "/" + subdir)
	for file in da.get_files():
		if not file.ends_with(".glslinc"):
			continue
		var mode_name_length := file.length() - ".glslinc".length()
		var mode_name := file.substr(0, mode_name_length)
		if mode_name == "default":
			continue
		modes.append(mode_name)


func change_to_next (slice: Slice) -> void:
	change_by(slice, +1)
func change_to_previous (slice: Slice) -> void:
	change_by(slice, -1)


func change_by (slice: Slice, amount: int) -> void:
	var mode_i := modes.find(slice.mode) + amount
	while mode_i < 0:
		mode_i += modes.size()
	while mode_i >= modes.size():
		mode_i -= modes.size()
	slice.mode = modes[mode_i]

	if slice.mode == "custom" and not slice.custom_code:
		if amount > 0:
			change_to_next(slice)
		else:
			change_to_previous(slice)
