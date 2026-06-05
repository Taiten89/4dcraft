class_name Slice_Edit
extends VBoxContainer

var main: Editor
var mode_edit: ItemList
var modes := Calculation_Modes.new().modes
var max_n_edit: TextEdit
var position_edits: Array[TextEdit]
var precision_edit: SpinBox
var base_edit: Base_Edit
var palette_edit: Palette_Edit


func _ready () -> void:
	main = $/root/Editor

	mode_edit = $Details/Mode_Box/Mode
	for mode in modes:
		mode_edit.add_item(mode)
	max_n_edit = $Details/Props_Box/Max_N
	for axis in range(4):
		var position_edit := find_child("Position" + str(axis))
		position_edits.append(position_edit)
	precision_edit = $Details/Props_Box/Precision_Box/Precision
	base_edit = $Details/Base
	palette_edit = $Palette


func _on_visibility_changed () -> void:
	if is_visible_in_tree():
		update_from_main()
	else:
		push_to_main()


func update_from_main () -> void:

	for i in range(modes.size()):
		if main.slice.mode == modes[i]:
			mode_edit.select(i)
	max_n_edit.text = str(main.slice.max_n)
	for axis in range(4):
		var number := main.slice.position.numbers[axis]
		position_edits[axis].text = number.to_string()
	precision_edit.value = main.slice.position.precision
	base_edit.update(main.slice.base)
	palette_edit.update(main.slice.palette)


func push_to_main () -> void:

	var mode_i := mode_edit.get_selected_items()[0]
	var mode := modes[mode_i]
	var max_n := max_n_edit.text.to_int()
	if max_n <= 0:
		return
	var precision := int(precision_edit.value)
	@warning_ignore("shadowed_variable_base_class")
	var position := Position.new(precision)
	for axis in range(4):
		var n_string := position_edits[axis].text
		position.numbers[axis].set_from_string(n_string)
	var base := base_edit.pull()
	if base == null:
		return
	var palette := palette_edit.pull()

	main.slice.mode = mode
	main.slice.max_n = max_n
	main.slice.position = position
	main.slice.base = base
	main.slice.palette = palette
	main.slice_changed = true
