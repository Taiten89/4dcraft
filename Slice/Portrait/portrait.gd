class_name Portrait
extends RefCounted

var fore_margin := 0.5
var fore_range := 2.0
var max_distance := fore_margin + fore_range
var slices: Array[Slice] = []
var distances: Array[float] = []


func _init (mid: Slice, n: int) -> void:
	slices.resize(n)
	distances.resize(n)

	if n == 1:
		var distance := fore_margin + fore_range/2
		slices[0] = make_slice(mid, distance)
		return

	for i in range(n):
		var i_n := float(i) / float(n-1)
		var mapped_i := fore_range * i_n ** 3
		var distance := fore_margin + fore_range - mapped_i
		slices[i] = make_slice(mid, distance)
		distances[i] = distance


func make_slice (mid: Slice, distance: float) -> Slice:
	var slice := mid.copy()

	var fore_factor := distance - fore_range/2 - fore_margin
	var fore_column := slice.base.column(1)
	slice.position.translate_inplace(fore_factor * fore_column)

	slice.base.scale_inplace(distance / 2)

	return slice
