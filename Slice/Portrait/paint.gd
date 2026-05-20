class_name Portrait_Paint
extends RefCounted

var i: int
var portrait: Portrait
var params: Calculation.Params
var slice_paint: Slice_Paint
var result: Texture2DRD


func _init (calculation: Calculation) -> void:
	slice_paint = Slice_Paint.new(calculation)


func paint (new_portrait: Portrait, new_params: Calculation.Params) -> void:
	start(new_portrait, new_params)
	for s in range(n_steps()):
		step()


func start (new_portrait: Portrait, new_params: Calculation.Params) -> void:
	i = 0
	portrait = new_portrait
	params = new_params


func n_steps () -> int:
	return portrait.slices.size()


func step () -> void:
	var n: float = portrait.slices.size()
	var relative_distance := portrait.distances[i] / portrait.max_distance
	# alpha forged to fit usage
	slice_paint.alpha = (1 - relative_distance) ** (1 + n/5000)
	slice_paint.paint(modified_slice(portrait.slices[i]), params, i == 0)

	if i == n_steps() - 1:
		portrait = null
	result = slice_paint.result
	i += 1


func interpolate () -> void:
	slice_paint.interpolate()
	result = slice_paint.result


func modified_slice (orig_slice: Slice) -> Slice:
	var slice := orig_slice.copy()
	var orig_column1 = Vector4(orig_slice.base.columns[1])
	var orig_column2 = Vector4(orig_slice.base.columns[2])
	slice.base.columns[1] = orig_column2
	slice.base.columns[2] = orig_column1
	return slice
