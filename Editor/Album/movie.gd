extends Button

@onready var album_edit: Album_Edit = $"../.."

var mid: Slice
var output := ""
var paint := Portrait_Paint.new(Calculation.new())
var l_i: int  # current layer
var p_i: int  # current portrait (output image)
var progress_diag: Popup
var progress_bar: ProgressBar


func _process (_delta: float) -> void:
	if output:
		process_movie()


func process_movie () -> void:
	var p_start := Time.get_ticks_msec()
	var portraits := mid.render.movie.images
	for s_ in range(p_i, portraits):
		if l_i == 0:
			start_portrait()
		for s in range(l_i, paint.n_steps()):
			process_step()
			if Time.get_ticks_msec() - p_start > 50:
				return
	output = ""
	progress_diag.hide()


func process_step () -> void:
	var paint_n_steps := paint.n_steps()
	paint.step()
	l_i += 1
	if l_i == paint_n_steps:
		complete_image()
		l_i = 0
		p_i += 1

	var images := mid.render.movie.images
	var n_steps := images * paint_n_steps
	var step_i := l_i + p_i * paint_n_steps
	progress_bar.value = float(step_i) / float(n_steps) * 100


func complete_image () -> void:
	var fn := output + "/%05d.png" % p_i
	var png := Image.new()
	png.copy_from(paint.result.get_image())
	png.convert(Image.FORMAT_RGBA8)
	png.save_png(fn)


func start_portrait () -> void:
	var p_mid := mid.copy()
	var info := p_mid.render.movie
	var full_time_span := info.stop - info.start
	var rel_time := float(p_i) / float(info.images)
	var time := info.start + rel_time * full_time_span
	p_mid.position.translate_inplace(time * p_mid.base.column(3))
	var portrait := Portrait.new(p_mid, info.layers)
	paint.start(portrait, info)


func _on_pressed () -> void:
	mid = album_edit.album.get_item(album_edit.xi, album_edit.yi)
	if mid == null:
		return

	var diag := FileDialog.new()
	$/root.add_child(diag)
	diag.access = FileDialog.ACCESS_FILESYSTEM
	diag.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	diag.popup_file_dialog()
	diag.dir_selected.connect(start_movie_func)


func start_movie_func (new_output: String) -> void:
	output = new_output
	l_i = 0
	p_i = 0

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
	output = ""
	progress_diag.hide()
