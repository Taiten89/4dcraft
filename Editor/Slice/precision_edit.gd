extends SpinBox


func _ready () -> void:
	min_value = Position.PRECISION_FLOATS
	max_value = $/root/Editor.MAX_PRECISION


func _on_value_changed (v: float) -> void:
	$"../Precision_Repr".text = "   "
	var repr: String
	var precision := int(v)

	if precision == Position.PRECISION_FLOATS:
		repr = "floats"
	if precision == Position.PRECISION_DOUBLES:
		repr = "doubles"

	if precision >= Position.PRECISION_ARBITRARY:
		var mantissa_bits := (precision-1) * 16
		repr = "1+15 . " + str(mantissa_bits)

	$"../Precision_Repr".text = "  " + repr
