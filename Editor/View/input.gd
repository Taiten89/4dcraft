class_name View_Input
extends Node

var editor: Editor
var view: View
var w: int
var h: int
var last_frame_time := float(Time.get_ticks_msec()) / 1000
var mouse_clicked := 0  # +1: left, -1: right
var wheel_clicked := false
var mouse_position := Vector2(0, 0)
var mouse_delta: Vector2


func _ready () -> void:
	editor = $/root/Editor
	view = $".."


func _process (_delta: float) -> void:
	var current_time := float(Time.get_ticks_msec()) / 1000
	var delta := current_time - last_frame_time
	last_frame_time = current_time
	var clamped_delta: float = clamp(delta, 0.0, +0.1)

	if not view.is_visible_in_tree():
		return

	w = view.params.w
	h = view.params.h

	if mouse_clicked:
		var amount := clamped_delta * mouse_clicked
		editor.slice.zoom(mouse_position.x, mouse_position.y, amount)
		editor.slice_changed = true
	if wheel_clicked:
		process_drag()
	process_zoom_keys(clamped_delta)
	process_translation_keys(clamped_delta)
	process_rotations(clamped_delta)


func process_zoom_keys (clamped_delta: float) -> void:
	if Input.is_action_pressed("zoom+"):
		do_process_zoom_key(clamped_delta)
	if Input.is_action_pressed("zoom-"):
		do_process_zoom_key(-clamped_delta)


func do_process_zoom_key (amount: float) -> void:
	editor.slice.position.translate_inplace(-editor.slice.base.column(1))
	editor.slice.zoom(0, 0, amount)
	editor.slice.position.translate_inplace(editor.slice.base.column(1))
	editor.slice_changed = true


func process_translation_keys (clamped_delta: float) -> void:
	for axis in range(4):
		var column := editor.slice.base.column(axis)
		if Input.is_action_pressed("translate" + str(axis) + "+"):
			editor.slice.position.translate_inplace(clamped_delta * column)
			editor.slice_changed = true
		if Input.is_action_pressed("translate" + str(axis) + "-"):
			editor.slice.position.translate_inplace(-clamped_delta * column)
			editor.slice_changed = true


func process_drag () -> void:
	var position_delta := \
		-(mouse_delta.x*editor.slice.base.column(0) +
		  mouse_delta.y*editor.slice.base.column(1))
	editor.slice.position.translate_inplace(position_delta)
	editor.slice_changed = true
	mouse_delta = Vector2(0, 0)


func process_rotations (clamped_delta: float) -> void:

	for i0 in range(3):
		for i1 in range(i0+1, 4):
			for signum in [+1,-1]:

				var signum_str :=  "+" if signum == +1  else "-"
				var key := "rotate" + str(i0) + str(i1) + signum_str
				if Input.is_action_pressed(key):
					do_rotate(i0, i1, signum * clamped_delta)


func do_rotate (i0: int, i1: int, amount: float) -> void:
	var position := editor.slice.position
	var base := editor.slice.base
	position.translate_inplace(-base.column(1))
	base.rotate_inplace(i0, i1, amount)
	position.translate_inplace(base.column(1))
	editor.slice_changed = true


func gui_input (event: InputEvent) -> void:

	if event.is_action_pressed("mode"):
		mode_pressed()
	if event.is_action_pressed("max_n"):
		max_n_pressed()
	if event.is_action_pressed("precision"):
		precision_pressed()

	if w==0 or h==0:
		return

	if event is InputEventMouseButton:
		mouse_button(event)
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		mouse_motion(event)


func mode_pressed () -> void:
	if not Input.is_action_pressed("shift"):
		$"../Calculation/Modes".change_to_next(editor.slice)
		editor.slice_changed = true
	else:
		$"../Calculation/Modes".change_to_previous(editor.slice)
		editor.slice_changed = true


func max_n_pressed () -> void:
	if not Input.is_action_pressed("shift"):
		var new_max_n := int(editor.slice.max_n * 1.5)
		editor.slice.max_n = new_max_n
		editor.slice_changed = true
	else:
		var new_max_n := int(editor.slice.max_n / 1.5)
		if new_max_n < 2:
			return
		editor.slice.max_n = new_max_n
		editor.slice_changed = true


func precision_pressed () -> void:
	if not Input.is_action_pressed("shift"):
		if not editor.slice.position.precision >= editor.MAX_PRECISION:
			editor.slice.position.change_precision \
				(editor.slice.position.precision + 1)
			editor.slice_changed = true
	else:
		if not editor.slice.position.precision == Position.PRECISION_FLOATS:
			editor.slice.position.change_precision \
				(editor.slice.position.precision - 1)
			editor.slice_changed = true


func mouse_button (event: InputEvent) -> void:

	if event.pressed:
		if event.button_index == 1:
			mouse_clicked = +1
		if event.button_index == 2:
			mouse_clicked = -1
		if event.button_index == 3:
			wheel_clicked = true

	if not event.pressed:
		if event.button_index == 1 or event.button_index == 2:
			mouse_clicked = 0
		if event.button_index == 3:
			wheel_clicked = false


func mouse_motion (event: InputEvent) -> void:
	var rel_d_from_ul: Vector2 = event.position / Vector2(w,h)
	var new_position = Vector2(-1,1) + Vector2(2,-2) * rel_d_from_ul
	var aspect_ratio := float(w) / float(h)
	if aspect_ratio > 1:
		new_position.x *= aspect_ratio
	else:
		new_position.y /= aspect_ratio

	if mouse_delta == null:
		mouse_delta = Vector2(0, 0)
	elif wheel_clicked:
		mouse_delta += new_position - mouse_position

	mouse_position = new_position
