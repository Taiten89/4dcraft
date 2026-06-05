extends Button

@onready var editor: Editor = $/root/Editor
@onready var base_edit: Base_Edit = $/root/Editor/Slice/Details/Base
var ftime: Find_Time
var i: int
var progress_diag: Popup
var progress_bar: ProgressBar


func _process (_delta: float) -> void:
	if ftime != null:
		process_steps()


func process_steps () -> void:
	var start_time := Time.get_ticks_msec()
	for s in range(i, ftime.n_steps):
		step()
		if Time.get_ticks_msec() - start_time > 50:
			return
	finish()


func step () -> void:
	ftime.step()
	i += 1
	progress_bar.value = 100.0 * i / ftime.n_steps


func finish () -> void:
	base_edit.base = ftime.result
	base_edit.do_update()
	cleanup()


func cleanup () -> void:
	progress_diag.hide()
	progress_diag = null
	progress_bar = null
	ftime = null


func _on_pressed () -> void:
	ftime = Find_Time.new(editor.slice)
	i = 0

	progress_diag = Popup.new()
	$/root.add_child(progress_diag)
	var hbox := HBoxContainer.new()
	progress_diag.add_child(hbox)
	progress_bar = ProgressBar.new()
	hbox.add_child(progress_bar)
	progress_bar.custom_minimum_size.x = 500
	var cancel := Button.new()
	hbox.add_child(cancel)
	cancel.text = "Cancel"
	cancel.pressed.connect(cleanup)
	progress_diag.popup_centered_clamped()
