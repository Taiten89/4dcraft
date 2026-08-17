class_name Preview_Movie
extends ColorRect

enum STATES {RUNNING, WAITING}

var needs_setup: bool
var state: STATES
var start_time: float
var playing_time_span: float
var rel_time: float
var original_slice: Slice
var slice: Slice
var params := Calculation.Params.new()

@onready var editor: Editor = $/root/Editor

@onready var calculation := Calculation.new()
@onready var bird_paint := Slice_Paint.new(calculation)
@onready var portrait_paint := Portrait_Paint.new(calculation)


func _process (_delta: float) -> void:
	if not is_visible_in_tree():
		return
	if needs_setup:
		setup()
		needs_setup = false
	update_state()
	render_if_needed()
	material.set_shader_parameter(&"bg_c", editor.background_color)


func _on_visibility_changed () -> void:
	if is_visible_in_tree():
		needs_setup = true


func setup () -> void:
	start_time = Time.get_ticks_msec() / 1000.0
	state = STATES.RUNNING
	original_slice = editor.slice.copy()
	slice = editor.slice.copy()
	var info := slice.render.movie
	playing_time_span = info.preview_images / info.fps


func render_if_needed () -> void:
	var new_w := int(size.x)
	var new_h := int(size.y)

	var a := [new_w,new_h] != [params.w,params.h]
	var b := state == STATES.RUNNING

	if not (a or b):
		return

	params.w = new_w
	params.h = new_h
	params.workgroup_w = 16
	params.workgroup_h = 16

	update_slice()
	do_render()


func update_state () -> void:

	if state == STATES.RUNNING:
		var seconds_since_start := Time.get_ticks_msec() / 1000.0 - start_time
		rel_time = seconds_since_start / playing_time_span
		if rel_time >= 1.0:
			start_time = Time.get_ticks_msec() / 1000.0
			rel_time = 0.0
			state = STATES.WAITING

	elif state == STATES.WAITING:
		# wait one second
		rel_time = Time.get_ticks_msec() / 1000.0 - start_time
		if rel_time >= 1.0:
			start_time = Time.get_ticks_msec() / 1000.0
			rel_time = 0.0
			state = STATES.RUNNING


func update_slice() -> void:
	var info := slice.render.movie
	var translation_factor := info.start + rel_time * (info.stop - info.start)
	var translation := translation_factor * slice.base.column(3)
	slice.position = original_slice.position.copy()
	slice.position.translate_inplace(translation)


func do_render () -> void:
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
	material.set_shader_parameter(&"fractal_img", result)
