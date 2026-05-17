class_name Base_Edit
extends HBoxContainer

var base: Base
var matrix_repr: GridContainer
var length_edit: TextEdit
var axes_select: OptionButton
var axes_combinations: Array[String] = []
var axis_select: OptionButton


func _ready () -> void:
	matrix_repr = $L/Matrix_Repr
	length_edit = $L/Length
	axes_select = $R/Axes
	axis_select = $R/Axis

	for axis0 in range(3):
		for axis1 in range(axis0+1, 4):
			var r0 := Slice.AXIS_REPR_SHORT[axis0]
			var r1 := Slice.AXIS_REPR_SHORT[axis1]
			axes_select.add_item(r0 + r1)
			axes_combinations.append(str(axis0) + str(axis1))

	for repr in Slice.AXIS_REPR:
		axis_select.add_item(repr)


func update (new_base: Base) -> void:
	base = new_base.copy()
	do_update()


func do_update () -> void:

	for child in matrix_repr.get_children():
		matrix_repr.remove_child(child)
	for row in range(4):
		for col in range(4):
			var value := base.columns[col][row]
			matrix_repr.add_child(make_matrix_node(value))

	length_edit.text = var_to_str(base.length)


func make_matrix_node (value: float) -> Label:
	var child := Label.new()
	child.text = "%.02f " % value
	child.custom_minimum_size = Vector2(50,50)
	var style := StyleBoxFlat.new()
	if value < 0:
		style.bg_color = Color(-value,0,0, 1)
	else:
		style.bg_color = Color(0,value,0, 1)
	child.add_theme_stylebox_override("normal", style)
	return child


func pull () -> Base:
	var length := length_edit.text.to_float()
	if not (is_finite(length) and length > 0):
		return null
	base.length = length
	return base.copy()


func _on_reset_pressed () -> void:
	for axis in range(4):
		base.columns[axis] = Vector4(0,0,0,0)
		base.columns[axis][axis] = 1.0
	do_update()


func _on_mirror_pressed () -> void:
	var axis := axis_select.get_selected_id()
	base.columns[axis] = -base.columns[axis]
	do_update()


func _on_turn_pressed () -> void:
	var axes_id := axes_select.get_selected_id()
	var axis0 := axes_combinations[axes_id][0].to_int()
	var axis1 := axes_combinations[axes_id][1].to_int()
	base.rotate_inplace(axis0, axis1, TAU/8)
	do_update()
