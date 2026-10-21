class_name Slice
extends RefCounted

const AXIS_REPR_SHORT := "RFUT"
const AXIS_REPR := ["Right", "Fore", "Up", "Time"]

# factor found by trial and error
const CC_FINENESS_FOR_60FPS = 11 / log(Find_Time_Common.ANGLE_DIV)

var mode := "default"
var custom_code := ""
var max_n := 50
var position := Position.new()
var base := Base.new()
var palette := Palette.new()
var render := Render_Info.new()


func copy () -> Slice:
	var slice := Slice.new()
	slice.mode = mode
	slice.custom_code = str(custom_code)
	slice.max_n = max_n
	slice.position = position.copy()
	slice.base = base.copy()
	slice.palette = palette.copy()
	slice.render = render.copy()
	return slice


func bytes_for_uniforms
(aspect_ratio: float, render_z_pl := Vector4()) \
-> PackedByteArray:
	var render_xy := render_xy_for_aspect_ratio(aspect_ratio)
	return \
		vec4_bytes(render_xy[0]) + \
		vec4_bytes(render_xy[1]) + \
		vec4_bytes(render_z_pl) + \
		position.bytes_for_uniforms() + \
		PackedInt32Array([max_n]).to_byte_array()


func variant_for_storage () -> Dictionary[String,Variant]:
	var v: Dictionary[String,Variant] = {}
	v['mode'] = mode
	v['custom_code'] = custom_code
	v['max_n'] = max_n
	v['position'] = position.variant_for_storage()
	v['base'] = base.variant_for_storage()
	v['palette'] = palette.variant_for_storage()
	v['render'] = render.variant_for_storage()
	return v


func set_from_storage_variant (v: Dictionary) -> void:
	mode = v['mode']
	custom_code = v['custom_code']
	max_n = v['max_n']
	position.set_from_storage_variant(v['position'])
	base.set_from_storage_variant(v['base'])
	palette.set_from_storage_variant(v['palette'])
	render.set_from_storage_variant(v['render'])


func render_xy_for_aspect_ratio (aspect_ratio: float) -> Array[Vector4]:
	if aspect_ratio >= 1.0:
		var render_x := aspect_ratio * base.column(0)
		return [render_x, base.column(1)]
	else:
		var render_y := base.column(1) / aspect_ratio
		return [base.column(0), render_y]


func vec4_bytes (v: Vector4) -> PackedByteArray:
	return PackedFloat32Array([v.x, v.y, v.z, v.w]).to_byte_array()


func zoom (mouse_x: float, mouse_y: float, amount: float) -> void:

	# constant position under the mouse (before vs after)
	var mouse_pos: Position = position.copy()
	mouse_pos.translate_inplace \
		(mouse_x * base.column(0) +
		 mouse_y * base.column(1))  # old base

	var factor := 2.0 ** -amount

	base.scale_inplace(factor)

	position = mouse_pos
	mouse_pos = null
	var translation := \
	-(mouse_x * base.column(0) +
	  mouse_y * base.column(1))  # new base
	position.translate_inplace(translation)


func modify_for_1_image (always_cc := false) -> void:
	translate_for_1_image()
	if always_cc or render.movie.is_cc:
		correct_continuously_for_1_image()


func translate_for_1_image () -> void:
	var full_time_span := render.movie.stop - render.movie.start
	var time_factor := full_time_span / render.movie.images
	var time_translation := time_factor * base.column(3)
	position.translate_inplace(time_translation)


func correct_continuously_for_1_image () -> void:
	var rough_bases: Array[Find_Time_Common.Item] = \
		[Find_Time_Common.Item.new(base)]
	var fps := render.movie.fps
	var cc_fineness := log(fps) / log(60) * CC_FINENESS_FOR_60FPS
	var ftime := Find_Time_Common.new(self, rough_bases, cc_fineness)
	for ftime_step_i in range(ftime.n_steps()):
		ftime.step()
	base = ftime.result_with_lowest_aberration()
