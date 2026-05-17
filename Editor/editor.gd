class_name Editor
extends TabContainer

const MAX_PRECISION := 10

var slice := Slice.new()
var slice_changed := false
var background_color: Vector3

@onready var root: Window = $/root
@onready var view_settings: View_Settings = $View_Settings
@onready var album: Album_Edit = $Album


func _ready () -> void:
	get_tree().auto_accept_quit = false
	root.close_requested.connect(_quit_game)
	focus_current_tab()


func _process (_delta: float) -> void:
	update_background_color()


func _quit_game () -> void:
	if album.has_unsaved_changes:
		exit_on_confirmation()
	else:
		get_tree().quit()


func exit_on_confirmation () -> void:
	var diag := ConfirmationDialog.new()
	add_child(diag)
	diag.dialog_text = "There are unsaved changes. Quit anyway?"
	diag.confirmed.connect(get_tree().quit)
	diag.popup()


func update_background_color () -> void:
	var seconds := Time.get_ticks_msec() / 1000.0
	var phases := seconds / view_settings.bg_t
	var phase := phases - int(phases)
	var i := cos(phase * TAU)
	background_color = i * view_settings.bg_c_a + (1-i) * view_settings.bg_c_b


func _on_tab_selected (_tab: int) -> void:
	focus_current_tab()


func focus_current_tab () -> void:
	var current_item := get_current_tab_control()
	if current_item.focus_mode != FOCUS_NONE and current_item.is_inside_tree():
		current_item.grab_focus()
