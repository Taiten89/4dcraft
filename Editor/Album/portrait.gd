extends Button

@onready var album_edit: Album_Edit = $"../.."

var mid: Slice
var fn: String
var portrait: Portrait
var paint: Portrait_Paint
var w: SpinBox
var h: SpinBox
var n: SpinBox
var i: int
var progress_diag: Popup
var progress_bar: ProgressBar


func _process (_delta: float) -> void:
	if portrait:
		process_portrait()


func process_portrait () -> void:
	var p_start := Time.get_ticks_msec()
	for s in range(i, paint.n_steps()):
		paint.step()
		i += 1
		progress_bar.value = i / n.value * 100
		if Time.get_ticks_msec() - p_start > 50:
			return
	complete()


func complete () -> void:
	var png := Image.new()
	png.copy_from(paint.result.get_image())
	png.convert(Image.FORMAT_RGBA8)
	png.save_png(fn)
	portrait = null

	progress_diag.hide()


func _on_pressed() -> void:
	mid = album_edit.album.get_item(album_edit.xi, album_edit.yi)
	if mid == null:
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
	hbox.add_child(VSeparator.new())
	n = SpinBox.new()
	n.min_value = 1
	n.max_value = 20_000
	n.value = 3000
	hbox.add_child(n)
	var ok := Button.new()
	hbox.add_child(ok)
	ok.text = "OK"
	ok.pressed.connect(portrait_confirmed_func)
	$/root.add_child(diag)
	diag.popup_centered_clamped()


func portrait_confirmed_func () -> void:
	var diag := FileDialog.new()
	diag.access = FileDialog.ACCESS_FILESYSTEM
	diag.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	diag.add_filter("*.png")
	$/root.add_child(diag)
	diag.popup_file_dialog()
	diag.file_selected.connect(do_start_portrait)


func do_start_portrait (new_fn: String) -> void:
	portrait = Portrait.new(mid, int(n.value))
	fn = new_fn
	paint = Portrait_Paint.new(Calculation.new())
	var params := Calculation.Params.new()
	params.w = int(w.value)
	params.h = int(h.value)
	params.workgroup_w = 16
	params.workgroup_h = 16
	i = 0

	paint.start(portrait, params)

	progress_diag = Popup.new()
	var hbox := HBoxContainer.new()
	progress_diag.add_child(hbox)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.x = 500
	hbox.add_child(progress_bar)
	var cancel := Button.new()
	hbox.add_child(cancel)
	cancel.text = "Cancel"
	cancel.pressed.connect(cancel_func)
	$/root.add_child(progress_diag)
	progress_diag.popup_centered_clamped()


func cancel_func () -> void:
	portrait = null
	progress_diag.hide()
