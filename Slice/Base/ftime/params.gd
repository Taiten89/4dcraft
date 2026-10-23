class_name Find_Time_Params


class Params \
extends RefCounted:

	var fineness := 1.0
	var n_items_kept := 4
	var angle_div := 4
	var time_div := 15
	var resolution := 30


	func copy () -> Params:
		var params := Params.new()
		params.fineness = fineness
		params.n_items_kept = n_items_kept
		params.angle_div = angle_div
		params.time_div = time_div
		params.resolution = resolution
		return params


	func variant_for_storage () -> Dictionary[String,Variant]:
		var v: Dictionary[String,Variant] = {}
		v['fineness'] = fineness
		v['n_items_kept'] = n_items_kept
		v['angle_div'] = angle_div
		v['time_div'] = time_div
		v['resolution'] = resolution
		return v


	func set_from_storage_variant (v: Dictionary) -> void:
		fineness = v['fineness']
		n_items_kept = v['n_items_kept']
		angle_div = v['angle_div']
		time_div = v['time_div']
		resolution = v['resolution']
