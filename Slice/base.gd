class_name Base
extends RefCounted

var length := 2.0
var columns: Array[Vector4]


func _init () -> void:
	for axis in range(4):
		var new_column := Vector4(0.0, 0.0, 0.0, 0.0)
		new_column[axis] = 1.0
		columns.append(new_column)
	variant_for_storage()


func copy () -> Base:
	var base := Base.new()
	base.length = length
	for axis in range(4):
		base.columns[axis] = Vector4(columns[axis])
	return base


func variant_for_storage () -> Dictionary[String,Variant]:
	var v: Dictionary[String,Variant] = {}
	v['length'] = length
	var v_columns: Array[Array] = []
	for c in columns:
		v_columns.append([c.x,c.y,c.z,c.w])
	v['columns'] = v_columns
	return v


func set_from_storage_variant (v: Dictionary) -> void:
	length = v['length']
	for a in range(4):
		var vc: Array = v['columns'][a]
		columns[a] = Vector4(vc[0],vc[1],vc[2],vc[3])


func column (axis: int) -> Vector4:
	return length * columns[axis]


func scale_inplace (by: float) -> void:
	length *= by


func rotate_inplace (i0: int, i1: int, θ: float) -> void:
	var new_column_i0 := cos(θ)*columns[i0] + sin(θ)*columns[i1]
	var new_column_i1 := -sin(θ)*columns[i0] + cos(θ)*columns[i1]
	columns[i0] = new_column_i0
	columns[i1] = new_column_i1
	stabilize_if_needed()


func stabilize_if_needed () -> void:
	# this measure was made up on the spot;
	# after ca. 100 tests with print(), assuming correctness
	var measure := 0.0
	for axis0 in range(3):
		for axis1 in range(axis0+1, 4):
			var dot_product := columns[axis0].dot(columns[axis1])
			measure += abs(dot_product)
	if measure > 0.001 ** 2:
		do_stabilize()


func do_stabilize() -> void:
	# Modified Gram-Schmidt procedure as in:
	# https://www.math.uci.edu/~ttrogdon/105A/html/Lecture23.html
	var q := columns

	var v: Array[Vector4] = []
	for j in range(4):
		var v_j := Vector4(q[j])
		v.push_back(v_j)

	for j in range(4):
		q[j] = v[j].normalized()
		for k in range(j+1, 4):
			var projection := q[j].dot(v[k]) * q[j]
			v[k] -= projection
