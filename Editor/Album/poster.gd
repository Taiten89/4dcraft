extends Button

@onready var album_edit: Album_Edit = $"../.."

var slice: Slice
var w: SpinBox
var h: SpinBox


func _on_pressed () -> void:
	slice = album_edit.album.get_item(album_edit.xi, album_edit.yi)
	if slice == null:
		return

	var diag := Popup.new()
	var hbox := HBoxContainer.new()
	diag.add_child(hbox)
	w = SpinBox.new()
	hbox.add_child(w)
	w.min_value = 1
	w.max_value = 19200
	w.value = 1920
	h = SpinBox.new()
	hbox.add_child(h)
	h.min_value = 1
	h.max_value = 10800
	h.value = 1080
	var ok := Button.new()
	hbox.add_child(ok)
	ok.text = "OK"
	ok.pressed.connect(poster_confirmed_func)
	$/root.add_child(diag)
	diag.popup_centered_clamped()


func poster_confirmed_func () -> void:
	var diag := FileDialog.new()
	diag.access = FileDialog.ACCESS_FILESYSTEM
	diag.add_filter("*.png")
	diag.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	$/root.add_child(diag)
	diag.popup_file_dialog()
	diag.file_selected.connect(do_make_poster)


func do_make_poster (fn: String) -> void:
	var poster := Poster.new(slice, int(w.value), int(h.value))
	for s in range(poster.n_steps()):
		poster.step()
	poster.output(fn)
