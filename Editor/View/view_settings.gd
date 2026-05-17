class_name View_Settings
extends HBoxContainer

var view: View
var subsampling: SpinBox
var workgroup_w: SpinBox
var workgroup_h: SpinBox
var portrait: CheckBox
var portrait_toggled := false
var portrait_n: SpinBox


func _ready () -> void:
	view = $"../View"
	subsampling = find_child("Subsampling")
	workgroup_w = find_child("Workgroup_W")
	workgroup_h = find_child("Workgroup_H")
	portrait = find_child("Portrait")
	portrait_n = find_child("Portrait_N")
	push_to_view()


func _on_visibility_changed () -> void:
	if not is_visible_in_tree():
		push_to_view()


func push_to_view () -> void:
	var vparams := view.params
	vparams.subsampling = int(subsampling.value)
	vparams.subsampling_step = 0
	vparams.workgroup_w = int(workgroup_w.value)
	vparams.workgroup_h = int(workgroup_h.value)
	view.render_complete = false


func _on_workgroup_w_changed(value: float) -> void:
	workgroup_h.max_value = int(256 / value)
func _on_workgroup_h_changed(value: float) -> void:
	workgroup_w.max_value = int(256 / value)


func _on_portrait_toggled (toggled_on: bool) -> void:
	portrait_toggled = toggled_on
	portrait_n.editable = toggled_on
