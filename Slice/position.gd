class_name Position
extends RefCounted

const PRECISION_FLOATS = 3
const PRECISION_DOUBLES = 4
const PRECISION_ARBITRARY = 5

var precision: int
var numbers: Array[Number]


@warning_ignore("shadowed_variable")
func _init (precision := PRECISION_FLOATS) -> void:
	self.precision = precision
	numbers = [Number.new(precision), Number.new(precision),
		Number.new(precision), Number.new(precision)]


func copy () -> Position:
	var p := Position.new(precision)
	for a in range(4):
		p.numbers[a] = numbers[a].copy()
	return p


func bytes_for_uniforms () -> PackedByteArray:
	var bytes := \
		numbers[0].bytes_for_uniforms() + \
		numbers[1].bytes_for_uniforms() + \
		numbers[2].bytes_for_uniforms() + \
		numbers[3].bytes_for_uniforms()
	return bytes


func variant_for_storage () -> Dictionary[String,Variant]:
	var v: Dictionary[String,Variant] = {}
	v['precision'] = precision
	var v_numbers: Array[String] = []
	for number in numbers:
		v_numbers.append(str(number))
	v['numbers'] = v_numbers
	return v


func set_from_storage_variant (v: Dictionary) -> void:
	change_precision(v['precision'])
	for a in range(4):
		var number_s: String = v['numbers'][a]
		numbers[a].set_from_string(number_s)


func change_precision (new_precision: int) -> void:
	precision = new_precision
	for a in range(4):
		numbers[a].change_precision(new_precision)


func translate_inplace (t: Vector4) -> void:
	for a in range(4):
		numbers[a].add_d_inplace(t[a])
