extends Button

@onready var album_edit: Album_Edit = $"../.."

var mid: Slice
var exporter: Movie_Exporter
var progress_diag: Popup
var progress_bar: ProgressBar


func _process (_delta: float) -> void:
	if exporter:
		process_movie()


func process_movie () -> void:
	var p_start := Time.get_ticks_msec()
	while not exporter.is_finished():
		exporter.step()
		if Time.get_ticks_msec() - p_start > 50:
			progress_bar.value = exporter.progress_percents()
			return
	exporter = null
	progress_diag.hide()


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


func start_movie_func (output: String) -> void:
	exporter = Movie_Exporter.create(mid, output)

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
	exporter = null
	progress_diag.hide()
