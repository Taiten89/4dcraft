class_name Find_Time
extends RefCounted

const N_FINE_ITERATIONS := 10
const Params := Find_Time_Params.Params
const Item := Find_Time_Item.Item

var result: Base
var slice: Slice
var params: Params
var common: Find_Time_Common
var n_steps: int
var i := 0


func _init (new_slice: Slice, new_params := Params.new()) -> void:
	slice = new_slice
	params = new_params
	common = Find_Time_Common.new(slice, make_rough_bases(), params)
	make_n_steps()


func step () -> void:
	if common.rough_base_i == common.rough_bases.size():
		params.fineness += 1.0
		common = Find_Time_Common.new(slice, common.result, params)
	common.step()
	i += 1
	if i == n_steps:
		result = common.result_with_lowest_aberration()


func make_rough_bases () -> Array[Item]:
	var rough_bases: Array[Item] = []
	for a_mangle in range(4):
		for signum in [+1,-1]:
			rough_bases.append(make_rough_base(a_mangle, signum))
	return rough_bases


func make_rough_base (a_mangle: int, signum: int) -> Item:
	var base := Base.new()
	base.length = slice.base.length
	for a in range(4):
		base.columns[a] = Vector4(0,0,0,0)
		var mapped_to := (a + a_mangle) % 4
		base.columns[a][mapped_to] = 1
	base.columns[3] *= signum
	return Item.new(base)


func make_n_steps () -> void:
	var rough_bases: Array[Item] = [null,null, null,null, null,null, null,null]
	var rough_dummy := Find_Time_Common.new(slice, rough_bases, Params.new())
	var fine_bases := rough_bases
	var fine_params := Params.new()
	fine_params.fineness = 0.1
	fine_bases.resize(fine_params.n_items_kept)
	var fine_dummy := Find_Time_Common.new(slice, fine_bases, fine_params)
	n_steps = rough_dummy.n_steps() + N_FINE_ITERATIONS * fine_dummy.n_steps()
