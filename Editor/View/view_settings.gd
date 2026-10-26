class_name View_Settings
extends HBoxContainer

const ORIENTATION_VIEWER := 0
const ORIENTATION_CENTER := 1

@onready var view: View = $/root/Editor/Main/View
@onready var subsampling: SpinBox = find_child("Subsampling")
@onready var workgroup_w: SpinBox = find_child("Workgroup_W")
@onready var workgroup_h: SpinBox = find_child("Workgroup_H")
@onready var orientation: OptionButton = find_child("Orientation")
@onready var bg_c_ar_sb: SpinBox = $Column2/BG_C/A/R
@onready var bg_c_ag_sb: SpinBox = $Column2/BG_C/A/G
@onready var bg_c_ab_sb: SpinBox = $Column2/BG_C/A/B
@onready var bg_c_br_sb: SpinBox = $Column2/BG_C/B/R
@onready var bg_c_bg_sb: SpinBox = $Column2/BG_C/B/G
@onready var bg_c_bb_sb: SpinBox = $Column2/BG_C/B/B
@onready var bg_t_sb: SpinBox = $Column2/BG_C/T

var bg_c_a: Vector3
var bg_c_b: Vector3
var bg_t: float


func _ready () -> void:
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

	for sb in [bg_t_sb,
			bg_c_ar_sb, bg_c_ag_sb, bg_c_ab_sb,
			bg_c_br_sb, bg_c_bg_sb, bg_c_bb_sb]:
		sb.apply()

	bg_c_a.x = bg_c_ar_sb.value / 15
	bg_c_a.y = bg_c_ag_sb.value / 15
	bg_c_a.z = bg_c_ab_sb.value / 15
	bg_c_b.x = bg_c_br_sb.value / 15
	bg_c_b.y = bg_c_bg_sb.value / 15
	bg_c_b.z = bg_c_bb_sb.value / 15
	bg_t = bg_t_sb.value

	view.render_complete = false


func _on_workgroup_w_changed(value: float) -> void:
	workgroup_h.max_value = int(256 / value)
func _on_workgroup_h_changed(value: float) -> void:
	workgroup_w.max_value = int(256 / value)
