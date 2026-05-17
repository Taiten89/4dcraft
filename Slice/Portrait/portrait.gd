class_name Portrait
extends RefCounted

var max_distance: float
var slices: Array[Slice] = []
var distances: Array[float] = []


func _init (mid: Slice, n: int, new_max_distance := 2.0) -> void:
	max_distance = new_max_distance
	slices.resize(n)
	distances.resize(n)

	if n == 1:
		slices[0] = make_slice(mid, 1.0)
		return

	for i in range(n):
		var i_n := float(i) / float(n)
		var distance_rev := max_distance * i_n ** 3
		var distance := max_distance - distance_rev
		slices[i] = make_slice(mid, distance)
		distances[i] = distance


func make_slice (mid: Slice, distance: float) -> Slice:
	var slice := mid.copy()

	var fore := slice.base.column(1)
	slice.position.translate_inplace(-fore)
	slice.position.translate_inplace(distance * fore)
	slice.base.scale_inplace(distance / 2)

	return slice
