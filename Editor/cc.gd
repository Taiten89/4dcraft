extends Control

const FTIME_LIMIT_MSEC := 100.0

var playing := false
var initted := false
var retained_process_delta := 0.0
var slice := Slice.new()
var params := Calculation.Params.new()

@onready var editor: Editor = $/root/Editor
@onready var play_button: Button = find_child('Play')
@onready var view: ColorRect = find_child('View')

@onready var calculation := Calculation.new()
@onready var bird_paint := Slice_Paint.new(calculation)
@onready var portrait_paint := Portrait_Paint.new(calculation)


func _process (delta: float) -> void:
	if not is_visible_in_tree():
		return

	view.material.set_shader_parameter(&"bg_c", editor.background_color)

	if not initted:
		paint()
		initted = true

	if not playing:
		return

	var full_delta := retained_process_delta + delta
	var info := slice.render.movie
	var time_per_frame := 1.0 / info.fps
	var n_frames: int = floor(full_delta / time_per_frame)
	retained_process_delta = full_delta - n_frames * time_per_frame

	var timeout_msec := Time.get_ticks_msec() + FTIME_LIMIT_MSEC
	for frame_i in range(n_frames):
		const always_cc = true
		slice.modify_for_1_image(always_cc)
		if Time.get_ticks_msec() > timeout_msec:
			break

	if n_frames:
		paint()


func paint () -> void:
	params.w = int(view.size.x)
	params.h = int(view.size.y)
	params.workgroup_w = 16
	params.workgroup_h = 16

	var result: Texture2DRD
	var perspective := slice.render.perspective
	if perspective == Render_Info.PERSPECTIVE.PORTRAIT:
		var layers := slice.render.movie.preview_layers
		var portrait := Portrait.new(slice, layers)
		portrait_paint.paint(portrait, params)
		result = portrait_paint.result
	if perspective == Render_Info.PERSPECTIVE.BIRD:
		bird_paint.paint(slice, params)
		result = bird_paint.result

	view.material.set_shader_parameter(&"fractal_img", result)


func _on_visibility_changed () -> void:
	if not is_visible_in_tree():
		playing = false
		update_play_button_text()


func update_play_button_text () -> void:
	play_button.text = "Pause" if playing else "Play"


func _on_from_main_pressed () -> void:
	slice = editor.slice.copy()
	if not playing:
		paint()


func _on_to_main_pressed () -> void:
	editor.slice = slice.copy()
	editor.slice_changed = true


func _on_play_pressed () -> void:
	playing = !playing
	update_play_button_text()
