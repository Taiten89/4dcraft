extends Button

@onready var editor: Editor = $/root/Editor
@onready var album_edit: Album_Edit = $"../.."

var slice: Slice


func _on_pressed () -> void:
	slice = album_edit.album.get_item(album_edit.xi, album_edit.yi)
	if slice == null:
		return

	var diag := FileDialog.new()
	diag.access = FileDialog.ACCESS_FILESYSTEM
	diag.add_filter("*.png")
	diag.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	$/root.add_child(diag)
	diag.popup_file_dialog()
	diag.file_selected.connect(do_make_poster)


func do_make_poster (fn: String) -> void:
	var poster := Poster.new(slice, slice.render.poster)
	for s in range(poster.n_steps()):
		poster.step()
	poster.output(fn)
