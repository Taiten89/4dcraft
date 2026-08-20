class_name Process_With_N_Steps
extends RefCounted

var n_steps: int
var step_i := 0

func _init (new_n_steps: int) -> void:
	n_steps = new_n_steps

func step () -> void:
	step_impl()
	step_i += 1

func is_finished () -> bool:
	return step_i == n_steps

func step_impl () -> void:
	pass

func progress_percents () -> float:
	if n_steps == 0:
		return 100.0
	return float(step_i) / float(n_steps) * 100.0
