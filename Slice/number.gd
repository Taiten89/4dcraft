class_name Number
extends RefCounted

var precision: int
var signum := +1
var parts: Array[int]
var double_repr: float  # gd float = c++ double


@warning_ignore("shadowed_variable")
func _init (precision: int) -> void:
	change_precision(precision)


func copy () -> Number:
	var n := Number.new(precision)
	if precision <= Position.PRECISION_DOUBLES:
		n.double_repr = double_repr
	else:
		for place in range(precision):
			n.parts[place] = parts[place]
		n.signum = signum
	return n


func bytes_for_uniforms () -> PackedByteArray:
	if precision == Position.PRECISION_FLOATS:
		return PackedFloat32Array([double_repr]).to_byte_array()
	if precision == Position.PRECISION_DOUBLES:
		return PackedFloat64Array([double_repr]).to_byte_array()
	# >= PRECISION_ARBITRARY
	return compact_uints32().to_byte_array()


func compact_uints32 () -> PackedInt32Array:
	var uints := PackedInt32Array()
	@warning_ignore("integer_division")
	uints.resize((precision+1) / 2)  # round-up
	uints[0] = int(signum == -1) << 15
	for place in range(precision):
		@warning_ignore("integer_division")
		var i := place / 2
		var is_odd_16 := (place & 1) * 16
		uints[i] |= parts[place] << is_odd_16
	return uints


func change_precision (new_precision: int) -> void:

	if new_precision <= Position.PRECISION_DOUBLES:

		if precision <= Position.PRECISION_DOUBLES:
			pass
		else:
			double_repr = to_double()

	else:  # new precision is fixed

		parts.resize(new_precision)

		if precision <= Position.PRECISION_DOUBLES:
			set_from_double(double_repr)
		else:
			pass

	precision = new_precision


func add_d_inplace (d: float) -> void:
	if precision <= Position.PRECISION_DOUBLES:
		double_repr += d
	else:
		var dn := Number.new(precision)
		dn.set_from_double(d)

		if dn.signum == signum:
			add_parts(dn)
		else:
			if abs_greater(dn):
				sub_parts(dn)
			else:
				dn.sub_parts(self)
				parts = dn.parts
				dn = null
				signum *= -1

func add_parts (n: Number) -> void:
	var carry := 0
	for place in range(precision-1, -1, -1):
		var new_part := parts[place] + n.parts[place] + carry
		parts[place] = new_part & 0xffff
		carry = new_part >> 16


func sub_parts (n: Number) -> void:
	var carry := 0
	for place in range(precision-1, -1, -1):
		var new_part := parts[place] - n.parts[place] - carry
		if new_part < 0:
			new_part += 0x1_00_00
			carry = 1
		else:
			carry = 0
		parts[place] = new_part


func to_double () -> float:
	if precision <= Position.PRECISION_DOUBLES:
		return double_repr

	var d := 0.0
	var d_factor := 1.0
	for place in range(precision):
		d += d_factor * parts[place]
		d_factor /= 0x1_00_00
	return signum * d


func set_from_double (d: float) -> void:
	if precision <= Position.PRECISION_DOUBLES:
		double_repr = d

	var abs_d: float = abs(d)
	for place in range(precision):
		parts[place] = int(abs_d)
		abs_d -= int(abs_d)
		abs_d *= 0x1_00_00

	signum =  -1 if d < 0  else +1


func _to_string () -> String:

	if precision < Position.PRECISION_ARBITRARY:
		return var_to_str(double_repr)

	var result :=  "-" if signum==-1  else "+"

	result += "%04X:" % [parts[0]]
	for place in range(1, precision):
		result += "%04X" % [parts[place]]

	return result


func set_from_string (s: String) -> void:

	# the temporary object for parsing must have at least fixed precision
	var tmp_precision: int = max(precision, Position.PRECISION_ARBITRARY)
	var tmp := Number.new(tmp_precision)

	if s.length() > 5 and s[1 + 4] == ":":
		tmp.signum =  -1 if s[0] == "-"  else +1
		tmp.parts[0] = s.substr(1,4).hex_to_int()
		var mantissa_str := s.substr(1+4+1)
		@warning_ignore("integer_division")
		var l: int = min(-1+tmp.precision, mantissa_str.length() / 4)
		for i in range(l):
			tmp.parts[1+i] = mantissa_str.substr(i*4, 4).hex_to_int()

	else:
		tmp.set_from_double(s.to_float())

	if precision < Position.PRECISION_ARBITRARY:
		double_repr = tmp.to_double()
	else:
		signum = tmp.signum
		parts = tmp.parts
		tmp = null



func abs_greater (n: Number) -> bool:
	for place in range(precision):
		if parts[place] > n.parts[place]:
			return true
		if parts[place] < n.parts[place]:
			return false
	return false
