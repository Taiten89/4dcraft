extends Button

@onready var album_edit: Album_Edit = $"../.."

var mid: Slice
var output := ""
var paint := Portrait_Paint.new(Calculation.new())
var b_time: SpinBox
var e_time: SpinBox
var w: SpinBox
var h: SpinBox
var d: SpinBox  # "depth", n render layers per output image
var n: SpinBox
var l_i: int  # current layer
var p_i: int  # current portrait (output image)
var progress_diag: Popup
var progress_bar: ProgressBar


func _process (_delta: float) -> void:
	if output:
		process_movie()


func process_movie () -> void:
	var p_start := Time.get_ticks_msec()
	for s_ in range(p_i, n.value):
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

	var n_steps := n.value * paint_n_steps
	var step_i := l_i + p_i * paint_n_steps
	progress_bar.value = step_i / n_steps * 100


func complete_image () -> void:
	var fn := output + "/%05d.png" % p_i
	var png := Image.new()
	png.copy_from(paint.result.get_image())
	png.convert(Image.FORMAT_RGBA8)
	png.save_png(fn)


func start_portrait () -> void:
	var p_mid := mid.copy()
	var time := b_time.value + p_i / n.value * (e_time.value - b_time.value)
	p_mid.position.translate_inplace(time * p_mid.base.column(3))
	var portrait := Portrait.new(p_mid, int(d.value))

	var params := Calculation.Params.new()
	params.w = int(w.value)
	params.h = int(h.value)
	params.workgroup_w = 16
	params.workgroup_h = 16

	paint.start(portrait, params)


func _on_pressed () -> void:
	mid = album_edit.album.get_item(album_edit.xi, album_edit.yi)
	if mid == null:
		return

	var diag := Popup.new()
	$/root.add_child(diag)
	var vbox := VBoxContainer.new()
	diag.add_child(vbox)

	var hbox_whdn := HBoxContainer.new()
	vbox.add_child(hbox_whdn)
	w = SpinBox.new()
	hbox_whdn.add_child(w)
	w.min_value = 1
	w.max_value = 19200
	w.value = 1920
	h = SpinBox.new()
	hbox_whdn.add_child(h)
	h.min_value = 1
	h.max_value = 10800
	h.value = 1080
	hbox_whdn.add_child(VSeparator.new())
	d = SpinBox.new()
	d.min_value = 1
	d.max_value = 20_000
	d.value = 3000
	hbox_whdn.add_child(d)
	hbox_whdn.add_child(VSeparator.new())
	n = SpinBox.new()
	n.min_value = 1
	n.max_value = 100_000
	n.value = 10
	hbox_whdn.add_child(n)

	var hbox_time := HBoxContainer.new()
	vbox.add_child(hbox_time)
	var time_label := Label.new()
	hbox_time.add_child(time_label)
	time_label.text = "begin/end time offset "
	b_time = SpinBox.new()
	hbox_time.add_child(b_time)
	b_time.rounded = false
	b_time.step = 0.01
	b_time.max_value = 100
	b_time.min_value = -b_time.max_value
	b_time.value = -0.5
	e_time = SpinBox.new()
	hbox_time.add_child(e_time)
	e_time.rounded = false
	e_time.step = 0.01
	e_time.max_value = 100
	e_time.min_value = -e_time.max_value
	e_time.value = 0.5

	var hbox_close := HBoxContainer.new()
	vbox.add_child(hbox_close)
	var ok := Button.new()
	hbox_close.add_child(ok)
	ok.text = "OK"
	ok.pressed.connect(movie_confirmed_func)
	ok.pressed.connect(diag.hide)
	var cancel := Button.new()
	hbox_close.add_child(cancel)
	cancel.text = "Cancel"
	cancel.pressed.connect(diag.hide)

	diag.popup_centered_clamped()


func movie_confirmed_func () -> void:
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
