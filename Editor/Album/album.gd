class_name Album_Edit
extends HBoxContainer

const FN_EXT := ".json"

var album := Album.new()
var album_changed := false
var xi := 0
var yi := 0
var current_fn := ""
var has_unsaved_changes := false

@onready var editor: Editor = $/root/Editor
@onready var view: TextureRect = $View/View


func _ready () -> void:
	album.paint = Slice_Paint.new(Calculation.new())
	view.texture = ImageTexture.create_from_image(album.image)


func _process (_delta: float) -> void:
	if not album_changed:
		return

	if xi >= album.nx:
		xi = album.nx - 1
	if yi >= album.ny:
		yi = album.ny - 1

	view.texture = ImageTexture.create_from_image(album.image)


func _on_from_main_pressed () -> void:
	album.set_item(xi, yi, editor.slice)
	album.render(xi, yi)
	album_changed = true
	has_unsaved_changes = true


func _on_to_main_pressed () -> void:
	var item := album.get_item(xi, yi)
	if item == null:
		editor.slice = Slice.new()
		editor.slice_changed = true
	else:
		editor.slice = item
		editor.slice_changed = true


func _on_delete_pressed () -> void:
	album.set_item(xi, yi, null)
	album.render(xi, yi)
	album_changed = true
	has_unsaved_changes = true


func _on_new_pressed () -> void:
	var diag := Popup.new()
	var vbox := VBoxContainer.new()
	diag.add_child(vbox)

	var hbox0 := HBoxContainer.new()
	vbox.add_child(hbox0)
	var nx := SpinBox.new()
	nx.value = album.nx
	hbox0.add_child(nx)
	var ny := SpinBox.new()
	ny.value = album.ny
	hbox0.add_child(ny)
	var ew := SpinBox.new()
	ew.max_value = Album.MAX_EW
	ew.value = album.ew
	hbox0.add_child(ew)
	var eh := SpinBox.new()
	eh.max_value = Album.MAX_EH
	eh.value = album.eh
	hbox0.add_child(eh)

	var hbox1 := HBoxContainer.new()
	vbox.add_child(hbox1)
	var ok := Button.new()
	hbox1.add_child(ok)
	ok.text = "OK"
	ok.connect("pressed", new_confirmed_func.bind(nx,ny,ew,eh))
	ok.connect("pressed", diag.hide)
	var cancel := Button.new()
	hbox1.add_child(cancel)
	cancel.text = "Cancel"
	cancel.connect("pressed", diag.hide)

	add_child(diag)
	diag.popup_centered_clamped()

func new_confirmed_func
(nx: SpinBox, ny: SpinBox, ew: SpinBox, eh: SpinBox) \
-> void:
	album.nx = int(nx.value)
	album.ny = int(ny.value)
	album.ew = int(ew.value)
	album.eh = int(eh.value)
	album.make_new()
	album_changed = true
	has_unsaved_changes = false

	current_fn = ""


func _on_save_pressed () -> void:
	if not current_fn:
		_on_save_as_pressed()
	else:
		do_save(current_fn)

func _on_save_as_pressed () -> void:
	var diag := FileDialog.new()
	diag.access = FileDialog.ACCESS_FILESYSTEM
	#diag.use_native_dialog = true  # makes the main window accessible while diag open
	diag.clear_filename_filter()
	diag.add_filter("*" + FN_EXT)
	diag.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	add_child(diag)
	diag.popup_file_dialog()
	diag.file_selected.connect(do_save)

func do_save (fn: String) -> void:
	if not fn.ends_with(FN_EXT):
		print('"',fn,'" doesn\'t end with ', FN_EXT ,'; aborting.')
		return

	var album_as_json := JSON.stringify(album.variant_for_storage())
	var json_file = FileAccess.open(fn, FileAccess.WRITE)
	json_file.store_string(album_as_json)
	json_file.close()

	var fn_no_ext := fn.substr(0, fn.length() - FN_EXT.length())
	album.image.save_png(fn_no_ext + ".png")

	current_fn = fn
	has_unsaved_changes = false


func _on_open_pressed () -> void:
	var diag := FileDialog.new()
	diag.access = FileDialog.ACCESS_FILESYSTEM
	#diag.use_native_dialog = true  # leaves the main window accessible while diag open
	diag.clear_filename_filter()
	diag.add_filter("*" + FN_EXT)
	diag.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	add_child(diag)
	diag.popup_file_dialog()
	diag.file_selected.connect(do_open)

func do_open (fn: String) -> void:
	if not fn.ends_with(FN_EXT):
		print('"',fn,'" doesn\'t end with ', FN_EXT ,'; aborting.')
		return

	var album_as_json := FileAccess.open(fn, FileAccess.READ).get_as_text()
	var album_as_storage_variant = JSON.parse_string(album_as_json)
	if album_as_storage_variant == null:
		print(fn, ": Parse failed.")
	album.set_from_storage_variant(album_as_storage_variant)

	var fn_no_ext := fn.substr(0, fn.length() - FN_EXT.length())
	album.image.load(fn_no_ext + ".png")
	album.image.convert(Album.IMAGE_FORMAT)

	album_changed = true
	current_fn = fn
	has_unsaved_changes = false


func _on_extend_u_pressed () -> void:
	if album.extend(Vector2i(xi,yi), 1, -1):
		yi -= 1
func _on_extend_l_pressed () -> void:
	if album.extend(Vector2i(xi,yi), 0, -1):
		xi -= 1
func _on_extend_r_pressed () -> void:
	if album.extend(Vector2i(xi,yi), 0, +1):
		xi += 1
func _on_extend_d_pressed () -> void:
	if album.extend(Vector2i(xi,yi), 1, +1):
		yi += 1
