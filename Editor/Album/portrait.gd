extends Button

@onready var album_edit: Album_Edit = $"../.."

var mid: Slice
var fn: String
var portrait: Portrait
var paint: Portrait_Paint
var i: int
var progress_diag: Popup
var progress_bar: ProgressBar


func _process (_delta: float) -> void:
	if portrait:
		process_portrait()


func process_portrait () -> void:
	var p_start := Time.get_ticks_msec()
	var info := mid.render.portrait
	for s in range(i, paint.n_steps()):
		paint.step()
		i += 1
		var rel_i := float(i) / float(info.layers)
		progress_bar.value = rel_i * 100
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

	var diag := FileDialog.new()
	diag.access = FileDialog.ACCESS_FILESYSTEM
	diag.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	diag.add_filter("*.png")
	$/root.add_child(diag)
	diag.popup_file_dialog()
	diag.file_selected.connect(do_start_portrait)


func do_start_portrait (new_fn: String) -> void:
	var info := mid.render.portrait
	portrait = Portrait.new(mid, info.layers)
	fn = new_fn
	paint = Portrait_Paint.new(Calculation.new())
	i = 0

	paint.start(portrait, info)

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
