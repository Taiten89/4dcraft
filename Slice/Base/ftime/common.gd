class_name Find_Time_Common
extends RefCounted

const RESULT_SIZE := 4

const ANGLE_DIV := 4
const TIME_DIV := 15
const RESOLUTION := 30

const ROUGH_ANGLE_START := -TAU / 8
const ROUGH_ANGLE_STEP := TAU / 4 / ANGLE_DIV

var result: Array[Item] = []
var slice: Slice
var rough_bases: Array[Item]

var calculation := Calculation.new()

var angle_start: float
var angle_step: float
var rough_base_i := 0
var angle_i: Array[int] = [0,0,0]


class Item:
	var base: Base
	var aberration := 0
	func _init (new_base: Base) -> void:
		base = new_base.copy()


func _init
(new_slice: Slice, new_rough_bases: Array[Item], fineness: float) \
-> void:
	result.resize(RESULT_SIZE)
	slice = new_slice.copy()
	rough_bases = new_rough_bases
	angle_start = ROUGH_ANGLE_START / (ANGLE_DIV**fineness)
	angle_step = ROUGH_ANGLE_STEP / (ANGLE_DIV**fineness)


func n_steps () -> int:
	return rough_bases.size() * ANGLE_DIV**3


func step () -> void:
	var item := make_item()
	item.aberration = calculate_aberration(item.base)
	insert_item(item)
	increment()


func make_item () -> Item:
	var base := rough_bases[rough_base_i].base
	for i0 in range(3):
		const i1 := 3
		var amount := angle_start + angle_i[i0] * angle_step
		base.rotate_inplace(i0, i1, amount)
	return Item.new(base)


func calculate_aberration (base: Base) -> int:
	var aberration := 0
	var mass0 := calculate_mass(base, 0)
	for time_i in range(1, TIME_DIV+1):
		aberration += abs(mass0 - calculate_mass(base, time_i))
	return aberration


func calculate_mass (base: Base, time_i: int) -> int:
	var original_position := slice.position.copy()
	slice.base = base

	var z_trans := -1.0
	var t_trans := float(time_i) / float(TIME_DIV)
	slice.position.translate_inplace \
		(z_trans * slice.base.column(2)
		 + t_trans * slice.base.column(3))
	var z_pl := 2 * base.length / RESOLUTION

	var params := Calculation.Params.new()
	params.w = RESOLUTION
	params.h = RESOLUTION
	params.d = RESOLUTION
	params.render_z_pl = z_pl * slice.base.columns[2]
	params.workgroup_w = 8
	params.workgroup_h = 8

	calculation.calculate(slice, params)

	var mass := 0
	for r in calculation.retrieve_result():
		mass += int(r)  # Array.reduce is slower

	slice.position = original_position
	return mass


func insert_item (item: Item) -> void:
	var rwha := result_with_highest_aberration()
	if result[rwha] == null or item.aberration < result[rwha].aberration:
		result[rwha] = item


func result_with_lowest_aberration () -> Base:
	var r := result[0]
	for i in range(1, result.size()):
		if result[i].aberration < r.aberration:
			r = result[i]
	return r.base


func result_with_highest_aberration () -> int:
	var i := 0
	for j in range(result.size()):
		if result[j] == null:
			return j
		if result[j].aberration > result[i].aberration:
			i = j
	return i


func increment () -> void:
	angle_i[0] += 1
	if angle_i[0] == ANGLE_DIV:
		angle_i[1] += 1
		angle_i[0] = 0
	if angle_i[1] == ANGLE_DIV:
		angle_i[2] += 1
		angle_i[1] = 0
	if angle_i[2] == ANGLE_DIV:
		rough_base_i += 1
		angle_i[2] = 0
