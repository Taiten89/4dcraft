class_name View
extends ColorRect

var params := Calculation.Params.new()
var render_complete := false

@onready var editor: Editor = $/root/Editor
@onready var view_settings: View_Settings = $/root/Editor/View_Settings

@onready var calculation := Calculation.new()
@onready var bird_paint := Slice_Paint.new(calculation)
@onready var portrait_paint := Portrait_Paint.new(calculation)


func _process (_delta: float) -> void:
	if not is_visible_in_tree():
		return
	render_if_needed()
	material.set_shader_parameter(&"bg_c", editor.background_color)


func render_if_needed () -> void:
	var new_w := int(size.x)
	var new_h := int(size.y)

	var a := [new_w,new_h] != [params.w,params.h]
	var b := editor.slice_changed
	var c := editor.slice.mode == "custom" and calculation.custom_code_changed
	var d := not render_complete

	if not (a or b or c or d):
		return

	if a or b:
		params.subsampling_step = 0

	params.w = new_w
	params.h = new_h

	do_render()

	params.subsampling_step += 1
	if params.subsampling_step == params.subsampling ** 2:
		params.subsampling_step = 0
		render_complete = true
	else:
		render_complete = false

	editor.slice_changed = false


func do_render () -> void:
	var result: Texture2DRD
	if view_settings.portrait_toggled:
		var portrait_n := int(view_settings.portrait_n.value)
		var portrait := Portrait.new(editor.slice, portrait_n)
		portrait_paint.paint(portrait, params)
		portrait_paint.interpolate()
		result = portrait_paint.result
	else:
		bird_paint.paint(editor.slice, params)
		bird_paint.interpolate()
		result = bird_paint.result
	material.set_shader_parameter(&"fractal_img", result)


func _gui_input (event: InputEvent) -> void:
	$Input.gui_input(event)
