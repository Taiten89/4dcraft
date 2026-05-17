class_name Portrait_Paint
extends RefCounted

var slice_paint: Slice_Paint
var portrait: Portrait
var result: Texture2DRD


func _init (calculation: Calculation) -> void:
	slice_paint = Slice_Paint.new(calculation)


func paint (new_portrait: Portrait, params: Calculation.Params) -> void:
	portrait = new_portrait
	var slices := portrait.slices
	var distances := portrait.distances
	update_alpha(distances[0])
	paint_slice(slices[0], params, true)
	for i in range(1, slices.size()):
		update_alpha(distances[i])
		paint_slice(slices[i], params, false)
	portrait = null


func interpolate () -> void:
	slice_paint.interpolate()
	result = slice_paint.result


func update_alpha (distance: float) -> void:
	var relative_distance := distance / portrait.max_distance
	slice_paint.alpha = 1 - relative_distance


func paint_slice (slice: Slice, params: Calculation.Params, clear_bg: bool) -> void:
	slice_paint.paint(modified_slice(slice), params, clear_bg)


func modified_slice (orig_slice: Slice) -> Slice:
	var slice := orig_slice.copy()
	var orig_column1 = Vector4(orig_slice.base.columns[1])
	var orig_column2 = Vector4(orig_slice.base.columns[2])
	slice.base.columns[1] = orig_column2
	slice.base.columns[2] = orig_column1
	return slice
