extends Button

const Iteration = Find_Time_Iteration.Iteration
const Item = Find_Time_Item.Item
const Params = Find_Time_Params.Params

@onready var editor: Editor = $/root/Editor
@onready var basic_edit: Slice_Edit = $/root/Editor/Main/Basic
var diag: Popup


func _on_pressed () -> void:
	basic_edit.push_to_main()

	diag = Popup.new()
	$/root.add_child(diag)
	var hbox := HBoxContainer.new()
	diag.add_child(hbox)
	var label := Label.new()
	label.text = var_to_str(calculate_relative_aberration())
	hbox.add_child(label)
	var ok := Button.new()
	hbox.add_child(ok)
	ok.text = "OK"
	ok.pressed.connect(ok_pressed)
	diag.popup_centered_clamped()


func ok_pressed () -> void:
	diag.hide()


func calculate_relative_aberration () -> float:
	var slice := editor.slice
	var base := slice.base
	var item := Item.new(base)
	var params := Params.new()
	var ftime := Iteration.new(slice, [item], params)
	var aberration := ftime.calculate_aberration(editor.slice.base)
	var resolution := params.resolution
	var time_div := params.time_div
	var max_aberration := resolution**3 * time_div * slice.max_n
	return float(aberration) / float(max_aberration)
